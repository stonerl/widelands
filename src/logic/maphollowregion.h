/*
 * Copyright (C) 2004-2019 by the Widelands Development Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 */

#ifndef WL_LOGIC_MAPHOLLOWREGION_H
#define WL_LOGIC_MAPHOLLOWREGION_H

#include "logic/map.h"

namespace Widelands {

enum class MapHollowRegionPhase {
	kNone = 0,    // not initialized or completed
	kTop = 1,     // above the hole
	kUpper = 2,   // upper half
	kLower = 4,   // lower half
	kBottom = 8,  // below the hole
};

// A bunch of operators that turn MapHollowRegionPhase into a bitwise combinable class.
inline MapHollowRegionPhase operator|(MapHollowRegionPhase left, MapHollowRegionPhase right) {
	return MapHollowRegionPhase(static_cast<int>(left) | static_cast<int>(right));
}
inline int operator&(MapHollowRegionPhase left, MapHollowRegionPhase right) {
	return static_cast<int>(left) & static_cast<int>(right);
}

/**
 * Producer/Coroutine struct that iterates over every node for which the
 * distance to the center point is greater than hollow_area.hole_radius and
 * at most hollow_area.radius.
 *
 * \note The order in which fields are returned is not guarantueed.
 */
template <typename AreaType = Area<>> struct MapHollowRegion {
	MapHollowRegion(const Map& map, const HollowArea<AreaType>& hollow_area)
	   : hollow_area_(hollow_area),
		 phase_(MapHollowRegionPhase::kTop),
		 delta_radius_(hollow_area.radius - hollow_area.hole_radius),
		 row_(0),
		 rowwidth_(hollow_area.radius + 1),
		 rowpos_(0),
		 left_(hollow_area) {
		assert(hollow_area.hole_radius < hollow_area.radius);
		for (uint16_t r = hollow_area.radius; r; --r)
			map.get_tln(hollow_area_, &hollow_area_);
		left_ = hollow_area_;
	}

	const typename AreaType::CoordsType& location() const {
		return hollow_area_;
	}

	/**
	 * Moves on to the next location, traversing the region by row.
	 *
	 * I hope traversing by row results in slightly better cache behaviour
	 * than other algorithms (e.g. one could also walk concentric "circles"
	 * / hexagons).
	 *
	 * \return Whether the new location has not yet been reached during this
	 * iteration.
	 *
	 * \note When the area is so large that it overlaps itself because of
	 * wrapping, the same location may be reached several times during an
	 * iteration, while advance keeps returning true. When finally advance
	 * returns false, it means that the iteration is done.
	 */
	bool advance(const Map& map) {
		if (phase_ == MapHollowRegionPhase::kNone) {
			return false;
		}
		++rowpos_;
		if (rowpos_ < rowwidth_) {
			map.get_rn(hollow_area_, &hollow_area_);
			if ((phase_ & (MapHollowRegionPhase::kUpper | MapHollowRegionPhase::kLower)) && rowpos_ == delta_radius_) {
				//  Jump over the hole.
				const uint32_t holewidth = rowwidth_ - 2 * delta_radius_;
				for (uint32_t i = 0; i < holewidth; ++i)
					map.get_rn(hollow_area_, &hollow_area_);
				rowpos_ += holewidth;
			}
		} else {
			++row_;
			if (phase_ == MapHollowRegionPhase::kTop && row_ == delta_radius_) {
				phase_ = MapHollowRegionPhase::kUpper;
			}

			// If we completed the widest, center line, switch into lower mode
			// There are radius_+1 lines in the upper "half", because the upper
			// half includes the center line.
			else if (phase_ == MapHollowRegionPhase::kUpper && row_ > hollow_area_.radius) {
				row_ = 1;
				phase_ = MapHollowRegionPhase::kLower;
			}

			if (phase_ & (MapHollowRegionPhase::kTop | MapHollowRegionPhase::kUpper)) {
				map.get_bln(left_, &hollow_area_);
				++rowwidth_;
			} else {

				if (row_ > hollow_area_.radius) {
					phase_ = MapHollowRegionPhase::kNone;
					return true;  // early out
				} else if (phase_ == MapHollowRegionPhase::kLower && row_ > hollow_area_.hole_radius) {
					phase_ = MapHollowRegionPhase::kBottom;
				}

				map.get_brn(left_, &hollow_area_);
				--rowwidth_;
			}

			left_ = hollow_area_;
			rowpos_ = 0;
		}

		return true;
	}

private:
	HollowArea<AreaType> hollow_area_;
	MapHollowRegionPhase phase_;
	const uint32_t delta_radius_;
	uint32_t row_;                        // # of rows completed in this phase
	uint32_t rowwidth_;                   // # of fields to return per row
	uint32_t rowpos_;                     // # of fields we have returned in this row
	typename AreaType::CoordsType left_;  //  left-most node of current row
};

}  // namespace Widelands

#endif  // end of include guard: WL_LOGIC_MAPHOLLOWREGION_H

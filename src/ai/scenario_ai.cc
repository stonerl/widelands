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

#include "ai/scenario_ai.h"

#include "economy/flag.h"
#include "economy/road.h"
#include "logic/field.h"
#include "logic/game.h"
#include "logic/map.h"
#include "logic/map_objects/checkstep.h"
#include "logic/player.h"

ScenarioAI::ScenarioAIImpl ScenarioAI::implementation;

ScenarioAI::ScenarioAI(Widelands::Game& ggame, Widelands::PlayerNumber const pid)
   : ComputerPlayer(ggame, pid),
   did_init_(false),
   last_time_thought_(0) {
}

ScenarioAI::~ScenarioAI() {
}

template<typename Key = std::string>
static inline void allow_or_erase(std::set<Key>* set, const Key& what, bool insert) {
	if (insert) {
		set->insert(what);
	} else {
		const auto it = set->find(what);
		if (it != set->end()) {
			set->erase(it);
		}
	}
}

void ScenarioAI::set_militarysite_allowed(const std::string& name, bool allow) {
	allow_or_erase<>(&allowed_militarysites_, name, allow);
}

void ScenarioAI::set_productionsite_allowed(const std::string& name, bool allow) {
	allow_or_erase<>(&allowed_productionsites_, name, allow);
}

void ScenarioAI::set_trainingsite_allowed(const std::string& name, bool allow) {
	allow_or_erase<>(&allowed_trainingsites_, name, allow);
}

void ScenarioAI::set_warehouse_allowed(const std::string& name, bool allow) {
	allow_or_erase<>(&allowed_warehouses_, name, allow);
}

void ScenarioAI::set_basic_economy(const std::string& building, uint32_t amount, uint32_t importance) {
	if (amount > 0) {
		basic_economy_[building] = {amount, importance};
	} else {
		basic_economy_.erase(building);
	}
}

void ScenarioAI::set_ware_preciousness(const std::string& ware, uint32_t p) {
	ware_preciousness_[ware] = p;
}

void ScenarioAI::set_is_enemy(Widelands::PlayerNumber player, bool enemy) {
	allow_or_erase<Widelands::PlayerNumber>(&enemies_, player, enemy);
}

void ScenarioAI::init() {
	// If we ever want to do initialisation stuff like setting economy targets, do it here

	log("ScenarioAI %u initialized\n", player_number());
	did_init_ = true;
}

constexpr uint32_t flag_connecting_search_radius = 24;

bool ScenarioAI::try_connect_flag(Widelands::FCoords& start, Widelands::FCoords* end) {
	const Widelands::Map& map = game().map();
	Widelands::CheckStepRoad cstep(game().player(player_number()), Widelands::MOVECAPS_WALK);
	Widelands::Path path(start);

	if (end) {
		if (map.findpath(start, *end, 0, path, cstep) > 0) {
			game().send_player_build_road(player_number(), path);
			return true;
		}
		return false;
	}

	std::vector<Widelands::ImmovableFound> results;
	map.find_reachable_immovables(Widelands::Area<Widelands::FCoords>(start, flag_connecting_search_radius),
			&results, cstep, Widelands::FindImmovableType(Widelands::MapObjectType::FLAG));
	if (results.empty()) {
		return false;
	}
	std::map<Widelands::Path*, int32_t> paths;
	int32_t shortest = std::numeric_limits<int32_t>::max();
	for (const Widelands::ImmovableFound& r : results) {
		Widelands::Path* p = new Widelands::Path(start);
		int32_t cost = map.findpath(start, map.get_fcoords(r.coords), 0, *p, cstep);
		if (cost > 0) {
			paths[p] = cost;
			shortest = std::min(shortest, cost);
		}
		else {
			delete p;
		}
	}
	bool done = false;
	for (auto pair : paths) {
		if (pair.second == shortest) {
			game().send_player_build_road(player_number(), *pair.first);
			done = true;
		}
		else {
			delete pair.first;
		}
	}

	return done;
}

// Don't think too often, because we like to wait until our commands have been executed
constexpr uint32_t kThinkInterval = 200;

void ScenarioAI::think() {
	const uint32_t time = game().get_gametime();
	if (time - last_time_thought_ < kThinkInterval) {
		return;
	}
	last_time_thought_ = time;

	if (!did_init_) {
		return init();
	}

	const Widelands::Map& map = game().map();

	// We begin by cleaning up our road network. Long roads are broken into shorter sections, dead-ends are removed.

	for (Widelands::MapIndex i = map.max_index(); i; --i) {
		Widelands::Field& f = map[i - 1];
		Widelands::FCoords coords = map.get_fcoords(f);
		if (f.get_owned_by() == player_number()) {
			if (upcast(Widelands::Flag, flag, f.get_immovable())) {
				if (flag->nr_of_roads() < 2) {
					// Found a flag with at most one road – connect or remove
					if (flag->get_building()) {
						if (try_connect_flag(coords)) {
							return;
						}
					} else {
						return game().send_player_bulldoze(*flag);
					}
				}
				for (uint8_t dir = 1; dir <= 6; ++dir) {
					if (Widelands::Road* r = flag->get_road(dir)) {
						const size_t max_length = r->get_path().get_nsteps();
						Widelands::FCoords iterate = map.get_fcoords(r->get_path().get_start());
						for (size_t id = 0; id < max_length; ++id) {
							map.get_neighbour(iterate, r->get_path()[id], &iterate);
							if (iterate.field->nodecaps() & Widelands::BUILDCAPS_FLAG) {
								return game().send_player_build_flag(player_number(), iterate);
							}
							if (id > 2) {
								return game().send_player_bulldoze(*r);
							}
						}
					}
				}
			}
		}
	}



}


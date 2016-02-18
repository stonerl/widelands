/*
 * Copyright (C) 2009-2010 by the Widelands Development Team
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

#include "ai/ai_help_structs.h"

#include "base/macros.h"
#include "logic/player.h"

namespace Widelands {

// CheckStepRoadAI
CheckStepRoadAI::CheckStepRoadAI(Player* const pl, uint8_t const mc, bool const oe)
	: player(pl), movecaps(mc), open_end(oe) {}

bool CheckStepRoadAI::allowed(
   Map& map, FCoords start, FCoords end, int32_t, CheckStep::StepId const id) const {
	uint8_t endcaps = player->get_buildcaps(end);

	// we should not cross fields with road or flags (or any other immovable)
	if ((map.get_immovable(start)) && !(id == CheckStep::stepFirst)) {
		return false;
	}

	// Calculate cost and passability
	if (!(endcaps & movecaps))
		return false;

	// Check for blocking immovables
	if (BaseImmovable const* const imm = map.get_immovable(end))
		if (imm->get_size() >= BaseImmovable::SMALL) {
			if (id != CheckStep::stepLast && !open_end)
				return false;

			if (dynamic_cast<Flag const*>(imm))
				return true;

			if (!dynamic_cast<Road const*>(imm) || !(endcaps & BUILDCAPS_FLAG))
				return false;
		}

	return true;
}

bool CheckStepRoadAI::reachable_dest(Map& map, FCoords const dest) const {
	NodeCaps const caps = dest.field->nodecaps();

	if (!(caps & movecaps)) {
		if (!((movecaps & MOVECAPS_SWIM) && (caps & MOVECAPS_WALK)))
			return false;

		if (!map.can_reach_by_water(dest))
			return false;
	}

	return true;
}

// We are looking for fields we can walk on
// and owned by hostile player.
FindNodeEnemy::FindNodeEnemy(Player* p, Game& g) : player(p), game(g) {}

bool FindNodeEnemy::accept(const Map&, const FCoords& fc) const {
	return (fc.field->nodecaps() & MOVECAPS_WALK) && fc.field->get_owned_by() != 0 &&
			 player->is_hostile(*game.get_player(fc.field->get_owned_by()));
}

// We are looking for buildings owned by hostile player
// (sometimes there is a enemy's teritorry without buildings, and
// this confuses the AI)
FindNodeEnemiesBuilding::FindNodeEnemiesBuilding(Player* p, Game& g) : player(p), game(g) {}

bool FindNodeEnemiesBuilding::accept(const Map&, const FCoords& fc) const {
	return (fc.field->get_immovable()) && fc.field->get_owned_by() != 0 &&
			 player->is_hostile(*game.get_player(fc.field->get_owned_by()));
}

// When looking for unowned terrain to acquire, we are actually
// only interested in fields we can walk on.
// Fields should either be completely unowned or owned by an opposing player
FindNodeUnowned::FindNodeUnowned(Player* p, Game& g, bool oe) : player(p), game(g), only_enemies(oe) {}

bool FindNodeUnowned::accept(const Map&, const FCoords& fc) const {
	return (fc.field->nodecaps() & MOVECAPS_WALK) &&
			 ((fc.field->get_owned_by() == 0) ||
			  player->is_hostile(*game.get_player(fc.field->get_owned_by()))) &&
			 (!only_enemies || (fc.field->get_owned_by() != 0));
}

// Sometimes we need to know how many nodes our allies owns
FindNodeAllyOwned::FindNodeAllyOwned(Player* p, Game& g, PlayerNumber n) : player(p), game(g), player_number(n) {}

bool FindNodeAllyOwned::accept(const Map&, const FCoords& fc) const {
	return (fc.field->nodecaps() & MOVECAPS_WALK) && (fc.field->get_owned_by() != 0) &&
			 (fc.field->get_owned_by() != player_number) &&
			 !player->is_hostile(*game.get_player(fc.field->get_owned_by()));
}

// When looking for unowned terrain to acquire, we must
// pay speciall attention to fields where mines can be built.
// Fields should be completely unowned
FindNodeUnownedMineable::FindNodeUnownedMineable(Player* p, Game& g) : player(p), game(g) {}

bool FindNodeUnownedMineable::accept(const Map&, const FCoords& fc) const {
	return (fc.field->nodecaps() & BUILDCAPS_MINE) && (fc.field->get_owned_by() == 0);
}

// Unowned but walkable fields nearby
FindNodeUnownedWalkable::FindNodeUnownedWalkable(Player* p, Game& g) : player(p), game(g) {}

bool FindNodeUnownedWalkable::accept(const Map&, const FCoords& fc) const {
	return (fc.field->nodecaps() & MOVECAPS_WALK) && (fc.field->get_owned_by() == 0);
}

// Looking only for mines-capable fields nearby
// of specific type
FindNodeMineable::FindNodeMineable(Game& g, int32_t r) : game(g), res(r) {}

bool FindNodeMineable::accept(const Map&, const FCoords& fc) const {

	return (fc.field->nodecaps() & BUILDCAPS_MINE) && (fc.field->get_resources() == res);
}


// Fishers and fishbreeders must be built near water
FindNodeWater::FindNodeWater(const World& world) : world_(world) {}

bool FindNodeWater::accept(const Map& /* map */, const FCoords& coord) const {
	return (world_.terrain_descr(coord.field->terrain_d()).get_is() &
			  TerrainDescription::Is::kWater) ||
			 (world_.terrain_descr(coord.field->terrain_r()).get_is() &
			  TerrainDescription::Is::kWater);
}

// FindNodeWithFlagOrRoad
bool FindNodeWithFlagOrRoad::accept(const Map&, FCoords fc) const {
	if (upcast(PlayerImmovable const, pimm, fc.field->get_immovable()))
		return (dynamic_cast<Flag const*>(pimm) ||
				  (dynamic_cast<Road const*>(pimm) && (fc.field->nodecaps() & BUILDCAPS_FLAG)));
	return false;
}

NearFlag::NearFlag(const Flag& f, int32_t const c, int32_t const d) : flag(&f), cost(c), distance(d) {}

BuildableField::BuildableField(const Widelands::FCoords& fc)
	: coords(fc),
	  field_info_expiration(20000),
	  preferred(false),
	  enemy_nearby(0),
	  unowned_land_nearby(0),
	  near_border(false),
	  unowned_mines_spots_nearby(0),
	  trees_nearby(0),
	  // explanation of starting values
	  // this is done to save some work for AI (CPU utilization)
	  // base rules are:
	  // count of rocks can only decrease, so  amount of rocks
	  // is recalculated only when previous count is positive
	  // count of water fields are stable, so if the current count is
	  // non-negative, water is not recaldulated
	  rocks_nearby(1),
	  water_nearby(-1),
	  distant_water(0),
	  fish_nearby(-1),
	  critters_nearby(-1),
	  ground_water(1),
	  space_consumers_nearby(0),
	  rangers_nearby(0),
	  area_military_capacity(0),
	  military_loneliness(1000),
	  military_in_constr_nearby(0),
	  area_military_presence(0),
	  military_stationed(0),
	  military_unstationed(0),
	  is_portspace(false),
	  port_nearby(false),
	  portspace_nearby(Widelands::ExtendedBool::kUnset),
	  max_buildcap_nearby(0),
	  last_resources_check_time(0) {
}

int32_t BuildableField::own_military_sites_nearby_() {
	return military_stationed + military_unstationed;
}

MineableField::MineableField(const Widelands::FCoords& fc)
	: coords(fc),
	  field_info_expiration(20000),
	  preferred(false),
	  mines_nearby(0),
	  same_mine_fields_nearby(0) {
}

EconomyObserver::EconomyObserver(Widelands::Economy& e) : economy(e) {
	dismantle_grace_time = std::numeric_limits<int32_t>::max();
}

int32_t BuildingObserver::total_count() const {
	return cnt_built + cnt_under_construction;
}

Widelands::AiModeBuildings BuildingObserver::aimode_limit_status() {
	if (total_count() > cnt_limit_by_aimode) {
		return Widelands::AiModeBuildings::kLimitExceeded;
	} else if (total_count() == cnt_limit_by_aimode) {
		return Widelands::AiModeBuildings::kOnLimit;
	} else {
		return Widelands::AiModeBuildings::kAnotherAllowed;
	}
}
bool BuildingObserver::buildable(Widelands::Player& p) {
	return is_buildable && p.is_building_type_allowed(id);
}


// Computer player does not get notification messages about enemy militarysites
// and warehouses, so following is collected based on observation
// It is conventient to have some information preserved, like nearby minefields,
// when it was attacked, whether it is warehouse and so on
// Also AI test more such targets when considering attack and calculated score is
// is stored in the observer
EnemySiteObserver::EnemySiteObserver()
	: is_warehouse(false),
	  attack_soldiers_strength(0),
	  defenders_strength(0),
	  stationed_soldiers(0),
	  last_time_attackable(std::numeric_limits<uint32_t>::max()),
	  last_tested(0),
	  score(0),
	  mines_nearby(Widelands::ExtendedBool::kUnset),
	  no_attack_counter(0) {}


// as all mines have 3 levels, AI does not know total count of mines per mined material
// so this observer will be used for this
MineTypesObserver::MineTypesObserver() : in_construction(0), finished(0) {}

uint16_t MineTypesObserver::total_count() const {
	return in_construction + finished;
}

// this is used to count militarysites by their size
MilitarySiteSizeObserver::MilitarySiteSizeObserver() : in_construction(0), finished(0) {}

// this represents a scheduler task
SchedulerTask::SchedulerTask
	(const uint32_t time, const Widelands::SchedulerTaskId t, const uint8_t p, const char* d):
	due_time(time), id(t), priority(p), descr(d) {}

bool SchedulerTask::operator<(SchedulerTask other) const {
	return priority > other.priority;
}


// List of blocked fields with block time, with some accompanying functions
// NOCOM(#codereview) better pass the Coords here and have the BlockedFields calculate the coords_hash,
// so we can be sure that the hash is always correct.
void BlockedFields::add(uint32_t hash, uint32_t till) {
	if (BlockedFields.count(hash) == 0) {
		BlockedFields.insert(std::pair<uint32_t, uint32_t>(hash, till));
	} else if (BlockedFields[hash] < till) {
		BlockedFields[hash] = till;
	}
	// The third possibility is that a field has been already blocked for longer time than 'till'
}

uint32_t BlockedFields::count() {
	return BlockedFields.size();
}

void BlockedFields::remove_expired(uint32_t gametime) {
	std::vector<uint32_t> fields_to_remove;
	for (auto field: BlockedFields) {
		if (field.second < gametime) {
			fields_to_remove.push_back(field.first);
		}
	}
	while (!fields_to_remove.empty()) {
		BlockedFields.erase(fields_to_remove.back());
		fields_to_remove.pop_back();
	}
}

// NOCOM(#codereview) better pass the Coords here and have the BlockedFields calculate the coords_hash.
bool BlockedFields::is_blocked(uint32_t hash) {
	if (BlockedFields.count(hash) == 0) {
		return false;
	} else {
		return true;
	}
}

// This is an struct that stores strength of players, info on teams and provides some outputs from these data
PlayersStrengths::PlayerStat::PlayerStat() {}
PlayersStrengths::PlayerStat::PlayerStat(Widelands::TeamNumber tc, uint32_t pp) : team_number(tc), players_power(pp) {}

// Inserting/updating data
void PlayersStrengths::add(Widelands::PlayerNumber pn, Widelands::TeamNumber tn, uint32_t pp) {
	if (all_stats.count(pn) == 0) {
		all_stats.insert(std::pair<Widelands::PlayerNumber, PlayerStat>(pn, PlayerStat(tn, pp)));
	} else {
		all_stats[pn].players_power = pp;
	}
}

void PlayersStrengths::recalculate_team_power() {
	team_powers.clear();
	for (auto& item: all_stats) {
		if (item.second.team_number > 0) { // is a member of a team
			if (team_powers.count(item.second.team_number) > 0) {
				team_powers[item.second.team_number] += item.second.players_power;
			} else {
				team_powers[item.second.team_number] = item.second.players_power;
			}
		}
	}
}

// This is strength of player plus third of strength of other members of his team
uint32_t PlayersStrengths::get_modified_player_power(Widelands::PlayerNumber pn) {
	uint32_t result = 0;
	Widelands::TeamNumber team = 0;
	if (all_stats.count(pn) > 0) {
		result = all_stats[pn].players_power;
		team = all_stats[pn].team_number;
	};
	if (team > 0 && team_powers.count(team) > 0) {
		result = result + (team_powers[team] - result) / 3;
	};
	return result;
}

bool PlayersStrengths::players_in_same_team(Widelands::PlayerNumber pl1, Widelands::PlayerNumber pl2) {
	if (all_stats.count(pl1) > 0 && all_stats.count(pl2) > 0 && pl1 != pl2) {
		// team number 0 = no team
		return all_stats[pl1].team_number > 0 && all_stats[pl1].team_number == all_stats[pl2].team_number;
	} else {
		return false;
	}
}

bool PlayersStrengths::strong_enough(Widelands::PlayerNumber pl) {
	if (all_stats.count(pl) == 0) {
		return false;
	}
	uint32_t my_strength = all_stats[pl].players_power;
	uint32_t strongest_opponent_strength = 0;
	for (auto item : all_stats) {
		if (!players_in_same_team(item.first, pl) && pl != item.first) {
			if (get_modified_player_power(item.first) > strongest_opponent_strength) {
				strongest_opponent_strength = get_modified_player_power(item.first);
			}
		}
	}
	return my_strength > strongest_opponent_strength + 50;
}

} // namespace WIdelands

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

#ifndef WL_AI_SCENARIO_AI_H
#define WL_AI_SCENARIO_AI_H

#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

#include "ai/computer_player.h"
#include "base/i18n.h"
#include "base/log.h"
#include "base/macros.h"
#include "logic/widelands.h"
#include "logic/widelands_geometry.h"
#include "random/random.h"
#include "scripting/lua_table.h"

namespace Widelands {
	class Game;
}

using Stock = std::vector<Widelands::Quantity>;

struct ScenarioAI : ComputerPlayer {

	ScenarioAI(Widelands::Game&, const Widelands::PlayerNumber);
	~ScenarioAI() override;
	void think() override;

	void set_militarysite_allowed(const std::string&, bool = true);
	void set_productionsite_allowed(const std::string&, bool = true);
	void set_trainingsite_allowed(const std::string&, bool = true);
	void set_warehouse_allowed(const std::string&, bool = true);
	void set_basic_economy(const std::string&, uint32_t, uint32_t);
	void set_ware_preciousness(const std::string&, uint32_t);
	void set_is_enemy(Widelands::PlayerNumber, bool);
	void set_aggression_treshold(int32_t);
	int32_t get_aggression_treshold();
	void set_road_density(uint32_t);
	uint32_t get_road_density();
	void set_think_interval(uint32_t);
	uint32_t get_think_interval();
	void set_active(bool);
	bool is_active();

	struct ScenarioAIImpl : public ComputerPlayer::Implementation {
		ScenarioAIImpl()
		   : Implementation(
		        "scenario",
		        /** TRANSLATORS: This is the name of an AI used in the game setup screens */
		        _("Scenario AI"),
		        "images/ai/ai_scenario.png",
		        Implementation::Type::kScenario) {
		}
		ComputerPlayer* instantiate(Widelands::Game& game,
		                            Widelands::PlayerNumber const p) const override {
			return new ScenarioAI(game, p);
		}
	};

	static ScenarioAIImpl implementation;

private:

	void init();
	void cleanup_roads();
	void military_stuff();
	void basic_economy();
	void connect_flags();
	void balance_economy();
	void check_borders();

	bool try_connect_flag(Widelands::FCoords&, Widelands::FCoords* = nullptr);
	bool build_building_somewhere(std::vector<const Widelands::BuildingDescr*>&);

	std::vector<Widelands::FCoords> owned_fields();
	Stock get_stock();

	// What we are allowed to build
	std::set<std::string> allowed_militarysites_;
	std::set<std::string> allowed_productionsites_;
	std::set<std::string> allowed_trainingsites_;
	std::set<std::string> allowed_warehouses_;

	std::map<std::string, std::pair<uint32_t, uint32_t>> basic_economy_; // {amount, importance}

	// We consider wares important only if they are listed here
	std::map<std::string, uint32_t> ware_preciousness_;

	std::set<Widelands::PlayerNumber> enemies_;
	bool active_;
	uint32_t think_interval_;
	int32_t aggression_treshold_;
	uint32_t road_density_;

	bool did_init_;
	uint32_t last_time_thought_;
	uint8_t phase_;

	RNG random_;

	// We do not cache any game-related information so we can react at once when a script changes something

	// TODO(Nordfriese): NOCOM – Saveloading support!!!

};

#endif  // end of include guard: WL_AI_SCENARIO_AI_H

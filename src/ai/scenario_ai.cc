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

#include <memory>

#include "economy/flag.h"
#include "economy/road.h"
#include "logic/field.h"
#include "logic/game.h"
#include "logic/map.h"
#include "logic/map_objects/checkstep.h"
#include "logic/map_objects/world/world.h"
#include "logic/maphollowregion.h"
#include "logic/mapregion.h"
#include "logic/player.h"

ScenarioAI::ScenarioAIImpl ScenarioAI::implementation;

ScenarioAI::ScenarioAI(Widelands::Game& ggame, Widelands::PlayerNumber const pid)
   : ComputerPlayer(ggame, pid),
   active_(true),
   think_interval_(250),
   aggression_treshold_(0),
   road_density_(4),
   did_init_(false),
   last_time_thought_(0),
   phase_(0) {
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

void ScenarioAI::set_aggression_treshold(int32_t t) {
	aggression_treshold_ = t;
}

int32_t ScenarioAI::get_aggression_treshold() {
	return aggression_treshold_;
}

void ScenarioAI::set_road_density(uint32_t d) {
	road_density_ = d;
}

uint32_t ScenarioAI::get_road_density() {
	return road_density_;
}

void ScenarioAI::set_think_interval(uint32_t i) {
	think_interval_ = i;
}

uint32_t ScenarioAI::get_think_interval() {
	return think_interval_;
}

void ScenarioAI::set_active(bool a) {
	active_ = a;
}

bool ScenarioAI::is_active() {
	return active_;
}

/************************************************
 *              Private functions               *
 ************************************************/

void ScenarioAI::init() {
	random_.seed(game().get_gametime());
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
			game().send_player_build_road(player_number(), *new Widelands::Path(path));
			return true;
		}
		return false;
	}

	upcast(Widelands::Flag, flag, start.field->get_immovable());
	assert(flag);
	std::vector<Widelands::ImmovableFound> results;
	map.find_reachable_immovables(Widelands::Area<Widelands::FCoords>(start, flag_connecting_search_radius),
			&results, Widelands::CheckStepDefault(Widelands::MOVECAPS_WALK),
			Widelands::FindImmovableType(Widelands::MapObjectType::FLAG));
	if (results.empty()) {
		return false;
	}
	std::multimap<int32_t, Widelands::Path> paths;
	int32_t shortest = std::numeric_limits<int32_t>::max();
	for (const Widelands::ImmovableFound& r : results) {
		if (r.coords == start || flag->get_road(*dynamic_cast<Widelands::Flag*>(r.object))) {
			continue;
		}
		Widelands::Path p;
		int32_t cost = map.findpath(start, map.get_fcoords(r.coords), 0, p, cstep);
		if (cost > 0) {
			paths.emplace(cost, p);
			shortest = std::min(shortest, cost);
		}
	}
	for (const auto& pair : paths) {
		if (pair.first == shortest) {
			game().send_player_build_road(player_number(), *new Widelands::Path(pair.second));
			return true;
		}
	}

	return false;
}

Stock ScenarioAI::get_stock() {
	Stock stock;
	const auto nr_wares = game().tribes().nrwares();
	for (Widelands::DescriptionIndex di = 0; di < nr_wares; ++di) {
		stock.push_back(0);
	}
	for (const auto& eco : game().get_player(player_number())->economies()) {
		for (const Widelands::Warehouse* wh : eco.second->warehouses()) {
			const Widelands::WareList& wares = wh->get_wares();
			for (Widelands::DescriptionIndex di = 0; di < nr_wares; ++di) {
				stock[di] += wares.stock(di);
			}
		}
	}
	return stock;
}

std::vector<Widelands::FCoords> ScenarioAI::owned_fields() {
	const Widelands::Map& map = game().map();
	std::vector<Widelands::FCoords> fields;
	for (Widelands::MapIndex i = map.max_index(); i; --i) {
		Widelands::Field& f = map[i - 1];
		if (f.get_owned_by() == player_number()) {
			fields.push_back(map.get_fcoords(f));
		}
	}
	return fields;
}

constexpr uint16_t militarysite_border_score_factor = 20;
constexpr uint16_t trainingsite_border_score_factor = 40;
constexpr uint16_t trainingsite_border_score_offset = 100;

bool ScenarioAI::build_building_somewhere(std::vector<const Widelands::BuildingDescr*>& buildings) {
	Widelands::Player& player = *game().get_player(player_number());
	const Widelands::Map& map = game().map();
	Stock stock = get_stock();
	const std::vector<Widelands::FCoords> own_fields = owned_fields();

	const Widelands::BuildingDescr* best = nullptr;
	const Widelands::BuildingDescr* cheapest = nullptr;
	float best_score = 0;
	float cheapest_score = 0;

	float size_bias = 0;
	for (const Widelands::FCoords& f : own_fields) {
		Widelands::NodeCaps caps = player.get_buildcaps(f);
		if (caps & Widelands::BUILDCAPS_BIG) {
			--size_bias;
		} else if ((f & Widelands::BUILDCAPS_SMALL) && !(f & Widelands::BUILDCAPS_MEDIUM)) {
			++size_bias;
		}
		size_bias /= own_fields.size();
	}

	for (const auto& descr : buildings) {
		float score = 0;
		bool affordable = true;
		for (const auto& cost : descr->buildcost()) {
			score += ware_preciousness_[game().tribes().get_ware_descr(cost.first)->name()] * cost.second;
			affordable &= stock[cost.first] >= cost.second;
		}
		score *= (12 * std::exp((descr->get_size() == Widelands::BaseImmovable::SMALL ? 1 :
				descr->get_size() == Widelands::BaseImmovable::BIG ? -1 : 0) - size_bias) * std::log(12));

		if (!cheapest || score < cheapest_score) {
			cheapest = descr;
			cheapest_score = score;
		}
		if (affordable && (!best || score > best_score)) {
			best = descr;
			best_score = score;
		}
	}
	if (!best) {
		if (!cheapest) {
			return false;
		}
		best = cheapest;
	}

	// All scoring values are arbitrary. They are designed to produce fairly good results.
	const Widelands::FCoords* field = nullptr;
	float field_score = 0;
	for (const Widelands::FCoords& f : own_fields) {
		const Widelands::NodeCaps caps = player.get_buildcaps(f);
		if (caps & best->get_size()) {
			float score = 0;

			uint32_t border_distance = 0;
			for (uint32_t d = 1; border_distance == 0; ++d) {
				Widelands::MapHollowRegion<Widelands::Area<Widelands::FCoords>> mr(map,
						Widelands::HollowArea<Widelands::Area<Widelands::FCoords>>(
						Widelands::Area<Widelands::FCoords>(f, d), d - 1));
				do {
					if (enemies_.count(mr.location().field->get_owned_by())) {
						border_distance = d;
						break;
					}
				} while (mr.advance(map));
			}

			uint32_t workarea_radius = 0;
			for (const auto& pair : best->workarea_info()) {
				workarea_radius = std::max(workarea_radius, pair.first);
			}
			if (best->type() == Widelands::MapObjectType::MILITARYSITE) {
				score = militarysite_border_score_factor - border_distance;
				score = 72 * score * score * score;
			} else if (best->type() == Widelands::MapObjectType::WAREHOUSE) {
				score = 72 * border_distance * border_distance;
			} else if (best->type() == Widelands::MapObjectType::TRAININGSITE) {
				score = 72 * (trainingsite_border_score_offset - (border_distance - trainingsite_border_score_factor) *
						(border_distance - trainingsite_border_score_factor) * trainingsite_border_score_offset /
						(trainingsite_border_score_factor * trainingsite_border_score_factor));
			} else if (best->hints().has_mines()) {
				score = 0;
				Widelands::MapRegion<Widelands::Area<Widelands::FCoords>> mr(
						map, Widelands::Area<Widelands::FCoords>(f, 6));
				const Widelands::DescriptionIndex mines = game().world().get_resource(best->hints().get_mines());
				do {
					if (mr.location().field->get_resources() == mines) {
						score += mr.location().field->get_resources_amount();
					}
				} while (mr.advance(map));
			} else if (workarea_radius > 0) {
				score = border_distance;
				for (uint32_t d = 1; d <= workarea_radius; ++d) {
					float sc = 84 - 12 * d;
					Widelands::MapHollowRegion<Widelands::Area<Widelands::FCoords>> mr(map,
							Widelands::HollowArea<Widelands::Area<Widelands::FCoords>>(
							Widelands::Area<Widelands::FCoords>(f, d), d - 1));
					do {
						// TODO(Nordfriese): Ideally, we should check whether we are
						// interested in this type of immovable and then decide whether
						// to count its existance (woodcutters and trees) or absence
						// (farmers and free spaces) positive or negative
						if (mr.location().field->get_immovable()) {
							score -= sc;
						} else {
							score += sc;
						}
					} while (mr.advance(map));
				}
			} else {
				score = 12 * border_distance;
			}

			if (caps & Widelands::BUILDCAPS_BIG) {
				if (best->get_size() == Widelands::BaseImmovable::SMALL) {
					score /= 6;
				} else if (best->get_size() == Widelands::BaseImmovable::MEDIUM) {
					score /= 3;
				}
			} else if ((caps & Widelands::BUILDCAPS_BIG) && best->get_size() == Widelands::BaseImmovable::SMALL) {
				score /= 2;
			}

			Widelands::MapRegion<Widelands::Area<Widelands::FCoords>> mr(
					map, Widelands::Area<Widelands::FCoords>(f, workarea_radius + 4));
			do {
				if (const Widelands::BaseImmovable* imm = mr.location().field->get_immovable()) {
					if (imm->descr().type() >= Widelands::MapObjectType::BUILDING &&
							!dynamic_cast<const Widelands::BuildingDescr&>(imm->descr()).workarea_info().empty()) {
						score /= 2;
					}
				}
			} while (mr.advance(map));

			if (score > 0 && (!field || field_score < score)) {
				field = &f;
				field_score = score;
			}
		}
	}
	if (!field) {
		return false;
	}

	game().send_player_build(player_number(), *field, game().tribes().building_index(best->name()));
	return true;
}

static inline int32_t evaluate_soldier(const Widelands::Soldier& soldier) {
	int32_t v = soldier.get_total_level() + 1;
	return v * v * soldier.get_current_health() / (soldier.descr().get_base_health() +
			soldier.descr().get_health_incr_per_level() * soldier.get_health_level());
}

void ScenarioAI::cleanup_roads() {
	const Widelands::Map& map = game().map();
	for (Widelands::MapIndex i = map.max_index(); i; --i) {
		Widelands::Field& f = map[i - 1];
		Widelands::FCoords coords = map.get_fcoords(f);
		if (f.get_owned_by() == player_number()) {
			if (Widelands::BaseImmovable* imm = f.get_immovable()) {
				if (imm->descr().type() == Widelands::MapObjectType::FLAG) {
					upcast(Widelands::Flag, flag, imm);
					uint8_t roads = flag->nr_of_roads();
					if (flag->get_building()) {
						if (roads == 0 && try_connect_flag(coords)) {
							return;
						}
					} else if (roads < 2) {
						return game().send_player_bulldoze(*flag);
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
}

void ScenarioAI::military_stuff() {
	const Widelands::Map& map = game().map();
	Widelands::Player& player = *game().get_player(player_number());

	std::map<Widelands::Building*, std::tuple<int32_t, uint32_t>> attackable; // {evaluation, number_of_soldiers}
	int32_t best_eval = std::numeric_limits<int32_t>::min();
	for (Widelands::DescriptionIndex di = 0; di < game().tribes().nrbuildings(); ++di) {
		const Widelands::BuildingDescr& descr = *game().tribes().get_building_descr(di);
		if (descr.type() != Widelands::MapObjectType::MILITARYSITE &&
				descr.type() != Widelands::MapObjectType::WAREHOUSE) {
			continue;
		}
		for (const Widelands::PlayerNumber& n : enemies_) {
			const Widelands::Player& enemy = *game().get_player(n);
			for (const Widelands::Player::BuildingStats& stat : enemy.get_building_statistics(di)) {
				if (!stat.is_constructionsite) {
					upcast(Widelands::Building, bld, map[stat.pos].get_immovable());
					assert(bld);
					std::vector<Widelands::Soldier*> soldiers;
					if (uint32_t amount = player.find_attack_soldiers(bld->base_flag(), &soldiers)) {
						int32_t eval = 0;
						for (const auto& soldier : soldiers) {
							eval += evaluate_soldier(*soldier);
						}
						if (descr.type() == Widelands::MapObjectType::WAREHOUSE) {
							eval = eval * 3 / 2;
						}
						for (const auto& soldier : bld->soldier_control()->present_soldiers()) {
							eval -= evaluate_soldier(*soldier);
						}
						if (eval > 0) {
							best_eval = std::max(best_eval, eval);
							attackable[bld] = {eval, amount};
						}
					}
				}
			}
		}
	}
	if (best_eval >= aggression_treshold_) {
		std::vector<Widelands::Building*> best_buildings;
		for (const auto& pair : attackable) {
			if (std::get<0>(pair.second) == best_eval) {
				best_buildings.push_back(pair.first);
			}
		}
		assert(!best_buildings.empty());
		Widelands::Building* building_to_attack = best_buildings[random_.rand() % best_buildings.size()];
		return player.enemyflagaction(building_to_attack->base_flag(), player_number(),
				std::get<1>(attackable.at(building_to_attack)));
	}
}

void ScenarioAI::basic_economy() {
	const Widelands::Map& map = game().map();
	Widelands::Player& player = *game().get_player(player_number());

	std::map<std::string, std::tuple<uint32_t, uint32_t>> all_missing;
	uint32_t most_important_missing = 0;
	for (const auto& pair : basic_economy_) {
		const Widelands::DescriptionIndex di = game().tribes().building_index(pair.first);
		assert(di != Widelands::INVALID_INDEX);
		size_t amount = player.get_building_statistics(di).size();
		if (amount < std::get<0>(pair.second)) {
			uint32_t importance = std::get<1>(pair.second);
			all_missing[pair.first] = {std::get<0>(pair.second) - amount, importance};
			most_important_missing = std::max(most_important_missing, importance);
		}
	}
	if (!all_missing.empty()) {
		//                    {number missing, can build directly, buildings we can enhance to this}
		std::map<std::string, std::tuple<uint32_t, bool, std::vector<Widelands::Building*>>> missing_we_can_build;
		uint32_t highest_amount_missing = 0;
		for (const auto& pair : all_missing) {
			if (std::get<1>(pair.second) < most_important_missing) {
				continue;
			}
			const Widelands::DescriptionIndex di = game().tribes().building_index(pair.first);
			const Widelands::BuildingDescr& descr = *game().tribes().get_building_descr(di);
			std::vector<Widelands::Building*> enhanceable;

			// TODO(Nordfriese): If trainingsites that use upgraded workers are introduced, enhance this code
			std::map<Widelands::DescriptionIndex, uint32_t> workers_required;
			if (descr.type() == Widelands::MapObjectType::PRODUCTIONSITE) {
				upcast(const Widelands::ProductionSiteDescr, site_descr, &descr);
				assert(site_descr);
				for (const auto& worker_pair : site_descr->working_positions()) {
					const Widelands::WorkerDescr& worker_descr = *game().tribes().get_worker_descr(worker_pair.first);
					if (!worker_descr.is_buildable()) {
						uint32_t amount = 0;
						for (const auto& eco : player.economies()) {
							for (const Widelands::Warehouse* wh : eco.second->warehouses()) {
								amount += wh->get_workers().stock(worker_pair.first);
							}
						}
						if (amount < worker_pair.second) {
							workers_required[worker_pair.first] = worker_pair.second - amount;
						}
					}
				}
			}

			if (descr.is_enhanced()) {
				for (const auto& stat : player.get_building_statistics(descr.enhanced_from())) {
					if (stat.is_constructionsite) {
						continue;
					}
					upcast(Widelands::Building, bld, map[stat.pos].get_immovable());
					assert(bld);
					assert(bld->descr().enhancement() == di);
					if (!workers_required.empty()) {
						std::map<Widelands::DescriptionIndex, uint32_t> workers_found;
						for (const auto& worker : bld->get_workers()) {
							const Widelands::DescriptionIndex w = game().tribes().worker_index(worker->descr().name());
							assert(w != Widelands::INVALID_INDEX);
							auto iterator = workers_found.find(w);
							if (iterator == workers_found.end()) {
								workers_found.emplace(w, 1);
							} else {
								++iterator->second;
							}
						}
						bool something_missing = false;
						for (const auto& worker_pair : workers_required) {
							auto iterator = workers_found.find(worker_pair.first);
							if (iterator == workers_found.end() || iterator->second < worker_pair.second) {
								something_missing = true;
								break;
							}
						}
						if (something_missing) {
							continue;
						}
					}
					enhanceable.push_back(bld);
				}
			}
			bool can_build_directly = descr.is_buildable();
			uint32_t amount = std::get<0>(pair.second);
			if (can_build_directly || !enhanceable.empty()) {
				missing_we_can_build[pair.first] = {amount, can_build_directly, enhanceable};
				highest_amount_missing = std::max(highest_amount_missing, amount);
			}
		}
		assert(highest_amount_missing > 0);
		assert(!missing_we_can_build.empty());
		std::vector<Widelands::Building*> enhanceable_buildings;
		std::vector<const Widelands::BuildingDescr*> buildable_buildings;
		for (const auto& pair : missing_we_can_build) {
			if (std::get<0>(pair.second) < highest_amount_missing) {
				continue;
			}
			for (const auto& bld : std::get<2>(pair.second)) {
				enhanceable_buildings.push_back(bld);
			}
			if (std::get<1>(pair.second)) {
				const Widelands::DescriptionIndex di = game().tribes().building_index(pair.first);
				const Widelands::BuildingDescr* descr = game().tribes().get_building_descr(di);
				buildable_buildings.push_back(descr);
			}
		}
		if (enhanceable_buildings.empty()) {
			assert(!buildable_buildings.empty());
			if (build_building_somewhere(buildable_buildings)) {
				return;
			}
		} else {
			Widelands::Building* enhance = enhanceable_buildings[random_.rand() % enhanceable_buildings.size()];
			return game().send_player_enhance_building(*enhance, enhance->descr().enhancement());
		}
	}
}

void ScenarioAI::connect_flags() {
	const Widelands::Map& map = game().map();
	Widelands::Player& player = *game().get_player(player_number());

	std::map<Widelands::FCoords, Widelands::Flag*> all_flags;
	for (Widelands::MapIndex i = map.max_index(); i > 0; --i) {
		Widelands::Field& f = map[i - 1];
		if (f.get_immovable() && f.get_owned_by () == player_number() &&
				f.get_immovable()->descr().type() == Widelands::MapObjectType::FLAG) {
			all_flags[map.get_fcoords(f)] = dynamic_cast<Widelands::Flag*>(f.get_immovable());
		}
	}
	std::map<std::pair<const Widelands::FCoords, const Widelands::FCoords>, uint32_t> connect_candidates;
	uint32_t most_urgent = 0;
	for (auto i = all_flags.begin(); i != all_flags.end(); ++i) {
		for (auto j = i; j != all_flags.end(); ++j) {
			Widelands::Path path;
			int32_t distance = map.findpath(i->first, j->first, 0, path,
					Widelands::CheckStepDefault(Widelands::MOVECAPS_WALK));
			if (distance <= 0) {
				continue;
			}
			Widelands::Route route;
			bool route_found = (i->second->get_economy() != j->second->get_economy()) ? false :
					i->second->get_economy()->find_route(*i->second, *j->second, &route, Widelands::wwWORKER);
			if (!route_found || route.get_totalcost() > road_density_ * distance * 1800L) {
				uint32_t urgency;
				if (route_found) {
					urgency = route.get_totalcost() / distance;
					most_urgent = std::max(most_urgent, urgency);
				} else {
					urgency = std::numeric_limits<uint32_t>::max();
				}
				connect_candidates.emplace(std::make_pair(i->first, j->first), urgency);
			}
		}
	}
	if (!connect_candidates.empty()) {
		std::list<std::pair<const Widelands::FCoords, const Widelands::FCoords>> urgent_candidates;
		for (const auto& pair : connect_candidates) {
			if (pair.second >= most_urgent) {
				if (random_.rand() % 2 == 0) {
					urgent_candidates.push_back(pair.first);
				} else {
					urgent_candidates.push_front(pair.first);
				}
			}
		}
		assert(!urgent_candidates.empty());
		while (!urgent_candidates.empty()) {
			Widelands::Path path;
			if (map.findpath(urgent_candidates.back().first, urgent_candidates.back().second, 0, path,
					Widelands::CheckStepRoad(player, Widelands::MOVECAPS_WALK))) {
				return game().send_player_build_road(player_number(), *new Widelands::Path(path));
			}
			urgent_candidates.pop_back();
		}
	}
}

void ScenarioAI::think() {
	const uint32_t time = game().get_gametime();
	if (time - last_time_thought_ < think_interval_) {
		return;
	}
	last_time_thought_ = time;

	if (!active_) {
		return;
	}
	if (!did_init_) {
		return init();
	}

	++phase_;
	switch (phase_) {
		case 1:
			/* We begin by cleaning up our road network. Unconnected building or separate economies
			 * are connected, long roads are broken into shorter sections, dead-ends are removed.
			 */
			cleanup_roads();
			break;
		case 2:
			/* Military stuff
			 * ==============
			 * We frequently check for enemy militarysites near our border.
			 * Attackable warehouses (port/HQ) are preferred over other milsites.
			 * If we see one which can be attacked, we compare strengths, and
			 * if we are stronger than the enemy, we attack!
			 */
			military_stuff();
			break;
		case 3:
			/* Now, let's take care of our economy. A script defined our very own "basic economy".
			 * If we haven't built everything from there yet, we really need to take care of that.
			 */
			basic_economy();
			break;
		case 4:
			/* Let's check whether there are two flags that are physically close but far apart in the road network */
			connect_flags();
			break;
		case 5:
		  	// TODO(Nordfriese): NOCOM
		  	/* Do other stuff – micromanage workers and wares,
		  	 * find out if we should build more productionsites, warehouses, milsites...
		  	 */

			break;
		case 6:
			// TODO(Nordfriese): NOCOM
			/* We check our borders now. Any field where we can build something and the border is
			 * close is interesting, even more so if any immovables nearby are owned by an enemy.
			 * Fields located closely to an enemy warehouse or milsite are also much more
			 * interesting. Fields located closely to an own warehouse are a bit more interesting.
			 * Fields located closely to an own milsite or milsite-constructionsite are less
			 * interesting. Consider building a militarysite on an interesting field.
			 */

			break;
		default:
			/* Sleep phase */
			phase_ = 0;
			break;
	}
}


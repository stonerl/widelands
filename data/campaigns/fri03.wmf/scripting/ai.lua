-- This function simulates an enire standalone AI.
-- It is intended to be run for a player that is NOT the human player and set to the empty (!) AI.
-- This AI is designed specifically for the special conditions of this scenario.
-- If you wish to use it for a different purpose, you will need to enhance it significantly.

-- So how does it work?
-- Our first and foremost priority is fighting. If we don't have enough militarysites somewhere, we need to build more.
-- If we are stronger than the enemy somewhere, we attack!
-- If the military looks good, we take care of our economy.
-- If there are shortages of some ware which we can produce, we need to build more buildings for it.

function ai(pl)
   if pl.tribe.name == "empire" then
      local eco = pl:get_buildings("empire_headquarters")[1].flag.economy
      eco:set_ware_target_quantity("planks", 25)
      eco:set_ware_target_quantity("marble_column", 5)
      eco:set_ware_target_quantity("coal", 15)
      eco:set_ware_target_quantity("iron", 10)
      eco:set_ware_target_quantity("gold", 5)
      eco:set_worker_target_quantity("empire_soldier", 20)
      eco:set_worker_target_quantity("empire_donkey", 10)
   elseif pl.tribe.name == "barbarians" then
      local eco = pl:get_buildings("barbarians_headquarters")[1].flag.economy
      eco:set_ware_target_quantity("blackwood", 25)
      eco:set_ware_target_quantity("grout", 15)
      eco:set_ware_target_quantity("coal", 15)
      eco:set_ware_target_quantity("iron", 10)
      eco:set_ware_target_quantity("gold", 5)
      eco:set_ware_target_quantity("beer", 0)
      eco:set_worker_target_quantity("barbarians_soldier", 20)
      eco:set_worker_target_quantity("barbarians_ox", 10)
   else
      print("FATAL EXCEPTION: The custom AI for fri03 does not support the tribe '" .. pl.tribe.name .. "'!")
      return
   end
   local init = true
   while not pl.defeated do
      ai_one_loop(pl, init)
      init = false
      sleep(3000) -- NOCOM very slow, for testing
      -- Yes, we need to do this after every single step. I'm sorry :(
      collectgarbage()
   end
end

function ai_one_loop(pl, initial)
   
   -- We begin by cleaning up our road network. Long roads are broken into shorter sections, dead-ends are removed.
   if not initial then
   for y=0, map.height - 1 do
      sleep(1)
      for x=0, map.width - 1 do
         local f = map:get_field(x, y)
         if f.owner == pl and f.immovable then
            if f.immovable.descr.type_name == "road" then
               local l = 0
               for i,field in ipairs(f.immovable.fields) do
                  if field:has_caps("flag") then
                     pl:place_flag(field)
                     print("NOCOM built flag")
                     return
                  elseif field.immovable and f.immovable.descr.type_name == "flag" then
                     l = 0
                  else
                     l = l + 1
                     if l > 3 then
                        field.immovable:destroy()
                     print("NOCOM destroyed road")
                        return
                     end
                  end
               end
            elseif f.immovable.descr.type_name == "flag" then
               local r = 0
               for _ in pairs(f.immovable.roads) do r = r + 1 end
               if f.immovable.building and r < 1 then
                  connect(pl, f.immovable, 3)
                     print("NOCOM built road")
                  return
               elseif not f.immovable.building and r < 2 then
                  f.immovable:destroy()
                     print("NOCOM destroyed unreachable building")
                  return
               end
            end
         end
      end
   end
   end
   
   -- Military stuff
   -- ==============
   -- We frequently check for enemy militarysites near our border.
   -- If we see one which can be attacked, we compare strengths:
   --   If we are stronger than the enemy, we attack!
   --   Otherwise, we construct a new militarysite nearby.
   --     (If a new own milsite is already under construction nearby, we ignore that enemy site – for now...)
   
   sleep(10)
   
   for i,b in pairs(array_combine(
         p1:get_buildings("frisians_headquarters"),
         p1:get_buildings("frisians_port"),
         p3:get_buildings("frisians_port")
   )) do
      local n = #pl:get_attack_soldiers(b)
      if n > 0 then
         pl:attack(b, n)
                     print("NOCOM attacked hq or port")
         return
      end
   end
   
   sleep(10)
   
   for i,b in pairs(array_combine(
         p1:get_buildings("frisians_tower"),
         p1:get_buildings("frisians_outpost"),
         p1:get_buildings("frisians_sentinel"),
         p1:get_buildings("frisians_wooden_tower"),
         p1:get_buildings("frisians_wooden_tower_high"),
         p3:get_buildings("frisians_tower"),
         p3:get_buildings("frisians_outpost"),
         p3:get_buildings("frisians_sentinel"),
         p3:get_buildings("frisians_wooden_tower"),
         p3:get_buildings("frisians_wooden_tower_high")
   )) do
      sleep(10)
      local attack_soldiers = pl:get_attack_soldiers(b)
      if #attack_soldiers > 0 then
         local attackers_score = 0
         local defenders_score = 0
         local attackers = 0
         local milsite_under_construction = false
         for j,f in pairs(b.fields[1]:region(25)) do
            sleep(10)
            if f.owner and f.owner.team ~= pl.team and f.immovable and f.immovable.descr.type_name == "militarysite" then
               for descr,n in pairs(f.immovable.get_soldiers("all")) do
                  -- This approximation is incorrect for several reasons, but they balance each other out fairly well ;)
                  defenders_score = defenders_score + n *
                        ((descr[1] + 1) * (descr[2] + 1) * (descr[3] + 1) * (descr[4] + 1))
               end
            elseif f.owner == pl and f.immovable and f.immovable.descr.type_name == "constructionsite" and
                  game:get_building_description(f.immovable.building).type_name == "militarysite" then
               milsite_under_construction = true
            end
         end
         for j,s in pairs(attack_soldiers) do
            sleep(10)
            attackers_score = attackers_score + (s.attack_level + 1) * (s.evade_level + 1) *
                  (s.health_level + 1) * (s.defense_level + 1)
            attackers = attackers + 1
            if attackers_score > defenders_score then
               break
            end
         end
         if attackers_score < defenders_score then
            if not milsite_under_construction then
               local buildings = nil
               if pl.tribe.name == "empire" then
                  buildings = {
                     game:get_building_description("empire_sentry"),
                     game:get_building_description("empire_outpost"),
                     game:get_building_description("empire_barrier"),
                     game:get_building_description("empire_tower"),
                     game:get_building_description("empire_fortress"),
                  }
               elseif pl.tribe.name == "barbarians" then
                  buildings = {
                     game:get_building_description("barbarians_sentry"),
                     game:get_building_description("barbarians_barrier"),
                     game:get_building_description("barbarians_tower"),
                     game:get_building_description("barbarians_fortress"),
                  }
               end
               if build_best_building(pl, buildings, b.fields[1]:region(21)) then
                  print("NOCOM built new milsite")
                  return
               end
            end
         else
            pl:attack(b, attackers)
                     print("NOCOM attacked milsite")
            return
         end
      end
   end
   
   sleep(10)
   
   -- Now, let's take care of our economy. We define our very own "basic economy" below.
   -- If we haven't built everything from there yet, we really need to take care of that.
   
   local basic_economy
   if pl.tribe.name == "empire" then basic_economy = ai_basic_economy_emp else basic_economy = ai_basic_economy_bar end
   local most_important_missing_build = nil
   local most_important_missing_enhance = nil
   for b,tbl in pairs(basic_economy) do
      sleep(10)
      local buildable = game:get_building_description(b).buildable
      local count = count_buildings(pl, b) < tbl.amount
      if buildable and ((not most_important_missing_build) or
            most_important_missing_build < tbl.importance) and count then
         most_important_missing_build = tbl.importance
      end
      if (not buildable) and ((not most_important_missing_enhance) or
            most_important_missing_enhance < tbl.importance) and count then
         most_important_missing_enhance = tbl.importance
      end
   end
   if most_important_missing_build ~= nil then
      -- There is at least 1 basic building that can be built directly
      local bld = {}
      for b,tbl in pairs(basic_economy) do
         sleep(10)
         local descr = game:get_building_description(b)
         if descr.buildable and tbl.importance >= most_important_missing_build and
               count_buildings(pl, b) < tbl.amount then
            table.insert(bld, descr)
         end
      end
      -- We choose a region around a random building somewhere
      local field = array_combine(
         pl:get_buildings("empire_headquarters"),
         pl:get_buildings("barbarians_headquarters"),
         pl:get_buildings("empire_warehouse"),
         pl:get_buildings("barbarians_warehouse"))
      local size = #field
      field = field[math.random(size)].fields[1]
      if build_best_building(pl, bld, field:region(20 * size)) then
         print("NOCOM built basic building")
         return
      end
   elseif most_important_missing_enhance ~= nil then
      -- TODO We need to find out whether we can enhance something to a missing building
      
   end
   
   print("NOCOM I am bored :(")
   sleep(100)
   
end

-- Our own basic economy. Each building has an amount and an importance (higher importance = built earlier)
ai_basic_economy_bar = {
   barbarians_fishers_hut    = { amount = 2, importance = 3 },
   barbarians_well           = { amount = 1, importance = 3 },
   barbarians_reed_yard      = { amount = 1, importance = 8 },
   barbarians_wood_hardener  = { amount = 2, importance = 9 },
   barbarians_lime_kiln      = { amount = 1, importance = 8 },
   barbarians_charcoal_kiln  = { amount = 3, importance = 7 },
   barbarians_bakery         = { amount = 1, importance = 4 },
   barbarians_brewery        = { amount = 1, importance = 2 },
   barbarians_micro_brewery  = { amount = 1, importance = 3 },
   barbarians_smelting_works = { amount = 2, importance = 6 },
   barbarians_metal_workshop = { amount = 2, importance = 5 },
   barbarians_ax_workshop    = { amount = 1, importance = 2 },
   barbarians_warmill        = { amount = 1, importance = 2 },
   barbarians_farm           = { amount = 2, importance = 4 },
   barbarians_cattlefarm     = { amount = 1, importance = 1 },
   barbarians_helmsmithy     = { amount = 1, importance = 2 },
   barbarians_barracks       = { amount = 1, importance = 2 },
   barbarians_battlearena    = { amount = 1, importance = 1 },
   barbarians_trainingcamp   = { amount = 1, importance = 1 },
   barbarians_barrier        = { amount = 1, importance = 7 },
   barbarians_sentry         = { amount = 1, importance = 4 },
}
ai_basic_economy_emp = {
   empire_fishers_house     = { amount = 2, importance = 3 },
   empire_well              = { amount = 1, importance = 3 },
   empire_stonemasons_house = { amount = 1, importance = 8 },
   empire_sawmill           = { amount = 2, importance = 9 },
   empire_mill              = { amount = 1, importance = 4 },
   empire_bakery            = { amount = 1, importance = 4 },
   empire_charcoal_kiln     = { amount = 3, importance = 7 },
   empire_smelting_works    = { amount = 2, importance = 6 },
   empire_toolsmithy        = { amount = 1, importance = 4 },
   empire_armorsmithy       = { amount = 1, importance = 3 },
   empire_donkeyfarm        = { amount = 1, importance = 1 },
   empire_farm              = { amount = 2, importance = 4 },
   empire_sheepfarm         = { amount = 1, importance = 3 },
   empire_weaving_mill      = { amount = 1, importance = 3 },
   empire_weaponsmithy      = { amount = 1, importance = 2 },
   empire_barracks          = { amount = 1, importance = 2 },
   empire_trainingcamp      = { amount = 1, importance = 1 },
   empire_arena             = { amount = 1, importance = 1 },
   empire_colosseum         = { amount = 1, importance = 1 },
   empire_outpost           = { amount = 1, importance = 7 },
   empire_sentry            = { amount = 1, importance = 4 },
}

-- The preciousness for all wares. The higher the preciousness, the more reluctant we are to spend the ware
ai_ware_preciousness = {
   log = 1,
   granite = 1,
   blackwood = 3,
   grout = 3,
   thatch_reed = 1,
   cloth = 1,
   planks = 2,
   marble = 2,
   marble_column = 4,
   
   fish = 1,
   meat = 2,
   water = 1,
   wheat = 2,
   flour = 1,
   empire_bread = 2,
   barbarians_bread = 3,
   beer = 1,
   beer_strong = 1,
   
   coal = 4,
   iron_ore = 3,
   iron = 4,
   gold_ore = 5,
   gold = 6,
   
   pick = 1,
   felling_ax = 1,
   saw = 1,
   shovel = 1,
   hammer = 1,
   fishing_rod = 1,
   hunting_spear = 1,
   scythe = 1,
   bread_paddle = 1,
   basket = 1,
   kitchen_tools = 1,
   fire_tongs = 1,
   
   spear_wooden = 1,
   spear = 2,
   spear_advanced = 2,
   spear_heavy = 1,
   spear_war = 1,
   armor_helmet = 1,
   armor = 2,
   armor_chain = 1,
   armor_gilded = 1,
   ax = 1,
   ax_sharp = 3,
   ax_broad = 2,
   ax_bronze = 2,
   ax_battle = 1,
   ax_warriors = 1,
   helmet = 2,
   helmet_mask = 2,
   helmet_warhelm = 1
}

constructionsites = {}

function count_buildings(pl, building)
   local n = #pl:get_buildings(building)
   if constructionsites[building] then
      for i,f in pairs(constructionsites[building]) do
         if f.immovable and f.immovable.descr.type_name == "constructionsite" and
               f.immovable.descr.name == "constructionsite" and f.immovable.building == building then
            n = n + 1
         else
            table.remove(constructionsites[building], i);
         end
      end
   end
   return n
end

-- Returns a table of ware names mapped to the amount of that ware in stock
function stock(pl)
   local tbl = {}
   for i,ware in pairs(pl.tribe.wares) do
      tbl[ware.name] = 0
      for j,wh in pairs(array_combine(
         pl:get_buildings("empire_headquarters"),
         pl:get_buildings("empire_warehouse"),
         pl:get_buildings("barbarians_headquarters"),
         pl:get_buildings("barbarians_warehouse"))) do
         tbl[ware.name] = tbl[ware.name] + wh:get_wares(ware.name)
      end
   end
   return tbl
end

local ai_milsite_border_score_factor = 20
local ai_trainsite_border_score_factor = 40
local ai_trainsite_border_score_offset = 100

function suitability(pl, field, building_descr)
   if not field:has_caps(building_descr.size) then return false end
   local size
   if building_descr.size == "big" then size = 2 else size = 1 end
   for i,f in pairs(array_combine(field.brn:region(1), field:region(size))) do
      if f.owner ~= pl then return false end
   end
   return true
end

-- Selects the best building of the given array of BuildingDescriptions
-- and builds it on the best field in the specified region
function build_best_building(pl, buildings, region, sleeptime)
   local stock = stock(pl)
   -- First, the best building is determined by comparing construction costs with our stock.
   -- We consider the most expensive building which we can afford to be the best one.
   -- If we can't afford any of them, we choose the cheapest
   local best = nil
   local cheapest = nil
   local best_score
   local cheapest_score
   
   for i,b in pairs(buildings) do
      local score = 0
      local affordable = true
      for ware,amount in pairs(b.buildcost) do
         score = score + ai_ware_preciousness[ware]
         if stock[ware] < amount then
            affordable = false
         end
      end
      if (not cheapest) or score < cheapest_score then
         cheapest = b
         cheapest_score = score
      end
      if affordable and ((not best) or score > best_score) then
         best = b
         best_score = score
      end
   end
   if not best then best = cheapest end
   if not best then return nil end
   
   -- We will build the building 'best'. Now we must decide where.
   -- We map each field to a score. Only fields where we can actually build the building are considered.
   -- All scoring values are arbitrary. They are designed to produce fairly good results.
   local field = nil
   local field_score = nil
   for i,f in pairs(region) do
      if suitability(pl, f, best) then
         local score
         
         -- Militarysites should be played near the border, Warehouses far inland, Trainingsites in-between
         local border_distance = nil
         local d = 1
         while not border_distance do
            for j,fld in pairs(f:region(d, d - 1)) do
               if fld.owner and fld.owner.team ~= pl.team then
                  border_distance = d
                  break
               end
            end
            d = d + 1
         end
   
         if best.type_name == "militarysite" then
            score = ai_milsite_border_score_factor - border_distance
         elseif best.type_name == "warehouse" then
            score = border_distance
         elseif best.type_name == "trainingsite" then
            score = ai_trainsite_border_score_offset - (border_distance - ai_trainsite_border_score_factor) *
                  (border_distance - ai_trainsite_border_score_factor) * ai_trainsite_border_score_offset /
                  (ai_trainsite_border_score_factor * ai_trainsite_border_score_factor)
         else
            score = 1
         end
         
         -- For nicer integer arithmetics in the following section
         score = score * 72
         
         -- Placing a small building on a big plot is BAD. Placing a small building on a small plot is GOOD.
         if f:has_caps("big") then
            if best.size == "small" then
               score = score / 6
            elseif best.size == "medium" then
               score = score / 4
            end
         elseif f:has_caps("medium") then
            if best.size == "small" then
               score = score / 2
            else
               score = score * 4
            end
         else
            score = score * 6
         end
         
         if score > 0 and ((not field) or field_score < score) then
            field = f
            field_score = score
         end
      end
   end
   if not field then return nil end
   
   local is_flag = field.brn
   is_flag = is_flag.immovable and is_flag.immovable.descr.type_name == "flag"
   local building = pl:place_building(best.name, field, true)
   if not constructionsites[best.name] then
      constructionsites[best.name] = {}
   end
   table.insert(constructionsites[best.name], building.fields[1])
   if not is_flag then
      sleep(100)
      if not connect(pl, building.flag, 1) then
         building:destroy()
      end
   end
   return building
end

-- Connects the given flag to a nearby road network
function connect(pl, flag, precision)
   local d = precision
   while d < map.width / 2 do
      local fields = flag.fields[1]:region(d, d - precision)
      while #fields > 0 do
         local fi = math.random(#fields)
         local f = fields[fi]
         table.remove(fields, fi)
         if f.immovable and (f.immovable.descr.type_name == "flag" or
               (f.immovable.descr.type_name == "road" and f:has_caps("flag"))) then
            if pl:connect_with_road(flag, f.immovable, 10) then
               return true
            end
         end
      end
      d = d + precision
   end
   return false
end

-- Helper function: Determine the distance between two fields
function distance(f1, f2)
   if f1.x == f2.x and f1.y == f2.y then return 0 end
   local d = 1
   while true do
      for i,f in pairs(f1:region(d, d - 1)) do
         if f.x == f2.x and f.y == f2.y then return d end
      end
      d = d + 1
   end
end

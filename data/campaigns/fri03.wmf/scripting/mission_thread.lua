include "scripting/messages.lua"
include "scripting/field_animations.lua"

farm_connect_done = false

function steady_supply(player, wares)
   while not player.defeated do
      sleep(60000)
      local whs = array_combine(
         player:get_buildings(player.tribe_name .. "_headquarters"),
         player:get_buildings(player.tribe_name .. "_warehouse"))
      -- If the player is low on a ware, he'll certainly get it replaced;
      -- otherwise, there's a random chance that he'll get it anyway.
      for ware,n in pairs(wares) do
         local wh = whs[math.random(#whs)]
         if wh:get_wares(ware) < n then
            wh:set_wares(ware, n)
         end
      end
   end
end

function farms()
   campaign_message_box(farms_1)
   local o = add_campaign_objective(obj_connect_farms)
   local hq = p1:get_buildings("frisians_headquarters")[1].flag
   while true do
      sleep(60000)
      local ok = true
      for i,farm in pairs(p1:get_buildings("frisians_farm")) do
         if farm.flag.economy ~= hq.economy then
            ok = false
            p1:send_message(unconnected_farm.title, unconnected_farm.body, {
               heading = unconnected_farm.heading,
               field = farm.fields[1],
               icon = farm.descr.representative_image,
            })
            break
         end
      end
      if ok then
         set_objective_done(o)
         farm_connect_done = true
         return
      end
   end
end

function mission_thread()

   p1.team = 1
   p2.team = 2
   p3.team = 1
   p4.team = 2

   for i,f in pairs(p3_start) do
      map:place_immovable("debris00", f, "world")
   end

   for x=3, map.width - 4 do
      for y=2, map.height - 3 do
         local f = map:get_field(x, y)
         p1:reveal_fields{f}
         p1:conquer(f)
      end
   end
   include "map:scripting/starting_conditions.lua"

   run(steady_supply, p1, {
      log = 40,
      granite = 20,
      iron_ore = 20,
      gold_ore = 10,
   })
   run(steady_supply, p2, {
      log = 60,
      granite = 30,
      marble = 80,
      iron_ore = 30,
      gold_ore = 20,
   })
   run(steady_supply, p4, {
      log = 70,
      granite = 40,
      iron_ore = 30,
      gold_ore = 20,
   })
   scroll_to_field(map.player_slots[1].starting_field)

   -- Introduction
   sleep(3000)
   campaign_message_box(intro_1)
   sleep(3000)
   campaign_message_box(intro_2)
   scroll_to_field(map.player_slots[2].starting_field)
   sleep(3000)
   campaign_message_box(intro_3)
   scroll_to_field(map.player_slots[4].starting_field)
   sleep(3000)
   campaign_message_box(intro_4)
   scroll_to_field(map.player_slots[1].starting_field)
   sleep(3000)
   campaign_message_box(intro_5)
   local o = add_campaign_objective(obj_wait_for_reinforcements)
   sleep(10000)
   campaign_message_box(intro_6)

   sleep(30000)
   run(farms)

   -- now we wait until the enemy is nearly at the Castle
   while not farm_connect_done do sleep(1000) end
   local fields = map.player_slots[1].starting_field:region(21, 16)
   while true do
      sleep(10000)
      local enemy = false
      for i,f in pairs(fields) do
         if f.owner and f.owner.team == 2 then
            enemy = true
            break
         end
      end
      if #p1:get_buildings("frisians_headquarters") == 0 then
         scroll_to_field(map.player_slots[1].starting_field)
         sleep(2000)
         campaign_message_box(defeated_1)
         wl.ui.MapView():close()
         return
      end
      if enemy then break end
   end

   for i,f in pairs(p3_start) do
      f.immovable:remove()
   end
   p3:place_ship(map:get_field(333, 204))
   scroll_to_field(map.player_slots[3].starting_field)
   sleep(3000)
   campaign_message_box(help_arrives_1)
   
   local port = p3:place_building("frisians_port", map.player_slots[3].starting_field, false, true)
   port:set_wares {
      log = 40,
      granite = 50,
      thatch_reed = 50,
      brick = 80,
      clay = 30,
      water = 10,
      fish = 10,
      meat = 10,
      fruit = 10,
      barley = 5,
      ration = 20,
      honey = 10,
      smoked_meat = 5,
      smoked_fish = 5,
      mead = 5,
      meal = 2,
      coal = 20,
      iron = 5,
      gold = 4,
      iron_ore = 10,
      bread_frisians = 15,
      honey_bread = 5,
      beer = 5,
      cloth = 5,
      fur = 10,
      fur_garment = 5,
      sword_short = 5,
      hammer = 5,
      fire_tongs = 2,
      bread_paddle = 2,
      kitchen_tools = 2,
      felling_ax = 3,
      needles = 2,
      basket = 2,
      pick = 5,
      shovel = 5,
      scythe = 3,
      hunting_spear = 2,
      fishing_net = 3,
   }
   port:set_workers {
      frisians_blacksmith = 3,
      frisians_baker = 1,
      frisians_brewer = 1,
      frisians_builder = 10,
      frisians_charcoal_burner = 1,
      frisians_claydigger = 2,
      frisians_brickmaker = 2,
      frisians_carrier = 40,
      frisians_reed_farmer = 2,
      frisians_berry_farmer = 2,
      frisians_fruit_collector = 2,
      frisians_farmer = 1,
      frisians_landlady = 1,
      frisians_smoker = 1,
      frisians_geologist = 4,
      frisians_woodcutter = 3,
      frisians_beekeeper = 1,
      frisians_miner = 4,
      frisians_miner_master = 2,
      frisians_forester = 2,
      frisians_stonemason = 2,
      frisians_reindeer = 5,
      frisians_trainer = 3,
   }
   port:set_soldiers {
      [{0,0,0,0}] = 40,
      [{2,3,2,0}] = 10,
   }
   p3:allow_buildings("all")
   p3:forbid_buildings {
      "frisians_hunters_house",
      "frisians_quarry",
      "frisians_foresters_house",
      "frisians_woodcutters_house",
      "frisians_coalmine",
      "frisians_ironmine",
      "frisians_rockmine",
      "frisians_goldmine",
      "frisians_ironmine_deep",
      "frisians_coalmine_deep",
      "frisians_rockmine_deep",
      "frisians_goldmine_deep",
      "frisians_fortress",
   }
   run(steady_supply, p3, {
      log = 30,
      granite = 20,
      iron_ore = 10,
      gold_ore = 5,
   })
   set_objective_done(o)

   sleep(1000)
   campaign_message_box(help_arrives_2)
   p1:switchplayer(3)
   campaign_message_box(help_arrives_3)
   o = add_campaign_objective(obj_rescue)

   -- wait until the enemy is pushed well back
   fields = map.player_slots[1].starting_field:region(60)
   while true do
      local enemy = false
      for i,f in pairs(fields) do
         if f.owner and f.owner.team == 2 then
            enemy = true
            break
         end
         sleep(10)
      end
      if p3.defeated or #p1:get_buildings("frisians_headquarters") == 0 then
         scroll_to_field(map.player_slots[1].starting_field)
         sleep(2000)
         campaign_message_box(defeated_1)
         wl.ui.MapView():close()
         return
      end
      if enemy then break end
   end
   set_objective_done(o)

   local critters = {
      bunny,
      sheep,
      wisent,
      wildboar,
      chamois,
      deer,
      reindeer,
      stag,
      elk,
      marten,
      badger,
      lynx,
      fox,
      wolf,
      brownbear
   }
   local witch = {}
   for i=1,64 do
      local f = fields[math.random(#fields)]
      table.insert(witch, map:place_critter(f, critters[math.random(#critters)]))
   end
   witch = witch[math.random(#witch)]

   -- Now, we have placed the witch on the map. She'll walk around and cause buildings to spontaneously burst into flames.

   local plr = p1
   local destroyed = 0
   while result == nil do
      local did_destroy = false
      for i,f in pairs(witch.field:region(1)) do
         if f.owner == plr and f.immovable and is_building(f.immovable) then
            f.immovable:destroy()
            did_destroy = true
            if destroyed ~= nil then
               destroyed = destroyed + 1
               scroll_to_field(f)
               if destroyed > 3 then
                  destroyed = nil
                  campaign_message_box(witchhunt_1)
                  campaign_message_box(witchhunt_2)
                  campaign_message_box(witchhunt_3)
                  o = add_campaign_objective(obj_witchhunt)
               end
            end
            break
         end
      end
      if did_destroy then
         -- give the witch some time to get away from the flames
         sleep(3600)
      else
         -- check if the player killed or conjured the witch
         
         
         
      end
      
      sleep(math.random(600, 18000))
   end



end

run(mission_thread)

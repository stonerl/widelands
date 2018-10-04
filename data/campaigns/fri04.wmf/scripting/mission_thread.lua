include "scripting/field_animations.lua"

function mission_thread()

   scroll_to_field(map.player_slots[1].starting_field)
   include "map:scripting/starting_conditions.lua"

   -- TODO(Nordfriese): p3 should be forbidden to attack p1 until p1 has attacked p3

   -- Introduction
   sleep(1000)
   campaign_message_box(intro_1)
   -- This objective stays active until the player meets the Empire
   local o_north = add_campaign_objective(obj_north)

   -- Wait until the first port space is found (and reachable)
   while true do
      sleep(2341)
      local ok = true
      for i,f in pairs(port_south:region(2)) do
         if f.owner ~= p1 then
            ok = false
            break
         end
      end
      if ok then
         ok = nil
         for x = 7, 12 do
            for y = 456, 470 do
               local f = map:get_field(x, y)
               if f.immovable and f.immovable.descr.type_name == "flag" and
                     f.immovable:is_flag_reachable(map.player_slots[1].starting_field.brn.immovable) then
                  ok = f
               end
            end
            if ok then break end
         end
         if ok then break end
      end
   end
   p1:conquer(port_south, 4)
   for i,f in pairs(obstacles_1) do
      f.immovable:remove()
   end
   scroll_to_field(port_south)
   campaign_message_box(port_1)

   -- Wait for the player to build a port on the Volcano Island
   while not (port_volcano.immovable and port_volcano.immovable.descr.name == "frisians_port") do sleep(2341) end
--    for i,f in pairs(obstacles_2) do
--       f.immovable:remove()
--    end
   scroll_to_field(port_volcano)
   sleep(2000)
   campaign_message_box(port_2)

   -- Wait for the player to meet the Atlanteans
   local fields = {}
   for x = 0, map.width - 1 do
      for y = 307, 404 do
         table.insert(fields, map:get_field(x, y))
      end
   end
   local see_other = nil
   while not see_other do
      for i,f in ipairs(fields) do
         sleep(5)
         local p1c = false
         local p2c = false
         for j,claimer in ipairs(f.claimers) do
            if claimer == p1 then p1c = true end
            if claimer == p2 then p2c = true end
         end
         if p1c and p2c then
            see_other = f
            break
         end
      end
   end
   scroll_to_field(see_other)
   sleep(1000)
   campaign_message_box(atl_1)
   campaign_message_box(atl_2)
   campaign_message_box(atl_3)
   campaign_message_box(atl_4)
   campaign_message_box(atl_5)
   campaign_message_box(atl_6)
   local o = add_campaign_objective(obj_atl)

   -- Wait for the player to defeat the Atlanteans
   while not (map.player_slots[2].starting_field.immovable and
         map.player_slots[2].starting_field.immovable.descr.name == "frisians_port") do sleep(2341) end
   set_objective_done(o)
   scroll_to_field(map.player_slots[2].starting_field)
   campaign_message_box(atl_7)

   -- Wait for the player to build a port on the Desert Island
   while not (port_desert_s.immovable and port_desert_s.immovable.descr.name == "frisians_port") do sleep(2341) end
   scroll_to_field(port_desert_s)
   sleep(1000)
   campaign_message_box(port_3)
   campaign_message_box(port_4)

   -- Wait for the player to find the other port space on the Desert Island
   while port_desert_n.owner ~= p1 do sleep(2341) end
   p1:conquer(port_desert_n, 4)
   scroll_to_field(port_desert_n)
   sleep(2000)
   campaign_message_box(port_5)

   -- Wait for the player to build a port on the Northern Shore
   while not (port_north.immovable and port_north.immovable.descr.name == "frisians_port") do sleep(2341) end
--    for i,f in pairs(obstacles_3) do
--       f.immovable:remove()
--    end
   scroll_to_field(port_north)
   sleep(1000)
   campaign_message_box(port_6)
   campaign_message_box(port_7)

   -- Wait for the player to meet the Empire
   fields = {}
   for x = 0, map.width - 1 do
      for y = 0, 164 do
         table.insert(fields, map:get_field(x, y))
      end
   end
   local see_other = nil
   while not see_other do
      for i,f in ipairs(fields) do
         sleep(5)
         local p1c = false
         local p3c = false
         for j,claimer in ipairs(f.claimers) do
            if claimer == p1 then p1c = true end
            if claimer == p3 then p3c = true end
         end
         if p1c and p3c then
            see_other = f
            break
         end
      end
   end
   set_objective_done(o_north)
   scroll_to_field(see_other)
   sleep(1000)
   local cost = p1:get_wares("gold") + 200
   campaign_message_box(emp_1)
   campaign_message_box(emp_2)
   campaign_message_box(emp_3)
   campaign_message_box(emp_4)
   campaign_message_box(emp_5)
   campaign_message_box(emp_6(cost))
   campaign_message_box(emp_7(cost))
   o = add_campaign_objective(obj_emp(cost))

   local end_time = game.time + 7200000 -- 2 hours until timeout
   while game.time < end_time do
      sleep(1999)
      local fight = nil
      if map.player_slots[3].starting_field.immovable and
            map.player_slots[3].starting_field.immovable.descr.name == "frisians_port" then
         fight = true
      elseif port_north.immovable:get_wares("gold") >= cost then
         fight = false
         p1:reveal_fields(map.player_slots[3].starting_field:region(7))
      end
      if fight ~= nil then
         set_objective_done(o)
         game:save_campaign_data("frisians", "fri04", { defeated_iniucundus = fight })
         scroll_to_field(map.player_slots[3].starting_field)
         local field = map.player_slots[3].starting_field.trn.trn.tln
         if fight then
            p1:place_ship(field)
            sleep(2000)
            campaign_message_box(victory_fight)
         else
            p3:place_ship(field)
            sleep(2000)
            campaign_message_box(victory_pay)
         end
         p1:reveal_scenario("frisians04")
         -- END OF MISSION 4
         return
      end
   end
   -- Timeout
   campaign_message_box(timeout_1)
   wl.ui.MapView():close()

end

run(mission_thread)

include "scripting/messages.lua"
include "scripting/field_animations.lua"

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

function mission_thread()

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

end

run(mission_thread)

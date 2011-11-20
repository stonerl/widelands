-- =======================================================================
--                 Start conditions for Hardcore Barbarians
-- =======================================================================

use("aux", "infrastructure")

set_textdomain("tribe_barbarians")

init = {
   name = _ "Hardcore",
   func = function(player, shared_in_start)

   local sf = wl.Game().map.player_slots[player.number].starting_field
   if shared_in_start then
      sf = shared_in_start
   else
      player:allow_workers("all")
   end

   hq = prefilled_buildings(player, { "headquarters", sf.x, sf.y,
      wares = {
         trunk = 7,
      },
      workers = {
         blacksmith = 1,
         smelter = 1,
         builder = 1,
         carrier = 10,
         ferner = 1,
         geologist = 1,
         ["lime-burner"] = 1,
         lumberjack = 2,
         miner = 2,
         ranger = 1,
         stonemason = 1,
         hunter = 1,
         farmer = 1,
         fisher = 1,
         baker = 1,
         innkeeper = 1,
         burner = 1
      },
      soldiers = {
         [{0,0,0,0}] = 1,
      }
   })
end
}

return init


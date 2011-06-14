-- =======================================================================
--                Starting conditions for Hardcore Empire
-- =======================================================================

use("aux", "infrastructure")

set_textdomain("tribe_empire")

return {
   name = _ "Hardcore",
   func =  function(p, shared_in_start)

   local sf = wl.Game().map.player_slots[p.number].starting_field

   if shared_in_start then
      sf = shared_in_start
   else
      p:allow_workers("all")
   end

   prefilled_buildings(p, { "headquarters", sf.x, sf.y,
      wares = {
         trunk = 2,
         wood = 3,
      },
      workers = {
         baker = 1,
         brewer = 2,
         builder = 1,
         burner = 1,
         carpenter = 1,
         carrier = 10,
         farmer = 1,
         fisher = 1,
         forester = 1,
         geologist = 1,
         hunter = 1,
         innkeeper = 1,
         lumberjack = 1,
         miller = 1,
         miner = 3,
         smelter = 1,
         stonemason = 2,
         toolsmith = 1,
         vinefarmer =1
      },
      soldiers = {
         [{0,0,0,0}] = 1,
      }
   })
end
}


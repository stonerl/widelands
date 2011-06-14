-- =======================================================================
--              Starting Conditions for Hardcore Atlanteans
-- =======================================================================

use("aux", "infrastructure")

set_textdomain("tribe_atlanteans")

init = {
   name = _ "Hardcore",
   func =  function(plr, shared_in_start)

   local sf = wl.Game().map.player_slots[plr.number].starting_field
   if shared_in_start then
      sf = shared_in_start
   else
      plr:allow_workers("all")
   end

   plr:forbid_buildings{"shipyard"}


   prefilled_buildings(plr, { "headquarters", sf.x, sf.y,
      wares = {
         trunk = 2,
         planks = 2,
         spidercloth = 1
      },
      workers = {
         baker = 1,          
         blackroot_farmer = 1,
         builder = 1,
         burner = 1,
         carrier = 10,
         farmer = 1,
         fisher = 1,
         forester = 1,
         geologist = 1,
         hunter = 1,
         miller = 1,
         miner = 6,
         sawyer = 1,
         smelter = 1,
         smoker = 1,
         spiderbreeder = 1,
         stonecutter = 1,
         toolsmith = 1,
         woodcutter = 1,
         weaver = 1
      },
      soldiers = {
         [{0,0,0,0}] = 1,
      }
   })
end
}

return init


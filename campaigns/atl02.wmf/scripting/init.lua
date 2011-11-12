-- =======================================================================
--                      Atlanteans Tutorial Mission 02
-- =======================================================================

use("aux", "coroutine")
use("aux", "table")
use("aux", "infrastructure")
use("aux", "objective_utils")
use("aux", "ui")

-- ===================
-- Constants & Config
-- ===================
set_textdomain("scenario_atl02.wmf")

game = wl.Game()
map = game.map
p1 = game.players[1]
kalitath = game.players[3]
maletus = game.players[2]

-- =================
-- global variables
-- =================

use("map", "texts")

-- =================
-- Helper functions
-- =================
-- Show one message box
function msg_box(i)
   if i.pre_func then i.pre_func() end

   if not i.h then i.h = 400 end

   p1:message_box(i.title, i.body, i)

   if i.post_func then i.post_func() end

   sleep(130)
end

-- Show many message boxes
function msg_boxes(boxes_descr)
   for idx,box_descr in ipairs(boxes_descr) do
      msg_box(box_descr)
   end
end

-- Add an objective
function add_obj(o)
   return p1:add_objective(o.name, o.title, o.body)
end

-- ===============
-- Initialization
-- ===============
function _initialize_player(args)
   p1:allow_buildings("all")
   p1:forbid_buildings{"shipyard"}

   -- TODO: should not be a default headquarter
   -- A default headquarters
   use("tribe_atlanteans", "sc00_headquarters_medium")
   init.func(p1) -- defined in sc00_headquarters_medium
   set_textdomain("scenario_atl02.wmf")
   local hq = wl.Game().map.player_slots[1].starting_field.immovable
   hq:set_workers{shipwright=1}
end
function _initialize_kalitath()
   kalitath:allow_buildings("all")

   -- A default headquarters
   use("tribe_barbarians", "sc00_headquarters_medium")
   init.func(kalitath) 
   set_textdomain("scenario_atl02.wmf")

   -- Place some fortifications so that he does not get overrun
   prefilled_buildings(kalitath, 
      { "citadel", 81, 125, soldiers = {
            [{3,5,0,2}] = 4,
            [{1,3,0,1}] = 6,
            [{0,0,0,0}] = 2,
         },
      },
      { "donjon", 76, 120, soldiers = {
            [{3,5,0,2}] = 2,
            [{1,2,0,0}] = 2,
            [{0,0,0,0}] = 1,
         },
      },
      { "donjon", 87, 116, soldiers = {
            [{3,5,0,2}] = 2,
            [{1,2,0,0}] = 2,
            [{0,0,0,0}] = 1,
         },
      }
   )

   -- Conquer basically all of the south area
   prefilled_buildings(kalitath, 
      { "barrier", 89, 140 },
      { "barrier", 107, 144 },
      { "barrier", 96, 148 },
      { "barrier", 89, 160 },
      { "barrier", 104, 160 },
      { "barrier", 116, 145 },
      { "barrier", 134, 155 },
      { "barrier", 121, 118 },
      { "barrier", 127, 131 },
      { "barrier", 142, 116 },
      { "barrier", 125, 152 },
      { "barrier", 135, 141 },
      { "barrier", 139, 130 },
      { "donjon", 132, 118 },
      { "barrier", 120, 166 },
      { "barrier", 119, 134 },
      { "donjon", 128, 162 },
      { "fortress", 102, 135 },
      { "citadel", 150, 141 },
      { "fortress", 155, 119 }
   )

   -- Infrastructure
   prefilled_buildings(kalitath, 
      { "quarry", 88, 144 },
      { "quarry", 98, 143 },
      { "quarry", 113, 124 },
      { "hardener", 114, 148 },
      { "hardener", 114, 150 },
      { "lumberjacks_hut", 111, 148 },
      { "lumberjacks_hut", 106, 162 },
      { "lumberjacks_hut",  99, 162 },
      { "lumberjacks_hut",  88, 154 },
      { "lumberjacks_hut",  79, 173 },
      { "lumberjacks_hut", 127, 157 },
      { "lumberjacks_hut", 138, 139 },
      { "lumberjacks_hut", 143, 148 },
      { "lumberjacks_hut", 136, 151 }
   )


end
function _initialize_maletus(args)
   maletus:allow_buildings("all")

   -- A default headquarters
   use("tribe_empire", "sc00_headquarters_medium")
   init.func(maletus) 
   set_textdomain("scenario_atl02.wmf")
end

function initialize()
   _initialize_player()
   _initialize_kalitath()
   _initialize_maletus()
end

-- ==============
-- Logic Threads
-- ==============
function intro()
   sleep(1000)

   p1.see_all = true -- TODO: remove this
   initialize()

   add_obj(obj_basic_infrastructure)
   add_obj(obj_tools)
   add_obj(obj_explore)
   msg_boxes(initial_messages)
end

run(intro)


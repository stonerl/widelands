dirname = path.dirname (__file__)

tribes:new_productionsite_type {
   msgctxt = "frisians_building",
   name = "frisians_shipyard",
   -- TRANSLATORS: This is a building name used in lists of buildings
   descname = pgettext ("frisians_building", "Shipyard"),
   helptext_script = dirname .. "helptexts.lua",
   icon = dirname .. "menu.png",
   size = "medium",
   needs_seafaring = true,

   buildcost = {
      brick = 4,
      granite = 2,
      log = 3,
      thatch_reed = 3
   },
   return_on_dismantle = {
      brick = 2,
      granite = 1,
      log = 2,
      thatch_reed = 1
   },

   animations = {
      idle = {
         pictures = path.list_files (dirname .. "idle_??.png"),
         hotspot = {56, 80},
         fps = 10,
      },
      unoccupied = {
         pictures = path.list_files (dirname .. "unoccupied_?.png"),
         hotspot = {56, 80},
      },
   },

   aihints = {
      needs_water = true,
      shipyard = true,
      prohibited_till = 1050
   },

   working_positions = {
      frisians_shipwright = 1
   },

   inputs = {
      { name = "log", amount = 10 },
      { name = "cloth", amount = 6 },
      { name = "clay", amount = 3 }
   },

   programs = {
      work = {
         -- TRANSLATORS: Completed/Skipped/Did not start working because ...
         descname = _"working",
         actions = {
            "sleep=20000",
            "call=ship",
            "return=skipped"
         }
      },
      ship = {
         -- TRANSLATORS: Completed/Skipped/Did not start constructing a ship because ...
         descname = _"constructing a ship",
         actions = {
            "checkmap=seafaring",
            "construct=frisians_shipconstruction buildship 6",
            "sleep=35000",
            "return=completed"
         }
      },
   },
}

dirname = path.dirname (__file__)

tribes:new_productionsite_type {
   msgctxt = "frisians_building",
   name = "frisians_scouts_house",
   -- TRANSLATORS: This is a building name used in lists of buildings
   descname = pgettext ("frisians_building", "Scout’s House"),
   helptext_script = dirname .. "helptexts.lua",
   icon = dirname .. "menu.png",
   size = "small",

   buildcost = {
      granite = 1,
      log = 1,
      reed = 1
   },
   return_on_dismantle = {
      granite = 1,
      log = 1
   },

   animations = {
      idle = {
         pictures = path.list_files (dirname .. "idle_??.png"),
         hotspot = {49, 82},
         fps = 10,
      },
      unoccupied = {
         pictures = path.list_files (dirname .. "unoccupied_?.png"),
         hotspot = {49, 73},
      },
   },

   aihints = {},

   working_positions = {
      frisians_scout = 1
   },

   inputs = {
      { name = "ration", amount = 2 }
   },

   programs = {
      work = {
         -- TRANSLATORS: Completed/Skipped/Did not start scouting because ...
         descname = _"scouting",
         actions = {
            "consume=ration",
            "sleep=30000",
            "callworker=scout"
         }
      },
   },
}

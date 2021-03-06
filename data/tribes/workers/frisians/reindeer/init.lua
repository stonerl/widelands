dirname = path.dirname (__file__)

animations = {
   idle = {
      pictures = path.list_files (dirname .. "idle_??.png"),
      hotspot = {27, 21},
      fps = 20
   }
}

add_directional_animation(animations, "walk", dirname, "walk", {21, 43}, 20)
add_directional_animation(animations, "walkload", dirname, "walk", {21, 43}, 20)

tribes:new_carrier_type {
   msgctxt = "frisians_worker",
   name = "frisians_reindeer",
   -- TRANSLATORS: This is a worker name used in lists of workers
   descname = pgettext ("frisians_worker", "Reindeer"),
   helptext_script = dirname .. "helptexts.lua",
   icon = dirname .. "menu.png",
   vision_range = 2,

   default_target_quantity = 10,
   ware_hotspot = { 0, 18 },

   animations = animations,

   aihints = {
      preciousness = {
         frisians = 2
      },
   }
}

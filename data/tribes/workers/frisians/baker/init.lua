dirname = path.dirname (__file__)

animations = {
   idle = {
      pictures = path.list_files (dirname .. "idle_??.png"),
      hotspot = {8, 23},
   }
}
add_directional_animation(animations, "walk", dirname, "walk", {11, 23}, 15)
add_directional_animation(animations, "walkload", dirname, "walkload", {10, 26}, 15)

tribes:new_worker_type {
   msgctxt = "frisians_worker",
   name = "frisians_baker",
   -- TRANSLATORS: This is a worker name used in lists of workers
   descname = pgettext ("frisians_worker", "Baker"),
   helptext_script = dirname .. "helptexts.lua",
   icon = dirname .. "menu.png",
   vision_range = 2,

   buildcost = {
      frisians_carrier = 1,
      bread_paddle = 1
   },

   experience = 13,
   becomes = "frisians_baker_master",

   ware_hotspot = {0, 20},
   animations = animations,
}

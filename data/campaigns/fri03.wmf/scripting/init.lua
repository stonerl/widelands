-- =======================================================================
--                         Frisian Campaign Mission 3
-- =======================================================================
set_textdomain("scenario_fri03.wmf")

include "scripting/coroutine.lua"
include "scripting/objective_utils.lua"
include "scripting/infrastructure.lua"
include "scripting/table.lua"
include "scripting/ui.lua"

game = wl.Game()
map = game.map
p1 = game.players[1] -- Claus Lembeck     – Player's tribe
p2 = game.players[2] -- Waldemar Atterdag – Enemy, King of Denmark
p3 = game.players[3] -- Henneke Lembeck   – Claus's son
p4 = game.players[4] -- Hans Ravenstrupp  – Enemy to Claus's other son

ai_speed_1 = 500
ai_speed_2 = 10

p3_start = {
   map:get_field(334, 206),
   map:get_field(334, 207),
   map:get_field(335, 208),
   map:get_field(335, 206),
   map:get_field(335, 207),
   map:get_field(335, 205),
   map:get_field(336, 206),
   map:get_field(336, 207),
   map:get_field(336, 205),
   map:get_field(337, 206),
   map:get_field(337, 204),
   map:get_field(337, 205),
   map:get_field(338, 204),
   map:get_field(338, 205),
}

include "map:scripting/texts.lua"
include "map:scripting/ai.lua"
include "map:scripting/mission_thread.lua"

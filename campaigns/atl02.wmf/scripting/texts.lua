-- =======================================================================
--                 Texts for the Atlantean Mission 2
-- =======================================================================

use("aux", "formatting")

function jundlina(title, text)
   return speech("map:princess.png", "2F9131", title, text)
end
function loftomor(text)
   return speech("map:loftomor.png", "FDD53D", "Loftomor", text)
end
function sidolus(text)
   return speech("map:sidolus.png", "FF1A30", "Sidolus", text)
end
function colionder(text)
   return speech("map:colionder.png", "33A9FD", "Colionder", text)
end
function opol(text)
   return speech("map:opol.png", "FF3FFB", "Opol", text)
end
function ostur(text)
   return speech("map:ostur.png", "375FFC", "Ostur", text)
end

-- Append an objective text to a dialog box in a nice fashion.
function new_objectives(...)
   local s = rt(
   "<p font=FreeSerif font-size=18 font-weight=bold font-color=D1D1D1>"
   .. _"New Objectives" .. "</p>")

   for idx,obj in ipairs{...} do
      s = s .. obj.body
   end
   return s
end

-- =======================================================================
--                                Objectives
-- =======================================================================
-- obj_ensure_build_wares_production = {
   -- name = "obj_ensure_build_wares_production",
   -- title = _ "Ensure the supply of build wares",
   -- body = objective_text(_"The supply of build wares", _
-- [[Build a quarry, two woodcutter's houses, two forester's houses and a
-- sawmill.]]
   -- ),
-- }

-- =======================================================================
--                                  Texts
-- =======================================================================

-- This is an array or message descriptions
initial_messages = {
{
   title = _ "Proudest to the death",
   body = rt(
      h1(_"Favored by the god") ..
      p(_
[[On the hidden and lost island of Atlantis, a proud tribe settled since the
world was very young. Ruled by the bloodline of King Ajanthul - the first human
to be empowered by the sea god Lutas to breathe above the sea level - and the
wise clerics, who provided the link to Lutas - they prospered and became
civilized.]]
      ) .. p(_
[[This story happens during the regency of King Askandor, the 43rd successor of
King Ajanthul. He has been a good king, ruling Atlantis with wisdom and
foresight. But with age, he became afraid of dying and so he began looking for
a cure to death even though most clerics warned him. Some said, endless life
was only for the gods and to seek for it was forbidden.]]
      )
   ),
},
{
   title = _ "The god's disgrace",
   body = rt(
      h1(_"The god's punishment") ..
      p(_
[[But all seemed well. Only the horses seemed to feel something was wrong.
In the nights, they went crazy and were full of fear. It was not long before the
horsebreeder Xydra figured out what was wrong with them: The sea level in front
of their stable was rising in an ever accelerating speed.]]
   ) .. p(_
[[The clerics went into their meditation and the reason for the rising water
was soon to be found: The god Lutas had lost faith in the Atlanteans because of
the boldness of their king. He decided to withdraw the rights that were granted
to King Ajanthul and his children. And so, he called them back below the sea
again.]]
   )
)
},
{
   title = _ "Uproar and confusion",
   body = rt(
      h1(_"Chaos emerges...") ..
      p(_
[[Guilt-ridden, the king committed suicide. Without a monarch, the people
turned to the clerics, but those had no substantial help to offer. Most
accepted their fate while others tried to change the god's mind by offering
animals in his temple. But to no avail...]]
   ) .. p(_
[[Jundlina, the late king's daughter and the highest priestess of the god
was the most determined cleric. As countless offerings didn't change the
situation, she convinced herself that to soothe the god, an offer of great
personal value was needed. So she offered him her most beloved:
her husband, father of her only child.]]
   ) .. p(_
[[But not even this changed the mind of the god. The water kept on rising.
Nearly driven crazy by guilt, pain and anger, Jundlina became a heretic:
Secretly, she gathered people of the common folk who were not in line with the
decision of the clerics to accept the god's will. Together with them, she set
the temple on fire and stole a ship to flee from the god's influence of
Atlantis. This small group started praying to Satul, the fire god and the worst
enemy of Lutas.]]
   ) .. p(_
[[Leaving the dying Atlantis and their past behind, they started a quest to
find a place sheltered by the fire and protected from the sea.]]
   )
)
},
} -- end of initial messages.




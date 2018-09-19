-- =========================
-- Some formating functions
-- =========================

include "scripting/richtext_scenarios.lua"

function claus(title, text)
   return speech ("map:lembeck_claus.png", "1CC200", title, text)
end
function henneke(title, text)
   return speech ("map:lembeck_henneke.png", "F7FF00", title, text)
end
function atterdag(title, text)
   return speech ("map:dane.png", "8A0004", title, text)
end
function hans(title, text)
   return speech ("map:haderslev.png", "1590B5", title, text)
end

-- =======================================================================
--                           Texts - No logic here
-- =======================================================================

-- ===========
-- objectives
-- ===========

obj_wait_for_reinforcements = {
   name = "wait_for_reinforcements",
   title=_"Survive until help arrives",
   number = 1,
   body = objective_text(_"Wait For Help",
      li(_[[Survive the attacks until Henneke Lembeck arrives with reinforcements.]])
   ),
}

obj_ = {
   name = "",
   title=_"Title name",
   number = 1,
   body = objective_text(_"Body Heading",
      li(_[[Text]])
   ),
}

-- ==================
-- Texts to the user
-- ==================

intro_1 = {
   title =_ "Introduction",
   body=claus(_"Welcome Back!",
      -- TRANSLATORS: Claus Lembeck – Introduction 1
      _([[I wish I could greet you, but the circumstances deny me that luxury.]])),
}
intro_2 = {
   title =_ "Introduction",
   body=claus(_"Welcome Back!",
      -- TRANSLATORS: Claus Lembeck – Introduction 2. The "Thing" (DO NOT TRANSLATE) is the gathering of the frisian aldermen
      _([[In other times, I would welcome you with a banquet, introduce you to the Thing, and show you around Föhr, this beautiful island, which we also call the Green Island due to its shining meadows, or the Frisian Carribbean, in comparison with a faraway land which the captains and sailors talk so highly about.]])),
}
intro_3 = {
   title =_ "Introduction",
   body=claus(_"Welcome Back!",
      -- TRANSLATORS: Claus Lembeck – Introduction 3
      _([[But I am none other than Claus Lembeck, and my troubles are too great; for danger has risen from a partly unexpected source, and it has arrived ere I was ready for it.]])
      .. paragraphdivider() ..
      -- TRANSLATORS: Claus Lembeck – Introduction 3
      _([[My old enemy Waldemar Atterdag, King of the Danes, is leveling at my life yet again. I have lost count of the number of times I have fought him and prevailed. But then, I was always in my fortress at Dorning, which is impenetrable even to the strongest foe. But recently, I have left Dorning to my oldest son Rolf to build a castle here on Föhr.]])),
}
intro_4 = {
   title =_ "Introduction",
   body=claus(_"Welcome Back!",
      -- TRANSLATORS: Claus Lembeck – Introduction 4
      _([[Added to this worry is the fact that Rolf made an enemy of Atterdag’s kinsmen Hans Ravenstrupp, who owns the castle of Haderslevhuus. If the news hold true, he has dishonourably murdered my son and is now seeking to be revenged on me as well for God knows what.]])
      .. paragraphdivider() ..
      -- TRANSLATORS: Claus Lembeck – Introduction 4
      _([[Atterdag and Ravenstrupp have joined in complot and have both landed on this island before my watchmen discovered their approach.]])),
}
intro_5 = {
   title =_ "Introduction",
   body=claus(_"Welcome Back!",
      -- TRANSLATORS: Claus Lembeck – Introduction 5
      _([[I have sent word to my other son Henneke, and he is coming to my aid. Until then, we must hold out against the enemies’ attacks. They are still far away and may appear weak, but my scouts assure me that they are much too strong for our modest army.]]))
      .. new_objectives(obj_wait_for_reinforcements),
}
intro_6 = {
   title =_ "Note",
   -- TRANSLATORS: Narrator – Introduction 6
   body=p(_([[No mines can be built on the island. There are no rocks to cut granite from. And it is not possible to grow trees on this map. All players will be supplied frequently with wood, stones, and ores.]])),
   w = 450,
   h = 150,
}

victory_1 = {
   title =_ "Victory",
   body=claus(_"We escaped!",
      -- TRANSLATORS: Reebaud – victory
      _([[The gods have answered our prayers. We will escape the island’s drowning, and I am confident we will be able to build a new home again in a more peaceful corner of this world!]]))
      .. objective_text(_"Congratulations",
      -- TRANSLATORS: Reebaud – victory
      _[[You have completed this mission. You may move on to the next scenario now to help us build a new home, far from the false God’s vengeful reach…]]),
}

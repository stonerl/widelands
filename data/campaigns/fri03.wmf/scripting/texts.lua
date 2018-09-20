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
      li(_[[Survive the attacks until Henneke Lembeck arrives with reinforcements.]]) ..
      li_arrow(_[[The enemies must not destroy your headquarters.]])
   ),
}

obj_connect_farms = {
   name = "connect_farms",
   title=_"Connect the farms",
   number = 1,
   body = objective_text(_"Build Roads to All Farms",
      li(_[[Build roads to ensure all farms can be reached from your headquarters.]])
   ),
}

obj_rescue = {
   name = "rescue",
   title=_"Rescue the Castle",
   number = 1,
   body = objective_text(_"Prevent the Enemies from Destroying the Castle",
      li(_[[Push back the enemies. They must not conquer Claus Lembeck’s headquarters.]])
   ),
}

obj_witchhunt = {
   name = "witchhunt",
   title=_"Chase the witch",
   number = 1,
   body = objective_text(_"Kill or Capture the Evil Witch",
      li(_[[A witch in animal shape is destroying your buildings. Either kill her or capture her.]]) ..
      li_arrow(_[[To kill the witch, burn down a building when the witch is close to its flag.]]) ..
      li_arrow(_[[To capture the witch, conjure the spirits residing within her. Hint: You need to make a circle.]])
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
   title = _"Introduction",
   body=claus(_"Welcome back!",
      -- TRANSLATORS: Claus Lembeck – Introduction 1
      _([[I wish I could greet you, but the circumstances deny me that luxury.]])),
}
intro_2 = {
   title = _"Introduction",
   body=claus(_"Welcome back!",
      -- TRANSLATORS: Claus Lembeck – Introduction 2. The "Thing" (DO NOT TRANSLATE) is the gathering of the frisian aldermen
      _([[In other times, I would welcome you with a banquet, introduce you to the Thing, and show you around Föhr, this beautiful island, which we also call the Green Island due to its shining meadows, or the Frisian Carribbean, in comparison with a faraway land which the captains and sailors talk so highly about.]])),
}
intro_3 = {
   title = _"Introduction",
   body=claus(_"Welcome back!",
      -- TRANSLATORS: Claus Lembeck – Introduction 3
      _([[But I am none other than Claus Lembeck, and my troubles are too great; for danger has risen from a partly unexpected source, and it has arrived ere I was ready for it.]])
      .. paragraphdivider() ..
      -- TRANSLATORS: Claus Lembeck – Introduction 3
      _([[My old enemy Waldemar Atterdag, King of the Danes, is leveling at my life yet again. I have lost count of the number of times I have fought him and prevailed. But then, I was always in my fortress at Dorning, which is impenetrable even to the strongest foe. But recently, I have left Dorning to my oldest son Rolf to build a castle here on Föhr.]])),
}
intro_4 = {
   title = _"Introduction",
   body=claus(_"Welcome back!",
      -- TRANSLATORS: Claus Lembeck – Introduction 4
      _([[Added to this worry is the fact that Rolf made an enemy of Atterdag’s kinsmen Hans Ravenstrupp, who owns the castle of Haderslevhuus. If the news hold true, he has dishonourably murdered my son and is now seeking to be revenged on me as well for God knows what.]])
      .. paragraphdivider() ..
      -- TRANSLATORS: Claus Lembeck – Introduction 4
      _([[Atterdag and Ravenstrupp have joined in complot and have both landed on this island before my watchmen discovered their approach.]])),
}
intro_5 = {
   title = _"Introduction",
   body=claus(_"Welcome back!",
      -- TRANSLATORS: Claus Lembeck – Introduction 5
      _([[I have sent word to my other son Henneke, and he is coming to my aid. Until then, we must hold out against the enemies’ attacks. They are still far away and may appear weak, but my scouts assure me that they are much too strong for our modest army.]]))
      .. new_objectives(obj_wait_for_reinforcements),
}
intro_6 = {
   title = _"Note",
   -- TRANSLATORS: Narrator – Introduction 6
   body=p(_([[No mines can be built on this island. There are no rocks to cut granite from. And it is not possible to grow trees on this map. All players will be supplied frequently with wood, stones, and ores.]])),
   w = 450,
   h = 150,
}

farms_1 = {
   title = _"Barley Supply",
   body=claus(_"Connect our farms",
      -- TRANSLATORS: Claus Lembeck – Farms
      _([[We used to get the barley we need for bread, beer, and to feed the reindeer by trading with the farmers. In this time of war, we have to make this trade more efficient. The farmers have agreed to deliver their entire harvest to our headquarters at a fixed price. Build roads to all farms to ensure our carriers can take care of that.]]))
      .. new_objectives(obj_connect_farms),
}

unconnected_farm = {
   title = _"Unconnected Farm",
   heading = _"A Farm is not connected yet",
   body = p(_[[At least one of your farms is not connected to your headquarters yet.]])
}

help_arrives_1 = {
   title = _"Aid is Arriving",
   body=claus(_"Henneke is coming!",
      -- TRANSLATORS: Claus Lembeck – Henneke arrives 1
      _([[Finally! A ship has landed on the eastern cost of the island. I know these colours – my son Henneke has come to our aid at last!]])),
}
help_arrives_2 = {
   title = _"Aid is Arriving",
   body=henneke(_"Unwelcome news",
      -- TRANSLATORS: Henneke Lembeck – Henneke arrives 2
      _([[Peace, Father! I have come to help you, but I fear I bring cold news. When I was lately at Kiel, the citizens mistook my soldiers for bandits and killed most of them, and I lost more when destroying the town in revenge. To cut the tale short – I have brought but few soldiers to aid you.]])),
}
help_arrives_3 = {
   title = _"Aid is Arriving",
   body=claus(_"Unwelcome news",
      -- TRANSLATORS: Claus Lembeck – Henneke arrives 3
      _([[These news are terrible indeed! The enemies are strong, and a mighty army would be hard-pressed to drive them off! But it is useless to complain, since there is nothing that can be done about it. Let us pray for strength, and fight the foes together!]]))
      .. new_objectives(obj_rescue),
}

witchhunt_1 = {
   title = _"Unexplicable Fires",
   body=claus(_"Buildings are burning",
      -- TRANSLATORS: Claus Lembeck – Witchhunt 1
      _([[The enemies have been pushes back, but something strange is going on. Several buildings have burst into flame for no apparent reason! How can this be?]])),
}
witchhunt_2 = {
   title = _"Unexplicable Fires",
   body=henneke(_"Buildings are burning",
      -- TRANSLATORS: Henneke Lembeck – Witchhunt 2
      _([[It is rumoured among our people that there is a witch or wizard inside our fortifications. This evildoer, they say, is responsible for the fires. Sightings of ferocious animals that strolled through out town have been reported. I suspect the evil witch is disguised as one of these, and working havoc in our Castle!]])),
}
witchhunt_3 = {
   title = _"Unexplicable Fires",
   body=claus(_"Buildings are burning",
      -- TRANSLATORS: Claus Lembeck – Witchhunt 3
      _([[You think so? You know I am sceptical whether witches even exist, but the clerics seem to share your suspicions. Very well, let’s see if we can identify and kill the witch. Or perhaps, it might even be possible to capture her alive and make her fight our enemies for us! I have no idea how that could be done though…]]))
      .. new_objectives(obj_witchhunt),
}

defeated_1 = {
   title = _"You are Defeated",
   -- TRANSLATORS: Narrator – Player was defeated
   body=p(_([[You were defeated and may not continue playing. May you have better luck when you retry this scenario. Click OK to return to the main menu.]])),
   w = 450,
   h = 150,
}
victory_1 = {
   title = _"Victory",
   body=claus(_"We escaped!",
      -- TRANSLATORS: Reebaud – victory
      _([[The gods have answered our prayers. We will escape the island’s drowning, and I am confident we will be able to build a new home again in a more peaceful corner of this world!]]))
      .. objective_text(_"Congratulations",
      -- TRANSLATORS: Reebaud – victory
      _[[You have completed this mission. You may move on to the next scenario now to help us build a new home, far from the false God’s vengeful reach…]]),
}

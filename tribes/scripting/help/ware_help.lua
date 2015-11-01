-- NOCOM we should have a common include for the helper functions.

include "scripting/formatting.lua"

--  =======================================================
--  *************** Basic helper functions ****************
--  =======================================================

-- RST
-- .. function:: image_line(image, count[, text = nil])
--
--    Aligns the image to a row on the right side with text on the left.
--
--    :arg image: the picture to be aligned to a row.
--    :arg count: length of the picture row.
--    :arg text: if given the text aligned on the left side, formatted via
--       formatting.lua functions.
--    :returns: the text on the left and a picture row on the right.
--
function image_line(image, count, text)
	local imgs={}
	for i=1,count do
		imgs[#imgs + 1] = image
	end
	local imgstr = table.concat(imgs, ";")

	if text then
		return rt("image=" .. imgstr .. " image-align=right", "  " .. text)
	else
		return rt("image=" .. imgstr .. " image-align=right", "")
	end
end

-- RST
-- .. function:: dependencies(items[, text = nil])
--
--    Creates a dependencies line of any length.
--
--    :arg items: ware, worker and/or building descriptions in the correct order
--                from left to right as table (set in {}).
--    :arg text: comment of the image.
--    :returns: a row of pictures connected by arrows.
--
function dependencies(items, text)
	if not text then
		text = ""
	end
	local string = "image=" .. items[1].icon_name
	for k,v in ipairs({table.unpack(items,2)}) do
		string = string .. ";pics/arrow-right.png;" ..  v.icon_name
	end
	return rt(string, p(text))
end

-- Helper function for building_help_building_section
function building_help_building_line(ware_description, amount)
	amount = tonumber(amount)
	local image = ware_description.icon_name
	local result = ""
	local imgperline = 6
	local temp_amount = amount

	while (temp_amount > imgperline) do
		result = result .. image_line(image, imgperline)
		temp_amount = temp_amount - imgperline
	end
	-- TRANSLATORS: %1$d is a number, %2$s the name of a ware, e.g. 12x Stone
	result = image_line(image, temp_amount, p(_"%1$dx %2$s":bformat(amount, ware_description.descname))) .. result
	return result

end

--  =======================================================
--  ************* Main worker help functions *************
--  =======================================================

-- RST
-- .. function ware_help_string(tribe, ware_description)
--
--    Displays the ware with a helptext and an image
--
--    :arg tribe: The :class:`LuaTribeDescription` for a tribe that uses this ware.
--    :arg ware_description: the worker_description from C++.
--    :returns: Help string for the ware
--
function ware_help_string(tribe, ware_description)
	include(ware_description.directory .. "helptexts.lua")

	local purpose_text = ware_helptext()
	if (purpose_text ~= "") then
		purpose_text = purpose_text .. " "
	end
	purpose_text = ware_helptext() .. ware_helptext(tribe.name)

	-- TODO(GunChleoc): Split into purpose and note
	local result = rt(h2(_"Purpose")) ..
		rt("image=" .. ware_description.icon_name, p(purpose_text))

	for i, building in ipairs(ware_description.producers) do
		if (tribe:has_building(building.name)) then
			-- TRANSLATORS: Ware Encyclopedia: A building producing a ware
			result = result .. rt(h2(_"Producer"))
			result = result .. dependencies({building, ware_description}, building.descname)

			-- Find out which programs in the building produce this ware
			local producing_programs = {}
			local produced_wares_strings = {}
			for j, program_name in ipairs(building.production_programs) do
				for ware, amount in pairs(building:produced_wares(program_name)) do
					if (ware_description.name == ware) then
						table.insert(producing_programs, program_name)
					end
				end
			end

			local produced_wares_counters = {}
			-- Now collect all produced wares by the filtered programs
			for j, program_name in ipairs(producing_programs) do
				local produced_wares_amount = {}
				produced_wares_counters[program_name] = 0
				for ware, amount in pairs(building:produced_wares(program_name)) do
					if (produced_wares_amount[ware] == nil) then
						produced_wares_amount[ware] = 0
					end
					produced_wares_amount[ware] = produced_wares_amount[ware] + amount
					produced_wares_counters[program_name] = produced_wares_counters[program_name] + amount
				end
				local produced_wares_string = ""
				for ware, amount in pairs(produced_wares_amount) do
				local ware_descr = wl.Game():get_ware_description(ware)
					produced_wares_string = produced_wares_string
						.. building_help_building_line(ware_descr, amount)
				end
				produced_wares_strings[program_name] = produced_wares_string
			end

			-- Now collect the consumed wares for each filtered program and print the program info
			for j, program_name in ipairs(producing_programs) do
				local consumed_wares_string = ""
				local consumed_wares_counter = 0
				local consumed_wares = building:consumed_wares(program_name)
				for countlist, warelist in pairs(consumed_wares) do
					local consumed_warenames = {}
					local consumed_images = {}
					local consumed_amount = {}
					local count = 1
					for consumed_ware, amount in pairs(warelist) do
						local ware_description = wl.Game():get_ware_description(consumed_ware)
						consumed_warenames[count] = _"%1$dx %2$s":bformat(amount, ware_description.descname)
						consumed_images[count] = ware_description.icon_name
						consumed_amount[count] = amount
						count = count + 1
						consumed_wares_counter = consumed_wares_counter + amount
					end
					local text = localize_list(consumed_warenames, "or")
					if (countlist > 1) then
						text = _"%s and":bformat(text)
					end
					local images = consumed_images[1]
					local image_counter = 2
					while (image_counter <= consumed_amount[1]) do
						images = images .. ";" .. consumed_images[1]
						image_counter = image_counter + 1
					end
					for k, v in ipairs({table.unpack(consumed_images,2)}) do
						image_counter = 1
						while (image_counter <= consumed_amount[k + 1]) do
							images = images .. ";" .. v
							image_counter = image_counter + 1
						end
					end
					consumed_wares_string = image_line(images, 1, p(text)) .. consumed_wares_string
				end
				if (consumed_wares_counter > 0) then
					-- TRANSLATORS: Ware Encyclopedia: Wares consumed by a productionsite
					result = result .. rt(h3(ngettext("Ware consumed:", "Wares consumed:", consumed_wares_counter)))
					result = result .. consumed_wares_string
				end
				if (produced_wares_counters[program_name] > 0) then
					-- TRANSLATORS: Ware Encyclopedia: Wares produced by a productionsite
					result = result
						.. rt(h3(ngettext("Ware produced:", "Wares produced:", produced_wares_counters[program_name])))
						.. produced_wares_strings[program_name]
				end
			end

		end
	end

	-- Now collecting the buildings that consume this ware
	local consumers_string = ""
	local consumers_amount = 0

	for i, building in ipairs(ware_description.consumers) do
		if (tribe:has_building(building.name)) then
			consumers_string = consumers_string .. dependencies({ware_description, building}, building.descname)
			consumers_amount = consumers_amount + 1
		end
	end

	-- Constructionsite isn't listed with the consumers, so we need a special check
	if (ware_description:is_construction_material(tribe.name)) then
		local constructionsite_description = wl.Game():get_building_description("constructionsite")
		consumers_string = consumers_string
			.. dependencies({ware_description, constructionsite_description}, constructionsite_description.descname)
		consumers_amount = consumers_amount + 1
	end

	-- Now collecting the workers that use this ware as a tool
	local workers_string = ""
	for i, workername in ipairs(tribe.workers) do
	local worker = wl.Game():get_worker_description(workername)
		local add_this_worker = false
		for j, buildcost in ipairs(worker.buildcost) do
			if (buildcost ~= nil and buildcost == ware_description.name) then
				add_this_worker = true
				consumers_amount = consumers_amount + 1
				break
			end
		end
		if(add_this_worker) then
			workers_string = workers_string .. image_line(worker.icon_name, 1, p(worker.descname))
		end
	end

	-- Now show consumers (buildings + workers)
	if (consumers_amount > 0) then
		-- TRANSLATORS: Ware Encyclopedia: A list of buildings and / or workers that consume a ware
		result = result .. rt(h2(ngettext("Consumer", "Consumers", consumers_amount)))
		if (consumers ~= "") then
			result = result .. consumers_string
		end
		if (workers_string ~= "") then
			result = result .. workers_string
		end
	end
	return result
end


return {
   func = function(tribename, ware_description)
      set_textdomain("tribes_encyclopedia")
      local tribe = wl.Game():get_tribe_description(tribename)
	   return ware_help_string(tribe, ware_description)
   end
}

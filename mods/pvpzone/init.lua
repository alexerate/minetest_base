pvpzone = {}
pvpzone_store = AreaStore()
pvpzone_store:from_file(minetest.get_worldpath() .. "/pvpzone_store.dat")

-- Register privilege and chat command.
minetest.register_privilege("pvpzone_admin", "Set PvP Zones.")

minetest.register_chatcommand("pvpzone", {
	description = "Set PvP Zones.",
	params = "{ pos1 | pos2 | set [zonename] | remove <id> | list }",
	privs = "pvpzone_admin",
	func = function(name, paramlist)
		local piterator = string.gmatch(paramlist,"%S+")
		local param = piterator()
		local pos = vector.round(minetest.get_player_by_name(name):getpos())
		if param == "pos1" then
			if not pvpzone[name] then
				pvpzone[name] = {pos1 = pos}
			else
				pvpzone[name].pos1 = pos
			end
			minetest.chat_send_player(name, "Position 1 : " .. minetest.pos_to_string(pos))
		elseif param == "pos2" then
			if not pvpzone[name] then
				pvpzone[name] = {pos2 = pos}
			else
				pvpzone[name].pos2 = pos
			end
			minetest.chat_send_player(name, "Position 2 : " .. minetest.pos_to_string(pos))
		elseif param == "set" then
			local zonename = "pvpzone"
			local newname = piterator()
			if newname then zonename = newname end

			if not pvpzone[name] or not pvpzone[name].pos1 then
				minetest.chat_send_player(name, "Position 1's missing, use \"/pvpzone pos1\" to set.")

			elseif not pvpzone[name].pos2 then
				minetest.chat_send_player(name, "Position 2's missing, use \"/pvpzone pos2\" to set.")

			else
				local zoneID = pvpzone_store:insert_area(pvpzone[name].pos1, pvpzone[name].pos2, zonename)
				minetest.chat_send_player(name, "PvP "..zonename.." ["..zoneID.."] has been set.")
				pvpzone_store:to_file(minetest.get_worldpath() .. "/pvpzone_store.dat")
			end

		elseif param == "remove" then
			local zoneID = piterator()
			if pvpzone_store:remove_area(zoneID) then
				pvpzone_store:to_file(minetest.get_worldpath() .. "/pvpzone_store.dat")
				minetest.chat_send_player(name, "Removed zone "..zoneID)
			else
				minetest.chat_send_player(name, "Invalid zone "..zoneID..". Use \"/pvpzone list\" to list zones.")
			end

		elseif param == "list" then
			pvpzone_store = AreaStore()
			pvpzone_store:from_file(minetest.get_worldpath() .. "/pvpzone_store.dat")
			local i = 0
			while true do
				local thiszone = pvpzone_store:get_area(i,true,true)
				if thiszone == nil or i > 50 then
					break
				end
				local zonestring = "PvP ["..i.."] : " .. thiszone.data .. " from "..minetest.pos_to_string(thiszone.min).." to "..minetest.pos_to_string(thiszone.max)
				minetest.chat_send_player(name, zonestring)
				i = i+1
			end
		else
			minetest.chat_send_player(name, "Invalid usage.  Type \"/help pvpzone\" for more information.")
		end
	end
})

-- Register punchplayer callback.
minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
	if not hitter:is_player() then return false end
	for k, v in pairs(pvpzone_store:get_areas_for_pos(player:getpos())) do
		if k then
			return false
		end
	end
	return true
end)

local modpath = minetest.get_modpath("pvpzone")
dofile(modpath .. "/hud.lua")



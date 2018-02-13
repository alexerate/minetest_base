local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")

local old_is_protected = minetest.is_protected
function minetest.is_protected(pos, name)
	if not areas:canInteract(pos, name) then
		return true
	end
	return old_is_protected(pos, name)
end

minetest.register_on_protection_violation(function(pos, name)
	if not areas:canInteract(pos, name) then
		local owners = areas:getNodeOwners(pos)
		--minetest.chat_send_player(name,	("%s est protégé par %s."):format(minetest.pos_to_string(pos),table.concat(owners, ", ")))
		minetest.chat_send_player(name, S("@1 est protégé par @2.",minetest.pos_to_string(pos),table.concat(owners, ", ")))
	end
end)

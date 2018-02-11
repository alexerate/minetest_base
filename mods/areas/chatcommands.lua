
minetest.register_chatcommand("protect", {
	params = "<NomArea>",
	description = "Protéger votre propre zone",
	privs = {[areas.config.self_protection_privilege]=true},
	func = function(name, param)
		if param == "" then
			return false, "Usage invalide, voir /help protect."
		end
		local pos1, pos2 = areas:getPos(name)
		if not (pos1 and pos2) then
			return false, "Vous devez d'abord définir une zone."
		end

		minetest.log("action", "/protect invoked, owner="..name..
				" AreaName="..param..
				" StartPos="..minetest.pos_to_string(pos1)..
				" EndPos="  ..minetest.pos_to_string(pos2))

		local canAdd, errMsg = areas:canPlayerAddArea(pos1, pos2, name)
		if not canAdd then
			return false, "Vous ne pouvez pas protéger cette zone : "..errMsg
		end

		local id = areas:add(name, param, pos1, pos2, nil)
		areas:save()

		return true, "Zone protégé. ID : "..id
	end
})


minetest.register_chatcommand("set_owner", {
	params = "<NomJoueur> <NomZone>",
	description = "Protéger une zone entre 2 positions et donne l'accès à un joueur sans définir de zone parent.",
	privs = areas.adminPrivs,
	func = function(name, param)
		local ownerName, areaName = param:match('^(%S+)%s(.+)$')

		if not ownerName then
			return false, "Usage incorrect, voir /help set_owner."
		end

		local pos1, pos2 = areas:getPos(name)
		if not (pos1 and pos2) then
			return false, "Vous devez d'abord définir une zone."
		end

		if not areas:player_exists(ownerName) then
			return false, "Le joueur \""..ownerName.."\" n'existe pas."
		end

		minetest.log("action", name.." runs /set_owner. Owner = "..ownerName..
				" AreaName = "..areaName..
				" StartPos = "..minetest.pos_to_string(pos1)..
				" EndPos = "  ..minetest.pos_to_string(pos2))

		local id = areas:add(ownerName, areaName, pos1, pos2, nil)
		areas:save()

		minetest.chat_send_player(ownerName, "Vous avez reçu le contrôle de la zone #"..id..". Tapez /list_areas pour voir vos zone.")
		return true, "Zone protégé. ID: "..id
	end
})


minetest.register_chatcommand("add_owner", {
	params = "<IDParent> <NomJoueur> <NomZone>",
	description = "Donne l'accès à une sous-zone entre 2 positions qui a déjà été protégée. Utilisez set_owner si vous ne voulez pas définir de parent.",
	func = function(name, param)
		local pid, ownerName, areaName
				= param:match('^(%d+) ([^ ]+) (.+)$')

		if not pid then
			minetest.chat_send_player(name, "Usage incorrect, voir /help add_owner")
			return
		end

		local pos1, pos2 = areas:getPos(name)
		if not (pos1 and pos2) then
			return false, "Vous devez d'abord définir une zone."
		end

		if not areas:player_exists(ownerName) then
			return false, "Le joueur \""..ownerName.."\" n'existe pas."
		end

		minetest.log("action", name.." runs /add_owner. Owner = "..ownerName..
				" AreaName = "..areaName.." ParentID = "..pid..
				" StartPos = "..pos1.x..","..pos1.y..","..pos1.z..
				" EndPos = "  ..pos2.x..","..pos2.y..","..pos2.z)

		-- Check if this new area is inside an area owned by the player
		pid = tonumber(pid)
		if (not areas:isAreaOwner(pid, name)) or
		   (not areas:isSubarea(pos1, pos2, pid)) then
			return false, "Vous ne pouvez pas protéger cette zone."
		end

		local id = areas:add(ownerName, areaName, pos1, pos2, pid)
		areas:save()

		minetest.chat_send_player(ownerName, "Vous avez reçu le contrôle de la zone #"..id..". Tapez /list_areas pour montrer vos zones.")
		return true, "Zone protégée. ID: "..id
	end
})


minetest.register_chatcommand("rename_area", {
	params = "<ID> <nouveauNom>",
	description = "Renommer une zone que vous possédez",
	func = function(name, param)
		local id, newName = param:match("^(%d+)%s(.+)$")
		if not id then
			return false, "Usage invalide, voir /help rename_area."
		end

		id = tonumber(id)
		if not id then
			return false, "Cette zone n'existe pas."
		end

		if not areas:isAreaOwner(id, name) then
			return true, "Vous n'êtes pas propriétaire de la zone."
		end

		areas.areas[id].name = newName
		areas:save()
		return true, "Zone renommée."
	end
})


minetest.register_chatcommand("find_areas", {
	params = "<regexp>",
	description = "Trouve la/les zones qui correspondent à l'expression régulière lua",
	privs = areas.adminPrivs,
	func = function(name, param)
		if param == "" then
			return false, "Une expression régulière est requise."
		end

		-- Check expression for validity
		local function testRegExp()
			("Test [1]: Player (0,0,0) (0,0,0)"):find(param)
		end
		if not pcall(testRegExp) then
			return false, "Expression régulière non valide."
		end

		local matches = {}
		for id, area in pairs(areas.areas) do
			local str = areas:toString(id)
			if str:find(param) then
				table.insert(matches, str)
			end
		end
		if #matches > 0 then
			return true, table.concat(matches, "\n")
		else
			return true, "Aucune correspondance."
		end
	end
})


minetest.register_chatcommand("list_areas", {
	description = "Liste vos zones, ou toutes les zones si vous êtes admin.",
	func = function(name, param)
		local admin = minetest.check_player_privs(name, areas.adminPrivs)
		local areaStrings = {}
		for id, area in pairs(areas.areas) do
			if admin or areas:isAreaOwner(id, name) then
				table.insert(areaStrings, areas:toString(id))
			end
		end
		if #areaStrings == 0 then
			return true, "Pas de zone visible."
		end
		return true, table.concat(areaStrings, "\n")
	end
})


minetest.register_chatcommand("recursive_remove_areas", {
	params = "<id>",
	description = "Supprime des zones de façon récursive avec un id",
	func = function(name, param)
		local id = tonumber(param)
		if not id then
			return false, "Usage non valide, voir /help recursive_remove_areas"
		end

		if not areas:isAreaOwner(id, name) then
			return false, "Zone "..id.." n'existe pas ou vous n'êtes pas propriétaire."
		end

		areas:remove(id, true)
		areas:save()
		return true, "Zone supprimée "..id.." ainsi que ses sous-zones."
	end
})


minetest.register_chatcommand("remove_area", {
	params = "<id>",
	description = "Supprime une zone identifiée par id",
	func = function(name, param)
		local id = tonumber(param)
		if not id then
			return false, "Usage non valide, voir /help remove_area"
		end

		if not areas:isAreaOwner(id, name) then
			return false, "Zone "..id.." n'existe pas ou vous n'êtes pas propriétaire."
		end

		areas:remove(id)
		areas:save()
		return true, "Zone supprimée : "..id
	end
})


minetest.register_chatcommand("change_owner", {
	params = "<ID> <NouveauProprio>",
	description = "Change le propriétaire d'une zone en utilisant son id",
	func = function(name, param)
		local id, newOwner = param:match("^(%d+)%s(%S+)$")
		if not id then
			return false, "Usage non valide, voir /help change_owner."
		end

		if not areas:player_exists(newOwner) then
			return false, "Le joueur \""..newOwner.."\" n'existe pas."
		end

		id = tonumber(id)
		if not areas:isAreaOwner(id, name) then
			return false, "La zone "..id.." n'existe pas ou vous n'êtes pas propriétaire."
		end
		areas.areas[id].owner = newOwner
		areas:save()
		minetest.chat_send_player(newOwner,
			("%s vous a donné le contrôle sur la zone %q (ID %d).")
				:format(name, areas.areas[id].name, id))
		return true, "Owner changed."
	end
})


minetest.register_chatcommand("area_open", {
	params = "<ID>",
	description = "Bascule une zone entre ouverte (tout le monde peut modifier) ou fermée",
	func = function(name, param)
		local id = tonumber(param)
		if not id then
			return false, "Usage invalide, voir /help area_open."
		end

		if not areas:isAreaOwner(id, name) then
			return false, "La zone "..id.." n'existe pas ou vous n'êtes pas propriétaire."
		end
		local open = not areas.areas[id].open
		-- Save false as nil to avoid inflating the DB.
		areas.areas[id].open = open or nil
		areas:save()
		return true, ("Zone %s."):format(open and "ouverte" or "fermée")
	end
})


minetest.register_chatcommand("move_area", {
	params = "<ID>",
	description = "Bouge (ou redimensionne) une zone aux positions courante.",
	privs = areas.adminPrivs,
	func = function(name, param)
		local id = tonumber(param)
		if not id then
			return false, "Usage non valide, voir /help move_area."
		end

		local area = areas.areas[id]
		if not area then
			return false, "La zone n'existe pas."
		end

		local pos1, pos2 = areas:getPos(name)
		if not pos1 then
			return false, "Vous devez d'abord définir une zone."
		end

		areas:move(id, area, pos1, pos2)
		areas:save()

		return true, "La zone a été bougé avec succès."
	end,
})


minetest.register_chatcommand("area_info", {
	description = "Retourne des informations sur l'utilisation et la configuration de area.",
	func = function(name, param)
		local lines = {}
		local privs = minetest.get_player_privs(name)

		-- Short (and fast to access) names
		local cfg = areas.config
		local self_prot  = cfg.self_protection
		local prot_priv  = cfg.self_protection_privilege
		local limit      = cfg.self_protection_max_areas
		local limit_high = cfg.self_protection_max_areas_high
		local size_limit = cfg.self_protection_max_size
		local size_limit_high = cfg.self_protection_max_size_high

		local has_high_limit = privs.areas_high_limit
		local has_prot_priv = not prot_priv or privs[prot_priv]
		local can_prot = privs.areas or (self_prot and has_prot_priv)
		local max_count = can_prot and
			(has_high_limit and limit_high or limit) or 0
		local max_size = has_high_limit and
			size_limit_high or size_limit

		-- Privilege information
		local self_prot_line = ("L'auto-protection est %sactivée"):format(self_prot and "" or "dés")
		if self_prot and prot_priv then
			self_prot_line = self_prot_line..(" %s avez le privilège nécessaire (%q)."):format(has_prot_priv and "et vous" or "mais vous n'", prot_priv)
		else
			self_prot_line = self_prot_line.."."
		end
		table.insert(lines, self_prot_line)
		if privs.areas then
			table.insert(lines, "Vous êtes administrateur area (\"areas\" privilege).")
		elseif has_high_limit then
			table.insert(lines,
				"Vous avez une zone de protection étendue"..
				" (\"areas_high_limit\" privilege).")
		end

		-- Area count
		local area_num = 0
		for id, area in pairs(areas.areas) do
			if area.owner == name then
				area_num = area_num + 1
			end
		end
		local count_line = ("Vous avez %d zone%s"):format(
			area_num, area_num == 1 and "" or "s")
		if privs.areas then
			count_line = count_line..
				" et aucune limite de protection de zone."
		elseif can_prot then
			count_line = count_line..(", sur un maximum de %d.")
				:format(max_count)
		end
		table.insert(lines, count_line)

		-- Area size limits
		local function size_info(str, size)
			table.insert(lines, ("%s couvre jusqu'à %dx%dx%d.")
				:format(str, size.x, size.y, size.z))
		end
		local function priv_limit_info(priv, max_count, max_size)
			size_info(("Les joueurs avec le privilège %q peuvent protéger jusqu'à %d zones"):format(priv, max_count), max_size)
		end
		if self_prot then
			if privs.areas then
				priv_limit_info(prot_priv,
					limit, size_limit)
				priv_limit_info("areas_high_limit",
					limit_high, size_limit_high)
			elseif has_prot_priv then
				size_info("Vous pouvez protéger des zones", max_size)
			end
		end

		return true, table.concat(lines, "\n")
	end,
})

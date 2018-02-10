pvpzone.hud = {}
pvpzone.timer = 0
pvpzone.color_alert = "0xFF0000"
pvpzone.color_normal = "0xFFFFFF"
pvpzone.text_safe = "PvP Safe"

pvpzone.hud_texte = {hud_elem_type="text",number="0xFF00000",position={x=1,y=1},offset={x=-8,y=-8},text="Zone PvP!",alignment={x=-1,y=-1},scale={x=100,y=100}}
pvpzone.hud_image = {hud_elem_type = "image", position = {x=0.5,y=0.25}, scale = {x=1,y=1}, text = "pvpzone_alert.png", alignment = {x=0,y=0}, offset = {x=0,y=0}}

function pvpzone.update_hud(player)
	local name = player:get_player_name()
	pvpzone.hud[name] = {}
	pvpzone.hud[name].texte = player:hud_add(pvpzone.hud_texte)
	pvpzone.hud[name].last = pvpzone.text_safe
end

function pvpzone.delete_alert(name)
	local player = minetest.get_player_by_name(name)
	player:hud_remove(pvpzone.hud[name].image)
end

minetest.register_globalstep(function(dtime)
	pvpzone.timer = pvpzone.timer + dtime
	if pvpzone.timer<=1 then return end
	for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local pos = vector.round(player:getpos())
		local couleur = pvpzone.color_normal
		local texte = pvpzone.text_safe
		
		for k, v in pairs(pvpzone_store:get_areas_for_pos(pos, true, true)) do
			if k then
				texte = "PvP : "..v.data
				couleur = pvpzone.color_alert
				break
			end
		end
		if texte~=pvpzone.hud[name].last and texte~=pvpzone.text_safe then
			player:hud_remove(pvpzone.hud[name].image)
			pvpzone.hud[name].image = player:hud_add(pvpzone.hud_image)
			minetest.after(2,pvpzone.delete_alert,name)
		end
		pvpzone.hud[name].last = texte
		player:hud_change(pvpzone.hud[name].texte,"text",texte)
		player:hud_change(pvpzone.hud[name].texte,"number",couleur)
	end
	pvpzone.timer = 0
end)


minetest.register_on_joinplayer(pvpzone.update_hud)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	pvpzone.hud[name] = nil
end)

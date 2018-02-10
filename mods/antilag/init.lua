antilag = {}

function antilag.rollback(player)
  player.player:setpos(player.playerpos)
end

minetest.register_on_protection_violation(function(pos,name)
  local player = minetest.get_player_by_name(name)
  local playerpos = player:getpos()
  if areas and not areas:canInteract(pos,name) or not default.can_interact_with_node(player,pos) then
    minetest.after(1,antilag.rollback,{player=player,playerpos=playerpos})
  end
end)

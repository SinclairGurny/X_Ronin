-- Helpers.lua
-- Contains helper functions for game


local M = {}

--=========================================================================
--======================= Small Helpers ===================================
--=========================================================================

function M.arrayPrint( tbl )
   for i, val in ipairs(tbl) do
      print( val[1], val[2] )
   end
end

function M.displayCoord( in_x, in_y )
   local xx  = gui.startpt.x + gui.tilesize * (in_x - world.renderpt.x)
   local yy  = gui.startpt.y + gui.tilesize * (in_y - world.renderpt.y)
   return xx, yy
end

function M.onBoard( in_x, in_y )
   if (in_x >= 1 and in_x <= gui.bsize.x) and
      (in_y >= 1 and in_y <= gui.bsize.y)
   then return true else return false end
end

function M.onScreen( in_x, in_y )
   if (in_x >= world.renderpt.x and in_x < world.renderpt.x + gui.size.x) and
      (in_y >= world.renderpt.y and in_y < world.renderpt.y + gui.size.y)
   then return true else return false end
end

function M.findEnemy( in_x, in_y )
   for i, e in ipairs(enemies) do
      if (e.x == in_x and e.y == in_y) then
	 return i
      end
   end
   return nil
end

function M.isOpen( in_x, in_y, e_idx )
   local fe = M.findEnemy( in_x, in_y )
   if (fe == nil or fe == e_idx) and
      (in_x ~= player.x or in_y ~= player.y)
   then return true else return false end
end

function M.isMoreOpen( in_x, in_y, e_idx )
   if M.onBoard(in_x,in_y) and board[in_y][in_x].mode == 0 and
      M.isOpen(in_x,in_y,e_idx)
   then return true else return false end
end

--=============================================================================
--=================== Larger Helpers ==========================================
--=============================================================================

function M.updateRenderPt()
   local deltax = player.x - world.renderpt.x
   local deltay = player.y - world.renderpt.y
   local midx, midy = gui.size.x/2, gui.size.y/2
   if deltax < math.floor(midx-0.5) then world.renderpt.x = player.x - math.floor(midx-0.5)
   elseif deltax >= math.ceil(midx-0.5) then world.renderpt.x = player.x - math.floor(midx)  end
   if deltay < math.floor(midy-0.5) then world.renderpt.y = player.y - math.floor(midy-0.5)
   elseif deltay >= math.ceil(midy-0.5) then world.renderpt.y = player.y - math.floor(midy) end
end

function M.clickedOnThis( loc )
   -- Cells
   if (loc.x > gui.startpt.x and loc.x < gui.startpt.x + gui.size.x*gui.tilesize) and
   (loc.y > gui.startpt.y and loc.y < gui.startpt.y + gui.size.y*gui.tilesize) then
      local px, py = loc.x - gui.startpt.x, loc.y - gui.startpt.y
      px = math.ceil(px/gui.tilesize) + world.renderpt.x - 1
      py = math.ceil(py/gui.tilesize) + world.renderpt.y - 1
      if M.onBoard(px,py) then
	 return {obj='cell', x=px, y=py}
      else
	 return nil
      end
   end
   -- GUI
   local ans = nil
   local vec = { gui.mov_bt, gui.jmp_bt, gui.pnch_bt, gui.sla_bt, gui.sht_bt,
		 gui.ovw_bt, gui.def_bt, gui.can_bt }
   local vec_obj = { 'mov', 'jmp', 'pnch', 'sla', 'sht', 'ovw', 'def', 'can' }
   for i, b in ipairs( vec ) do
      if (loc.x > b.x and loc.x < b.x + b.w) and
      (loc.y > b.y and loc.y < b.y + b.h) then
	 return {obj=vec_obj[i]}
      end
   end
end

-- Highlight

function M.highlight( px, py, delta, isE )
   local op = function (X) if isE then return X == nil else return X ~= nil end end
   for dy = -delta, delta do
      for dx = -delta, delta do
	 if M.onBoard( px+dx, py+dy ) then
	    if px+dx == px and py+dy == py then goto h_cont end
	    if board[py+dy][px+dx].mode > 0 then goto h_cont end
	    if op( M.findEnemy(px+dx,py+dy) ) then goto h_cont end
	    board[py+dy][px+dx].selected = true
	    ::h_cont::
	 end
      end
   end
end

function M.unhighlight( px, py, delta )
   for dy = -delta, delta do
      for dx = -delta, delta do
	 if M.onBoard( px+dx, py+dy ) then
	    board[py+dy][px+dx].selected = false
	 end
      end
   end
end

--=================================================================================
--======================= Player and Enemy Functions ==============================
--=================================================================================

function M.activate( in_mode )
   if world.mode ~= nil then M.cancel() end
   if in_mode == 'move' then
      if player.ap > 0 then
	 world.mode = 'move'
	 -- delta 1, open only
	 M.highlight( player.x, player.y, 1, false )
      end
   elseif in_mode == 'jump' then
      if player.ap > 1 then
	 world.mode = 'jump'
	 M.highlight( player.x, player.y, 3, false )
	 M.unhighlight( player.x, player.y, 2 )
      end
   elseif in_mode == 'punch' then
      if player.ap > 0 then
	 world.mode = 'punch'
	 -- delta 1, enemies only
	 M.highlight( player.x, player.y, 1, true )
      end
   elseif in_mode == 'slash' then
      if player.ap > 1 then
	 world.mode = 'slash'
	 -- delta 1, enemies only
	 local px,py = player.x, player.y
	 for dy = -2, 2 do
	    for dx = -2, 2 do
	       if M.onBoard( px+dx, py+dy ) and (math.abs(dx) == 2 or math.abs(dy) == 2)
		  and board[py+dy][px+dx].mode == 0 and M.findEnemy(px+dx,py+dy) == nil
		  and M.findEnemy(px+(dx/2), py+(dy/2))
	       then
		  board[py+dy][px+dx].selected = true
	       end
	    end
	 end
      end
   elseif in_mode == 'shoot' then
      if player.ap > 0 then
	 world.mode = 'shoot'
	 -- delta 2, enemies only
	 M.highlight( player.x, player.y, 2, true )
      end
   elseif in_mode == 'overwatch' then
      print('OVERWATCH1')
      if world.mode ~= nil then M.cancel() end
      print('OVERWATCH2')
      if player.ap > 0 and player.ovw == false then
	 print('OVERWATCH3')
	 player.ovw = true
	 player.ap = player.ap - 1
      end
   elseif in_mode == 'defense' then
      if player.ap > 0 and player.def == 0 then
	 print('DEFENSE')
	 player.def = 2
	 player.ap = player.ap - 1
      end
   elseif in_mode == 'cancel' then
      M.cancel()
      world.mode = 'skip'
   end
end

function M.cancel()
   if world.mode == nil then
      -- do nothing
   elseif world.mode == 'move' then
      M.unhighlight( player.x, player.y, 1 )
      world.mode = nil
   elseif world.mode == 'jump' then
      M.unhighlight( player.x, player.y, 3 )
      world.mode = nil
   elseif world.mode == 'punch' then
      M.unhighlight( player.x, player.y, 1 )
      world.mode = nil
   elseif world.mode == 'slash' then
      M.unhighlight( player.x, player.y, 3 )
      world.mode = nil
   elseif world.mode == 'shoot' then
      M.unhighlight( player.x, player.y, 2 )
      world.mode = nil
   end
end

-- Player Functions --------------------------------------------

function M.movement( mv_mode, nx, ny )
   if mv_mode == 'move' then
      M.unhighlight( player.x, player.y, 1 )
      player.x, player.y = nx, ny
      player.ap = player.ap - 1
      M.updateRenderPt()
      world.mode = nil
   elseif mv_mode == 'jump' then
      print('movement')
      M.unhighlight( player.x, player.y, 3 )
      player.x, player.y = nx, ny
      player.ap = player.ap - 2
      M.updateRenderPt()
      world.mode = nil
   end
end

function M.enemyAttack( e_idx, dmg )
   print('ENEMY ATTACK')
   if enemies[e_idx].cbuff then
      if enemies[e_idx].bhp > 0 then
	 if dmg >= 1 then
	    print('damage buffed')
	    enemies[e_idx].bhp = 0
	    enemies[e_idx].hp = enemies[e_idx].hp - (dmg - 1)
	    return
	 else
	    print('took off shield')
	    enemies[e_idx].bhp = 0
	    return
	 end
      end
   end
   print('normal damage')
   enemies[e_idx].hp = enemies[e_idx].hp - dmg
end

function M.attack( atk_mode, in_x, in_y )
   if atk_mode == 'punch' then
      local dx, dy = in_x - player.x, in_y - player.y
      local e_idx = M.findEnemy( in_x, in_y )
      
      --enemies[e_idx].hp = enemies[e_idx].hp - 1
      M.enemyAttack( e_idx, 1 )
      
      print("punch", dx, dy )
      local txx,tyy = player.x+(dx*2), player.y+(dy*2)
      if M.onBoard(txx, tyy) and board[tyy][txx].mode == 0 and
	 M.findEnemy(txx, tyy) == nil
      then
	 enemies[e_idx].x = player.x+(dx*2)
	 enemies[e_idx].y = player.y+(dy*2)
      else
	 --enemies[e_idx].hp = enemies[e_idx].hp - 1
	 M.enemyAttack( e_idx, 1 )
      end
      if enemies[e_idx].hp <= 0 then
	 table.remove( enemies, e_idx )
      end
      M.unhighlight( player.x, player.y, 2 )
      player.ap = player.ap - 1
      world.mode = nil
   elseif atk_mode == 'slash' then
      local dx, dy = in_x - player.x, in_y - player.y
      local e_idx = M.findEnemy( player.x+(dx/2), player.y+(dy/2) )
      --enemies[e_idx].hp = enemies[e_idx].hp - 3
      M.enemyAttack( e_idx, 3 )
      
      if enemies[e_idx].hp <= 0 then
	 table.remove( enemies, e_idx )
      end
      M.unhighlight( player.x, player.y, 3 )
      player.x, player.y = player.x+dx, player.y+dy
      player.ap = player.ap - 2
      M.updateRenderPt()
      world.mode = nil
   elseif atk_mode == 'shoot' then
      local e_idx = M.findEnemy( in_x, in_y )
      if e_idx ~= nil then
	 --enemies[e_idx].hp = enemies[e_idx].hp - 1
	 M.enemyAttack( e_idx, 1 )
	 if enemies[e_idx].hp <= 0 then
	    table.remove( enemies, e_idx )
	 end
	 M.unhighlight( player.x, player.y, 2 )
	 player.ap = player.ap - 1
	 world.mode = nil
      end
   end
end

-- export namespace
return M

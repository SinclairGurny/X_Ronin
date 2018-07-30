-- Enemy_ai.lua
-- Contains pathfinding

local N = {}

local H = require 'helpers'

--===================================================================
--===================== Small Helpers ===============================
--===================================================================

function N.tblEq( t1, t2 )
   if type(t1) ~= 'table' or type(t2) ~= 'table' then
      return t1 == t2 end
   
   if #t1 == #t2 then
      for i = 1,#t1 do
	 if not N.tblEq(t1[i], t2[i]) then
	    return false
	 end
      end
      return true
   end
   return false
end

function N.inTable( tbl, item )
   for key, value in pairs(tbl) do
      if N.tblEq( value, item ) then return key end
   end
   return false
end

function N.deepCopy( tbl )
   if type(tbl) ~= 'table' then
      return tbl end
   local ret = {}
   for i=1,#tbl do
      table.insert( ret, tbl[i] )
   end
   return ret
end

function N.splitEnemies( ae )
   local sret, oret = {}, {}
   for i, e_num in ipairs( ae ) do
      if enemies[e_num].var == 4 then -- shards
	 table.insert( sret, e_num )
      else -- other
	 table.insert( oret, e_num )
      end
   end
   return sret, oret
end
			 

--===================================================================
--===================== Pathfinding = ===============================
--===================================================================

-- TODO - replace with A*
function N.bfs( in_x, in_y, goal_x, goal_y )
   visited = {}
   Queue = {}
   table.insert( visited, {in_x, in_y} )
   table.insert( Queue, {{in_x,in_y}, {}})
   while #Queue > 0 do
      local val = table.remove( Queue, 1 )
      local v_x, v_y, v_path = val[1][1], val[1][2], N.deepCopy(val[2])
      table.insert( v_path, {v_x,v_y} )

      if v_x == goal_x and v_y == goal_y then
	 return v_path
      end
      
      for dy=-1,1 do
	 for dx=-1,1 do
	    local xx, yy = v_x+dx, v_y+dy
	    -- fix
	    if H.onBoard(xx, yy) and (not N.inTable(visited, {xx,yy})) and
	       (xx ~= v_x or yy ~= v_y) and
	       board[yy][xx].mode == 0 and
	       H.findEnemy( xx, yy ) == nil
	    then
	       table.insert( visited, {xx,yy})
	       table.insert( Queue, {{xx,yy}, v_path} )
	    end
	 end
      end
   end
   return nil
end

--===================================================================
--===================== Enemy AI ====================================
--===================================================================

-- Spawning ---------------------------------------------------------

function N.pickType()
   local p = { 33, 22, 33, 12 }
   local n = love.math.random(100)
   if (n <= p[1]) then return 1
   elseif ((n - p[1]) <= p[2]) then return 2
   elseif ((n - p[1] - p[2]) <= p[3]) then return 3
   else return 4 end
end


function N.enemyType( t )
   if t == 1 then -- Crawlers
      return { hp=3, dmg=1, img=enemyImg[t+2], x=-1, y=-1, var=1, cbuff=false, bbf=false, bhp=0 }
   elseif t == 2 then -- Heavy
      return { hp=4, dmg=1, img=enemyImg[t+2], x=-1, y=-1, var=2, cbuff=false, bbf=false, bhp=0 }
   elseif t == 3 then -- Ranger
      return { hp=2, dmg=1, img=enemyImg[t+2], x=-1, y=-1, var=3, cbuff=false, bbf=false, bhp=0 }
   elseif t == 4 then -- Shard
      return { hp=1, dmg=0, img=enemyImg[t+2], x=-1, y=-1, var=4, cbuff=false, bbf=false, bhp=0 }
   end
end


function N.spawnEnemies( num )
   for n = 1, num do
      ::spawn_e_start::
      local tx, ty = love.math.random(gui.bsize.x), love.math.random(gui.bsize.y)
      local squad_size = love.math.random(2)+1
      if board[ty][tx].mode ~= 0 or (tx == player.x and ty == player.y) or
	 (tx >= gui.bsize.x - 1 or ty >= gui.bsize.y - 1)
      then goto spawn_e_start end
      print("SPAWNING SQUAD", tx, ty, squad_size)
      for edx = 0, squad_size do
	 for edy = 0, squad_size do
	    if H.isMoreOpen(tx+edx, ty+edy,nil) then
	       local spawn_chance = love.math.random(100) -- 75%
	       if spawn_chance <= 80 then
		  local new_enemy = N.enemyType( N.pickType() )
		  new_enemy.x, new_enemy.y = tx+edx, ty+edy
		  table.insert( enemies, new_enemy )
	       end
	    end
	 end
      end
   end
end


-- Attacking functions -----------------------------------------------------

function N.checkCharge( in_x, in_y, e_idx )
   local fe = H.findEnemy(in_x,in_y)
   if not (H.onBoard(in_x,in_y) and board[in_y][in_x].mode == 0 and 
	   (fe == nil or fe == e_idx)) then
      return nil end
   local mvs = {{-1,-1},{0,-1},{1,-1}, {-1,0},{0,0},{1,0}, {-1,1},{0,1},{1,1}}
   for i, m in ipairs(mvs) do
      local mx, my = m[1], m[2]
      local nx, ny = mx*2, my*2
      if H.isMoreOpen(in_x+mx, in_y+my, e_idx) and H.onBoard( in_x+nx, in_y+ny ) and
	 (in_x+nx==player.x and in_y+ny==player.y)
      then
	 --print( 'charge from ', in_x, in_y, ' in dir: ', mx, my )
	 return {mx,my}
      end
   end
   return nil
end

function N.checkLinedUp( in_x, in_y, e_idx )
   -- shoot over cover? no
   local mvs = {{0,-1},{-1,0},{1,0},{0,1}}
   for i, m in ipairs(mvs) do
      for d = 1, 3 do
	 local nx, ny = in_x + (d*m[1]), in_y + (d*m[2])
	 if H.onBoard(nx,ny) and board[ny][nx].mode ~= 0 then break end
	 if nx == player.x and ny == player.y then
	    return m
	 end
      end
   end
   return nil
end
     

function N.attackPlayer( atk_dmg, buf )
   local ad = atk_dmg
   if buf then ad = ad + 1 end
   if player.def > 0 then
      if player.def >= ad then
	 player.def = player.def - ad
      else
	 player.hp = player.hp + player.def - atk_dmg
	 player.def = 0
      end
   else
      player.hp = player.hp - atk_dmg
   end
end

function N.applyStatBuff( shards, others )
   --if shards == nil or others == nil then return 
   for i, e_num in ipairs( others ) do
      local e = enemies[e_num]
      local buff = false
      for j, s_num in ipairs( shards ) do
	 local s = enemies[s_num]
	 local dx, dy = e.x - s.x, e.y - s.y
	 if (math.abs(dx) + math.abs(dy)) <=3 then
	    buff = true
	 end
      end
      
      if buff == true then
	 print('buffing ', enemies[e_num].var, enemies[e_num].x, enemies[e_num].y )
	 enemies[e_num].cbuff = true
	 if enemies[e_num].bbf == false then
	    enemies[e_num].bhp = 1
	 end
	 enemies[e_num].bbf = true
      else
	 enemies[e_num].cbuff = false
      end
   end
end

-- Enemy movement ------------------------------------------------------------

function N.findActiveEnemies()
   local ret = {}
   local dist = math.ceil( gui.size.y/2 )+1
   for i, e in ipairs( enemies ) do
      local dxx, dyy = player.x - e.x, player.y - e.y
      if (math.abs(dxx) + math.abs(dyy)) <= dist then
	 table.insert( ret, i )
      end
   end
   return ret
end


function N.randMove( in_x, in_y, e_idx )
   local count = 0
   ::rand_move::
   local dx,dy = love.math.random(3)-2, love.math.random(3)-2
   local nx,ny = in_x+dx, in_y+dy
   if H.isMoreOpen( nx, ny, e_idx ) then
      return {nx,ny}
   else
      if count > 4 then return {in_x,in_y} end
      goto rand_move
   end
end
   


function N.moveEnemies()
   active_enemies_idx = N.findActiveEnemies()
   if active_enemies_idx == nil then return end
   print('--actually working======================', #active_enemies_idx)
   print('player', player.x, player.y )
   local shards, other_e = N.splitEnemies( active_enemies_idx )
   print( 'split ', #shards, #other_e )
   N.applyStatBuff( shards, other_e )
   
   for i, e_idx in ipairs( active_enemies_idx ) do
      local e = enemies[e_idx]
      if e.var == 1 then -- Crawlers
	 print('--moving crawler--')
	 local c_path = N.bfs( e.x, e.y, player.x, player.y )
	 if c_path ~= nil then
	    if #c_path <= 2 then
	       N.attackPlayer( e.dmg, e.buffed )
	    else
	       enemies[e_idx].x = c_path[2][1]
	       enemies[e_idx].y = c_path[2][2]
	    end
	 end
      elseif e.var == 2 then -- Heavy
	 print('--moving heavy--', e.x, e.y)
	 local mvs = {{-1,-1},{0,-1},{1,-1}, {-1,0},{0,0},{1,0}, {-1,1},{0,1},{1,1}}
	 local chosen_mv = nil
	 for i, m in ipairs(mvs) do
	    local charge_dir = N.checkCharge( e.x+m[1], e.y+m[2], e_idx )
	    if charge_dir ~= nil then
	       chosen_mv = {m, charge_dir}
	       goto hvy_pick_move
	    end
	 end
	 ::hvy_pick_move::
	 if chosen_mv == nil then
	    print('no charge, no move')
	    local hv_mv = N.randMove( e.x, e.y, e_idx )
	    enemies[e_idx].x, enemies[e_idx].y = hv_mv[1], hv_mv[2]
	 elseif chosen_mv[1][1] ~= 0 or chosen_mv[1][2] ~= 0 then
	    print('move to charge position')
	    enemies[e_idx].x = e.x+chosen_mv[1][1]
	    enemies[e_idx].y = e.y+chosen_mv[1][2]
	 else
	    local kb1 = {player.x+chosen_mv[2][1], player.y+chosen_mv[2][2]}
	    local kb2 = {player.x+(2*chosen_mv[2][1]), player.y+(2*chosen_mv[2][2])}
	    print('kb1', kb1[1], kb1[2] )
	    print('kb2', kb2[1], kb2[2] )
	    if H.isMoreOpen( kb1[1], kb1[2], nil ) then
	       -- Knockback 2
	       if H.isMoreOpen(kb2[1], kb2[2], e_idx ) then
		  -- Knockback 2
		  print('two knockback')
		  enemies[e_idx].x = player.x
		  enemies[e_idx].y = player.y
		  player.x, player.y = kb2[1], kb2[2]
		  N.attackPlayer( e.dmg, e.buffed )
	       else
		  -- Knockback 1
		  print('one knockback')
		  enemies[e_idx].x = player.x
		  enemies[e_idx].y = player.y
		  player.x, player.y = kb1[1], kb1[2]
		  N.attackPlayer( e.dmg+1, e.buffed )
	       end
	    else
	       -- Knockback 0
	       print('no knockback')
	       enemies[e_idx].x = e.x+chosen_mv[2][1]
	       enemies[e_idx].y = e.y+chosen_mv[2][2]
	       N.attackPlayer( e.dmg+1, e.buffed )
	    end
	 end
      elseif e.var == 3 then -- Ranger
	 print('--moving ranger--')
	 local mvs = {{-1,-1},{0,-1},{1,-1}, {-1,0},{0,0},{1,0}, {-1,1},{0,1},{1,1}}
	 local open_moves = {}
	 local best_move, canShoot = nil, false
	 for i, m in ipairs(mvs) do
	    local rx, ry = e.x+m[1], e.y+m[2]
	    if H.isMoreOpen( rx, ry , e_idx ) then
	       table.insert( open_moves, m )
	       local ret = N.checkLinedUp( rx, ry, e_idx )
	       if ret ~= nil  then
		  best_move = m
		  print('can move into shot')
		  if m[1] == 0 and m[2] == 0 then
		     canShoot = true
		     print('canshoot')
		     goto rng_choose_move
		  end
	       end
	    end
	 end
	 ::rng_choose_move::
	 if best_move ~= nil then
	    enemies[e_idx].x, enemies[e_idx].y = e.x+best_move[1], e.y+best_move[2]
	    if canShoot then N.attackPlayer( e.dmg, e.buffed ) end
	 elseif #open_moves > 0 then
	    local n = math.random(#open_moves)
	    enemies[e_idx].x, enemies[e_idx].y = e.x+open_moves[n][1], e.y+open_moves[n][2]
	 end
      elseif e.var == 4 then -- Shard
	 print('--moving shard--')
	 local sh_mv = N.randMove( e.x, e.y, e_idx )
	 enemies[e_idx].x, enemies[e_idx].y = sh_mv[1], sh_mv[2]
      end
   end
end

-- Crawlers -- move and melee
-- Heavy -- line up and charge
-- Ranger -- line up and shoot
-- Stat Buff -- random

-- export namespace
return N

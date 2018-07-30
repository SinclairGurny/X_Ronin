-- Turn Based Strategy Game

local helper = require 'helpers'
local e_ai = require 'enemy_ai'
local ll = require 'levels'

-- VARIABLES

-- Mouse
clickedLoc = nil
clickedObj = nil

-- Game
gui = {
   -- used for static values
   startpt = { x=0, y=0 },
   size = { x=9, y=9 },
   bsize = { x=40, y=40 },
   tilesize = 80,
   bg = nil, bg1=nil, bgQ = nil,
   tile = {norm=nil, high=nil},
   hp=nil,
   ap=nil,
   dp=nil,
   mov_bt = {img=nil, x=20,  y=112, w=80, h=80},
   jmp_bt = {img=nil, x=104, y=112, w=80, h=80},
   pnch_bt ={img=nil, x=192, y=112, w=80, h=80},
   sla_bt = {img=nil, x=276, y=112, w=80, h=80},
   sht_bt = {img=nil, x=360, y=112, w=80, h=80},
   ovw_bt = {img=nil, x=448, y=112, w=80, h=80},
   def_bt = {img=nil, x=532, y=112, w=80, h=80},
   can_bt = {img=nil, x=620, y=112, w=80, h=80},
   e_act_snd = nil,
   act_snd = nil,
   font = nil
}

world = {
   -- global variables
   mode = nil,
   renderpt = {x=0, y=0},
   timer1 = 0
}
   
board = {} -- each cell has mode and objs

consts = { max_hp = 6, max_ap = 2, e_wait=1.2 }

player = {
   x = nil,
   y = nil,
   hp = consts.max_hp,
   ap = consts.max_ap,
   def = 0,
   ovw = false,
   img = nil
}

active_enemies = {}
enemies = {}
enemyImg = {}


--======================================================================

-- LOVE main
function love.load( arg )
   love.math.setRandomSeed( os.time() )
   
   -- Setup
   love.graphics.setBackgroundColor( 0.2, 0.2, 0.2 )

   -- load images
   -- background
   gui.bg = love.graphics.newImage('assets/bg.png')
   gui.bg1 = love.graphics.newImage('assets/frame_long.png')
   -- text
   
   -- tiles
   gui.tile.norm = love.graphics.newImage('assets/tilv4.png')
   gui.tile.high = love.graphics.newImage('assets/highlight.png')
   gui.tile.wood = love.graphics.newImage('assets/block.png')
   gui.tile.wall = love.graphics.newImage('assets/wall.png')
   gui.tile.goal = love.graphics.newImage('assets/Goal.png')
   -- player stats
   gui.hp = love.graphics.newImage('assets/hp3.png')
   gui.ap = love.graphics.newImage('assets/ap3.png')
   gui.dp = love.graphics.newImage('assets/def_pt.png')
   -- buttons
   gui.mov_bt.img = love.graphics.newImage('assets/move2.png')
   gui.jmp_bt.img = love.graphics.newImage('assets/jump.png')
   gui.pnch_bt.img = love.graphics.newImage('assets/punch.png')
   gui.sla_bt.img = love.graphics.newImage('assets/slash.png')
   gui.sht_bt.img = love.graphics.newImage('assets/shoot.png')
   
   gui.ovw_bt.img = love.graphics.newImage('assets/overwatch.png')
   gui.def_bt.img = love.graphics.newImage('assets/defense2.png')

   gui.can_bt.img = love.graphics.newImage('assets/cancel.png')
   -- player / enemies
   player.img = love.graphics.newImage('assets/playerv2lg.png')
   player.dead = love.graphics.newImage('assets/skull.png')
   
   table.insert( enemyImg, love.graphics.newImage('assets/e_hp.png') )
   table.insert( enemyImg, love.graphics.newImage('assets/buff_ehp.png') )
   table.insert( enemyImg, love.graphics.newImage('assets/new_crawler2.png') )
   table.insert( enemyImg, love.graphics.newImage('assets/heavy.png') )
   table.insert( enemyImg, love.graphics.newImage('assets/ranger.png') )
   table.insert( enemyImg, love.graphics.newImage('assets/shard.png') )
   
   -- sounds
   gui.e_act_snd = love.audio.newSource('assets/enemy_activity2.ogg','stream' )
   gui.act_snd = love.audio.newSource('assets/click3.ogg','static' )

   -- font
   gui.font = love.graphics.newFont(20)
   love.graphics.setFont(gui.font)

   -- setup background
   gui.bg:setWrap('repeat','repeat')
   gui.bgQ = love.graphics.newQuad( 0,0, love.graphics:getWidth(), love.graphics:getHeight(),
				    gui.bg:getDimensions() )
   --------------

   gui.startpt.x = (love.graphics:getWidth() - gui.size.x*gui.tilesize)/2
   gui.startpt.y = 216


   -- read levels
   ll.readLevels()
   
   -- setup
   reset()
   
end

function love.draw( dt )

   -- GUI
   -- Background
   love.graphics.draw( gui.bg, gui.bgQ, 0,0)
   love.graphics.draw( gui.bg1, 0,0)
   love.graphics.draw( gui.bg1, 720, 100, math.pi)
   love.graphics.draw( gui.bg1, 0,100)
   love.graphics.draw( gui.bg1, 720, 200, math.pi)

   -- Text
   displayText()
   
   -- Player Info
   for h = 1,player.hp do -- HP
      love.graphics.draw( gui.hp, 16 + 16*(h-1), 16 )
   end
   for a = 1, player.ap do -- AP
      love.graphics.draw( gui.ap, 16 + 48*(a-1), 60 )
   end
   for d = 1, player.def do -- Defense
      love.graphics.draw( gui.dp, 16 + 16*(player.hp+d-1), 16 )
   end
   -- Buttons
   love.graphics.draw( gui.mov_bt.img, gui.mov_bt.x, gui.mov_bt.y )
   love.graphics.draw( gui.jmp_bt.img, gui.jmp_bt.x, gui.jmp_bt.y )
   love.graphics.draw( gui.pnch_bt.img, gui.pnch_bt.x, gui.pnch_bt.y )
   love.graphics.draw( gui.sla_bt.img, gui.sla_bt.x, gui.sla_bt.y )
   love.graphics.draw( gui.sht_bt.img, gui.sht_bt.x, gui.sht_bt.y )
   love.graphics.draw( gui.ovw_bt.img, gui.ovw_bt.x, gui.ovw_bt.y )
   love.graphics.draw( gui.def_bt.img, gui.def_bt.x, gui.def_bt.y )
   love.graphics.draw( gui.can_bt.img, gui.can_bt.x, gui.can_bt.y )

   -- Board
   for ay = world.renderpt.y, world.renderpt.y+gui.size.y-1 do
      for ax = world.renderpt.x, world.renderpt.x+gui.size.x-1 do
	 if helper.onBoard( ax, ay ) then
	    local xx, yy = helper.displayCoord( ax, ay )
	    if board[ay][ax].mode == 1 then
	       love.graphics.draw( gui.tile.wood, xx, yy )
	    elseif board[ay][ax].mode == 2 then
	       love.graphics.draw( gui.tile.wall, xx, yy )
	    elseif board[ay][ax].mode == -10 then
	       love.graphics.draw( gui.tile.goal, xx, yy )
	    else
	       love.graphics.draw( gui.tile.norm, xx, yy )
	    end
	    if board[ay][ax].selected then
	       love.graphics.setColor( 1, 0.82, 0, 0.5 ) 
	       love.graphics.rectangle( 'fill', xx, yy, 80, 80 )
	       love.graphics.setColor( 1,1,1 ) 
	    end
	    -- fog of war
	    if player.ovw == false and
	       (ax == world.renderpt.x or ay == world.renderpt.y or
		   ax == world.renderpt.x+gui.size.x-1 or
		   ay == world.renderpt.y+gui.size.y-1)
	    then
	       love.graphics.setColor( 0, 0, 0, 0.8 ) 
	       love.graphics.rectangle( 'fill', xx, yy, 80, 80 )
	       love.graphics.setColor( 1,1,1 )
	    end
	 end
      end
   end
	 
   -- Player
   local px, py = helper.displayCoord( player.x, player.y )
   if player.hp > 0 then
      love.graphics.draw( player.img, px, py)
   else
      love.graphics.draw( player.dead, px, py)
   end
   -- Enemies
   for _, en in ipairs(enemies) do
      local ex, ey = helper.displayCoord( en.x, en.y )
      if helper.onScreen( en.x, en.y ) and
	((en.x ~= world.renderpt.x and en.y ~= world.renderpt.y and
	 en.x ~= world.renderpt.x+gui.size.x-1 and
	     en.y ~= world.renderpt.y+gui.size.y-1) or
	       player.ovw == true)
      then
	 love.graphics.draw( en.img, ex, ey)
	 for h = 1, en.hp do
	    love.graphics.draw( enemyImg[1], ex+40 + 9*(h-1), ey+64 )
	 end
	 if en.cbuff and en.bhp > 0 then
	    love.graphics.draw( enemyImg[2], ex+40 + 9*(en.hp), ey+64 )
	 end
      end
   end
   
end


function love.update( dt )
   -- Keyboard
   if love.keyboard.isDown('escape') then
      love.event.push('quit')
   end
   
   -- Mouse 
   -- Convert Location into Obj
   if not (clickedLoc == nil) then
      gui.act_snd:play()
      clickedObj = helper.clickedOnThis(clickedLoc)
      clickedLoc = nil
   end

   -- Process click
   if not (clickedObj == nil) then
      if world.mode == 'gameover' then reset() end
      helper.updateRenderPt()
      if clickedObj.obj == 'cell' then
	 local cx, cy = clickedObj.x, clickedObj.y
	 print('cell', cx, cy )
	 if (world.mode == 'move' or world.mode == 'jump') and
	    board[cy][cx].selected
	 then
	    helper.movement( world.mode, cx, cy )
	    
	 elseif (world.mode == 'punch' or world.mode == 'slash' or
		    world.mode == 'shoot') and board[cy][cx].selected
	 then
	    helper.attack( world.mode, cx, cy )
	 end
      elseif clickedObj.obj == 'mov' then
	 print('move')
	 helper.activate('move')
      elseif clickedObj.obj == 'jmp' then
	 print('jump')
	 helper.activate('jump')
      elseif clickedObj.obj == 'pnch' then
	 print('punch')
	 helper.activate('punch')
      elseif clickedObj.obj == 'sla' then
	 print('slash')
	 helper.activate('slash')
      elseif clickedObj.obj == 'sht' then
	 print('shoot')
	 helper.activate('shoot')
      elseif clickedObj.obj == 'ovw' then
	 print('overwatch')
	 helper.activate('overwatch')
      elseif clickedObj.obj == 'def' then
	 print('defense')
	 helper.activate('defense')
      elseif clickedObj.obj == 'can' then
	 print('cancel')
	 helper.activate('cancel')
      end
      clickedObj = nil
      print('stopping', player.ap, world.mode)
   end

   -- Default action is move
   if world.mode == nil and player.ap > 0 then
      print('default move activate')
      helper.activate( 'move' )
   end

   -- Check for escape
   if board[player.y][player.x].mode == -10 then
      print("Congrats, you escaped!")
      world.mode = 'gameover'
   end

   
   -- Enemy Moves
   if (player.ap == 0 or world.mode == 'skip') and
      world.mode ~= 'enemy_wait'
   then
      print('starting enemy turn')
      world.mode = 'enemy_wait'
      gui.e_act_snd:play()
   end


   -- Enemy Timer
   if world.mode == 'enemy_wait' then
      world.timer1 = world.timer1 + dt
      if world.timer1 >= consts.e_wait then
	 world.timer1 = 0
	 world.mode = 'enemy'
      end
   end
   
   if world.mode == 'enemy' then
      print(#enemies, ' - enemies are moving')
      e_ai.moveEnemies()
      -- Reset to players turn
      world.mode = nil
      player.ap = consts.max_ap
      player.def = 0
      player.ovw = false
   end

   -- End Game Check
   if player.hp == 0 then
      print("You lose!")
      world.mode = 'gameover'
   end
   if #enemies == 0 then
      print("Congratulations, you won!")
      e_ai.spawnEnemies(2)
      print("Do it again!")
   end

end


--==================================================================

function love.mousepressed( px, py, button, istouch )
   if button == 1 then
      clickedLoc = {x=px,y=py}
   end
end


function reset()
   world.mode = nil
   world.timer1 = 0
   
   -- player
   player.x = gui.bsize.x/2 + love.math.random(5)-3
   player.y = gui.bsize.y/2 + love.math.random(5)-3
   player.hp = consts.max_hp
   player.ap = consts.max_ap
   player.def = 0
   player.ovw = false

   helper.updateRenderPt()

   board = {}
   -- setup board
   for i = 1,gui.bsize.y do
      local row = {}
      for j = 1,gui.bsize.x do
	 local m = ( love.math.random(100) <= 10 ) and love.math.random(2) or 0
	 table.insert(row, {mode=m, selected=false, objs={}})
      end
      table.insert(board, row)
   end

   -- place goal
   local g_corner = love.math.random( 4 )
   local gx, gy = 2,2
   if g_corner == 2 then gx,gy = gui.bsize.x-1, 2
   elseif g_corner == 3 then gx,gy = gui.bsize.x-1, gui.bsize.y-1
   elseif g_corner == 4 then gx,gy = 2, gui.bsize.y-1 end
      
   board[gy][gx].mode = -10
   board[player.y][player.x].mode = 0

   -- spawn enemies
   e_ai.spawnEnemies( 6 )
end


function displayText()
   local dP = {150, {8,32,56} }
   local m_x, m_y = love.mouse.getX(), love.mouse.getY()
   local pos = helper.clickedOnThis( {x=m_x,y=m_y} )
   if pos == nil then return end
   
   love.graphics.setColor( 0,0,0,1 )
   if pos.obj == 'cell' then
      local e_num = helper.findEnemy( pos.x, pos.y )
      if e_num ~= nil then
	 if enemies[e_num].var == 1 then
	    love.graphics.print('Crawler:', dP[1], dP[2][1] )
	    love.graphics.print('Rush and attack', dP[1], dP[2][2] )
	    love.graphics.print('3HP, 1 DMG', dP[1], dP[2][3] )
	 elseif enemies[e_num].var == 2 then
	    love.graphics.print('Heavy:', dP[1], dP[2][1] )
	    love.graphics.print('Charge attack, 2 Knockback', dP[1], dP[2][2] )
	    love.graphics.print('4HP, 1 or 2 DMG', dP[1], dP[2][3] )
	 elseif enemies[e_num].var == 3 then
	    love.graphics.print('Ranger:', dP[1], dP[2][1] )
	    love.graphics.print('Ranged attack, 3 block', dP[1], dP[2][2] )
	    love.graphics.print('2HP, 2 DMG', dP[1], dP[2][3] )
	 elseif enemies[e_num].var == 4 then
	    love.graphics.print('Shard:', dP[1], dP[2][1] )
	    love.graphics.print('+1HP and +1 DMG for nearby enemies', dP[1], dP[2][2] )
	    love.graphics.print('3HP', dP[1], dP[2][3] )
	 end
      end
   elseif pos.obj == 'mov' then
      love.graphics.print('MOVE:', dP[1], dP[2][1] )
      love.graphics.print('Moves player one block', dP[1], dP[2][2] )
      love.graphics.print('Uses 1 AP', dP[1], dP[2][3] )
   elseif pos.obj == 'jmp' then
      love.graphics.print('JUMP:', dP[1], dP[2][1] )
      love.graphics.print('Moves player three block', dP[1], dP[2][2] )
      love.graphics.print('Uses 2 AP', dP[1], dP[2][3] )
   elseif pos.obj == 'pnch' then
      love.graphics.print('PUNCH:', dP[1], dP[2][1] )
      love.graphics.print('Punch enemy knocking them back, +1 DMG crushing them', dP[1], dP[2][2] )
      love.graphics.print('Uses 1 AP, 1 or 2 DMG', dP[1], dP[2][3] )
   elseif pos.obj == 'sla' then
      love.graphics.print('SLASH:', dP[1], dP[2][1] )
      love.graphics.print('Slashes enemy, while running past them', dP[1], dP[2][2] )
      love.graphics.print('Uses 2 AP, 3 DMG', dP[1], dP[2][3] )
   elseif pos.obj == 'sht' then
      love.graphics.print('SHOOT:', dP[1], dP[2][1] )
      love.graphics.print('Shoots enemy within 2 Blocks', dP[1], dP[2][2] )
      love.graphics.print('Uses 1 AP, 1 DMG', dP[1], dP[2][3] )
   elseif pos.obj == 'ovw' then
      love.graphics.print('OVERWATCH:', dP[1], dP[2][1] )
      love.graphics.print('Increases vision range until next turn', dP[1], dP[2][2] )
      love.graphics.print('Uses 1 AP', dP[1], dP[2][3] )
   elseif pos.obj == 'def' then
      love.graphics.print('BLOCK:', dP[1], dP[2][1] )
      love.graphics.print('Blocks 2 damage taken before the next turn', dP[1], dP[2][2] )
      love.graphics.print('Uses 1 AP', dP[1], dP[2][3] )
   elseif pos.obj == 'can' then
      love.graphics.print('CANCEL:', dP[1], dP[2][1] )
      love.graphics.print('Ends turn immediately', dP[1], dP[2][2] )
   end
   love.graphics.setColor( 1,1,1 )
end

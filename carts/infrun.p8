pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()
 --only define variables here!
 p = {
    x=15,
    y=15,
    sprite=3
   }
 
 enemies = {}
 powerups = {}
 frame_count = 0
end


function _update60()
 if frame_count % 30 == 0 then
  --make and enemy at the right 
  --and somwhere between top and bottom
  create_enemy()
 end

 move_enemies()
-- move_powerups()

	if btn(⬆️) then
		p.y -= 1
	end
	if btn(⬇️) then
		p.y += 1
	end
 
end

function _draw()
 cls(0)
 
 draw_enemies()
 print(#enemies)
 print(frame_count)
 spr(p.sprite, p.x, p.y)
 frame_count += 1
end
-->8
-- manage enemies and powerups

function move_enemies()
 --other way to iterate through all enemies
 --for i=1,#enemies in enemies do
 --  e = enemies[i]
 --  e.x -= e.speed --only moves left
 --end
  
 -- for e in all(enemies) do
 --   e.x -= e.speed --only moves left
 -- end
 
 foreach(enemies, move_single_enemy)
end


function move_single_enemy(e)
 e.x = flr(e.x - e.speed)
end

function draw_enemies()
 for e in all(enemies) do
  spr(e.sprite, e.x, e.y)  
 end
end

function move_powerups()

end

function create_enemy()
 local enemy = {
  x = 128,
  y = rnd(100)+10,
  speed = 0.65*rnd(3)+0.1,
  sprite = rnd(3)+1
 }
 add(enemies, enemy)
end

function create_powerup()
 local pu = {}
 pu.x = 128
 pu.y = rnd(100)+10
 pu.speed = 5
 pu.sprite = 1
 
 add(powerups, powerup)
end
-->8
function collide(a, b)
	print(a..b)
end

function player_collide_enemies()
 foreach(enemies, player_enemy_collide)
end

function player_enemy_collide(e)
 collide(player, e)
 --if the collision happens,
 --the game state will change here
end
__gfx__
00000000000aa0000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a99a000000000005500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000a9a9900555555055550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000aa9999a05cccccc585dd5c50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000a9aa9aaa0555555085dd5c50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700a0a9a9a05cccccc555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a99a000555555005500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000aaaa000000000005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

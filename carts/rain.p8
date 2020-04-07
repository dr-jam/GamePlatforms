pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

function _init() 
  player = {
    x=20,
    y=20,
    seedmax = 5
  }
  
  seeds = {}
  seedsplanted = 0
  seed_frametime = 0.333
  
  speed=20
  dt=0
  lastframe=t()
end

function _draw()
	cls()
	circ(player.x, player.y, 5, 11)
	draw_seeds()
end

function draw_seeds()
 for i=1,#seeds do
  --circfill(seeds[i].x, seeds[i].y, 3, 4)
  spr(seeds[i].frame, seeds[i].x, seeds[i].y)
 end
end

function _update60()
 dt = t() - lastframe
 lastframe = t()
 
	input() 
	update_seed_growth()
end

function input()
 if(btn(0)) then
  player.x -= speed * dt
 end
 if(btn(1)) then
  player.x += speed * dt
 end
 if(btn(2)) then
  player.y -= speed * dt
 end
 if(btn(3)) then
  player.y += speed * dt
 end

 if(btnp(4)) then
  plantseed()
 end
end

--plant a seed at the location of the player
function plantseed()
  if seedsplanted >= player.seedmax then
    return
  end
  local seed = {
    x=player.x,
    y=player.y,
    frame=1,
    time_planted=t()
   }
  seedsplanted += 1
  --seeds.add(seedsplanted, seed)
  seeds[seedsplanted] = seed
end

function update_seed_growth()

 for i=1,#seeds do
  local stage = flr((t()-seeds[i].time_planted)/seed_frametime)
  if (stage <= 4) then
   seeds[i].frame = 1 + stage
  end
 end
end
__gfx__
00000000000000000000000000000000000bb0000089980000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000440000004400000044000000bb0000009900000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007000044440000444400004b4400004334000043340000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770000044440000444400004b4400004334000bb334b000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000444400004bb40000433400004334000b3333b000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700004444000044440000444400004444000033330000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000440000004400000044000000440000003300000000000000000000000000000000000000000000000000000000000000000000000000000000000

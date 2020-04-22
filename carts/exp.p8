pico-8 cartridge // http://www.pico-8.com
version 19
__lua__
explosions = {}
previous_t = t()
dt = 0
sim_speed = 1
player = {x=63, y=64}
explosion_colors = {5,6,13,8,9,10,12}
logname = "explosion_log"

function _init()
 printh("begin!", logname, true)
end

function _draw()
 printh("update", explosion_log, false)
 cls()
 pset(player.x, player.y, 11)
 foreach(explosions, draw_explosion)
end

function draw_explosion(exp)
 if exp.active then
  circ(exp.x, exp.y, exp.radius, exp.color)
 end
end

function _update()

 dt = t() - previous_t
 dt *= sim_speed
 input()
 foreach(explosions, update_explosion)
 previous_t = t()
end

function input()
 if btnp(4) then
  printh("explosion!", explosion_log)
  make_explosion()
 end
end

function make_explosion()
 local explosion = {
   x=player.x,
   y=player.y,
   age=0,
   radius=1,
   speed=0.5,
   active=true,
   color=5
  }
 add(explosions, explosion)
end

function update_explosion(exp)
 if exp.active then
  exp.radius = flr(exp.age / exp.speed)+1
  exp.color = explosion_colors[exp.radius % #explosion_colors]
  if exp.age >= 5 then
   exp.active = false
  end
 exp.age += dt
 end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

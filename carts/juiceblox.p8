pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
	--juiceblox
--by: josh

--game state
gs = "title"

function _init()
	last_update = time()
	last_draw = time()
	dt = 0
 reset_level()

end

function _update60()
	dt = time() - last_update
	last_update = time()

 if "play" == gs then
  update_play_state()
 elseif "title" == gs then
  update_title_state()
 elseif "juice_bar" then
  update_juice_bar_state()
 end
end

function update_play_state()
 paddle_input() 
 update_balls()
 collisions()

 if btnp(🅾️) then
  gs = "juicebar"
 end
end

function update_title_state()
 if btnp(🅾️) then
  gs = "play"
 end
end

function update_juice_bar_state()
 if btnp(🅾️) then
  gs = "play"
 elseif btnp(❎) then
  gs = "play"
  reset_level()
 end
end

function _draw() 
	dt = time() - last_draw
	last_draw = time()

 if "play" == gs then
  draw_play_state()
 elseif "title" == gs then
  draw_title_state()
 elseif "juice_bar" then
  draw_juice_bar_state()
 end
end

function draw_title_state()
 cls(0)
 print("juiceblox", 50, 60, 9)
end

function draw_play_state()
 cls(0)
 draw_walls()
 draw_paddle()
 draw_balls()
 draw_blocks()

 print(debug)
end

function draw_juice_bar_state()
 cls(0)
 print("🅾️ to resue, ❎ to reset", 8, 120, 7)
end
-->8
--blocks and balls and paddles

--paddle
p = {}
p.x = 64
p.y = 120
p.w = 20
p.h = 4
p.c = 4 
p.acc = 900
p.drag = 180
p.maxv = 90
p.vx = 0
p.vy = 0
p.dx = 0
p.dy = 0

balls = {}


--walls
wc = 8

walls = {}

tw = {}
tw.x = 0
tw.y = 0
tw.w = 128
tw.h = 4

lw = {}
lw.x = 0
lw.y = 0
lw.w = 4
lw.h = 128

rw = {}
rw.x = 124
rw.y = 0
rw.w = 4
rw.h = 128

--blocks
blocks = {}

blocksmt = {} 

function blocksmt.__tostring(b)
 return "[" .. b.x .. ", " .. b.y .. ", " .. b.w .. ", " .. b.h .. "]"
end


hitinfo = {}
hitinfo.hit = false

add(walls, tw)
add(walls, lw)
add(walls, rw)

function reset_level()
 --default level for now
 balls = {}
 blocks = {}
 add_ball()
 make_block_of_blocks(8,12,2,16)
end

function paddle_input()
 if (btn(⬅️)) then
  p.vx -= p.acc * dt
 end

 if (btn(➡️)) then
  p.vx += p.acc * dt
 end

 p.vx = mid(-p.maxv, p.vx, p.maxv)
 p.x += p.vx * dt

 if not (btn(⬅️) or btn(➡️)) then
  if p.vx > 0 then
	 p.vx = max(0, p.vx - p.drag * dt)
  elseif p.vx < 0 then
	 p.vx = min(0, p.vx + p.drag * dt)
  end
 end
end

function add_ball(x,y) 
	b = {}

	b.w = 3
	b.h = 3
	b.s = 100
	b.dirx = 1 
	b.diry = 1
 b.c = 6
	b.x = x or p.x
	b.y = y or p.y - b.h
 add(balls, b)
end

function make_block_of_blocks(rows, cols, spacing, margin)
 --we have 120x80ish work with
 local areaw = 128 - margin*2 - lw.w - rw.w
 local areah = 80 - margin 
 local offsetx = lw.w + margin
 local offsety = tw.h + margin
 debug = cols
 printh("----- " .. rows .. " , " .. cols .. ", " .. spacing .. ", " .. margin, "blocks.txt", true)
 printh("areaw,areah: " .. areaw .. ", " .. areah, "blocks.txt", false)
 for r=1,rows do 
  for c=1,cols do
   b = {}
   b.x = areaw \ rows * (r-1) + offsetx 
   b.y = areah \ cols * (c-1) + offsety
   b.w = areaw \ rows - spacing
   b.h = areah \ cols - spacing
   b.c = 10
   setmetatable(b, blocksmt)
   add(blocks, b)
   printh(b, "blocks.txt", false)
  end
 end
end

function update_balls()
	for b in all(balls) do
		local dx, dy = normalize(b.dirx, b.diry)
		dx = dt * dx * b.s
  dy = dt * dy * b.s
  b.x += dx
  b.y += dy
	end
end

function collisions()
 --paddle-walls
 if aabb(p, lw) then
  p.x = lw.x + lw.w
  p.vx = 0
 end

 if aabb(p, rw) then
  p.x = rw.x - p.w
  p.vx = 0
 end
 --paddle-balls
 for b in all(balls) do
  if aabb(b, p) then
   if hit_axis_aabb(b, p) then
    hitinfo.hit = true
    --reflect horiz
    b.dirx *= -1
   else
    b.diry *= -1
   end
  end
 end

 --balls-walls
 for b in all(balls) do
  for w in all(walls) do
   if aabb(b, w) then
    if hit_axis_aabb(b, w) then
     --reflect horiz
     b.dirx *= -1
    else
     b.diry *= -1
    end
   end
  end
 end

 --balls-blocks
 for b in all(balls) do
  for bx in all(blocks) do
   if aabb(b, bx) then
    
    if hit_axis_aabb(b, bx) then
     --reflect horiz
     b.dirx *= -1
    else
     b.diry *= -1
    end
    del(blocks, bx)
   end
  end
 end

 --balls-balls


end

function draw_walls()
 --why the -1s? rectfill has inclusive bounds that makes rects
 --larger than they should be.
 rectfill(tw.x, tw.y, tw.x + tw.w - 1, tw.y + tw.h - 1, wc)
 rectfill(lw.x, lw.y, lw.x + lw.w - 1, lw.y + lw.h - 1, wc)
 rectfill(rw.x, rw.y, rw.x + rw.w - 1, rw.y + rw.h - 1, wc)
end

function draw_paddle()
 rectfill(p.x, p.y, p.x + p.w - 1, p.y + p.h - 1, p.c)
end

function draw_balls()
 for b in all(balls) do
  rectfill(b.x, b.y, b.x + b.w -1, b.y + b.h - 1, b.c)
 end
end

function draw_blocks()
  for b in all(blocks) do
   rectfill(b.x, b.y, b.x + b.w -1, b.y + b.h -1, b.c)
  end
end
-->8
--juicebar

config = {}
config.color = false
config.wall_screen_shake = false

selection = "no_juice"

function update_config() 

end

function draw_config()

end
-->8
--utils
function aabb(a, b)
	local a_right_b = a.x >= b.x+b.w
	local a_left_b = a.x+a.w <= b.x
	local a_above_b = a.y+a.h <= b.y
	local a_below_b = a.y >= b.y+b.h
	
	return not(a_right_b or 
		a_left_b or 
		a_above_b or 
		a_below_b)
end

--true if horizontal hit, false if vertical
function hit_axis_aabb(a, b)
 local intx = 0
 local inty = 0
 
 intx =  a.x - b.x + b.w
 inty = a.y - b.y + b.h
 if intx < inty then
  return true
 end
 return false
end

function normalize(x,y)
	--magnitude
	--normalize
	local mag = sqrt(x^2+y^2)
	--print("mag: " .. mag .. " from " .. x .. "," .. y)
	if mag == 0 then
		return 0,0
	end
	return x / mag, y / mag
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

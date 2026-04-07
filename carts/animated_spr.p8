pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--demo for sprite animations
--see the sprite sheet for the
--frames of the animated fire.

--code tabs 1,2, and 3 are each
--implementations of animated
--sprites in increasing
--complexity


function _init()
	--basic time functions
	--they are global; 
	--can be seen anywhere
	last_time = t()
	dt = 0
end

function _update()
 --calculate time since last update
	dt = t() - last_time
	last_time = t()
	
	easy_fire()
	standard_fire()
	fancy_fire()
end


function _draw()
	cls(1)
	draw_easy_fire()
	draw_standard_fire()
	draw_fancy_fire()
	color(8)
	print("dt: " .. dt)
	print("last_time: " .. flr(10*last_time)/10)
	print("fire_dt: " .. fire_dt)
	print("fire_spr: " .. fire_spr)
end
-->8
--fire without complex data

--the current fire frame
fire_spr = 1
--the first fire frame on the sheet
fire_spr_first = 1
--the last fire frame on the sheet
fire_spr_last = 8
--the amount of time per frame
fire_dt = 0.25
--fire_dt = 1/30 --30 fps
--the timer that counts up to fire_dt
fire_timer = 0


function easy_fire()
	--update the timer for this update
	fire_timer += dt
	
	--has the timer expired?
	if fire_timer > fire_dt then
		--if so, move to the next frame
		fire_spr += 1
		
		--did we move past the last spr?
		if fire_spr > fire_spr_last then
			--we did! go back to first spr
			fire_spr = fire_spr_first
		end
		
		--be sure to reset the timer!
		fire_timer = 0
	end
end

function draw_easy_fire()
	spr(fire_spr, 60, 60)
end
-->8
--standard fire using tables

fire_frames = {1, 2, 3, 4, 5, 6, 7, 8}
fire_frame = 1
anim_timer = 0

function standard_fire()
 anim_timer += dt

 if anim_timer > 0.25 then
  anim_timer = 0
  fire_frame += 1
  if fire_frame > #fire_frames then
   fire_frame = 1
  end
 end
end

function draw_standard_fire()
 spr(fire_frames[fire_frame], 54, 94)
end
-->8
--fancy🐱! can you grok?

f_fire_frames = {1, 2, 3, 4, 5, 6, 7, 8}
fancy_fire_spr = 1

function fancy_fire()
 fancy_fire_spr = f_fire_frames[flr(time() * 4) % #fire_frames + 1]
end

function draw_fancy_fire()
	 spr(fancy_fire_spr, 76, 76)
end
__gfx__
00000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000080000000800000000800000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000
00700700000880000000800000008800000008000000080000088000000080000008800000000000000000000000000000000000000000000000000000000000
00077000008880000008880000008900000088000088880000888800008888000088800000000000000000000000000000000000000000000000000000000000
00077000008880000088980000889800008888000088980000899800008998000089880000000000000000000000000000000000000000000000000000000000
0070070008999800089998000899a8000899a8000899980008999800089998000899980000000000000000000000000000000000000000000000000000000000
00000000089a9800089a9800089a9800089a9800089a9800089a9800089a9800089a980000000000000000000000000000000000000000000000000000000000

pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--controls debug printing
debug_print = false

--basic world parameters
g = {x=0,y=49.2}
floor = 100
drag = 4.5

player = {}
--position of the player
player.x = 30
player.y = 30

--player momentum
player.mx = 0
player.my = 0

--player movement speed
player.accel = 15
player.velx = 0
player.vely = 0
player.maxvel = 12
player.jumpvel = {x=0,y=-50}
player.jumping = false
player.jumpdur = 1
player.jumpt = 0
player.canjump = false
player.radius = 9

prev_t = 0

function _init()
	--start game time
	prev_t = time()
end

function _update60()
	local dt = time() - prev_t

	--player movement
	if btn(0) and player.canjump then
	 --player.vel += player.accel * dt
		player.velx += -1 * player.accel * dt
	end

	if btn(1) and player.canjump then
		-- player.mx += player.vel * dt
		player.velx += player.accel * dt
	end

if player.velx > player.maxvel then
	 player.velx = player.maxvel
end

if player.velx < -player.maxvel then
	 player.velx = -player.maxvel
end

	if btn(2) and player.canjump then
		player.jumping = true
		player.canjump = false
		player.vely = player.jumpvel.y
		player.jumpt = player.jumpdur
	end

	--jumping
	if player.jumpt - dt < 0 then
		player.jumping = false
	end

	if player.jumping then
		-- player.vely = player.jumpvel.y * dt
		player.jumpt -= dt
	end


	--drag
	if player.canjump then
		if player.velx < -drag * dt then
			player.velx += drag * dt
		elseif player.velx > drag * dt then
			player.velx += -1 * drag * dt
		else
			player.velx = 0
		end
 end

	--gravity
	player.velx += g.x * dt
	player.vely += g.y * dt

	player.x += player.velx * dt
	player.y += player.vely * dt

	if player.y > floor then
		player.y = floor
		player.vely = 0
		player.jumping = false
		player.canjump = true
	end

	prev_t = time()

end

function _draw()
	cls(2)
	--the ground
	line(0, floor, 128, floor)
	circ(player.x, player.y - player.radius/2, 5, player.radius)
	if debug_print then
	  print(player.velx, player.x+3, player.y-11, 10)
	  print(player.vely, player.x+3, player.y-5, 10)
	  print(player.jumping, player.x+3, player.y-17, 10)
	  print(player.canjump, player.x+3, player.y-23, 10)
	end
	draw_input()
end

function draw_input()
	if btn(0) then
		pset(player.x-1, player.y-3, 12)
	end
	if btn(1) then
		pset(player.x+1, player.y-3, 8)
	end
	if btn(2) then
	 pset(player.x, player.y-4, 11)
	end
 if btnp(4) then
	 debug_print = not debug_print
	end
end

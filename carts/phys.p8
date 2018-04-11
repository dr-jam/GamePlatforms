pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--basic world parameters
g = {x=0,y=0.5}
floor = 60
drag = 0.3

player = {}
--position of the player
player.x = 30
player.y = 30

--player momentum
player.mx = 0 
player.my = 0

--player movement speed
player.speed = 0.5
player.jump = {x=0,y=-12}
player.jumping = false
player.jumpdur = 1
player.jumpt = 0
player.canjump = false

prev_t = 0

function _init() 
	--start game time
	prev_t = time()
end

function _update60()
	local dt = time() - prev_t
	
	--player movement
	if btn(0) and player.canjump then
		player.mx += -1 * player.speed * dt
	end
	
	if btn(1) and player.canjump then
		player.mx += player.speed * dt
	end

	if btn(2) and player.canjump then
		player.jumping = true
		player.canjump = false
		player.jumpt = player.jumpdur
	end
	
	--jumping
	if player.jumpt - dt < 0 then
		player.jumping = false
	end
	
	if player.jumping then
		player.my = player.jump.y * dt
		player.jumpt -= dt
	end
	
	
	--drag
	if player.canjump then
		if player.mx < -drag * dt then
			player.mx += drag * dt
		elseif player.mx > drag * dt then
			player.mx += -1 * drag * dt
		else
			player.mx = 0
		end
 end

	--gravity	
	player.mx += g.x * dt
	player.my += g.y * dt
	
	player.x += player.mx
	player.y += player.my	
	
	if player.y > floor then
		player.y = floor
		player.my = 0
		player.jumping = false
		player.canjump = true
	end
	
	prev_t = time()
	
end

function _draw()
	cls(3)
	circ(player.x, player.y, 5, 4)
	print(player.mx, player.x+3, player.y-11, 9)
	print(player.my, player.x+3, player.y-5, 9)
	print(player.jumping, player.x+3, player.y-17,9)
	print(player.canjump, player.x+3, player.y-23,9)
	draw_input()
end

function draw_input()
	if btn(0) then
		pset(player.x-1, player.y, 7)
	end
	if btn(1) then 
		pset(player.x+1, player.y, 6)
	end
	if btn(2) then
	 pset(player.x, player.y-1, 8)
	end

end





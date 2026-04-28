pico-8 cartridge // http://www.pico-8.com
version 43
__lua__

function _init()
	dt = 0
	last_time = time()
	make_particle_system(800)
end

function _update60()
	dt = time() - last_time
	last_time = time()
	update_particle_systems()
end

function _draw()
 cls()
 print(time())
	print(stat(1)) --cpu usage
	print(stat(0)) --memory usage
	print(stat(7)) --fps
	print(particle_systems[1].active)
	draw_particle_systems()
end
-->8
particle_systems = {}

function make_particle_system(particle_count)
	local ps = {}
	ps.active = true
	ps.particles = {}
	
	for i=1,particle_count do
		local particle = {}
		local x, y = 0
		x = rnd(4)-2
		y = rnd(4)-2
		x,y = normalize(x,y)
		
		particle.start = time()+rnd(25)
		particle.x = 64
		particle.y = 64
		
		particle.sx = 0.5
		particle.sy = 0.5
		particle.g = 0.1
		particle.dx = x
		particle.dy = y
		
		particle.dur = 3
		particle.active = false
		particle.fired = false
		
		add(ps.particles,particle)
	end
	
	add(particle_systems,ps)

end

function update_particle_systems()
	for ps in all(particle_systems) do
		local active_check = false
		if not ps.active then
			break
		end
		
		for p in all(ps.particles) do
			
			if not p.fired and p.start <= time() then
				p.active = true
				p.fired = true
			end
			if p.active and p.dur > 0 then
				p.dur -= dt
				p.x += p.dx * p.sx
				p.dy += p.g --gravity
				p.y += p.dy * p.sy
			else
				p.active = false
			end
			
			if p.active or 
				not active and not p.fired 
				then
				active_check = true
			end
			
		end
		
		ps.active = active_check
	end
end

function draw_particle_systems()
	for psi=1,#particle_systems do

		local ps = particle_systems[psi]
		
		if not ps.active then
			break
		end
		
		for pi=1,#ps.particles do	
			local p = ps.particles[pi]
			if p.dur > 0 then
				pset(p.x, p.y, 9)
			 --print("🐱",p.x, p.y,9)
			 circ(p.x, p.y, 4, 9)
			end
		end
	end
end

-->8
function normalize(x,y)
	--magnitude
	--normalize
	local mag = sqrt(x^2+y^2)
	--print("mag: " .. mag .. " from " .. x .. "," .. y)
	return x / mag, y / mag
end

function printt(t)
	for key, value in pairs( t ) do
	 print(key .. ": " .. tostr(value))
	end
--	for i=1,#t do
--	 print(t[i]) 
--	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

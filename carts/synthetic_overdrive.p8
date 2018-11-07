pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--game vars
game_started = false
game_time = 0
song_offset = 16
dt = 0
lt = 0
vhs_on = true
glitch_amount = 50
song_percent = 0
beatmap_index = 1
boot_time = 0
music_playing = false
score = 0
combo = 0
car_pos_x = 10
car_pos_y = 64
car_frame = 1
car_anim_speed = 0.1
car_speed = 1000
road_x = 0
road_y = 65
road_speed = 1
last_index = 0
index_changed = false
arrows = {}
good_arrows = {}
good_arrow_lifespan = 4
misses = {}
miss_lifespan = 8
backgrounds = {}
arrow_spawn_x = 96
arrow_sink_x = 16
arrow_range_perfect = 1
arrow_range_good = 4
arrow_range_miss = 8
ui_offset = 84
arrow_spacing = 9
arrow_despawn_x = 6
arrow_up_y = ui_offset + 4
arrow_left_y = arrow_up_y + arrow_spacing
arrow_right_y = arrow_left_y + arrow_spacing
arrow_down_y = arrow_right_y + arrow_spacing
speed_multiplier = 16 -- 0.5 for double time, 2 for half time, etc
background_count = 0
background_speed = 0.3
background_spawn_x = 126
background_spawn_y = 41
background_despawn_x = -126
sun_x = 100
sun_y = 60
camera_shake_timer = 0
shake_amount = 1
pointer = 33
scoreboard_time = 0
scoreboard_duration = 5
lamp_counter = 80
lamps = {}
vhs_on = true
vhs_timer = 0
glitch_amount = 15

--particles
emitters = {}
particles = {}
particle_limit = 250
fireworks2 = 0
particle_count = 10

--color vars
splash_bg_color = 0
splash_text_color = 1
splash_text_outline_color = 2
game_bg_color = 0
sky_color = 14
sun_color = 14

--sprite values
spr_logo = 200
spr_arrow_up = 1
spr_arrow_left = 17
spr_arrow_right = 33
spr_arrow_down = 49
spr_good_arrow_up = 3
spr_good_arrow_left = 19
spr_good_arrow_right = 35
spr_good_arrow_down = 51
spr_arrow_sink_up = 2
spr_arrow_sink_left = 18
spr_arrow_sink_right = 34
spr_arrow_sink_down = 50
spr_car_f1 = 12
spr_car_f2 = 37
spr_road1 = 4
spr_road2 = 5
spr_road_side = 36
spr_lampa1 = 25
spr_lampa2 = 26
spr_lampb = 41
spr_miss = 52
ui_start = 160

levels = { city = "city", blue = "blue"}
current_level = levels.blue

--song data
song_city_len = 144.798 --song length in seconds
song_blue_len = 91.086 -- i haven't figured this one out yet --song length in seconds

song_len = song_city_len


--beatmap_city_help= [[0.......-.......+.......=.......1.......-.......+.......=.......2.......-.......+.......=.......3.......-.......+.......=.......4.......-.......+.......=.......5.......-.......+.......=.......6.......-.......+.......=.......7.......-.......+.......=.......8.......-.......+.......=.......9.......-.......+.......=.......10......-.......+.......=.......11......-.......+.......=.......12......-.......+.......=.......13......-.......+.......=.......14......-.......+.......=.......15......-.......+.......=.......16......-.......+.......=.......17......-.......+.......=.......18......-.......+.......=.......19......-.......+.......=.......20......-.......+.......=.......21......-.......+.......=.......22......-.......+.......=.......23......-.......+.......=.......24......-.......+.......=.......25......-.......+.......=.......26......-.......+.......=.......27......-.......+.......=.......28......-.......+.......=.......29......-.......+.......=.......30......-.......+.......=.......31......-.......+.......=.......32......-.......+.......=.......33......-.......+.......=.......]]
beatmap_city_up    = [[.....1.....1.........1.....1.........1.....1.........1.....1....1..1..1.......................1.................1..1..1...1..........1.....1......1.1..1....1........1.....1......1.1..1.............1.....1......1.1..1....1........1.....1......1.1..1.......................1.............1..............1...............1.....1...1...............1.......................1...............1..1............................1..1............................1..1............................1..1........................1..1.1......1.....1.........1.....1.........1.....1.........1.....1........1.....1......1.1..1....1........1.....1......1.1..1.............1.....1......1.1..1....1........1.....1......1.1..1.............1.....1......1.1..1....1........1.....1......1.1..1.......................1.............1..............1...............1.....1...1...............1.....................1....................1............................1..1............................1..1............................1..1..............................................................................................]]
beatmap_city_left  = [[1...1..1..1..1..1...1..1..1..1..1...1..1..1..1..1...1..1..1..1..................................................................1...1..1..1..1........1.........1...1..1..1..1........1.........1...1..1..1..1........1.........1...1..1..1..1........1......................1............1...........1.......................1.............1.......1.......1............1................1.......1.......................1.......1.......................1.......1.......................1.......1...................11........1...1..1..1..1..1...1..1..1..1..1...1..1..1..1..1...1..1..1..1..1...1..1..1..1........1.........1...1..1..1..1........1.........1...1..1..1..1........1.........1...1..1..1..1........1.........1...1..1..1..1........1.........1...1..1..1..1........1......................1............1...........1.......................1.............1.......1.......1.....................................1.......................1.......1.......................1.......1.......................1.......1.............................................................................................]]
beatmap_city_right = [[........1.....1.........1.....1.........1.....1.........1.....1.............................................................1...........1.....1.1.......................1.....1.1.......................1.....1.1.......................1.....1.1...............1.........1.....................1.......................1.......1.............1.................1...............................1...............................1...............................1...............................1...............11......................1.....1.........1.....1.........1.....1.........1.....1.........1.....1.1.......................1.....1.1.......................1.....1.1.......................1.....1.1.......................1.....1.1.......................1.....1.1...............1.........1.....................1.......................1.......1.............1.................1.............1.................1...............................1...............................1...............................1...............................................................................................]]
beatmap_city_down  = [[..1............1..1............1..1............1..1............1................................1..1..1..1........................1............1.1........1.......1............1.1................1............1.1........1.......1............1.1..........................1...............1.......................1...............1.....1.......1.......1.................1...............1...............................1...............................1...............................1......................11.............1............1..1............1..1............1..1............1..1............1.1........1.......1............1.1................1............1.1........1.......1............1.1................1............1.1........1.......1............1.1..........................1...............1.......................1................1.....1.......1.......1..............1.................................................1...............................1...............................1...................................................................................................]]
beat_city_len = song_city_len / (#beatmap_city_up) --beat length in seconds

--beatmap_blue_help= [[34......-.......+.......=.......35......-.......+.......=.......36......-.......+.......=.......37......-.......+.......=.......38......-.......+.......=.......39......-.......+.......=.......40......-.......+.......=.......41......-.......+.......=.......42......-.......+.......=.......43......-.......+.......=.......44......-.......+.......=.......45......-.......+.......=.......46......-.......+.......=.......47......-.......+.......=.......48......-.......+.......=.......49......-.......+.......=.......50......-.......+.......=.......51......-.......+.......=.......52......-.......+.......=.......]]
beatmap_blue_up    = [[............................................................................1...........1...............1.....1.............................1...........1...............................1...............1..1............1..1...1........1..1............1..1...1........1..1............1..1...1............................................................................1.1.1..1.11.....................1.1.1..1.11.....................1.1.1..1.11......1..............................................................................................................1.1.1..1.11......1..................................]]
beatmap_blue_left  = [[........................................................................1.....................1...........1.............................1.....................1.................1...............1..1............................1..1............................1..1......................................................................................................1.................1.1...........1.................1.1...........1...................1...........................................................................................................1...................1.................................]]
beatmap_blue_right = [[................................................................................1...........1.......1...................1.......................1...........1...........1.......................................1..1..........1.................1..1..........1.................1..1..........1.................................................................1..1.11.........................1..1.11.........................1..1.11.....................1...1...1.1..1..1.1.1...1.1.1..1.11.1...1..1..1.1..1..1..1..1.......................................1..1.11.....................1.....1.............................]]
beatmap_blue_down  = [[................................................................1...............................1.....1.........1...............1...............................1............................................................1...............................1...............................1............................................................................................1...............................1...............................1....1..1...............1...............1...1...................................................................................1....1................................]]
beat_blue_len = song_blue_len / (#beatmap_blue_up) --beat length in seconds

beatmap_up = beatmap_city_up
beatmap_left = beatmap_city_left
beatmap_right = beatmap_city_right
beatmap_down = beatmap_city_down
beat_len = beat_city_len

arrow_speed = (((arrow_spawn_x - arrow_sink_x) / beat_len) / 60) / speed_multiplier

game_states = {
    splash = 0,
    game = 1,
    scoreboard = 2
}

state = game_states.splash

function change_state()
    cls()
    if state == game_states.splash then
      if current_level == levels.blue then
        beatmap_up = beatmap_blue_up
        beatmap_left = beatmap_blue_left
        beatmap_right = beatmap_blue_right
        beatmap_down = beatmap_blue_down
        beat_len = beat_blue_len
        song_len = song_blue_len
        sky_color = 11
        sun_color = 11
        spr_car_f1 = 44
        spr_car_f2 = 44
        spr_road1 = 16
        spr_road2 = 8
        spr_road_bot = 23
      elseif current_level == levels.city then
        beatmap_up = beatmap_city_up
        beatmap_left = beatmap_city_left
        beatmap_right = beatmap_city_right
        beatmap_down = beatmap_city_down
        beat_len = beat_city_len
        song_len = song_city_len
        sky_color = 14
        sun_color = 14
        spr_car_f1 = 12
        spr_car_f2 = 37
        spr_road1 = 4
        spr_road2 = 5
        spr_road_bot = 36
      end

	  song_percent = 0
      arrow_speed = (((arrow_spawn_x - arrow_sink_x) / beat_len) / 60) / speed_multiplier
      state = game_states.game
    elseif state == game_states.game then
		scoreboard_time = time()
        state = game_states.scoreboard
    elseif state == game_states.scoreboard then
        state = game_states.splash
    end
end

function emit(emitter)
	if #particles >= particle_limit then
		del(particles, particles[1])
	end
	add(particles, {})
	particles[#particles].emitter = emitter
	particles[#particles].position_x = emitter.position_x + rnd(emitter.width-1)
	particles[#particles].position_y = emitter.position_y + rnd(emitter.height-1)
	particles[#particles].velocity_x = emitter.velocity_x
	particles[#particles].velocity_y = emitter.velocity_y
	particles[#particles].ttl = emitter.ttl
end

function count_backgrounds()
  background_count = 0
  for k, v in pairs(backgrounds) do
    background_count += 1
  end
end

function clean_backgrounds()
  del(backgrounds, nil)
  count_backgrounds()
end

function spawn_lamp(td)
  local new_lamp = {d = td, x = 130}
  add(lamps, new_lamp)
end

function check_lamps()
  if (lamp_counter == 100) then
    spawn_lamp("up")
  elseif (lamp_counter >= 200) then
    spawn_lamp("down")
    lamp_counter = 0
  end

  if (#lamps > 0) then
    for i=1, #lamps do
      lamps[i].x -= road_speed
      if (lamps[i].x < -5) then
        lamps[i] = nil
      end
    end
  end
  for i=1, #lamps do
    del(lamps, nil)
  end
  lamp_counter += 1
end

function check_background()
  for i = 1, background_count do
    backgrounds[i].x -= background_speed
    if (backgrounds[i].x < background_despawn_x) then
      backgrounds[i] = nil
      local new_background = {x = background_spawn_x}
      add(backgrounds, new_background)
    end
  end
  clean_backgrounds()
end

function spawn_miss(tx, ty)
  local new_miss = {x = tx, y = ty, l = miss_lifespan}
  add(misses, new_miss)
  vhs_on = true
  vhs_timer = 2
  if (score > 25) then
    score -= 25
  elseif (score > 0) then
    score = 0
  end
  car_speed -= 25
  combo = 0
  camera_shake_timer = 2
end

function spawn_good_arrow(td, tx, ty)
  local new_good_arrow = {d = td, x = tx, y = ty, l = good_arrow_lifespan}
  add(good_arrows, new_good_arrow)
  car_speed += 25
  combo += 1
end

function check_misses()
  if (#misses > 0) then
    for i = 1, #misses do
      misses[i].l -= 1
      if (misses[i].l < 0) then
        misses[i] = nil
      end
    end
    for i=1,#misses do
      del(misses, nil)
    end
  end
end

function check_good_arrows()
  if (#good_arrows > 0) then
    for i = 1, #good_arrows do
      good_arrows[i].l -= 1
      if (good_arrows[i].l < 0) then
        good_arrows[i] = nil
      end
    end
    for i=1,#good_arrows do
      del(good_arrows, nil)
    end
  end
end

function check_road()
  road_x -= road_speed
  if (road_x <= -16) then
    road_x = 0
  end
end

function vhs_screen()
		local t={7,6,2}
		local c=rnd(3)
		c=flr(c)
		for i=0, glitch_amount, 4 do
			local gl_height = rnd(glit.height)
			for h=0, 100, 2 do
				pset(rnd(glit.width), gl_height, t[c])
			end
		end
end

function vhs_screen()
        local t={7,6,2}
        local c=rnd(3)
        c=flr(c)
        for i=0, glitch_amount, 4 do
            local gl_height = rnd(glit.height)
            for h=0, 100, 2 do
                pset(rnd(glit.width), gl_height, t[c])
            end
        end
end

function spawn_perfect_particles(x, y)
  fireworks2.position_x = x + 8
  fireworks2.position_y = y + 8
  fireworks2.old_position_x = x + 8
  fireworks2.old_position_y = y + 8
  for p = 0, particle_count do
    --blast
    fireworks2.velocity_x = rnd(4)-2
    fireworks2.velocity_y = rnd(4)-2
    emit(fireworks2) --call this whenever you want a new particle
  end
end

-- player input
function handle_input()
    -- left
    if btnp(0) then
      check_arrow(spr_arrow_left)
    end
    -- right
    if btnp(1) then
      check_arrow(spr_arrow_right)
    end
    -- up
    if btnp(2) then
      check_arrow(spr_arrow_up)
    end
    -- down
    if btnp(3) then
      check_arrow(spr_arrow_down)
    end

    -- button 1
    if btnp(4) then
      --spawn_perfect_particles(50,50)
    end

    -- button 2
    if btnp(5) then
    end
end

-- pico8 game funtions
function _init()
    cls()
    glit = {}
  	glit.height=128 -- set the width of area the screen glitch will appear
  	glit.width=128 -- set the width of area the screen glitch will appear

    add(emitters,{})
  	fireworks2 = emitters[#emitters] --last emitter made
  	--save some tokens here by creating a local variable
  	fireworks2.position_x = 0
  	fireworks2.position_y = 0
  	fireworks2.old_position_x = 0 --set this to the same as position x and y to avoid weird tails
  	fireworks2.old_position_y = 0
  	fireworks2.width = 1
  	fireworks2.height = 1
  	fireworks2.color = {12,7,6,5} --list of one or more colors to fade to, chosen evenly by (the particle age / time to live)
  	fireworks2.velocity_x = 0
  	fireworks2.velocity_y = 0
  	fireworks2.drag = 0.88 --simple multiplier
  	fireworks2.gravity_x = 0 --gravity in any direction, use negatives for reverse gravity, like for fire and smoke
  	fireworks2.gravity_y = 0.2
  	fireworks2.ttl = 30 --time to live, in frames

    palt(0, false)
    palt(15, true)
    boot_time = time()
    local new_background = {x = 0}
    add(backgrounds, new_background)
    local new_background2 = {x = background_spawn_x}
    add(backgrounds, new_background2)
    local new_background3 = {x = (background_spawn_x * 2)}
    add(backgrounds, new_background3)
    clean_backgrounds()
end


function check_arrow(dir)
  if (#arrows > 0) then
    for i = 1, #arrows do
      if (arrows[i].d == dir) then
        if ((arrow_sink_x - arrow_range_perfect) <= arrows[i].x and arrows[i].x <= (arrow_sink_x + arrow_range_perfect)) then
          fireworks2.position_x = arrows[i].x
        	fireworks2.position_y = arrows[i].y
          spawn_perfect_particles(fireworks2.position_x, fireworks2.position_y)
          spawn_good_arrow(arrows[i].d, arrows[i].x, arrows[i].y)
          del(arrows, arrows[i])
          score += 25
          break
        elseif ((arrow_sink_x - arrow_range_good) <= arrows[i].x and arrows[i].x <= (arrow_sink_x + arrow_range_good)) then
          spawn_good_arrow(arrows[i].d, arrows[i].x, arrows[i].y)
          del(arrows, arrows[i])
          score += 10
          break
        elseif ((arrow_sink_x - arrow_range_miss) <= arrows[i].x and arrows[i].x <= (arrow_sink_x + arrow_range_miss)) then
          spawn_miss(arrows[i].x, arrows[i].y)
          del(arrows, arrows[i])
          vhs_screen()
          break
        end
      end
    end
  end
end


function _update60()
    if state == game_states.splash then
        update_splash()
    elseif state == game_states.game then
        update_game()
    elseif state == game_states.scoreboard then
        update_scoreboard()
    end
end

function _draw()
    cls()
    if state == game_states.splash then
        draw_splash()
    elseif state == game_states.game then
        draw_game()
    elseif state == game_states.scoreboard then
        draw_scoreboard()
    end
end


-- splash
splash_selection = 1
max_levels = 2
function update_splash()
  handle_input()

  if btnp(2) then --up
    splash_selection -= 1
    if splash_selection < 1 then
      splash_selection = max_levels
    end
  end
  if btnp(3) then --up
    splash_selection += 1
    if splash_selection > max_levels then
      splash_selection = 1
    end
  end

  if btnp(5) then
    if splash_selection == 1 then
      current_level = levels.blue
      change_state()
    elseif splash_selection == 2 then
      current_level = levels.city
      change_state()
    end
  end
end

function draw_splash()
  --[[
    rectfill(0,0,screen_size,screen_size,splash_bg_color)
    local text1 = [[____ _   _ _  _ ___ _  _]]
    local text2 = [[[__   \_/  |\ |  |  |__|]]
    local text3 = [[___]   |   | \|  |  |  |]]
    local text4 = [[____ ___ _ ____ ]]
    local text5 = [[|___  |  | |    ]]
    local text6 = [[|___  |  | |___ ]]
    local text7 = [[____ _  _ ____ ____ ]]
    local text8 = [[|  | |  | |___ |__/ ]]
    local text9 = [[|__|  \/  |___ |  \ ]]
    local text10 = [[___  ____ _ _  _ ____ ]]
    local text11 = [[|  \ |__/ | |  | |___ ]]
    local text12 = [[|__/ |  \ |  \/  |___ ]]

    write(text1, 0, 0,splash_text_color)
    write(text2, 0, 6,splash_text_color)
    write(text3, 0, 12,splash_text_color)
    write(text4, 0, 18,splash_text_color)
    write(text5, 0, 24,splash_text_color)
    write(text6, 0, 30,splash_text_color)
    write(text7, 0, 36,splash_text_color)
    write(text8, 0, 42,splash_text_color)
    write(text9, 0, 48,splash_text_color)
    write(text10, 0, 54,splash_text_color)
    write(text11, 0, 60,splash_text_color)
    write(text12, 0, 66,splash_text_color)
    ]]--

    sspr(64, 96, 40, 16, 0, 0, 128, 48)
    sspr(96, 112, 40, 16, 54, 76, 128, 48)
    local text13 = [[select song with arrows and x]]
    local text14 = [[the space cops! they're
    gaining on you!]]
    local text13 = [[song 1 (easy)]]
    local text16 = [[song 2 (hard)]]
    local text14 = [["halt, citizen!]]
    local text15 = [[joy rides are a crime in 20xx!"]]
    local text17 = [[select song with arrows and x  ]]
    write(text13, 15, 84, 14)
    write(text16, 15, 93, 14)
    write(text14, 28, 52, 14)
    write(text15, 1,58,14)
    write(text17, 1,66, 14)

    -- pointer
    spr(pointer, 5, 84 + (splash_selection - 1) * 8)
end

-- game
function update_game()
  if (song_percent >= 1) then
    music(-1, 5000)
    change_state()
  end

  car_pos_x = car_speed / 100

  for particle in all(particles) do
		if particle.ttl > 0 then
			particle.velocity_y += particle.emitter.gravity_x
			particle.velocity_y += particle.emitter.gravity_y
			particle.velocity_x = particle.velocity_x * particle.emitter.drag
			particle.velocity_y = particle.velocity_y * particle.emitter.drag
			particle.old_position_x = particle.position_x
			particle.old_position_y = particle.position_y
			particle.position_x += particle.velocity_x
			particle.position_y += particle.velocity_y

			particle.ttl -= 1
		else
			del(particles, particle)
		end
	end

  sun_x = (100 - (song_percent * 50))

  handle_input()

  if (game_started == false) then
    game_time = time()
    game_started = true
  end

  dt = (time() - game_time)/2
  if (dt > (beat_len * song_offset)) and not music_playing then
    if current_level == levels.city then
      music(0)
    elseif current_level == levels.blue then
      music(34)
    end
    music_playing = true
  end

  check_road()
  check_lamps()
  check_misses()
  check_good_arrows()

  if (dt - lt > car_anim_speed) then
    if (car_frame == 1) then
      car_frame = 2
      --car_pos_y = 62
    else
      car_frame = 1
      --car_pos_y = 63
    end
    lt = dt
  end

  if (beatmap_index < #beatmap_up) then
    song_percent = dt / song_len
    beatmap_index = flr(#beatmap_up * song_percent)
  end

  if (beatmap_index > last_index) then
    index_changed = true
    last_index = beatmap_index
  else
    index_changed = false
  end

  if(index_changed) then
    if (sub(beatmap_up, beatmap_index, beatmap_index) == '1') then
      local new_arrow = {d = spr_arrow_up, x = arrow_spawn_x, y = arrow_up_y}
      add(arrows, new_arrow)
    end
    if (sub(beatmap_left, beatmap_index, beatmap_index) == '1') then
      local new_arrow = {d = spr_arrow_left, x = arrow_spawn_x, y = arrow_left_y}
      add(arrows, new_arrow)
    end
    if (sub(beatmap_right, beatmap_index, beatmap_index) == '1') then
      local new_arrow = {d = spr_arrow_right, x = arrow_spawn_x, y = arrow_right_y}
      add(arrows, new_arrow)
    end
    if (sub(beatmap_down, beatmap_index, beatmap_index) == '1') then
      local new_arrow = {d = spr_arrow_down, x = arrow_spawn_x, y = arrow_down_y}
      add(arrows, new_arrow)
    end
  end

  if (#arrows > 0) then
    for i = 1, #arrows do
      arrows[i].x -= arrow_speed
      if (arrows[i].x < arrow_despawn_x) then
        spawn_miss(arrows[i].x, arrows[i].y)
        arrows[i] = nil
      end
    end
    for i=1,#arrows do
      del(arrows, nil)
    end
  end

  check_background()
end

function draw_game()
  --rectfill(0,0,screen_size,screen_size,game_bg_color)
  --rectfill(0,76,screen_size,86,5)
  --rectfill(0,87,screen_size,screen_size,0)
  --rect(0,87,127,127,2)

  --draw skybox
  rectfill(0,0,128,12,sky_color)
  rectfill(0,16,128,24,sky_color)
  rectfill(0,27,128,30,sky_color)
  rectfill(0,32,128,34,sky_color)
  rectfill(0,36,128,37,sky_color)
  rectfill(0,39,128,39,sky_color)
  rectfill(0,41,128,41,sky_color)
  rectfill(0,43,128,43,sky_color)
  rectfill(0,45,128,45,sky_color)
  rectfill(0,47,128,47,sky_color)

  --draw sun
  circfill(sun_x,sun_y,36,sun_color)

  --draw background
  for i=1,background_count do
      local bg_spr
      if current_level == levels.city then
        bg_spr = 80
      elseif current_level == levels.blue then
        bg_spr = 144
      end
      spr(bg_spr, backgrounds[i].x, background_spawn_y, 16, 3)
  end

  --draw road
  for i=0,8 do
    spr(spr_road1, road_x + (16 * i), road_y, 1, 3)
    spr(spr_road2, road_x + (16 * i) + 8, road_y, 1, 2)
    spr(spr_road_bot, road_x + (16 * i) + 8, road_y + 16, 1, 1)
  end
  if(#lamps > 0) then
  for i=1,#lamps do
      if (lamps[i].d == "up") then
        spr(spr_lampa1, lamps[i].x, road_y-23, 1, 3)
      end
    end
  end

  --draw car
  if (car_frame == 1) then
    spr(spr_car_f1, car_pos_x, car_pos_y, 4, 2)
  else
    spr(spr_car_f2, car_pos_x, car_pos_y, 4, 2)
  end
  if(#lamps > 0) then
    for i=1,#lamps do
      if (lamps[i].d == "down") then
        spr(spr_lampa2, lamps[i].x, road_y-6)
        spr(spr_lampb, lamps[i].x, road_y+2, 1, 2)
      end
    end
  end

  --draw ui -_-
  spr(192, 0, ui_offset)
  spr(193, 8, ui_offset)
  --spr(192, 0, ui_offset + 8)
  for i=1,3 do
      spr(208, 0, ui_offset + (8 * i))
  end
  spr(224, 0, ui_offset + 32, 1, 2)
  for i=1,9 do
    spr(194, 8 + (8 * i), ui_offset)
  end
  spr(241, 8, ui_offset + 40)
  spr(243, 88, ui_offset + 40)
  for i=1,9 do
    spr(242, 8 + (8 * i), ui_offset + 40)
  end
  for i=1,11 do
    for j=1,4 do
      spr(209, (8 * i), (ui_offset + (8 * j)))
    end
  end
  spr(227, 88, (ui_offset + 32))
  spr(195, 88, ui_offset)

  --draw arrow sinks
  spr(spr_arrow_sink_up, arrow_sink_x, arrow_up_y)
  spr(spr_arrow_sink_left, arrow_sink_x, arrow_left_y)
  spr(spr_arrow_sink_right, arrow_sink_x, arrow_right_y)
  spr(spr_arrow_sink_down, arrow_sink_x, arrow_down_y)

  --draw arrows
  if (#arrows > 0) then
    for i = 1, #arrows do
      spr(arrows[i].d, arrows[i].x, arrows[i].y)
    end
  end

  --more ui
  spr(196, 96, ui_offset, 4,2)
  for i=2,4 do
    spr(228, 96, ui_offset + (8 * i))
    spr(228, 104, ui_offset + (8 * i))
    spr(228, 112, ui_offset + (8 * i))
    spr(229, 120, ui_offset + (8 * i))
  end
  spr(196, 104, ui_offset + 12, 2,2)
  spr(199, 120, ui_offset + 12, 1,2)
  spr(244, 96, ui_offset + 40)
  spr(244, 104, ui_offset + 40)
  spr(244, 112, ui_offset + 40, 2, 1)

  --spr(230, 98, ui_offset + 27, 4, 2)

  --rectfill(0,80,128,83,12)

  --print("seconds:" .. flr(dt), 0, 0, 7)
  --print("music:" .. flr(song_percent * 100) .. "/100%", 0, 8, 7)
  --print("beats:" .. flr(beatmap_index) .. "/" .. #beatmap_up, 0, 16, 7)
  --print("arrows:" .. #arrows, 0, 24, 7)
  --print("carf:" .. lt, 0, 32, 7)
  print(score, 105, 88, 12)

  --draw misses
  if(#misses > 0) then
    for i=1,#misses do
      spr(spr_miss, misses[i].x, misses[i].y)
    end
  end

  --draw good arrows
  if(#good_arrows > 0) then
    for i=1,#good_arrows do
      spr(good_arrows[i].d + 2, good_arrows[i].x, good_arrows[i].y)
    end
  end

  for particle in all(particles) do
		line(particle.old_position_x, particle.old_position_y, particle.position_x, particle.position_y,particle.emitter.color[flr(#particle.emitter.color * (1-(particle.ttl / particle.emitter.ttl))+1)])
	end

  if (vhs_on) then
    if (vhs_timer > 0) then
      vhs_screen()
      vhs_timer -= 1
    elseif (vhs_timer <= 0) then
      vhs_on = false
    end
  end

  --draw combo
  if (combo > 5) then
    print(combo, 113, ui_offset + 16)
  end

  --shake the camera
  camera(0, 0)
  if (camera_shake_timer > 0) then
    if (camera_shake_timer % 2 == 0) then
      camera(0, -shake_amount)
    else
      camera(0, shake_amount)
    end
    camera_shake_timer -= 1
  end
end


-- game over
function update_scoreboard()
  if btnp(5) then
    change_state()
  end
end

function draw_scoreboard()
  cls()
  write ("your score: " .. score, 24, 64)
  write ("press x to return", 24, 72)
end

-- calculate center position in x axis
-- this is asuming the text uses the system font which is 4px wide
function text_x_pos(text)
    local letter_width = 4

    -- first calculate how wide is the text
    local width = #text * letter_width

    -- if it's wider than the screen then it's multiple lines so we return 0
    if width > screen_size then
        return 0
    end

   return screen_size / 2 - flr(width / 2)

end

-- prints black bordered text
function write(text,x,y,color)
    for i=0,2 do
        for j=0,2 do
            print(text,x+i,y+j, splash_text_outline_color)
        end
    end
    print(text,x+1,y+1,color)
end


-- returns if module of a/b == 0. equals to a % b == 0 in other languages
function mod_zero(a,b)
   return a - flr(a/b)*b == 0
end
__gfx__
00000000fffcc5fffff665fffff776ff6666666666666666555555555000000055555555ffffffff0000000000000000ffffffffffffffffffffffffffffffff
00000000ffcccc5fff6fff5fff77776f5555555555555555555555555000000000000000ffffffff0000000000000000ffffffffffffffffffffffffffffffff
00700700fcc5fcc5f6fffff5f776f776dddddddddddddddd555555557000000011111111ffffffff0000000000000000f22222ff221111111fffffffffffffff
00077000fc5cc5c5f6fffff5f7677676dddddddddddddddd555556667000000011111111ffffffff0000000000000000f55221121cc21cc7c7cfffffffffffff
00077000fffcc5fffff6f5fffff776ffdddddddddddddddd555566677000000011111111ffffffff0000000000000000fff51cc11ccc21cc7c7cffffffffffff
00700700fffcc5fffff6f5fffff776ffddddddddddddddddff55667f0000000011111111ffffffff0000000000000000fff2ccc121ccc21c11c7111122ffffff
00000000fffcc5fffff655fffff776ffddddddddddddddddff55667f0000000011111111ffffffff0000000000000000f999222a1211222211112111111122ff
00000000ffffffffffffffffffffffffeeeeedddddddddddff55667f0000000011111111ffffffff000000000000000088821111aaaaaa911111121111111122
55555555ffffffffffffffffffffffff55555dddddddddddff55667f5555555511111111fff5effffff5efff0000000082211111112111199999212111111189
00000000fffcc5ffff66fffffff776ffddddddddddddddddfff555ff5555555511111111ff55eeffff55eeff0000000012111111111211115222111211112212
11111111ffcc5ffff6ffffffff776fffddddddddddddddddfff566ff5555555511111111ff555effff55eeff00000000d1211222211211111111211122221112
11111111fcc5ccc56fff666ff7767776ddddddddddddddddfff556ff0000000011111111ffccccffffc5ecff00000000fd12265652211111111121225656211d
11111111fcc5ccc55fff555ff7767776ddddddddddddddddff55667f0000000011111111fff5effffff5efff00000000ffd216656612ddddddddd216656612df
11111111ffcc5ffff5ffffffff776fffddddddddddddddddff55667f0000000011111111fff5effffff5efff00000000ffff516661555555555555516661ffff
11111111fffcc5ffff55fffffff776ffddddddddddddddddff55667f0000000011111111fff5effffff5efff00000000fff5551115555555555555551115ffff
bbbbbbbbffffffffffffffffffffffffddddddddddddddddff55667fffffffff11111111fff5effffff5efff00000000ff5555555555555555555555555fffff
11111111ffffffffffffffffffffffff66666666fffffffffffffffffffffffffffffffffff5efffffffffff00000000ffffffffffffffffffffffffffffffff
11111111fffcc5ffffff66fffff776ff66666666fffffffffffffffffffffffffffffffffff5efffffffffff00000000ffccffffffffffffffffffffffffffff
11111111ffffcc5fffffff6fffff776f66666666f22222ff221111111ffffffffffffffffff5effffff9ffff00000000cccccffff7777777ffffffffffffffff
11111111fccc5cc5f666fff6f777677655555555f55221121cc21cc77c7ffffffffffffffff5effffff0ffff00000000fff11ffc6677777777ffffffffffffff
11111111fccc5cc5f555fff5f777677655555555fff51cc11ccc21cc77c7fffffffffffffff5efffff9a9fff00000000ff111111c66777116677ffffffffffff
11111111ffffcc5fffffff5fffff776f55555555fff2ccc121ccc21c117c111122fffffffff5efffff000fff00000000f111c1111c6666111666711cccccffff
11111111fffcc5ffffff55fffff776ff55555555f999222a1211222211112111111122fffff5effff9aaa9ff00000000aaaa1cc111ccccc11cc111111111ccff
11111111ffffffffffffffffffffffffffffffff88821111aaaaaa911111121111111122fff5efff1111111f000000008881111ccc11111ccccc1111111111cc
55555555ffffffffffffffffffffffffffffffff82211111112111199999212111111189fff5effffff5dfff0000000011111cc1111111111111c111111111a9
55555555fffcc5fffff665fffff776ffff8fff8f12111111111211115222111211112212fff5efff555ddddd000000001111c1111111111111111c1111cccc1c
55555555fffcc5fffff6f5fffff776ffff18f81fd1211222211211111111211122221112fff5effff555555f00000000c111c11111111111111111c11c111111
00000000fffcc5fffff6f5fffff776fffff181fffd12266562211111111121226566211dfff5effff5dddddf00000000fcc11ccccc1111111111111ccccc11cc
00000000fc5cc5c5f6f6f5f5f7677676fff818ffffd216565612ddddddddd216565612dffff5effff555dddf00000000ffccc56665c1ccccccccc1c56665cccf
00000000fcc5fcc5f6fffff5f776f776ff81f18fffff516661555555555555516661fffffff5effff5dddddf00000000fffff56665fffffffffffff56665ffff
00000000ffcccc5fff6fff5fff77776fff1fff1ffff5551115555555555555551115fffffff5effff55d5ddf00000000ffffff555fffffffffffffff555fffff
fffffffffffcc5fffff665fffff776ffffffffffff5555555555555555555555555fffffff5eeefff5dddddf00000000ffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2effffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffeeeeeeffffffffffffffffffffffffffffffffffffffffffffffffffffff22effffffffffffeeeeefffffffffffffffffffffffffeeeeeffffff
ffffffffffff222222effffffffffffeeeeeeeefffffffffffffffffffffffffffffffff22efffffffffeee222222efffffffffffffffffffffff22222efffff
ffffffffffff222222effffffffffff22222222efffffffffffffffffffffffffffffffff2efffffffff222200002efeffffffffffeffffffffff22222efffff
eeffffffffff2200022efffffffffff20000002efffffffffffffffffffffffffffffffff2efffffffff200000002ef2fffffffffffeeefffffff22002effeee
22efffeeee000222222efffffffffff20000002effffffffffffffffffffffffffffffff22eff22ffff2200000002ef2efffffffff20220effff202222eff222
22efff2222e00220022efffffffffff20000002efffffffffffeefffffffffffffffffff22eff22eeeee000000002e202effffffff202202efff202202eff222
02efff20002e0222222e00eeeefffff00000002efffffffffff2efffffffffffffffffff220ff2222222e00000002e202effffffff202202efff202222eff220
22efff20002e0022222e00220effff220000002eeffffffffff2eeefffffffffeffffff2222e02200202eeee00002e202effffffff202202efff202222eff222
02e0e020002e0022222e00220e0000220000002eeefffffffff222effffffffeeefffff2022e02220202e22200002e202effffffff202202efff202222eff222
22e02020002e0022222e00220220e022000000222efffffeee0222effffffff222effff2020e02020202e222e0002e202efeefffff202202eff2002222eef222
22e02000002e0022222e00220220e022000222202efffff0000222effffffff222effff2020e02020202e222e0002e202ef22effff000002eff2002222e2f222
222e2222002e0022222e00220220e022000222202eeefff2222222effffffff222effff2020002020202e0202e002e202e222effff2222200ff2002200e2f222
222e2222002e0022222e00220220e022000222202ee2eef2000202effffffff002efff220222e2020202e2222e002e2022202effff2222220ff2002002e22222
202e2222002e00022222e02000000022000220202e02eef2000222effffffff222eff2200222ee020202e2222e00222022022effff2222222022222000e00222
202e2222002e00020022e02022222022000222202e02eee2000202effffffff222ef000022222e020202e0202e00220022222effff2222220022eeeee0e20222
222e2220002e00022222e02022222022000220202e02222e000222e0eeeeee0222e0022222222e020202e22ee2e0220202002effff220002e02222222e222020
222e2220002e00220022e02022222022000222202e02222e000222e022222202222e002200022e220202e22222e0220220222effff222222e02222222e222020
202e2220002e00222222e02022222022002222202e02222e00022202222222020022e00022222e222202e22002e0220200002efffe222002e00200022e222020
20222220022eee222022e0202222202200222202e002222e000222020202020202222e2222222e222202ee22222e220222022efee0222222e02222222e222020
202002200222222220222e202222202200220202ee22222e000222022222220002222e2222222e2222222e20202e22020222222020222222e02222222e222202
202222202222222220222222222222220222022222222222200220022020220022222e2222222e2222222e20222e22022222222000222222e022200222222202
202220002222222220222222222222220222022222222222020200022002220220022e2222222e2202222e20222e22020222222020222222e022222222222202
20222220222222222222222222222222222202222222222202020000002222222222222222222e2222222e202222e20222222220222222220222222222222202
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffcccccfffffffffffffffffffbcffffffffffffffffffffffffffffffbccfffffff
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbccccccfffffffffffffffffb1cfffffffffffffffffffffffffffffb1cccffffff
fffffffffffffccfffffffffffffffffffffffffffffffffffffffffffffb111cccccfffffffffffffffb11ccfffffffffffffffffffffffffffb11ccccfffff
ffffffffffffbbccffffffffbbfffffffffffffffffffffffffffffffffb1111111cccffffffffffffbb111ccffffffffffffffffffffffffffb111ccccfffff
fffffffffffb11cccffffffb11cfffffffffffffffffffffffffffffffb111111cccccccfffffffffb11111ccffffffffffffffffffffffffbb111ccccccffff
ffffffffffb111ccccfffbb111ccfffffffffffffffffffffffffffffb111111cccccccccfffffffb111111cccffffffffffffffffffffffb11111cccccccfff
fffffffffb11111ccccbb11c11ccffffffffffffffffffffffffffffb111111cccc111ccccfffffb1111111ccccffffffffffffffffffffb1111111ccccccccf
ffffffffb111111cccc11111ccccfffffffffffffffffffffffffbbb11111ccccccc1111cccccccc1111111cccccffbcffffffffffffffb1111ccccccc1ccccc
cffffffb111ccccccccc111c11cccffffffbcffffffffffffffbb1111111111cccccccc11cccccc11111111ccc1ccb1ccffffffffffffb1111cccccccc111ccc
ccffff1111ccccccccccc11111ccccffffb1ccffffffffffffb11111111111111111ccccccccc11111111111ccc1cc11ccfffffffffffb1111111111ccc111cc
1ccc11111ccccccccccccc11111cccfffb11cccffffffffffb11111111c11111111111cccccc111111111c111cc11cc11cfffffffffffb11111111111cccc111
111cc1111111cc11cccccccc1c111cccb111ccccffffffffb11111111ccc1111111111ccc111111111111c1111cc11cc1ccfffffffbbb1111c1111111111c111
11111111111c11111cccccccc111111c11c1cccccffffffb111111111ccc11111111cccccccccccc111cc1111111c11cc1cfffbbbb111111cc1c1ccc111ccc11
1111111111c1111111cccccccc111111111cccccccccccb111111111c1cc11111111ccccccccc11111c1cc1111111c11c11bbb111111111111111111c111cc11
1111111111111111111cccccccc111c1111c11ccccccccc111111111cc1c111111111ccccc11111111111ccccc111cc111111111111111cc11111111111111c1
c111111111111111cccccccccccc11cc111111cccccc1111111111ccc1c1c11111111ccc111111111111ccccccccccccc1111111111111cccc111ccccccccc1c
cc111111111c11ccccccccccccccc111c11111ccc1111111111111cccc1c1111111ccccc1ccc11111111ccccccccc1ccccccccc111111ccccccccccccccc111c
ccccccc1cccc1ccccccccccccccccc111c11111cc111111111111cccc1c1c111cccccccccccccc1111111111c111cccccc11cccc1cccccccccccc11111111ccc
cccccccccccccccccccccccccccccccc11cc111ccc1111111111ccccc1c11111c111111111cccccc11111111cc11111cccccc11111111111111111cccccccccc
1111cccccccccc11111111ccccccccccc11c1111ccc111111111cccccc1c1111111111111111111cc111111111cc1111111cccccccc11111111111111111ccc1
1cccccccccc11111111111cccccccccccc1c11111ccc1111111ccccc111ccc111111111111111111cccccc11111111cc111111111111cc11111111111111cc11
cccccccc111111111111cccccccccccccccc1111111cc11111ccccc11111cccc1111111111111111cccccccc111111cccc111111111111111ccccccccccc11cc
ccccc111111111111ccccccccccccccccccccc111111ccc11ccccc11111111ccccc1111111111111cccccccccc11111cccccc1111111111111111111cccccccc
cccc11cccccccccccccccccccccccccccccccccc111111c1cccc11111111111cccccccccc11111111cccccccccccc11ccccccccc11111111111111111111cccc
55666666666666666666666666666666666666666666666666666666666666550eeeeeeeeee0eeeeeeeeeee0eeeeeeeeeeeeee00000000000000000000000000
5566666666666666666666666666666666666666666666666666666666666655ee22222eee002222222e2220222222e222222200000000000000000000000000
5566666660000000200000002000006666666666600000000000000000666655ee000002e20e0e000e0e0e00e00000e0e0000000000000000000000000000000
55666666200000002000000020000006666666660000000000000000000666552ee00000e00e0ee00e0e0e00e0eee0e0e0eeee00000000000000000000000000
556666602000000020000000200000006666666000000000000000000000665502eee000e00e0ee00e0e0e00e0e220e0e0e22200000000000000000000000000
55666660200000002000000020000000666666600000000000000000000066550022ee002eee0eee0e0e0e00e0e000e0e0e00000000000000000000000000000
5566666020000000200000002000000066666660000000000000000000006655000022e002e20e2e0e0e0eeee0eee0e0e0e00000000000000000000000000000
5566666020000000200000002000000066666660000000000000000000006655000000ee00e00e0eee0e0e00e0e220e0e0e00000000000000000000000000000
55666660200000000000000000000000666666600000000000000000000066550ee0002ee0e00e02ee0e0e00e0e000e0e0e00000000000000000000000000000
55666662222222220000000000000000666666650000000000000000000566550eeeeeeee0e00e002e0e0e00e0eee0e0e0eeee00000000000000000000000000
55666660200000000000000000000000666666655000000000000000005666550222222220200200020202002022202020222200000000000000000000000000
55666660200000000000000000000000666666665555555555555555556666550ccc1c100c1ccc1ccc1cc01ccc1c1c001c1ccc00000000000000000000000000
55666660200000000000000000000000666666666666666666666666666666550c1c1c100c1c100c1c1c1c1c1c1c1c001c1c0000000000000000000000000000
55666660200000000000000000000000666666666666666666666666666666550c1c10c1c10cc10cc11c1c1cc01c01c1c01cc000000000000000000000000000
55666660200000000000000000000000666666666666666666666666666666550c1c10c1c10c100c1c1c1c1c1c1c01c1c01c0000000000000000000000000000
55666660200000000000000000000000666666666666666666666666666666550ccc100c100ccc1c1c1cc01c1c1c001c001ccc00000000000000000000000000
55666660000000000000000020000000666666666666665500000000000000000000000000008c00000000000000000000000000ccc888800000000000000000
55666662000000000000000022222222666666666666665500000000000000000088000000088cc0000000000000000000000001111111110000000000000000
5566666000000000000000002000000066666666666666550000000000000000888880000777777700000000000000000050001ccccc7c771000500000000000
556666600000000000000000200000006666666666666655000000000000000000066001667777777700000000000000005501ccccc7c77cc105500000000000
55666660000000000000000020000000666666666666665500000000000000000066666616677788667700000000000000001ccccc7c77ccc710000000000000
55666660000000000000000020000000666666666666665500000000000000000666166661666688866676611111000000556111111111111165500000000000
5566666000000000000000002000000066666666666666550000000000000000aaaa811666111118811668888888110005888166666666666188850000000000
55666665000000000000000020000005666666666666665500000000000000008886688111888881111166666668881157988816666666661888975000000000
5566666650000000200000002000005666666666666666550000000000000000666661188666666666661666666666a916798881666666618889761000000000
55666666655555555555555555555566666666666666665500000000000000006666166666666666666661666611116116677711111111111777661000000000
55666666666666666666666666666666666666666666665500000000000000001666166666666666666666166166666616666615151515151666661000000000
55555555555555555555555555555555555555555555555500000000000000000116611111666666666666611111661116666615151515151666661000000000
00000000000000000000000000000000000000000000000000000000000000000011156665161111111116156665111001666661515151516666610000000000
00000000000000000000000000000000000000000000000000000000000000000000056665000000000000056665000005111111111111111111150000000000
00000000000000000000000000000000000000000000000000000000000000000000005550000000000000005550000005555000000000000055550000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000556000000000000055600000000000
__sfx__
011000000935509355153551535509355093551535515355093550935515355153550935509355153551535509355093551535515355093550935515355153550935509355153551535509355093551535515355
011000002855028550215002855021500215002855028550005000050028500005000050000500285002850026500265002150026500215002150026500265000050000500265000050000500005002855000500
011000002655026550265002655026500245002655000500000000000026550000002650024500265002650028550285502b500285502b5002b5002855028550285502855528550005002b5502b5502b5502b550
011000001c2650000521265000051c26526265000051c26528265000001c26526265000001c26524265232651a265002001e265002001a26521265002001a26524265002001a26521265002000e2651a2650e265
011000001c2521c25221252212521c25223252232521c25224252242521c25226252262521c25024250232502425023250212502125521250212501f255212522125221252152511525221251212522125221255
011000001a2521a2521e2521e2521a2521f2521f2521a25221252212521a2521f2521f2521a2501c2501a250152501c2551c2501c2551c2501c2551a2551c2521c2521c2521c2511c2521c2521c2521c2521c255
011000000c073000003c6250000026653266103c625000000c073000003c6250000026653266103c625000000c073000003c6250000026653266103c625000000c073000003c625000002665326610000003c625
0110000002355023550e3550e35502355023550e3550e35502355023550e3550e35502355023550e3550e35502355023550e3550e35502355023550e3550e35502355023550e3550e35502355023550e3550e355
011000000435504355103551035504355043551035510355043550435510355103550435504355103551035504355043551035510355043550435510355103550435504355103551035504355043551035510355
011000002835028340283302832028315000000000000300003000030028350003002635024350003002b3502b3402b3302b3202b3150000000000000000030000300003002635000300283502a3500030000300
011000002d3502d3402d3302d3202d3102d3152a3502a3402a3302a3202a3102a31532350323403233032320323103231032315003002b3502b3402b3302b3252d3502d3402d3302d3252a3502a3402635026345
011000002835028355243502435521350213552635026350263502635521350213551f3501f3552435024350243502435521350213551c3501c355233502335023350233551f3501f3551a3501a3501a3501a355
01100000213502134021330213202131021310213150030000300003001c3501c3551e3501e355203502034020330203202031020310203150030000300003000030000300282552b2552d255322553425537255
01100000307502f7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7522d755267522675528752287552b7522b755
011000003c2553b25539255342552d2553025534255302553225534255372553225534255372553b255372553c2553b25539255342552d2553025534255302553225534255372553225534255372553b25537255
011000003c2553b25539255342552d2553025534255302553225534255372553225534255372553b255372553c2553b25539255342552d2553025534255302553e2553c2553b25537255342553c2553b25537255
011000003c2553b25539255342552d2553025534255302553225534255372553225534255372553b255372553c2553b25539255342552d2553025534255302553c2553b25539255342552d255302553425530255
011000002677026760267502674026730267252177021760217502174021730217252a7702a7602a7502a7402a7352a7252a71500700007000070000700007000070000700007000070026770267602675026745
0110000000700007000070000700007000070021770217702877128760287501a74126770267752b7702b7702b7602b7602b7502b7502b7402b7402b7302b7350070000700217700070024770267702676026755
01100000287702876028750287402873028725267702676026750267402673026725247702476024750247402473024725237702376023750237402373023725217702176021750217451f7701f7601f7501f745
011000002177021760217502174021730217251e7701e7601e7501e7401e7301e7251a7701a7601a7501a7401a7301a7251577015760157501574015730157252177021775267702677528770287752b7742b770
011000002135028350283502135026350263502135024350243502135024350243502135024350003002435000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002145021450214502045020450204501f4501f4501f4500000018450000000000018455000001845000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000655000000000000655000000000000655000000000000655000000065500000006550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000c0532b653000000c0532b653000000c0532b65300000000000c0530c0532b6530c0532b6530c05300000000000000000000000000000000000000000000000000000000000000000000000000000000
01100000307502f7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d750
011000000c073000003c6250000026653266103c625000000c073000003c6250000026653266103c625000000c07300000000003c62526653266103c625000000c07300000000003c62526653266103c62500000
0110000002355023550e3550e35502355023550e3550e35502355023550e3550e35502355023550e3550e35502355023550e3550e35502355023550e3550e3550435504355103551035504355043551035510355
01100000302552f2552d255282552125524255282552425526255282552b25526255282552b2552f2552b2552145021450214502045020450204501f4501f4501f45000000184500000000000184550000018450
0110000002355023550e3550e35502355023550e3550e35502355023550e3550e35502355023550e3550e35506550000000000006550000000000006550000000000006550000000655000000065500000000000
011000000c073000003c6250000026653266103c625000000c073000003c6250000026653266103c625000000c0532b653000000c0532b653000000c0532b65300000000000c0530c0532b6530c0532b6530c053
01100000307502f7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d7502d75021350283502835021350263502635021350243502435021350243502435021350243500030024350
011000000935509355153551535509355093551535515355093550935509355093550935509355093550935502355023550e3550e35502355023550e3550e3550235502355023550235502355023550235502355
011000000000000000000000000000000000000000000000020000000000000000000200000000000000000002073000001a673000000207300000020731a6750000000000050731a675020731a6751a6731a675
011000000c073000003c6000000026653266103c600000000c073000003c6000000026653266103c600000000c073000003c6000000026653266103c600000000c073000003c600000002665326610000003c600
011000001c2650000021265000001c26523265000001c26524265000001c26526265000001c26524265232652426523265212650000021265000001f265212522125221252152511525221251212522125221255
011000001a2651e2001e265000001a2651f265000001a26521265000001a2651f265000001a2651c2651a265152651c2651c265000001c265000001a2651c2521c2521c2521c2521c2521c2521c2521c2521c255
01120000095530000000000000001a673186150000000000095530000000000000001a673186150000000000095530000000000000001a673186150000000000095530000000000000001a673186150000000000
011200001c25521255282551c25521255282551c25521255282551c25521255282551c2552125528255212551c25521255282551c25521255282551c25521255282551c25521255282551c255212552825521255
011200001c4721c4621c4521c4421c4321c4221c4121c4151f4521f4521f4521f452214522145221452214521a4721a4621a4521a4421a4321a4221a4121a415234722346223452234421f4721f4621a4721a462
01120000043550435510355103550435504355103551035502355023550e3550e35502355023550e3550e35501355013550d3550d35501355013550d3550d35501355013550d3550d35502355023550e3550e355
011200001e4721e4621e4521e4421f4721f4621e4721e4621c4721c4621a4721a4621a4521a4521c4721c46219472194621945219452194521945219452194521a4721a4621a4521a4521a4521a4521a4521a452
011200001c4721c4621c4521c4421c4321c4221c4121c4121e4721e4621e4521e4421e4321e4221e4121e4121f4721f4621f4521f4421f4321f4221f4121f4122147221462214522144221432214222141221412
01120000234722346400000234722346023452234522345221472214640000021472214622145221452214521f4721f474000001f4721f4621f4521f4521f4522147221464000002147200000194521c4521f452
01120000234722346400000234620000023465234600000000000234001f4520000021452214552145221455214722146400000214620000021465214600000000000234001c452000001e4521e4551e4521e455
01120000234722346400000234620000023465234600000000000234001f4520000021452214552145221455214722146400000214620000021465214600000000000234001c452000001f4521e4551c4521a455
011200001c4521c4521a4521a4521c4521c4551c45200000000001c45200000000001c452000001c452000001c4521c4521a4521a4521c4521c4551c452000001c45200000000001c452000001c4521c45200000
011200001c4521c4521a4521a4521c4521c4521a4521c4521c452000001c452000001c45200000000001c45200000000001c45200000000001c45200000000001c45200000000000000000000000000000000000
011200000000000000234702346023450234502345023450234402344023430234302343023430234302342023420234202342023420234102341023410234102341023410234102341023415000000000000000
0111000000000000001c4701c4601c4501c4401c4301c4301c4301c4301c4301c4301c4201c4201c4201c4201c4201c4101c4101c4101c4101c4101c4101c4101c4101c415000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800002725029450274502945027450294502745029451274502745027450274402744027430274302742027420274202741027410274102741027410274102741027410274102741000000000000000000000
__music__
00 20414603
00 20424303
00 20014641
00 20022107
01 00010604
00 07020605
00 00010604
00 07020605
00 00120609
00 0711060a
00 0013060b
00 0714060c
00 000e060d
00 070f060d
00 000e060d
00 1d1c1e1f
00 20474603
00 20404303
00 00074323
00 07002124
00 000e0604
00 070f0605
00 000e0604
00 07100605
00 00234309
00 0724430a
00 0023430b
00 0745210c
00 000e220d
00 0710220d
00 000e470d
00 070f000d
03 410e4344
04 41104344
01 25264367
00 25262844
00 25262827
00 25262829
00 25262827
00 2526282a
00 2526282b
00 2526282b
00 2566282b
00 2526686b
00 2566286b
00 2526282c
00 2526282c
00 2526282d
00 2526282e
00 2526282f
00 6526286f
00 2526282d
04 41314330


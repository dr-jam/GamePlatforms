pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--------------------------------------------------------------------------------
-- acknowledgements
    -- misato for the base game outline
    -- advanced micro platformer - starter kit by mhughson
        -- https://www.lexaloffle.com/bbs/?pid=37158#p37402

--------------------------------------------------------------------------------

game_states = {
    splash = 0,
    level1 = 1, --
    level2 = 2, -- dungeon
    level3 = 3, -- factory
    level4 = 4, -- factory escape
    lose_screen = 5,
    win_screen = 6,
    loading_screen = 7,
}

cam = {
  x = 0,
  y = 0
}

-- setting this to true shows the instructions menu and siabled the current state's updates and draws
is_showing_instructions = false
instructions_page = 0
num_instruction_pages = 2  -- how many pages to cycle through

state = game_states.splash
num_lives = 3
next_state = game_states.splash -- level to load after loading screen

loading_end_time = 0 -- keeps track of when loading screen ends automatically
loading_time = 12 -- 2/3rds the time is story background, and the other 1/3 is the episode title

function change_state(desired_state)
  cls()
  camera(0,0)
  cam.x = 0
  cam.y = 0
  enemycount = 0
    -- if loading a level that's not the win, lose, or splash screen, show the loading screen before hand
    -- change music based on desired scene as well
    if state != game_states.loading_screen and is_battle_state(desired_state) then
        -- requesting a new level but not in loading screen yet
        loading_end_time = time() + loading_time -- wait loading_time seconds before automatically moving on
        change_music(music_states.loading_screen)
        next_state = desired_state -- store the desired scene
        state = game_states.loading_screen -- and go to loading screen instead
    elseif state == game_states.loading_screen and is_battle_state(desired_state) then
        init_game()

        if desired_state == game_states.level1 then
            change_music(music_states.city)
        elseif desired_state == game_states.level2 then
            change_music(music_states.dungeon)
        elseif desired_state == game_states.level3 then
            change_music(music_states.factory)
        elseif desired_state == game_states.level4 then
            -- todo speed up this
            change_music(music_states.factory)
        end
        state = next_state
    elseif desired_state == game_states.splash then
        num_lives = 3
        state = game_states.splash
        change_music(music_states.splash_screen)
    elseif desired_state == game_states.lose_screen then
        state = game_states.lose_screen
        change_music(music_states.lose_screen)
    elseif desired_state == game_states.win_screen then
        state = game_states.win_screen
        change_music(music_states.win_screen)
    else
        -- unrecognized state
        throw("unrecogonized state")
    end
end


function is_battle_state(desired_state)
    return desired_state == game_states.level1 or desired_state == game_states.level2
      or desired_state == game_states.level3 or desired_state == game_states.level4
end

--------------------------------------------------------------------------------
---------------------------------- animation -----------------------------------
--------------------------------------------------------------------------------
actor = {} -- initalize the sprite object
actor.sprt = 0 -- sprite starting frame
actor.idletmr = 1 -- internal timer for managing animation
actor.flp = false -- used for flipping the sprite

function idle()
  actor.idletmr = actor.idletmr+1 -- interal timer to activate waiting animations
  if actor.idletmr>=10 then -- after 1/3 of sec, jump to sprite 6
    actor.sprt = 8
  end
  if actor.idletmr >= 60 then -- after 2 sec jump frame 8
    actor.sprt = 9
  end
  if actor.idletmr >= 62 then -- and jump back to frame 6,
    actor.sprt = 8
    actor.idletmr = 0 -- restart timer
  end
end

function block()
  actor.sprt = 6
  actor.idletmr = 0
  actor.sprt += sprite_animator(1)
  if actor.sprt>=8 then
    actor.sprt = 7
  end
end

function kick()

  -- play attack sound
  play_sound_effect(sound_effects.player_attack)

  actor.sprt = 11
  actor.idletmr = 0
  actor.sprt += sprite_animator(1)
  if actor.sprt>=13 then
    actor.sprt = 12
  end

  -- play attack sound
  play_sound_effect(sound_effects.player_attack)

  if actor.flp == true then
    if player.x-4 <= 0  or (solid(player, player.x-6, player.y-0.5, 1)) then
      player.x = player.x
    else
      player.x -= 6
    end
  else
    if (solid(player, player.x+6, player.y-0.5, 1)) then
      player.x = player.x
    else
    player.x += 6
    end
  end

  obs_collision(allninjas, player)
  obs_collision(allzombies, player)
  obs_collision(alldeities, player)
end

function punch()

   -- play attack sound
   play_sound_effect(sound_effects.player_attack)
   actor.sprt = player.combo.sprt
   actor.sprt += sprite_animator(0.2)
   actor.idletmr = 0
   if actor.sprt>=7 then
     actor.sprt = 4
   end

   -- play attack soundn
   play_sound_effect(sound_effects.player_attack)

  if actor.flp == true then
    if player.x-4 <= 0  or (solid(player, player.x-4, player.y-0.5, 1)) then
      player.x = player.x
    else
      player.x -= 4
    end
  else
    if (solid(player, player.x+4, player.y-0.5, 1)) then
      player.x = player.x
    else
    player.x += 4
    end
  end

  obs_collision(allninjas, player)
  obs_collision(allzombies, player)
  obs_collision(alldeities, player)
end


function sprite_animator(x) -- this function receives the number of frames to animate by, increaments by the supplied amount and returns the value back calling user input function
 local y = 0
 y += x
 return y
end

--------------------------------------------------------------------------------
---------------------------------- player --------------------------------------
--------------------------------------------------------------------------------
function make_player(x,y)
  local p = {
    tag=1,
    x=x,
    y=y-8,
    dx=0,
    dy=0,
    gravity=0.15,
    combotimer = 30,
    kicktimer = 10,
    incombo = false,
    last = false,
    combo = root,
    isgrounded = false,
    hearts=3,
    time=0
  }
  return p
end

-- player input

function move_player()

  accel = 0.25

  --idle
  idle()

  if btn(3) then
    if outter == 9 then
        play_sound_effect(sound_effects.shield_activate)
    elseif outter < 8.8 and outter > 0 then
        play_sound_effect(sound_effects.shield_hold)
    end
    if outter > 0 and inner  > 0 then
        blocking = true
    else blocking = false
    end
    outter -= .05
    inner -= .05
    block()

    -- player control
  elseif btn(4) or btn(5) then
    if player.last == false then
      --do the thing here
      player.combotimer = 30
    player.incombo = true
    player.last = true

      if btn(4) then
        if #player.combo.attac == 4 then
          player.combo = root.left
          player.combotimer=30
        else
          player.combo = player.combo.left
        end
        punch()

      end

    if player.kicktimer == 10 then
      if btn(5) then
            if #player.combo.attac == 4 then
                player.combo = root.right
                player.combotimer=30
            else
                player.combo = player.combo.right
            end
            kick()
            player.kicktimer -= 1
        end
end
    end
    else player.last = false
    blocking = false
    outter = 9
    inner = 6
    if player.kicktimer < 10 then
            player.kicktimer -= 1
        if player.kicktimer <=  0 then
            player.kicktimer = 10
            end
      end
    -- move player left
    if (btn(0)) then
      player.dx = player.dx - accel

      actor.flp = true -- flip the direction of the sprite
      actor.sprt+=sprite_animator(0.2)
      actor.idletmr = 0


      if actor.sprt>=4 then
          play_sound_effect(sound_effects.footstep) -- play walking sound
        actor.sprt = 0
      end
    end
    -- move player right
    if (btn(1)) then
      player.dx = player.dx + accel

      actor.flp = false -- set default direction of sprite
      actor.sprt += sprite_animator(0.2) -- animate the sprite by calling the sprite_animator function
      actor.idletmr = 0 -- reset internal timer
      if actor.sprt>=4 then -- set the max number frames to animate
          play_sound_effect(sound_effects.footstep) -- play walking sound
        actor.sprt = 0 -- reset the frame number, creating a loop
      end
    end
  end

  -- gravity and friction
  --if not solid_tile(player.x, player.y + 9, 1) then
  --  player.dy+=player.gravity
  --  player.dy*=0.95
  --  player.isgrounded = false
  --else
  --  player.isgrounded = true
  --  player.dy=0
  --end

  -- player jumping
  if (btn(2)) then
        if jumplast == false then
        jumplast = true
        if player.isgrounded then
            play_sound_effect(sound_effects.player_jump) -- play jump sound
        player.dy-=4
        end
        end
else
  jumplast = false
      end

  -- x friction
  player.dx*=0.8

  -- if ((btn(4) or btn(2)) and pl.standing) then
  --   pl.dy = -0.7
  --end

  --player.x+=player.dx
  --player.y+=player.dy
  --player.dy = player.dy * -0.7

  --if player.y >= 120 then
    --player.y = 120
  --end
  player.time+=1

  if dmgtimer > 0 then
        dmgtimer -= 1
    end

  if(brawl_clear == false and brawl_spawn == true) then
    if player.x <= brawl_bounds.x - 88 then
      player.x = brawl_bounds.x - 88
    end
    if player.x >= brawl_bounds.x + 31 then
      player.x = brawl_bounds.x + 31
    end
  end

  if player.hearts == 0 or (player.y >= 150 and player.y <= 155 and zone == 1) or (player.y >= 260 and player.y <= 265 and zone == 2) then
    num_lives -= 1
    if num_lives <= 0 then
        change_state(game_states.lose_screen)
    else
        -- new life
        reset_checkpoint()
    end
  end

  --testing!!!!
  -- if (player.x >= 150 and player.x <= 155 and zone == 1) then
  --   player.x=40*8
  --   player.y=21*8
  --
  --   cam.x = 296
  --   cam.y = 16*8
  --   zone = 2
  --   ninjaspawn = 0
  --
  --   cur_checkpoint.x = 44*8
  --   cur_checkpoint.y = 20*8
  --
  --   brawl_spawn = false
  --
  --   instantiate_level_obs()
  -- end


  if(solid(player, player.x, player.y-0.5, 7) and zone == 1) then

    player.x=40*8
    player.y=21*8

    cam.x = 296
    cam.y = 16*8
    zone = 2
    ninjaspawn = 0

    cur_checkpoint.x = 39*8
    cur_checkpoint.y = 20*8

    brawl_spawn = false
    -- delete level objects and recreate them
    delete_level_obs()
    instantiate_level_obs()
  end
  if(solid(player, player.x, player.y-0.5, 7) and zone == 2 and dz.health <= 0) then
    change_state(game_states.win_screen)
  end

  handle_combo()

end

function handle_combo()
  if player.incombo == true then
   player.combotimer -= 1
  end

  if player.combotimer==0 then
   player.combotimer=30
   player.incombo = false
   player.combo = root
  end
end

function solid(obs, x, y, tag)
  if ((obs.tag == 1) or (obs.tag == 2)) or (obs.tag == 6) or (obs.tag == 7) or (obs.tag == 8) then
    local tilex1 = ((x - (x % 8)) / 8)
    local tilex2 = ((x - (x % 8) + 8) / 8)
    local tiley1 = ((y - (y % 8)) / 8)
    local tiley2 = ((y - (y % 8) - 8) / 8)
    if (fget(mget(tilex1, tiley1), tag)) or (fget(mget(tilex2, tiley1), tag)) or (fget(mget(tilex1, tiley2), tag)) or (fget(mget(tilex2, tiley2), tag))then
      return true
    else
      return false
    end
  elseif (obs.tag == 3) or (obs.tag == 4)  then -- 8x8 collision
    -- 4 is hearts, 6 is checkpoints
    local tilex1 = ((x - (x % 8)) / 8)
    local tiley1 = ((y - (y % 8)) / 8)
    if (fget(mget(tilex1, tiley1), tag)) then
      return true
    else
      return false
    end
  end
end

function obs_collision(obj1, obj2)
  for f in all(obj1) do
    if obj1.tag == 4 then
      if((f.y <= obj2.y) and (f.y >= obj2.y-16)) and ((f.x <= obj2.x+4) and (f.x >= obj2.x-4)) then
        if obj2.hearts < 3 then
          play_sound_effect(sound_effects.health_pickup)
          obj2.hearts += 1
          if obj2.hearts > 3 then
            obj2.hearts = 3
          end
          del(obj1, f)
        end
      end
    elseif obj1.tag == 3 then
      if((f.y <= obj2.y) and (f.y >= obj2.y-16)) and ((f.x <= obj2.x+4) and (f.x >= obj2.x-4)) then

        play_sound_effect(sound_effects.explosion)
        del(obj1, f)
        if blocking == false then
          if obj2.hearts > 0 then
            taking_damage = true
            play_sound_effect(sound_effects.player_damaged)
            camera(cos(t/3), cos(t/2))
            obj2.hearts -= 0.5
          end
        else
         outter -= 4
          inner -= 4
        end
      end

    elseif obj1.tag == 2 or obj1.tag == 8 or obj1.tag == 7 then
      if((f.y <= obj2.y+8) and (f.y >= obj2.y-8)) and ((f.x <= obj2.x+8) and (f.x >= obj2.x-8)) then
        if actor.flp == true then
          if(f.x-6.5 <= 0 or solid(f, f.x - 6.5, f.y-0.5, 1)) then
            f.x = f.x
          else
            f.x -= 6.5
          end
        else
          if(f.x+6.5 <= 0 or solid(f, f.x + 6.5, f.y-0.5, 1)) then
            f.x = f.x
          else
            f.x += 6.5
          end
    end
        showdmg = true
        dmgtimer = 20
        dmg = {}
        dmg.x = f.x-2
        dmg.y = f.y - 22
        if(f.health) then
          f.health -= obj2.combo.dmg
          play_sound_effect(sound_effects.enemy_damaged)
        end
        if f.health <= 0 then
            del(obj1, f)
          end
      end

    elseif obj1.tag == 6 then
        -- obj1 is checkpoint
        if((f.y <= obj2.y+8) and (f.y >= obj2.y-20)) and ((f.x <= obj2.x+8) and (f.x >= obj2.x-8)) then
            if cur_checkpoint != f then
                play_sound_effect(sound_effects.checkpoint)
                cur_checkpoint = f
                f.sprite = 78
            end
        end
     end

    if (f.x<=0) del(obj1, f)
  end
end

function reset_checkpoint()
  change_music(music_states.city)
  play_sound_effect(sound_effects.level_start)
  player.hearts = 3
  player.x = cur_checkpoint.x
  player.y = cur_checkpoint.y

  -- reset enemies

  -- reset brawls
  brawl_clear = true
  brawl_spawn = false

  -- delete level objects and recreate them
  delete_level_obs()
  instantiate_level_obs()

  -- reset camera
  if cur_checkpoint.x <= 50 then
    cam.x = 0
  else
    cam.x = player.x
  end
end


function move_actor(actor)
  -- check actor tag
  -- 1: player
  -- 2: ninja
  -- 7: deityzilla
  -- 8: zombies

  if(actor.tag == 1) then
    move_player()
  end
  if (actor.tag == 2) then
    update_ninja(actor)
  end
  if(actor.tag == 7) then
    update_deityzilla(actor)
  end
  if(actor.tag == 8) then
    update_zombie(actor)
  end


  -- begin actor.x movement
  local x1 = actor.x + actor.dx + sgn(actor.dx)*0.3

  if(not solid(actor, x1, actor.y-0.5, 1)) then
    actor.x += actor.dx
  else
    while(not solid(actor, actor.x + sgn(actor.dx)*0.3, actor.y-0.5, 1)) do
      actor.x += sgn(actor.dx)*0.1
    end
    actor.dx = 0
  end
  -- end actor.x movement

  -- begin actor.y movement
  actor.isgrounded = false
  if (actor.dy < 0) then
    -- cieling collision detection
    if (solid(actor, actor.x-0.2, actor.y+(actor.dy-1), 1) or solid(actor, actor.x+0.2, actor.y+(actor.dy-1), 1)) then
      actor.dy = 0

      -- search up for collision point
      while ( not (solid(actor, actor.x-0.2, actor.y-8, 1) or solid(actor, actor.x+0.2, actor.y-8, 1))) do
        actor.y -= 0.01
      end
    else
      actor.y += actor.dy
    end
  else
    -- floor collision detection
    if (solid(actor, actor.x-0.2, actor.y+actor.dy, 1) or solid(actor, actor.x+0.2, actor.y+actor.dy, 1)) then
      -- if is jumping, don't change dy
      if (actor.dy > 3) then
        actor.dy = actor.dy
      else
        actor.isgrounded=true
        actor.dy = 0
      end

      -- remove ability to sneak through walls
      while (not (solid(actor, actor.x-0.2, actor.y, 1) or solid(actor, actor.x+0.2, actor.y, 1))) do
        actor.y += 0.05
      end
      while(solid(actor, actor.x+0.2,actor.y-0.1, 1)) do
        actor.y -= 0.05
      end
    else
      actor.y += actor.dy
    end
  end

  -- vertical friction
  actor.dy += actor.gravity
  actor.dy *= 0.95

  -- horizontal friction
  if (actor.isgrounded) then
    actor.dx *= 0.8
  else
    actor.dx *= 0.9
  end
end



-- pico8 game funtions

function _init()
    showdmg = false
    dmgtimer = 0
    t = 0
    taking_damage = false
    enemycount = 0
    zone = 1
    drawarrow = false
    -- checkpoint stuff
    cur_checkpoint = {x=21, y=1}
    brawl_bounds = {x=0}
    cls()
    camera(0, 0)
    change_music(music_states.splash_screen)
    menuitem(1, "controls", function() show_instructions() end)
end

function _update60()
    if is_showing_instructions then
        -- wait until instructions are closed
        update_instructions()
        return
    end
    if state == game_states.splash then
        update_splash()
    elseif state == game_states.loading_screen then
        update_loading()
    elseif is_battle_state(state) then
        update_game()
    elseif state == game_states.lose_screen then
        update_gameover()
    elseif state == game_states.win_screen then
        update_win()
    end
end

function _draw()
    cls()
        if is_showing_instructions then
        -- wait until instructions are closed
            draw_instructions()
        return
    end
    if state == game_states.splash then
        draw_splash()
    elseif state == game_states.loading_screen then
        draw_loading()
    elseif is_battle_state(state) then
        draw_game()
    elseif state == game_states.lose_screen then
        draw_gameover()
    elseif state == game_states.win_screen then
        draw_win()
    else
        assert("unknown scene to draw") -- throw aerror
    end
end

health_pack = {
  tag = 4
}

function update_health_pack(obj)
  obs_collision(health_pack, player)
  if not solid(obj, obj.x, obj.y+8, 1) then
    obj.y += 2 * obj.dx
  else
    if (t%25 == 0) then
      obj.y = obj.y-1
    end
  end
end

checkpoint = {
  tag = 6
}

function update_checkpoint(obj)
  obs_collision(checkpoint, player)
  if not solid(obj, obj.x, obj.y+16, 1) then
    obj.y += 2 * obj.dx
  end
end




------------------------------------------------ enemies

shuriken = {
  tag = 3
}

fireball = {
  tag = 3
}

allninjas = {
  tag = 2
}

allzombies = {
  tag = 8
}

alldeities = {
  tag = 7
}

function update_shuriken(obj)
  if t - obj.birthdate >= 500 then
    del(shuriken, obj)
  end

  -- deletes shurikens when they go off screen
  if(obj.dx < 0) then
   if (obj.x > (player.x + 128)) then
    del(shuriken, obj)
   end
  elseif (obj.dx > 0) then
   if (obj.x < (player.x - 128)) then
    del(shuriken, obj)
   end
  end

 if(t % 6 == 0) then
    if solid(obj, obj.x, obj.y, 1) then
      obj.x = obj.x
      obj.flip = false
    else
      obj.x -= 8 * obj.dx
    end
  if(obj.flip == true) then
   obj.flip = false
  else
   obj.flip = true
  end
 end
end

function update_fireball(obj)
  if t - obj.birthdate >= 500 then
    del(fireball, obj)
  end

  -- deletes fireball when it goes off screen
  if(obj.dx < 0) then
   if (obj.x > (player.x + 128)) then
    del(fireball, obj)
   end
  elseif (obj.dx > 0) then
   if (obj.x < (player.x - 128)) then
    del(fireball, obj)
   end
  end

 if(t % 6 == 0) then
    if solid(obj, obj.x, obj.y, 1) then
      obj.x = obj.x
      obj.flip = false
    else
      obj.x -= 8 * obj.dx
      obj.y -= 8 * obj.dy

    end
  if(obj.flip == true) then
   obj.flip = false
  else
   obj.flip = true
  end
 end
end

function draw_obj(obj)
   spr(obj.sprite, obj.x, obj.y, obj.width, obj.height, obj.flip)
end

function create_obs(obj, sprite, x, y, dx, tag, width, height)
  -- empty table to fill with below values
  local o = {}
  o.x = x
  o.y = y
  o.dx = dx
  o.dy = dx*dx*(rnd(0.5))-0.25
  o.sprite = sprite
  o.flip = false
  o.tag = tag
  o.birthdate = t

  o.width = width
  o.height = height

  add(obj, o)
  return o
end

function make_ninja(x,y, hp)
  local ninja = {
    tag=2,
    x=x,                 -- x position
    y=y,                 -- y position
    dx=0,
    dy=0,
    max_dx=.2,             -- max x speed
    p_speed=0.02 + (rnd(0.075)),         -- acceleration force
    drag=0.02,            -- drag force
    gravity=0.15,         -- gravity
    flip = false,  -- false == left facing, true == right facing
    health = hp,
    sprite = 67,
    is_throwing = false,
    is_walking = true,
    throw_mod = 250 + flr(rnd(150)),
    throw_timer = 0
  }
  add(allninjas, ninja)
  return ninja
end

function walk_ninja(ninja)
  if(ninja.is_walking) then
   if(ninja.dx == 0) then
    ninja.sprite = 64
    elseif(t % 10 == 0 and ninja.sprite != 72) then
      ninja.sprite = ninja.sprite + 1
    elseif(t % 10 == 0 and ninja.sprite == 72) then
      play_sound_effect(sound_effects.footstep)
      ninja.sprite = 67
    end
  end
end

function throw_ninja(ninja)
   if(ninja.is_throwing == true) then
    if(ninja.throw_timer == 0) then -- spawn a shuriken once animation finishes
    play_sound_effect(sound_effects.ninja_throw)
     if(ninja.flip) then -- facing right
      create_obs(shuriken, 79, ninja.x+4, ninja.y-10, -1, 3, 1, 1) 
     else -- facing left
      create_obs(shuriken, 79, ninja.x-4, ninja.y-10, 1, 3, 1, 1) 
     end
     ninja.is_throwing = false
        ninja.is_walking = true
     ninja.throw_mod = 250 + flr(rnd(200))
     ninja.sprite = 67
    elseif(ninja.throw_timer > 13) then
     ninja.sprite = 65
    elseif(ninja.throw_timer > 0) then
     ninja.sprite = 66
    end
    ninja.throw_timer -= 2
    elseif(t % ninja.throw_mod == 0) then -- cannot throw while previous throw is being completed
      ninja.is_throwing=true
      ninja.is_walking = false
      ninja.throw_timer =20
    end
end

function update_ninja(ninja)
  if(player.x < ninja.x and ninja.dx > -ninja.max_dx) then
   if((ninja.x - player.x) < 8) then
    ninja.dx = 0
   else
     ninja.flip = false
      ninja.dx-=ninja.p_speed
  end
  elseif(player.x > ninja.x and ninja.dx < ninja.max_dx) then
    if((player.x - ninja.x) < 8) then
    ninja.dx = 0
   else
     ninja.flip = true
     ninja.dx += ninja.p_speed
    end
  end

  ninja.dy+=ninja.gravity
  -- delete ninja if it falls into the abyss
  if((ninja.y >= 150 and ninja.y <= 155) or (ninja.y >= 260 and ninja.y <= 265) or ninja.health == nil) then
    del(allninjas, ninja)
  end
end

function draw_ninja(ninja)
    walk_ninja(ninja)
    throw_ninja(ninja)
   spr(ninja.sprite, ninja.x, ninja.y-16, 1, 2, ninja.flip)
end

function spawnbrawl(xlock, y_spawn)
  if brawl_spawn == false then
    brawl_spawn = true
    brawl_clear = false

    if (zone == 1) then
      enemycount = #allzombies
      enemycount += 1

      make_zombie(player.x - 50, y_spawn, 5)
      make_zombie(player.x + 50, y_spawn, 5)
      make_ninja(player.x - 100, y_spawn, 5)
      make_ninja(player.x + 100, y_spawn, 5)
      make_zombie(player.x - 25, y_spawn, 5)
      make_zombie(player.x + 25, y_spawn, 5)

    elseif(zone == 2) then
      enemycount = #allninjas
      enemycount += 1

      make_ninja(player.x - 50, y_spawn, 5)
      make_ninja(player.x + 50, y_spawn, 5)
      make_ninja(player.x - 100, y_spawn, 5)
      make_ninja(player.x + 100, y_spawn, 5)
    end

    if (xlock-cam.x>64+25) then cam.x+=1 end
    brawl_bounds = {x=xlock}
  end

  if not brawl_clear then
    if (zone == 1) then
      if #allzombies <= enemycount then
        brawl_clear = true
        enemycount = 0
        drawarrow = true
      end
    elseif (zone == 2) then
      if #allninjas <= enemycount then
        brawl_clear = true
        enemycount = 0
        drawarrow = true
      end
    end
  end
end

function make_zombie(x,y, hp)
  local zombie = {
    tag=8,
    x=x,                 -- x position
    y=y,                 -- y position
    dx=0,
    dy=0,
    max_dx=.2,             -- max x speed
    p_speed=0.02 + (rnd(0.075)),         -- acceleration force
    drag=0.02,            -- drag force
    gravity=0.15,         -- gravity
    flip = false,  -- false == left facing, true == right facing
    health = hp,
    sprite = 107,
    is_walking = true,
    throw_timer = 0
  }
  add(allzombies, zombie)
  return zombie
end

function update_zombie(zombie)
 if(t % 25 == 0 and zombie.sprite < 111) then
    zombie.sprite = zombie.sprite + 1
  elseif(t % 25 == 0 and zombie.sprite == 111) then
    --play_sound_effect(sound_effects.footstep)
    zombie.sprite = 107
  end

 if(t % 25 == 0) then
  if(player.x < zombie.x and zombie.dx > -zombie.max_dx) then
   if((zombie.x - player.x) < 8) then --player isnt moving, zombie stops at player location
    zombie.dx = 0
   else
     zombie.flip = false
     zombie.dx-=zombie.p_speed
  end
  elseif(player.x > zombie.x and zombie.dx < zombie.max_dx) then
    if((player.x - zombie.x) < 8) then
    zombie.dx = 0
   else
     zombie.flip = true
     zombie.dx += zombie.p_speed
    end
  end
end

  zombie.dy+=zombie.gravity
  if((zombie.y >= 150 and zombie.y <= 155) or (zombie.y >= 260 and zombie.y <= 265) or zombie.health == nil) then
    del(allzombies, zombie)
  end
end

function draw_zombie(zombie)
   spr(zombie.sprite, zombie.x, zombie.y-16, 1, 2, zombie.flip)
end

function make_deityzilla(x, y)
  deityzilla = {
    tag=7,
    x=x,                 -- x position
    y=y,                 -- y position
    dx=0,
    dy=0,
    max_dx=.2,             -- max x speed
    p_speed=0.02 + (rnd(0.075)),         -- acceleration force
    drag=0.02,            -- drag force
    gravity=0.15,         -- gravity
    flip = false,  -- false == left facing, true == right facing
    health = 50,
    sprite = 96,
    is_throwing = false,
    is_walking = true,
    throw_mod = 250 + flr(rnd(150)),
    throw_timer = 0,
    jump_timer = 50
  }
  add(alldeities, deityzilla)
  return deityzilla
end

function throw_deityzilla(deityzilla)
   if(deityzilla.is_throwing == true) then
    if(deityzilla.throw_timer == 0) then
      deityzilla.sprite = 104
      play_sound_effect(sound_effects.explosion)
     if(deityzilla.flip) then -- facing right
      create_obs(fireball, 95, deityzilla.x+4, deityzilla.y-14, -1, 3, 1, 1)
     else
      create_obs(fireball, 95, deityzilla.x-4, deityzilla.y-14, 1, 3, 1, 1)
     end
     deityzilla.is_throwing = false
    deityzilla.is_walking = true
     deityzilla.throw_mod = 250 + flr(rnd(200))
     deityzilla.sprite = 96
    elseif(deityzilla.throw_timer > 0) then
      deityzilla.sprite = 104
    end
    deityzilla.throw_timer -= 2
    elseif(t % deityzilla.throw_mod == 0) then -- cannot throw while previous throw is being completed
      deityzilla.is_throwing=true
      deityzilla.is_walking = false
      deityzilla.throw_timer = 20
    end
end

function update_deityzilla(deityzilla)
    if deityzilla.jump_timer <= 0 then
        deityzilla.jump_timer = 50
        deityzilla.dy -= 7
    else 
      deityzilla.jump_timer -= 1
    end
    
  throw_deityzilla(deityzilla)
   if(t % 15 == 0 and deityzilla.sprite < 102) then
      deityzilla.sprite = deityzilla.sprite + 2
    elseif(t % 15 == 0 and deityzilla.sprite == 102) then
      play_sound_effect(sound_effects.big_footstep)
      deityzilla.sprite = 96
    end

  if(player.x < deityzilla.x and deityzilla.dx > -deityzilla.max_dx) then
   if((deityzilla.x - player.x) < 8) then --player isnt moving, ninja stops at player location
    deityzilla.dx = 0
   else
     deityzilla.flip = false
      deityzilla.dx-=deityzilla.p_speed
  end
  elseif(player.x > deityzilla.x and deityzilla.dx < deityzilla.max_dx) then
    if((player.x - deityzilla.x) < 16) then
    deityzilla.dx = 0
   else
     deityzilla.flip = true
     deityzilla.dx += deityzilla.p_speed
    end
  end


  deityzilla.dy+=deityzilla.gravity

  if((deityzilla.y >= 150 and deityzilla.y <= 155) or (deityzilla.y >= 260 and deityzilla.y <= 265) or deityzilla.health == nil) then
    del(alldeities, deityzilla)
  end
end

spawncounter = 3

function update_enemies()

  if(zone==2 and player.x > 875 and spawn != 10000) then 
    dz = make_deityzilla(900, 230) 
    change_music(music_states.final_boss)
    spawn = 10000
  elseif(player.x >= spawn) then
    if (zone == 1) then
      if(spawncounter == 0) then
        make_ninja(player.x + 100, 0, 10)
        spawncounter = 3
      else
        make_zombie(player.x + 100, 0, 10)
        spawncounter -= 1
      end
      spawn += 20
      spawn += flr(rnd(100))
    elseif (zone == 2) then
       make_ninja(player.x + 100, 180, 10)
       spawn += 50
       spawn += flr(rnd(200))
    end
  end

  foreach(shuriken, update_shuriken)
  obs_collision(shuriken, player)
  foreach(fireball, update_fireball)
  obs_collision(fireball, player)
  foreach(allninjas, move_actor)
  foreach(allzombies, move_actor)
  foreach(alldeities, move_actor)
end


function draw_deityzilla(deityzilla)
   spr(deityzilla.sprite, deityzilla.x, deityzilla.y-16, 2, 2, deityzilla.flip)
end

function draw_enemies()
  foreach(allninjas, draw_ninja)
  foreach(allzombies, draw_zombie)
  foreach(alldeities, draw_deityzilla)
  foreach(shuriken, draw_obj)
  foreach(fireball, draw_obj)
end

------------------------------- end enemies

-- splash

function update_splash()
    -- usually we want the player to press one button
     if btnp(5) then
         change_state(game_states.level1)
     elseif btnp(4) then
         is_showing_instructions = true
     end
     t+= 1
end

function draw_splash()
  rectfill(0,0,screen_size,screen_size,1)
  local x = t / 8
  x = x % 128
  local y=0
  map(21, 16, -x, y, 16, 16, 0)
  map(21, 16, 128-x, y, 16, 16, 0)

  --static skyline
  palt(0, false)
  palt(1, true)
  pal(13,2)
  y = 0
  map(0, 17, 0, y-24, 128, 32)
  pal()
  palt(1,false)
  palt(0, true)

  palt(0, false)
  palt(1, true)
  map(0, 17, (-x)/2, y, 128, 32, 0x5)
  map(0, 17, 128-((x)/2), y, 128, 32, 0x5)
  palt(1, false)
  palt(0, true)

  spr(208, 4, 32, 15, 3)
  if(t % 60 >= 10) then
    local text = "press x to play"
    write(text, text_x_pos(text), 72,7)
    text = "press z for controls"
    write(text, text_x_pos(text), 80,7)
  end
end

-- loading

function update_loading()
    -- after enough time has passed or player, move on to the level
     if time() > loading_end_time then
         change_state(next_state)
     end
end

function draw_loading()
    rectfill(0,0,screen_size,screen_size,0)

    -- show story for the first part of loading screen and show title card for the last part
    if  time() + loading_time/3 > loading_end_time then
      local level_name = ""
      local level_description = ""
      if next_state == game_states.level1 then
          level_name = "episode 1:"
          level_description = "save the city, sailor v!"
      elseif next_state == game_states.level2 then
          level_name = "episode 2:"
          level_description = "escape the dungeon, sailor v!"
      elseif next_state == game_states.level3 then
          level_name = "episode 3:"
          level_description = "stop the robots, sailor v!"
      elseif next_state == game_states.level4 then
          level_name = "episode 4:"
          level_description = "escape the factory, sailor v!"
      else
          throw("unknown level")
      end
      write(level_name, text_x_pos(level_name), 50,7)
      write(level_description, text_x_pos(level_description), 64,7)
    else
      local plot1 = ""
      local plot2 = ""
      local plot3 = ""
      local plot4 = ""
      if next_state == game_states.level1 then
          plot1 = "oh no!"
          plot2 = "deityzilla and his minions"
          plot3 = "are attacking the city! it's"
          plot4 = "up to sailor v to stop them!"
      elseif next_state == game_states.level2 then
          plot1 = "oh no! big mech has captured"
          plot2 = "sailor v! break out of the"
          plot3 = "dungeon and stop him"
          plot4 = "from destroying the city!"
      elseif next_state == game_states.level3 then
          plot1 = "sailor v has found the "
          plot2 = "evil robot factory! time to"
          plot3 = "teach them a lesson!"
      elseif next_state == game_states.level4 then
          plot1 = "oh no!"
          plot2 = "big mech is self destructing!"
          plot3 = "get out of there!"
      else
          throw("unknown level")
      end
      write(plot1, text_x_pos(plot1), 42,7)
      write(plot2, text_x_pos(plot2), 52,7)
      write(plot3, text_x_pos(plot3), 62,7)
      write(plot4, text_x_pos(plot4), 72,7)
    end


end

-- game

function init_game()
  player = make_player(20,1)
  brawl_spawn = false
  brawl_clear = true

  create_obs(checkpoint, 77, 510, 4, 1, 6, 1, 2)

  instantiate_level_obs()
end

function update_game()
  update_enemies()
  foreach(health_pack, update_health_pack)
  foreach(checkpoint, update_checkpoint)
  move_actor(player)

  if(player.x >= 300 and player.x <= 350 and zone == 1) then
    spawnbrawl(300, 0)
  end
  if(player.x >= 700 and player.x <= 750 and zone == 1) then
    spawnbrawl(700, 0)
  end
  if(player.x >= 700 and player.x <= 722 and zone == 2) then
    spawnbrawl(705, 180)
  end
  if (player.x >= 500 and player.x <= 550 and zone == 1) or (player.x >= 300 and player.x <= 400 and zone == 2) then
    brawl_spawn = false
  end
  t+= 1
end

function draw_game()
  rectfill(0, 0, 127, 127, 1)

  --stars
  local x = t / 8
  x = x % 128
  local y=0
  map(21, 16, 0, y, 16, 16, 0)

  --static skyline
  palt(0, false)
  palt(1, true)
  pal(13,2)
  y = 0
  map(0, 17, 0, y-24, 128, 32)
  pal()
  palt(1,false)
  palt(0, true)

  palt(0, false)
  palt(1, true)
  map(0, 17, (-cam.x)/6, y, 128, 32, 0x5)
  map(0, 17, 128-((cam.x)/6), y, 128, 32, 0x5)
  palt(1,false)
  palt(0, true)

  camera(0,0)
  if(brawl_clear and player.x <= 980) then

    if (player.x-cam.x<64-20) then
      if (zone == 1 and player.x>45) or (zone == 2 and player.x>340) then
        cam.x-=1
      end
    end
    if (player.x-cam.x>64+25) then cam.x+=1 end


  end
  camera(cam.x, cam.y)


  map(0, 0, 0, 0, 128, 32)

  draw_enemies()
  foreach(health_pack, draw_obj)
  foreach(checkpoint, draw_obj)
  if(blocking == true) then
    if actor.flp == true then
      circfill(player.x+4, player.y-8, outter, 10)
      circfill(player.x+7, player.y-8, inner, 0)
    else
      circfill(player.x+2, player.y-8, outter, 10)
      circfill(player.x-1, player.y-8, inner, 0)
    end
  end

  if drawarrow == true then
    draw_arrow()
  end


  draw_player()

  --
 --write('combo: '..player.combo.attac,cam.x,cam.y+0,7)
 --write('damage:',cam.x,cam.y+8,7)
 if player.combo.dmg then
 --write(player.combo.dmg, cam.x+28,cam.y+8,7)
  if dmgtimer > 0 then
    write(-player.combo.dmg,dmg.x, dmg.y,8)
 end
end

 -- print('combo timer:'..player.combotimer,cam.x,8,7)
 -- print(player.incombo,cam.x,16,7)
  -- print(brawl_clear, cam.x + 5,24,0)
  -- print(brawl_spawn,cam.x + 5,32,0)
  -- print(player.x,cam.x + 5,cam.y+40,0)
  -- print(player.y,cam.x + 5,cam.y+50,0)
  -- print(enemycount,cam.x + 5,48,0)
  draw_hearts()
  draw_lives()
  camera(0,0)
end

-- instructions

function show_instructions()
    is_showing_instructions = true
    instructions_page = 0
end

function draw_instructions()

    if instructions_page == 0 then
        local header = 'controls'
        write(header, text_x_pos(header), 10, 7)

        local movement_text = "\139 \145  move left and right"
        write(movement_text, 10, 25, 7)

        local jump_text = "\148     jump"
        write(jump_text, 10, 35, 7)

        local shield_text = "\131     block"
        write(shield_text, 10, 45, 7)

        local punch_text = "z      punch"
        write(punch_text, 10, 55, 7)

        local kick_text = "x      kick"
        write(kick_text, 10, 65, 7)

        local block_info_text1 = 'note: your block does not last'
        write(block_info_text1, text_x_pos(block_info_text1), 80, 7)

        local block_info_text2 = 'forever and needs to recharge'
        write(block_info_text2, text_x_pos(block_info_text2), 90, 7)

        local more_info_text = 'press x for combo info'
        write(more_info_text, text_x_pos(more_info_text), 110, 7)

        local exit_text = 'press z to return to game'
        write(exit_text, text_x_pos(exit_text), 120, 7)
    elseif instructions_page == 1 then
        local header = 'combos'
        write(header, text_x_pos(header), 10, 7)

        local combo_text1 = 'use different combos of punch +'
        write(combo_text1, text_x_pos(combo_text1), 25, 7)

        local combo_text2 = 'kick for different situations'
        write(combo_text2, text_x_pos(combo_text2), 35, 7)

        local example_text = 'examples:'
        write(example_text, text_x_pos(example_text), 50, 7)

        local sample_combo1 = "xzzx - slow but powerful combo"
        write(sample_combo1, text_x_pos(sample_combo1), 60, 7)

        local sample_combo2 = "zzzz - fast but weak combo"
        write(sample_combo2, text_x_pos(sample_combo2), 70, 7)

        local try_text1 = "try different combos and"
        write(try_text1, text_x_pos(try_text1), 85, 7)

        local try_text2 = "see what works best!"
        write(try_text2, text_x_pos(try_text2), 95, 7)

        local more_info_text = 'press x for control info'
        write(more_info_text, text_x_pos(more_info_text), 110, 7)

        local exit_text = 'press z to return to game'
        write(exit_text, text_x_pos(exit_text), 120, 7)
    else
        throw("unknown instruction page")
    end
end

function update_instructions()
    if btnp(4) then
      -- resume game
      play_sound_effect(sound_effects.menu_close)
      is_showing_instructions = false
    elseif btnp(5) then
        -- cycle through instructions
        play_sound_effect(sound_effects.menu_sound)
        instructions_page = (instructions_page + 1) % num_instruction_pages
    end
end


-- game over

function update_gameover()
     if btnp(5) then
         change_state(game_states.splash)
     end
end

function draw_gameover()
    local text = "c'est la vie..."
    local restart_text = "press x to restart"
    write(text, text_x_pos(text), 50,7)
    write(restart_text, text_x_pos(restart_text), 64,7)
    -- remove checkpoints
    for obj in all(checkpoint) do
      del(checkpoint, obj)
    end
    -- remove everything else
    delete_level_obs()
end

-- win
function update_win()
    t += 1
    if are_credits_over() then
        if btnp(5) then
            -- reset cartridge data
            load("sailorv")
        end
    end
end

function draw_win()
    rectfill(0,0,screen_size,screen_size,1)
    local x = t / 8
    x = x % 128
    local y=0
    map(21, 16, -x, y, 16, 16, 0)
    map(21, 16, 128-(x), y, 16, 16, 0)

    --static skyline
    palt(0, false)
    palt(1, true)
    pal(13,2)
    y = 0
    map(0, 17, 0, y-24, 128, 32)
    pal()
    palt(1,false)
    palt(0, true)

    palt(0, false)
    palt(1, true)
    map(0, 17, 0, y, 128, 32, 0x5)
    map(0, 17, 64, y, 128, 32, 0x5)
    palt(1, false)
    palt(0, true)

    local cur_base_pos = base_credits_pos
    for i=1,#credits do
        write(credits[i], text_x_pos(credits[i]), cur_base_pos,7)
        cur_base_pos += credits_spacing
    end

    cur_win_tick +=1 -- increase tick

    -- if it is time to move the credits upwards
    if cur_win_tick % win_ticks_per_movement == 0 then
        if not are_credits_over() then
            -- credits are not done yet, keep scrolling the text
            base_credits_pos -= scroll_speed  -- move text upwards
        end
        cur_win_tick = 0 -- reset tick timer
    end
end



function draw_player()
  if(taking_damage) then
      for j=2,15 do
        pal(j,7+((player.time/2) % 4))
      end

      if(t%10==0) then
        taking_damage = false
      end
    end

  spr(actor.sprt,player.x,player.y-16,1,2,actor.flp)
  pal()
end

function draw_arrow()
  if drawarrow == true then
    spr(169, cam.x + 100, cam.y + 50, 2, 2)
    if time() % 7 == 0 then
      drawarrow = false
    end
  end

end

-- draw hearts ui
function draw_hearts()
  if(player.hearts == 3) then
    spr(36, cam.x+110, cam.y+1)
    spr(36, cam.x+101, cam.y+1)
    spr(36, cam.x+92, cam.y+1)
  elseif (player.hearts == 2.5) then
    spr(40, cam.x+110, cam.y+1)
    spr(36, cam.x+101, cam.y+1)
    spr(36, cam.x+92, cam.y+1)
  elseif (player.hearts == 2) then
    spr(37, cam.x+110, cam.y+1)
    spr(36, cam.x+101, cam.y+1)
    spr(36, cam.x+92, cam.y+1)
  elseif (player.hearts == 1.5) then
    spr(37, cam.x+110, cam.y+1)
    spr(40, cam.x+101, cam.y+1)
    spr(36, cam.x+92, cam.y+1)
  elseif (player.hearts == 1) then
    spr(37, cam.x+110, cam.y+1)
    spr(37, cam.x+101, cam.y+1)
    spr(36, cam.x+92, cam.y+1)
  elseif (player.hearts == 0.5) then
    spr(37, cam.x+110, cam.y+1)
    spr(37, cam.x+101, cam.y+1)
    spr(40, cam.x+92, cam.y+1)
  elseif (player.hearts == 0) then
    spr(37, cam.x+110, cam.y+1)
    spr(37, cam.x+101, cam.y+1)
    spr(37, cam.x+92, cam.y+1)
  end
end

-- draw lives ui
function draw_lives()
    local text = num_lives.."x"
    write(text, cam.x+100, cam.y+12, 7)
    spr(3, cam.x+110, 10)
end

function instantiate_level_obs()
  -- location to spawn first enemy
  spawn = 0

  if (zone == 1) then
    create_obs(health_pack, 39, 180, 4, 1, 4, 1, 1)
    create_obs(health_pack, 39, 300, 4, 1, 4, 1, 1)
    create_obs(health_pack, 39, 400, 4, 1, 4, 1, 1)
    create_obs(health_pack, 39, 500, 4, 1, 4, 1, 1)
    create_obs(health_pack, 39, 700, 4, 1, 4, 1, 1)

  elseif (zone == 2) then
    change_music(music_states.dungeon)
    create_obs(health_pack, 39, 39*8, 30*8, 1, 4, 1, 1)
    create_obs(health_pack, 39, 55*8, 17*8, 1, 4, 1, 1)
    create_obs(health_pack, 39, 66*8, 18*8, 1, 4, 1, 1)
    create_obs(health_pack, 39, 81*8, 27*8, 1, 4, 1, 1)

    make_ninja(44*8, 30*8, 10)
    make_ninja(50*8, 25*8, 10)
    make_ninja(59*8, 20*8, 10)
    make_ninja(67*8, 30*8, 10)

    --make_ninja(72*8, 20*8, 10)
    make_ninja(85*8, 24*8, 10)
    make_ninja(105*8, 28*8, 10)
    make_ninja(123*8, 25*8, 10)
  end

end

function delete_level_obs()
  -- deletes ninjas and shurikens
  for obj in all(allzombies) do
    del(allzombies, obj)
  end
  for obj in all(allninjas) do
    del(allninjas, obj)
  end
  for obj in all(shuriken) do
    del(shuriken, obj)
  end
  for obj in all(alldeities) do
    del(alldeities, obj)
  end
  for obj in all(fireball) do
    del(fireball, obj)
  end
  for obj in all(health_pack) do
    del(health_pack, obj)
  end

end

-- utils

-- change this if you use a different resolution like 64x64
screen_size = 128


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
            print(text,x+i,y+j, 0)
        end
    end
    print(text,x+1,y+1,color)
end


-- returns if module of a/b == 0. equals to a % b == 0 in other languages
function mod_zero(a,b)
   return a - flr(a/b)*b == 0
end
-->8
--combo tree
root = {}
root.attac= " "
root.sprt = 0
left = {}
root.left = left

right = {}
right.attac = "b"
right.sprt = 10
right.dmg = 2
root.right = right

left.attac = "a"
left.sprt = 4
left.dmg = 1
left.left = {}
left.left.attac = "aa"
left.left.sprt = 5
left.left.dmg = 1
left.right = {}
left.right.attac = "ab"
left.right.dmg = 2
left.left.left = {}
left.left.left.attac = "aaa"
left.left.left.sprt = 4
left.left.left.dmg = 1
left.left.right = {}
left.left.right.attac = "aab"
left.left.right.dmg = 2
left.right.left = {}
left.right.left.attac = "aba"
left.right.left.sprt = 5
left.right.left.dmg = 1
left.right.right = {}
left.right.right.attac = "abb"
left.right.right.dmg = 2
left.left.left.left = {}
left.left.left.left.attac="aaaa"
left.left.left.left.sprt = 5
left.left.left.left.dmg = 3
left.left.left.right = {}
left.left.left.right.attac="aaab"
left.left.left.right.dmg = 6
left.left.right.left = {}
left.left.right.left.attac="aaba"
left.left.right.left.sprt = 4
left.left.right.left.dmg = 3
left.left.right.right = {}
left.left.right.right.attac="aabb"
left.left.right.right.dmg = 6
left.left.right.right.sprt = 10
left.right.left.left = {}
left.right.left.left.attac="abaa"
left.right.left.left.sprt = 4
left.right.left.left.dmg = 3
left.right.left.right = {}
left.right.left.right.attac="abab"
left.right.left.right.dmg = 6
left.right.right.left = {}
left.right.right.left.attac="abba"
left.right.right.left.sprt = 5
left.right.right.left.dmg = 3
left.right.right.right = {}
left.right.right.right.attac="abbb"
left.right.right.right.dmg = 6


right.left = {}
right.left.attac = "ba"
right.left.sprt = 4
right.left.dmg = 1
right.right = {}
right.right.attac = "bb"
right.right.dmg = 2
right.left.left = {}
right.left.left.attac = "baa"
right.left.left.sprt = 5
right.left.left.dmg = 1
right.left.right = {}
right.left.right.attac = "bab"
right.left.right.dmg = 2
right.right.left = {}
right.right.left.attac = "bba"
right.right.left.sprt = 4
right.right.left.dmg = 1
right.right.right = {}
right.right.right.attac = "bbb"
right.right.right.dmg = 2
right.left.left.left = {}
right.left.left.left.attac="baaa"
right.left.left.left.sprt = 4
right.left.left.left.dmg = 3
right.left.left.right = {}
right.left.left.right.attac="baab"
right.left.left.right.dmg = 6
right.left.right.left = {}
right.left.right.left.attac="baba"
right.left.right.left.sprt = 5
right.left.right.left.dmg = 3
right.left.right.right = {}
right.left.right.right.attac="babb"
right.left.right.right.dmg = 6
right.right.left.left = {}
right.right.left.left.attac="bbaa"
right.right.left.left.sprt = 5
right.right.left.left.dmg = 3
right.right.left.right = {}
right.right.left.right.attac="bbab"
right.right.left.right.dmg = 6
right.right.right.left = {}
right.right.right.left.attac="bbba"
right.right.right.left.sprt = 4
right.right.right.left.dmg = 3
right.right.right.right = {}
right.right.right.right.attac="bbbb"
right.right.right.right.dmg = 6
-->8
--music stuff

-- enum for all possible music states
music_states = {
    splash_screen = 0,
    city = 1,
    dungeon = 2,
    miniboss = 3,
    factory = 4,
    final_boss = 5,
    lose_screen = 6,
    win_screen = 7,
    loading_screen = 8,
}

sound_effects = {
  shield_activate = 0,
  player_attack = 1,
  player_damaged = 2,
  ninja_throw = 3,
  enemy_damaged = 4,
  player_jump = 5,
  footstep = 6,
  shield_hold = 7,
  health_pickup = 8,
  checkpoint = 9,
  level_start = 10,
  menu_sound = 11,
  menu_close = 12,
  big_footstep = 13,
  explosion = 14,
  fireball = 15,
}

-- call this to change music based on given music_state
function change_music(music_state)
    pattern_num = -1
    if music_state == music_states.splash_screen then
        pattern_num = 0
    elseif music_state == music_states.city then
        pattern_num = 4
    elseif music_state == music_states.dungeon then
        pattern_num = 10
    elseif music_state == music_states.miniboss then
        pattern_num = 20
    elseif music_state == music_states.factory then
        pattern_num = 26
    elseif music_state == music_states.final_boss then
        pattern_num = 41
    elseif music_state == music_states.lose_screen then
        pattern_num = 2
    elseif music_state == music_states.win_screen then
        pattern_num = 37
    elseif music_state == music_states.loading_screen then
        -- shows level name and amount of lives
        pattern_num = 3
    end
    -- begin playing the selected song from channel 0 or throw an error if still -1
    music(pattern_num,0)
end

function play_sound_effect(sound_effect)
    sfx_num = -1
    length = -1
    offset = -1
    channel_num = 3 -- always use last channel because first 3 are for music

    if sound_effect == sound_effects.shield_activate then
      sfx_num = 58
      length = 8
      offset = 0
    elseif sound_effect == sound_effects.player_attack then
      combo_num = #player.combo.attac
      sfx_num = 60
      length = 1
      -- play higher pitched noise the longer the combo goes
      offset = combo_num - 1
    elseif sound_effect == sound_effects.player_damaged then
      sfx_num = 57
      length = 4
      offset = 0
    elseif sound_effect == sound_effects.ninja_throw then
      sfx_num = 59
      length = 4
      offset = 0
    elseif sound_effect == sound_effects.enemy_damaged then
      sfx_num = 57
      length = 4
      offset = 8
      -- player attack feedback is important and enemy_damaged must not drown out player_attack sound
      channel_num = 2
    elseif sound_effect == sound_effects.player_jump then
      sfx_num = 59
      length = 6
      offset = 8
    elseif sound_effect == sound_effects.footstep then
      sfx_num = 55
      length = 1
      offset = 0
    elseif sound_effect == sound_effects.shield_hold then
      sfx_num = 54
      length = 6
      offset = 0
    elseif sound_effect == sound_effects.health_pickup then
      sfx_num = 63
      length = 8
      offset = 0
    elseif sound_effect == sound_effects.checkpoint then
      sfx_num = 63
      length = 8
      offset = 16
    elseif sound_effect == sound_effects.level_start then
      sfx_num = 59
      length = 10
      offset = 16
      channel_num = 2
    elseif sound_effect == sound_effects.menu_sound then
      sfx_num = 62
      length = 1
      offset = 1
    elseif sound_effect == sound_effects.menu_close then
      sfx_num = 62
      length = 1
      offset = 2
    elseif sound_effect == sound_effects.big_footstep then
      sfx_num = 61
      length = 3
      offset = 0
    elseif sound_effect == sound_effects.explosion then
      sfx_num = 55
      length = 10
      offset = 8
    elseif sound_effect == sound_effects.fireball then
      sfx_num = 61
      length = 3
      offset = 8
    else
      throw("unknown sound effect")
    end

    sfx(sfx_num, channel_num, offset, length)
  end

-->8
-- win screen
win_ticks_per_movement = 3
cur_win_tick = 0
credits = {"the city is safe!", "", "art by:", "jamie chen", "sydney schiller", "",  "music by:", "davey jay belliss", "", "programmed by:", "davey jay belliss", "jessica hsieh",  "dan nguyen", "mark nickerson", "sydney schiller", "", "special thanks", "joshua mccoy", "", "", "", "", "", "", "", "c'est la vie"}
scroll_speed = 1 -- how many pixels a credit moves per draw
credits_spacing = 8  -- how far apart each credit is vertically
base_credits_pos = 120

function are_credits_over()
    -- if the last line of credits is past the middle of the screen, don't scroll anymore
    return (#credits * credits_spacing) + base_credits_pos < 60
end

__gfx__
0000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000065550000
00000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000065550000
00000000000000000000000000000000002080000000000000208000002080a00000000000000000000000000000000080008000000000000000000065550000
800000808820288080000080882028800228800080000080022880000228800a0800008008000080882028808820288082028000000000000000000065550000
88202880029aaaa088202880029aaaa00888aa00882028800888aa000888aa0a0820028008200280029aaaa0029aaaa029aaaa00000000000000000065550000
829aaaa008aa8f80829aaaa008aa8f802a88aa00829aaaa02a88a8002a88a80a029aaaa0029aaaa008aa8f8008aa8f808aa8f800000000000000000065500000
88aa8f8008aac8c088aa8f8008aac8c008aafa0088aa8f8008aafc0008aafc0a08a8f8a008a8f8a008aac8c008aac8c08aac8c00000000000000000065000000
08aac8c00aaffff008aac8c00aaffff00a7fffff08aac8c00aafff000aafff0a08ac8ca008af8fa00aaffff00aaafff0aaafff00000000000000000060000000
0aaffff00aa788000aaffff00aa788000a7770000affffff0aa770900aa7709a0aafffa00aafffa00aa788000af78800af788f00000000000000000000000000
0aa788a0aaf787000aa788a0aa778700aa7770000af78800aaa7ff90aaa7ff9a0aa888a00aa888a0aaf787000af787f00a787000000000000000000000000000
0af787a000f777ff0af787a000ff7700a0776000aaf78700a0776090a077609a0af878f00af878f000f777ff0077770007777100000000000000000000000000
00f777000001110000f777f0000111000011100000077700001110000011100a0af777f00af777f0000111000011111001111ff8000000000000000000000000
000111000011111000011100001111100111100000011110011110000111100a00011100000111000011111001111ff011111000000000000000000000000000
00111100000f00f000111100000f0f0000ffff000011111000f0f00000f0f00a0011110000111100000f00f000fff8000f000000000000000006666666666666
000ff00000f00800000f0f00008000f00f000f00000f00f00f00f0000f00f0a0000f0f00000f0f0000f0080000f080000f000000000000000066666666666666
0008800000800000000808000000008080000800008000800800800008008a000008080000080800008000000080000008000000000000000666666666666666
5555555577777777666666667777777708800880055005507666666d0ee00ee00880055000000000655500006667777777777666666666660000000000000000
5999999566666666777776777677777d888887885555575565555552eeeee7ee88885755000000006555000055563333333365556dddddd60000000000000000
594444454441444166666566766777d6888888785555557565222552eeeeee7e888855750000000065550000557b99999999b7556d5555560000000000000000
59444445111111115944444576667d66888888885555555565200652eeeeeeee888855550000000065550000556b44444444b6556d5555560000000000000000
555555551444144455555555766656660888888005555550652006520eeeeee00888555000000000655500006739455555549376666666660000000000000000
995599991111111199559999766dd56600888800005555006556675200eeee000088550000000000655666666b3445a5aa5443b6dd66dddd0000000066660000
44559444444144414455944476dddd56000880000005500065555552000ee00000085000000000006566666673944555555449375566d5550000000066650000
4455944411111111445594447dddddd500000000000000005222222200000000000000000000000066666666634445aa5a5444365566d5550000000066550000
1111000000000000000000000dddddddddd05000dddddddddddd0000000000000000000000000000000000006344455555544436777776775555555565550000
1110055555555555555555000d9999999dd00000ddd99999ddd00555000000000000a0000000000000a000006344944444444436999995995999999565550000
1105555555555555555550000dddddddddd00050dddddddddd055555000000000000a00000a0a000000000006349a944444444366d5555565944444565550000
0055555555555555555500000dddddddddd00500dddddddd005555550000000000a0a0a0000a00000000000063449444444444366d5555565944444565550000
0000000000000000000000000dddddddddd05000dddddddd00000000000000000000a00000a0a000000000006344444444444436666666665555555565550000
0dddddddddddddddddd000000d9999999dd00000ddd999990ddddddd00a000000000a0000000000000000a006344444444444436dd66dddd9955999965550000
0dddddddddddddddddd000500dddddddddd00050dddddddd0ddddddd0000000000000000000000000000000063444444444444365566d5554455944465550000
0dddddddddddddddddd005000dddddddddd00500dddddddd0ddddddd0000000000000000000000000000000063444444444444365566d5554455944465550000
00000000000000000000000000000000005550000000000000000000005550000000000000000000000000007777777777777775ff880000ffbb000000000000
005550000055508800000008005550000888880000555000005550000888880000555000000000000000000066666666666666659988880099bbbb0000000800
088888000888880000055508088888000f4f558008888800088888000f4f558008888800000000000000000066666666666666659988888099bbbbb000008800
0f4f45800f455500008888800f4f55800fff55800f4f55880f4f55800fff55800f4f5588000000000000000066599999999996659988888899bbbbbb088eee00
0ffff5800ff5550000f4f4500fff5580055555000fff55000fff5508055555000fff5500000000000000000066599999999996659988882099bbbb30008e0e80
055555000555550500ffff50055555000058500005555500055555000058500005555500000000000000000066599999999996659988220099bb3300000eee88
00555000005550505055555000585000008250000058500000585000008250000058500000000000000000006659999999999665992200009933000000088000
05555800005525000505550000825000005250000082500000825000005250000082500000000000000000006677777777777665990000009900000000080000
05558200222220000055552000552000005520000052500000525000005250000055200000000000000000006666666666666665990000009900000000400908
0558520000585000000555200055520000552000002550000025500000525000005552000000000000000000665999999999966599000000990000000499a900
05855200008550000005220002555200005550000025500002555200005550000255520000000000000000006659999999999665990000009900000049aa9888
0255520000555000000255000055500000525000005550000055500000525000005550000000000000000000665999999999966599000000990000009a884aa0
00505000005550000055520000525000005250000052500000525000002250000052500000000000000000006677777777777665990000009900000008a98880
005050000200550000500200002050000002000000052000005020000002000000020000000000000000000066666666666666659900000099000000008a9908
00505000020000500050002200200500005200000005200000500200002200000020500000000000000000006666666666666665995000009950000000040900
02202200220002200220000202200500002200000052200005500200005500000225500000000000000000005555555555555555555000005550000000000080
0000000000000000000bbb90000000000000000000000000000bbb90000000000000000000000000000000000000000000000000000000000000000000000000
000bbb900000000000bbb2b900000000000bbb900000000000bbb2b9000000000000000000000000000000000008840000088400000884000008840000088400
00bbb2b90000000bbbbb88bb0000009b00bbb2b90000000bbbbb88bb0000009b000bbb900000000b0000000000dddd4000dddd4000dddd4000dddd4000dddd40
bbbb88bb0000009b5b5bbbbb900009b0bbbb88bb0000009b5b5bbbbb900009b000bbb2b90000009b00000000007d7dd0007d7dd0007d7dd0007d7dd0007d7dd0
5b5bbbbb900009b0bbbbbbbbb0009bb05b5bbbbb900009b0bbbbbbbbb0009bb0bbbb88bb000009b00000000000dddd8000dddd8000dddd8000dddd8000dddd80
bbbbbbbbb0009bb033333bbbb900bbb0bbbbbbbbb0009bb033333bbbb900bbb05b5bbbbb90009bb000000000004dddd0004dddd0004dddd0004dddd0004dddd0
33333bbbb900bbb00005bbbbbaaabb5033333bbbb900bbb00005bbbbbaaabb50bbbbbbbbb900bbb000000000000d4400000d4400000d4400000d4400000d4400
000ab3bbbaaabb50000ab3bbbbbbbb00000abbbbbaaabb50000ab3bbbbbbbb0022233bbbbaaabb500000000008d4dd0008d4dd0008d4dd0008d4dd0008d4dd00
003a33bbbbbbbb00003a33bbbbbbbb00000ab3bbbbbbbb00003a33bbbbbbbb003330abbbbbbbbb0000000000000d4800000d4800000d4800000d4800000d4800
003a3abb55bbb500003a3abb55bbb500003a33bbbbbbbb00003a3a55bbbbb5000000ab3bbbbbbb00000000000888880008888800088888000888880008888800
0000aabb33bbb0000005aabb33bbb00000303bbb55bbb5000000aa33bbbbb0000003a33b55bbb500000000000008880000088800000888000008880000088800
00003aab335b500000055aab335b500000000aab33bbb00000000a333bbb50000003a3ab33bbb000000000000004840000048400000484000004840000048400
00003aaa3335000000035aaa3335000000000aaa335b500000000a333bb3000000000aaa335b5000000000000008080000080800000808000008800000080800
0000333a333000000003350a0333000000000aaa333300000000000330330000000000aa33330000000000000004080000040800000408000004800000400800
000000300030000000000300000300000000003000030000000000003003000000000030000300000000000000080d0000080dd000080d000008d00008800d00
00003330333000000003330000330000000033300033000000000033303300000000333000330000000000000088dd00008800d00088dd00008dd0000000dd00
43333353534353433353430000334333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
43333353534353433353430000334333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
43333353534353433353430000334333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
43333353534353433353430000334333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
49444944494449444944494449444944333333337266666672666666495600004956000000000000000000000000000000000000000000000000000000000000
494449444944494449444944494449447777767772ddddd672ddddd6495600004956000000000000000000000000000000000000000000000000000000000000
49444944494449444944494449444944333335337255555672555556495600004956000000000000000000000000000000000000000000000000000000000000
494449444944494449444944494449446d5555567255555672555556495600004956000000000000000000000000000000000000000000000000000000000000
494449444944494449444944494449446d5555567266666672666666495600004956000000000000000000000000000000000000000000000000000000000000
33333333494333333333494449444944666666667266dddd7266dddd495600003333666600000000000000000000000000000000000000000000000000000000
33333333493333333335494449444944dd66dddd7266d5557266d555495600003336666600000000000000000000000000000000000000000000000000000000
333333334333333333554944494449445566d5557266d55577777777495600003366666600000000000000000000000000000000000000000000000000000000
49456666666549446555494465554944777777777777777649477777777779443666666600000000000000000000000000000000000000000000000000000000
494449767944494465554944655549445555555555555556494655555555694477777677000000000aa000000000000000000000000000000000000000000000
4974474747447944655549446555494455555555555555564976eeeeeeee674466666566000000000aaa00000000000000000000000000000000000000000000
4947494c494749446555494465554944556000000000055649662222222266446d555556000000000aaaa0000000000000000000000000000000000000000000
494c7947497c494465554944655549445560000000000556475e25555552e5746d555556000000000aaaaa000000000000000000000000000000000000000000
4744c97c79c4474465554944655449445560000000000556465225005052256466666666000000000aaaaaa00000000000000000000000000000000000000000
49744747474479446555494465444944556000000000055675e2255555522e57dd66ddddaaaaaaaaaaaaaaa00000000000000000000000000000000000000000
49c749474947c9446555494469444944557777777777755665222505005222565566d555aaaaaaaaaaaaaaaa0000000000000000000000000000000000000000
494c49c7c94c494465554944666666665555555555555556652225555552225666666666aaaaaaaaaaaaaaaa0000000000000000000000000000000000000000
4944774747744944655549446dddddd65560000000000556652222222229225677777677999999999aaaaaa00000000000000000000000000000000000000000
4944497c79444944655549446d555556556000000000055665222222229a925666666566000000000aaaaa900000000000000000000000000000000000000000
4944494749444944655549446d555556556000000000055665222222222922566d555556000000000aaaa9000000000000000000000000000000000000000000
49444944494449446555494466666666557777777777755665222222222222566d555556000000000aaa90000000000000000000000000000000000000000000
494449444944494465533333dd66dddd5555555555555556652222222222225666666666000000000aa900000000000000000000000000000000000000000000
4944494449444944653333335566d55555555555555555566522222222222256dd66dddd00000000099000000000000000000000000000000000000000000000
4944494449444944633333335566d555666666666666666633333333333333335566d55500000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000077700000000000000000000000777777777770000000000777777777770000000000
00000000000000000000077700000000000000000000000000000000000779770000000000000000000000788888888870000000007888887222700000000000
00000000000000000000079970000000000000000000007777000000000799970000000000000000000000788888888870000000078888872227000000000000
00000000777777777770077970000000000000000000077997000000000779997000000000000000000000788888888870000000788888722270000000000000
00000007779999999977007970000000000007777000079997000000000077997000000777777770000000788888888870000007888887222777777700000000
00000077999999999997707970000000000077997700079997000000000007997000000799999970000000788888888870000078888872222222222700000000
00000779999999999999770770777777007799999970079977000000000007997700007799999977000000788888888870000788888777777222227000000000
00007799999777779999970077799997777999999977079970000000000007799700007997777997000000788888888870007888888888887222270000000000
00007999997700007799970079999999977997799997079970000000000000799700007997777997000000788888888870078888888888872222700000000000
00007999977000000779970079977779977997777997079970000000000000799700007997777997000000788888888870077778888888722227000000000000
00007999970000000077770079977779977997707777779977770000000000799700007997777997777000788888888870000788888887222270000000000000
00007999770000000000000079999999977799770079999999970000000000799700007999999999997000788888888870007888888872222700000000000000
00007999700000000000000079977777770799970079999999970000000000799700007799999779997000788888888870078888888722227000000000000000
00007999700000000000000079977777700779970077779977770000000000799700000777777777777000788888888870788888887222270000000000000000
00007999700000000000000079999999970079997700079970000000000000799700000000000000000000788888888877888888872222700000000000000000
00007999700000000000000077999999777077999770079970077770000007799700007777777700000000788888888888888888722227000000000000000000
00007999700000000000000007777777777707799970079970079970000077999700777999999777000000788888888888888887222270000000000000000000
00007999770000000000007777777777779707799970079970779970000079999777799999999997000000788888888888888872222700000000000000000000
00007999977000000000777999999997799777999970079977799770000079999779999999999997700000788888888888888722227000000000000000000000
00007799997777777777799999999999799999999970079999999700000079999999999997777999700000788888888888887222270000000000000000000000
00000799999999999999999997777799779999999770077999997700000079999999777777007777700000788888888888872222700000000000000000000000
00000779999999999999999777007779777777777700007777777000000079999977700000000000000000788888888888722227000000000000000000000000
00000077999999999999977700000077000000000000000000000000000077777770000000000000000000788888888887222270000000000000000000000000
00000007777777777777770000000000000000000000000000000000000000000000000000000000000000777777777777777700000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000020202020000020000000080800002000404040404040400000000808000000002020202020202020200000000404004020202020202020202000000000000000202020202020202020200000000000002020202020202020202000000000000
0000000000000000000000000000000000000000020202000000000000000000000000000000000002000000000000000000000200000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000
__map__
203f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cfcfcfcfcfcfcfcfcfcf
203f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d1e2f0000000000001e2f0000000000cfcf00000000000000cf
203f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001e1f1f2f00000d222a1f1f1f1f1f1f223f0000000000000000000000000000cf
203f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001e1f1f1f2fcfcf00000000000000000000000000000000000000000000002222220f0000002022222222222222203f0000000000000000000000000000cf
203f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cfcfcf00000000000000001e222222222a2f00000000000000000000000000000000000000000000000020200fcf00000020204b4c204b4c20203f000000000000cfcfcfcfcfcfcfcfcf
203f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001e1f1f1f1f1f1f1f1f2220202020223f00000000000000000000000000000000000000000000000000000000001e1f20205b5c205b5c20203f000000000000cfcfcfcfcfcfcfcfcf
202a1f1f1f2f0000000000000000000000000000000000000000000000000000000000000000000000000000000000001e1f1f1f2f0d0d0d22222222222222222220204b4c20203f0000cf000000000000000000000000000000000000000000000000000022222020202020202020203f000000000000cfcfcfcfcfcfcf00cf
20222222222a2f000000000000000000000000000e1e1f1f1f2f00000000000000000000000000000000000000000000222222222a2f0d0dcf202020202020202020205b5c20203f0000cf0000000000000000000000000000000000000000000000000000cf202020202020202020203f000000000000cfcfcfcfcfcfcf00cf
2020202020222a2f0000cf0000000000000000001e222222222a2f000000cf1e1f2f00000000000000000000000000cf20202020222a2f0d0d0d0dcf0000cf20202020202020203f0000cf0000000000000000000000000000000000000000001e1f1f2f00000020204b4c204b4c20203f0000000000cfcfcfcfcfcfcfcf00cf
202020202020220f000000000d0d0d0d000000002220202020223fcf00cf1e22222a2f0000000000000000cfcfcfcfcf2920202020220f0d0d0d0dcf0000cfcf202020202020203f0000cf0000000000000000000000000000000000000000002222220f00000020205b5c205b5c20203f00000000cf1e1f1f1f1f1f1f1f2fcf
203fcfcfcfcf0000000026000d0000000000000020204b4c20202a1f1f1f222020223f000000000000000000000000002900000d0d0d0d0d0d1e1f1f1f2f00cf2020204b4c20203f0000cf00000000000000000000000000000000000000000020200fcf0000002020202020202020203f00000000cf3d3d3d3d3d3d3d3d3fcf
203fcfcf00000000001e261f1f1f2f000000001e20205b5c202022222222202020200f0000000000000000000000000d2900000d0d0d0d0d1e222222223fcf002020205b5c20203f0000cf000000001e1f262fcfcfcf261f1f2f00000000000000000000001e1f2020202020202020203f00000000cf2d4b4c2d2d4b4c2d3fcf
203fcfcf000000cfcf22222222220f000000002220202020202020202020203f2929cf001e1f1f1f1f1f1f1f1f1f1f1f2f00000dcf1e1f1f22202020203fcf00202020202020203f0000cf000000cf2222220f00cfcf2222220f0000000000000000000000222220204b4c204b4c20203f00000000cf2d5b5c2b2c5b5c2d3fcf
203fcf000000000d00000000000000000000002020204b4c2020204b4c20203f2929cf1e2222222222222222222222222a2f000d1e22222220202020203fcf00202020202020203f0000000000000000000000cfcfcf00000000000000000000000d0d0000202020205b5c205b5c20203f00001e1f1f2d2d2d3b3c2d2d2d2a2f
202a1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f2020205b5c2020205b5c20202a1f1f1f22204b4c20204b4c20204b4c20222a2f0d22204b4c20204b4c203fcfcf2020204b4c20203f0000001e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f2f0020202020202020202020203f00002222222222222222222222223f
202222222222222222222222222222222222222020202020202020202020202222222220205b5c20205b5c20205b5c2020223f0d20205b5c20205b5c203fcfcf2020205b5c20203fcfcfcf2222222222222222222222222222222222222222222222223f0020202020202020202020203f00002020202020202020202020203f
0000000000000000000000000000000000000000000000003900370000003a00cfcfcfcfcfb3a29393a0a19393939393b3a29393939393939393939393939393b3b3b3b3b3b3b3a293939393939393939393939393939393939393939393939393953f00000000000000000000000000000000cfcfcfcfcfcfcfcfcfcf203fcf
0000000000000000000000000000000000000000000037000000003a00000000cfcfcfcfcfb3a2a4a5b0b1a4a5939393b3a293a4a5939190909293a4a5939393b3a29393a0a1b3a29393a4a59393a4a59393a4a59393a4a59393a4a59393a4a593953f0000000000000000000000000000000000000000000000000000203fcf
0000000000000000000000000000000000000000000038000000000000390037cfcfcf3acfb3a2b4b59393b4b5939393b3a293b4b593949494a293b4b5939393b3b29092b0b1b3a39393b4b59393b4b59393b4b59393b4b59393b4b59393b4b593953f0000000000000000000000000000000000000000000000000000203fcf
0000000000000000000000000000000000000000000000003a00000000000037cf3acfcfcfb3a2939393939393939393b3b2909293939393b3a2939393919293b39494a39393939393939393939393939393939393939393939393939393939393953f0000000000000000000000000000000000000000000000000000203fcf
0000000000000000000000000000000000000000000037370000390000003700cfcfcfcfcfb3a29393a6a79393939393b39494b292939393b3b290909094a293b3b3a3939391909090929393939393939393939393939393939393939393939393953f0000000000000000000000000000000000000000000000000000203fcf
0000000000000000000000000000000000000000000000003700003a00000000cfcf37cfcfb3b29090b6b79090929393b3b3b394a3939391b394949494b3a393b3a293939394949494a3a4a59393a4a59393a4a59393a4a59393a4a59393a4a593953f0000000000000000000000000000000000000000000000000000203fcf
0000000000000000000000000000000000000000000000000000000000000000cfcfcfcfcfb394949494949494b29293b3a2939393939194b3b3b3b3b3a39393b3b290929393b3b3a293b4b59393b4b59393b4b59393b4b59393b4b59393b4b593953f00000000000000000d0d0d0d0d0d000000000000000000000000203fcf
0000000000000000000000000000000000000000003700cf00000000003a0039cfcf37cf0db3b3b3b3b3b3b3b394a393b3a293a4a59394b3b3b3b3b3a3939393b39494a3939393b3a2939393939393939393939393939393939393939393939393953f000000000000000000cfcfcfcfcfcf0000000000000000000000203fcf
0000000000000000000000000000000000000000000000370000000000000000cfcfcfcf0db3b3b3b3b3b3b3b3a39393b3a293b4b5939393b3b3b3a393939393b3b3a393939393b3a2939393939393939393939190909092939393939393939393953f000000000000000000cfcfcfcfcfcfcf00000000000000000000203fcf
0000000000000000000000000000000000000000000039000000003837000037cf37cfcfcf2da29393a0a19393939391b3b2909092939393b3a2939393939393b3a29393939190b3a293a4a59393a4a593939394949494a39393a4a59393a4a593953f0000000000000000000000cf000000cfcfcfcfcf00001e1f1f1f203fcf
0000003032000000000000000000000000000000000000000000000000000000cfcfcf000db3a29393b0b19393939194b3949494b2929393b3a2939393939393b3a29393939494b3a293b4b59393b4b593939393a0a193939393b4b59393b4b593953f0d0000000000000000000000000000cfcfcfcfcf00003d3d3d3d203fcf
00000033340000003031320000000000000000000000003800003a0000000000cfcfcf000db3a2a4a59393a4a59394b3b3b3b3b394b29293b3a2a4a593a4a593b3b2909293b3b3b3a29393939393939190909293b0b19393919090929393939393960f0d0000000000000000000000000e0e0e0000000000002d2b2c2d203fcf
0030323334000000333534000000000000000000000000000000000000000000cfcfcfcf0db3a2b4b59393b4b593b3b3b3b3b3b3b394a393b3a2b4b593b4b593b39494a39393b3b3a2939393939393949494a39393939393949494a3939393939397840d000000001e1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f2d3b3c2d203fcf
0033343334303132333534000030320000000000000000000000000000000000cfcfcfcf0db3a29393939393939393939393939393939393b3a293939393939393939393939393b3a29393939393939393939393939393939393939393939393939784001e1f1f1f222222222222222222222222222222222222222222203fcf
323336313132353433353400003334302d2d2d000000002d0000000000000000cfcfcfcf0db3b29090909090909090909090909090909090b3b290909090909090909090909090b3b2909090909090909090909090909090909090909090909090981f1f2222222220204b4c20204b4c20204b4c20204b4c20204b4c20203fcf
343333353534353433353400003334332d2d2d000000002d0000000000000000cfcfcfcf0db3949494949494949494949494949494949494b39494949494949494949494949494b3949494949494949494949494949494949494949494949494942222222020202020205b5c20205b5c20205b5c20205b5c20205b5c20203fcf
__sfx__
01180020155551855515555185551555518555155551855510555175551355517555105551755513555175551055517555135551755510555175551355517555155551c555185551c555155551c555185551c555
011800001f5501f5501f5501d5501d5501d5501c550185001a5501a5501d5501d55018500175501a5501d5502155021550215502355023550215501f5501d5501c5501c5501f5501f5501850013550185501c550
01180000155501c550185501c550155501c550185501c5500e55015550115500050000500005000050000500105501d550115501d55011550135501f550155501555000500105551055510555105551055510555
0118000024550245500050024550235502355000500235502355023550215502155018500215501f5501d5501f5501f5501d5501d5501c5501a5501a55018550185501850018500185001850015550185501c550
011800080c605000051c6350000510605000051c63500005106050000500005000050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01240020155551855515555185551555518555155551855510555175551355517555105551755513555175551055517555135551755510555175551355517555155551c555185551c555155551c555185551c555
01080000155001850015500185001550018500155001850010500175001350017500105001750013500175001050017500135001750010500175001350017500155001c500185001c500155001c500185001c500
01120000095550b550095550b5501055500000095500b555095500b5551055500500105550050010555005000b5700b570105701057015570155701a5701a5701f5701f570245701d5001f500005001c50000000
0116000028120241002b1002612028120261202410026120261202312026120281202d120241002b120241002812024100241002612028120231202112021120211201a1201d1202112023120181002612000100
01160000101500010010635001001015000100106350e1500e1502d100106352b100151501063513150106351015021100106351a1001015000100106350e1500e1500010010635000000b150106350e15010635
011600001550000000106350000015500000001063511500115000000010635000001850010635106350000000000000001063500000000000000010635000000000000000106350000000000106351063500000
0116000018050106051805010605180500e0001805017050170500b000170501060511050000000e050000000b050000001805010605180500000018050170501705000000170501060513050106351705010635
0116000028120261202b120281202812028120281202812528120261202b12028120281202812028120281252812026120281202b1202b1202d1202b1202f120000002f120240002f1202d1202d1202b12028120
011600000c1400c1400c140181400c140181400c14000000171401714017140181401714018140171401060515140151401514017140171401714018140106051714017140171401814018140181401c14018100
010e0000105400000010540000001d6230000000000185000e540005000e540000001d623000000000000500105400050010540000001d623000000000000000115400050011540005001d6231d6031054029603
010e0000211550010500105001051f1550010500105001051c1550010500105001051815500105001050010518155001051a15500105001050010518155001001c1551c1551a15500100181551a1550010018155
010e0000100451004510045100450e0450e0450e0450e0451004510045100451004513045130451304513045100451004510045100450e0450e0450e0450e0451004510045100451004515045150451504515045
010e00001515517155181551a1550000000000000000000017155181551a1551c15500000000000000000000181551a1551c1551d15500000000000000000000181551a1551c1551a15518155171551515500000
010e00001515515155171551715518155171551515518100171551715518155181551a15518155171551a10018155181551a1551a1551c1551a155181551a1001c1551a155181551715518155171551515500000
010a0000215201f50000000000001f5200000021520000002152000000000001f5001f5201f500215201f500215201f5001f5201f5002152000000235200000000000000001f520000001d520000001c52000000
010a002025530005001c50027500235303c500255301c500255301c5001c500005002353010500255301c500255301c5002353010500255302150026530215002150021500235300050023530000002353000000
010a00001d6231c6031d7331d7431d7531c6031c710000001d6231c6031d7431d7431d7531c6031c710000001d6231c6031d7531d7531d7531c6031c710000001d6231c6031d7531d7531d753000001c70000000
010a0000235201f5000000000000215200000023520000002352000000000001f500215201f500235201f500235201f500215201f50023520000002652000000000000000021520000001f520000001d52000000
010a0020275200050000500005002452010500275200050027520275001c50000500245201c500275201c50027520005002452010500275201c5002a5201c5001c50010500245202a50022520005002052000000
010a0000235202352023500235002152021520215002150023520235202350023500215202152023520235202152021520215002150023520235202652026520265002650021520215001f5201f5001d5201d500
010a00202153500505005050050521535005050050500505215350050500505005052153500505005050050521535005052153524505215352450521535245052153521535215352153521535215052150521505
010a0000215202152021500215001f5201f5202152021520215002150021500215001f5201f520215202152021500215001f5201f5202152021520235202352023500235001f5201f5201d5201d5201c5201c520
010a00002552000000255200000027520000000000000000255200000025520000002a520000000000000000255200000025520000002a520000002c520000002752000000255200000022520000000000000000
010e00001c1551a1551f1551c155180001800018000180001c1551a1551f1551c1551c1051c1051c1051c1051c1551a1551c1551f1551f105211551f155231551800523155180052315521155211051f1551c155
0112000009420104200c4201040009420104200c42010400024200942005420004000040000400004000040004420114200542011420054200742013420094200942000400044250442504425044250442504425
0112000024140241400010024140231402314000100231402314023140211402114018100211401f1401d1401f1401f1401d1401d1401c1401a1401a14018140181401810018100181000c10015140181401c140
01120020094200c420094200c400094200c420094200c400044200b420074200b400044200b420074200b400044200b420074200b400044200b420074200b40009420104200c4201040009420104200c42010420
011200001f1401f1001f1001d1401d1001d1001c140181001a1401a1001d1401d10018100171401a1401d1402114021100211002314023100211401f1401d1401c1401c1001f1401f1001810013140181401c140
011200001f1401f1001f1001d1401d1001d1001c1401c1001a1401a1001d1401d1001f20013140171401a1401d1401d1001d1001c1401c1001c1001a1401a10018140181001c1401c1000000013140171401c140
010e00000e7430000010643000000e7430000010643007000e7430000010643000000e7430000010643007000e7430000010643000000e7430000010643007000c74300700116451164500700116451164500000
010e000004440044401a4000444002440044400744018400094400944018400074400744018400184001840007440074401a4000944007440094400c440184000e4400e440184000c4400c440004000040000400
010e000028500295002850029500285001f5001850023500255402554026500235402354024500265002850018500000000000000000000000000000000000002a5402a540240002854028540000000000000000
010e000004440044401a400044400440004400094001840004440044401a400044400440004400094000740004440044401a4000444004400044000c400004000944009440000000744000000054400444002400
010e000004440044401a4000444002400044400740018400094400940018400074400740018400184001840007440000001a4000944007400094400c440184000e4400e400184000c4400c400004000040000400
010e000004440044401a4000444002400044000740018400094000940018400074000740018400184001840007440074401a4000944007440094400c440184000e4000e400184000c4000c400004000040000400
010e000004440044401a4000444002440044400744018400000000000009440094400744007440184001840007440074401a4000944007440094400c4401840000000000000e4400e4400c4400c4400040000000
010e0000255402554000000255402554000000000002650027540275400000027540275400000000000000002a5402a540000002a5402a540000002c5402c54000000000002c54000000000002a5402754025540
010e000028500295002850029500285001f50018500235000000000000255402554023540235400000024500265002850018500000000000000000000000000000000000002a5402a54028540285400000000000
010e000028540265402b500285402854028500285002850528540265402b50028540285402850028500285052854026540285402b5402b5002d5402b5402f540005002f540245002f5402d5402d5002b54028540
010e00000044000440004000c440004000c44000440004000b4400b4400b4000c4400b4000c4400b440044000944009440094000b4400b4400b4000c440044000b4400b4400b4000c4400c4400c4001044018400
010d0000280200000028020000002b020000002902000000280200000026020000002402000000280202802128021280210000000000240200000026020260212602100000260200000026020000000000000000
010d0000280200000028020000002b02000000290200000028020000002602000000240200000028020280212802128021000000000024020000002b0202b0212b0212b0212b021000002d020000000010000100
010d00002b020000002b020000002d020000002b020000002b00029020280200000029020000002d0202d0212d0212d021000000000024020000002b0202b0212b0212b0212b021000002d020000000000000000
010d0000280200000028020000002b020000002902000000280200000026020000002402000000280202802128021280210000000000240200000026020260202402000000240200000000000000000000000000
010d0000005000050000500005002d5250050000500005002452500500245250050000500005000050000500005000050000500005002d5250050000500005002452500500245250050000500005000050000500
010d00001851018511185111851118511185111a5101a5111a5111a5111a5111a5111a5111a5111c5101c5111c5111c5111c5111c5111c5111c5111a5101a5111a5111a5111a5111a5111a5111a5111a5111a511
010d00001851018511185111851118511185111a5101a5111a5111a5111a5111a5111a5111a5111c5101c5111c5111c5111c5111c5111c5111c51100000000001851000000185100000000000000000000000000
010d00001851018511185111851118511185111a5101a5111a5111a5111a5111a5111a5111a5111c5101c5111c5111c5111c5111c5111c5111c5111f5101f5111f5111f5111f5111f5111f5111f5111f5111f511
011200001f1401f1001f1001d1401d1001d1001c1401c1001a1401a1001d1401d1001f20013140171401a1401d1401d1001f1401d1401c1401a1401a1001c1401c100181001c1001c1000000013140171401a140
000a00060e7501175014750127500e7500d75002700027000270000700007000c70000700007000c70000700007000c70000700007000c70000700007000c7000070000700007000070000700007000070000700
0104000007630086000260000000000000000000000000002d650186501d6501c6501a65018650056500465002650006500465000000000000000000000000000000000000000000000000000000000000000000
00020000155501a5501f5502155000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
0105000029750287502675024750000000000000000000001c6531a63318613146031360311603116030000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200002422024230242402425025250282502c2502f250002000020000200002000020000200002000020000200002000020000200002000020000200002000000000000000000000000000000000000000000
0103000015050180501b0501f05000000000000000000000180501c0501e050210502305023050230001f0000b5700b570105701057015570155701a5701a5701f5701f57024570295001d5000f5000250000000
010c000018063210632b06330063390633b0630070300703007030070300703007030070300703007030070300703007030070300703007030070300000000000000000000000000000000000000000000000000
010a00000066000621006110000000000000000000000000006000060000600006000060000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000025053280202d0200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500002875024750207502075022750277502c7502e7301470000000000000000000000000000000000000287502b050290502b050260502a0502c7502e7300000000000000000000000000000000000000000
__music__
01 00010444
02 02030444
03 05424344
04 46074344
00 0a094c4e
01 0a090b4e
00 080b094d
00 080b094d
00 0c0b0d4d
02 080b094d
01 100e5c54
00 100e0f5c
00 0e104e51
00 100e0f51
00 0e104e51
00 100e1151
00 0e104e51
00 10120e51
00 0e104e51
02 101c0e51
00 19155a44
01 1a611544
00 185c1544
00 13141544
00 16171544
02 1b421544
00 22256444
01 24232244
00 26682244
00 2a282244
00 24232244
00 27292244
00 24232244
02 2c2b2244
00 41424344
00 41424344
00 41424344
01 2d313276
00 2e313444
00 2f313244
04 30313344
01 1f5d5f60
00 1d5d5f60
01 5f4a1f20
00 1e1d5f44
00 211f4344
02 1d354344


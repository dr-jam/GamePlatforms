pico-8 cartridge // http://www.pico-8.com
version 34
__lua__


--lookups
attack, default, roll, dead = "attack", "default", "roll", "dead"
cutscene, gameplay = "cutscene", "gameplay"
melee, ranged, boss = "melee", "ranged", "boss"
---Actors---

--draw layers:
enemy_layer = 4
--2 exit doorway
--4 enemy sprites
--5 player
--6-10 vfx
--11 overlay
actors = {}

function update_actors()
    for layer in all(actors) do
        for actor in all(layer)do
            actor:update()
        end
    end 
end

function draw_actors()
    for layer in all(actors) do
        for actor in all(layer)do
            actor:draw()
        end
    end 
end

function remove_actor(actor)
    del(actors[actor.layer],actor)
    if(actor.die != nil)then
        actor:die()
    end
    --removes any physics bodies
    if(actor.p_body != nil)then
         remove_p_body(actor.p_body)
    end
end

function base_make_actor(position, update, draw, layer)
    local new_actor = {
        state = default,
        layer = layer,
        sprite = nil,
        sprite_size = vec_1,
        flip_x = 1,
        position = vec(position),
        update = update,
        draw = draw
    }
    add(actors[layer], new_actor)
    return new_actor
end

function base_draw_actor(actor)
    spr(actor.sprite,actor.position.x, actor.position.y, actor.sprite_size.x, actor.sprite_size.y, actor.flip_x == -1)
end

---PLAYER ACTOR---

function make_player(position)
    local player = base_make_actor(position, player_update,base_draw_actor,5)
    player.damaged = function(self, attacker, impact, dir)
        if(self.state == roll or self.in_damage) then 
            sfx(15) 
            return 
        end
        self.in_damage = true
        start_coroutine({
            0.05,
            function() 
                self.in_damage = false
                if(attacker and (attacker.state == dead or attacker.t_layer == 2)) return
                if(self.state == roll) then 
                    sfx(15) 
                    return 
                end
                impact()
                self.state = dead
                M_VFX.blood(self.position + vec_4, dir, 7)
                remove_actor(self) 
                start_coroutine({
                    2,
                    function() 
                        sfx(8)
                        start_transition(false, current_level) 
                    end
                })
            end,
        }, true)
    end
    --animations
    player.animations = {
        idle = make_animation("sprite=64,sx=1,sy=1,frame_count=2,frame_interval=0.4"),
        air_up = make_animation("sprite=66,sx=1,sy=1,frame_count=1,frame_interval=100"),
        air_down = make_animation("sprite=67,sx=1,sy=1,frame_count=1,frame_interval=100"),
        walk = make_animation("sprite=68,sx=1,sy=1,frame_count=2,frame_interval=0.15"),
        wall_slide = make_animation("sprite=70,sx=1,sy=1,frame_count=1,frame_interval=100"),
        roll = make_animation("sprite=71,sx=1,sy=1,frame_count=4,frame_interval=0.05"),
        attack_v = make_animation("sprite=75,sx=1,sy=1,frame_count=1,frame_interval=100"),
        attack_h = make_animation("sprite=76,sx=1,sy=1,frame_count=1,frame_interval=100"),
    }
    player.current_animation = player.animations.idle
    --stats
    player.stats = {
        movement = s2t("move_speed=90,accel=22,accel_air=10,jump_vel=0~-155,jump_count=1,jump_control_ratio=0.4,jump_margin=6,walljump_vel=270~-125,wallslide_vel=40,walljump_forgive=6,wallhang_frames=6,is_wall_hanging=false,wall_side=0"),
        roll = s2t("off_cd=true,cd=0.55,duration=0.16,vel=255,dir=0,sfx=11,afimg_c=1"),
        attack = s2t("off_cd=true,cd=0.65,hit_cd=0.2,duration=0.09,h_vel=310,v_vel=285,d_vel=245,h_hitbox=23~8,v_hitbox=10~23,d_hitbox=11~11,swing_sfx=10,hit_sfx=9,p_color=10,s_color=7,streak_c=7") 
    }
    --physics
    local p_body = add_p_body(player, humanoid_p_body_update, 1)
    p_body.friction, p_body.air_friction = 0.83, 0.92
    return player
end

function player_update(player)
    local sts = player.stats
    local p_body, p_mvm, p_roll, p_att = player.p_body, sts.movement, sts.roll, sts.attack
    local cache_dx, grounded = p_body.velocity.x, p_body.grounded
    --timers
    p_mvm.wallhang_frames += 1
    --input
    input_x, input_y = 
    (get_input_held("R") and 1 or 0) + (get_input_held("L") and -1 or 0),
    (get_input_held("D") and 1 or 0) + (get_input_held("U") and -1 or 0)
    --value resetting
    p_mvm.jump_count = grounded and 0 or p_mvm.jump_count --jump_count
    --attacks
    if(get_input_held("attack") and can_perform_attack(player, p_att))then
        perform_melee_attack(player, p_body, p_att, input_x, input_y, {2,3})
    end
    --roll
    if(get_input_held("D") and can_roll(player,p_roll,grounded) and input_x != 0)then
        slow_time(0.05,0.4)
        perform_roll(player, p_body, p_roll, input_x)
    end
    --dropdown
    p_body.drop_down = input_y > 0 and player.state != roll
    if(player.state == default) then
        p_body.friction_on = p_body_move(
            p_body, 
            input_x, 
            p_mvm) == false

        local is_over_max_speed = abs(p_body.velocity.x) > p_mvm.move_speed
        p_body.friction_on = p_body.friction_on or is_over_max_speed
        p_body.friction_scale = is_over_max_speed and 0.4 or 1

        wall_slide_update(player,p_body,p_mvm, input_x, grounded)
        --jumping
        if(get_input_down("jump") and can_jump(p_body, p_mvm)) then
            sfx(6)
            if(p_mvm.is_wall_hanging) then
                local j_vel = vec(p_mvm.walljump_vel)
                j_vel.x *= -p_mvm.wall_side
                p_body_jump(p_body, p_mvm, j_vel)
                M_VFX.jump(player.position + vec_4, -p_mvm.wall_side)
            else
                p_body_jump(p_body, p_mvm, p_mvm.jump_vel)
                M_VFX.jump(player.position + vec(4,8), 0)
            end
        elseif(get_input_up("jump") and p_body.velocity.y < 0) then
            p_body.velocity.y *= p_mvm.jump_control_ratio
        end
    end

    --animations
    if(input_x != 0) then
        player.flip_x = input_x
    end
    humanoid_anims(player, p_mvm, cache_dx)
    update_animation(player)
end

function wall_slide_update(actor, p_body, a_mvm, input_x, grounded)
    --Walljumping
    local wall_jumpable = function()
        a_mvm.is_wall_hanging, a_mvm.jump_count, jump_vel = 
        true,
        0,
        vec(a_mvm.walljump_vel)
        jump_vel.x *= -a_mvm.wall_side
        --slide particles
        M_VFX.sliding(actor.position + vec(8 * (input_x + 1)/2,4))
    end
    --wall sliding
    if(grounded == false) then
        if(p_body.wall_dir != 0 and p_body.wall_dir == input_x)then
            p_body.velocity.y = min(p_body.velocity.y,a_mvm.wallslide_vel)
            a_mvm.wallhang_frames = 0 
            a_mvm.wall_side = input_x
            wall_jumpable()
        elseif(a_mvm.wallhang_frames < a_mvm.walljump_forgive) then
            wall_jumpable()
        else
            a_mvm.is_wall_hanging = false
        end
    else
        a_mvm.is_wall_hanging = false
    end
end

function can_roll(actor,a_roll,grounded)
    return a_roll.off_cd and actor.state == default
end

function perform_roll(actor, p_body, a_roll, dir, variation)
    a_roll.off_cd, a_roll.dir, actor.state, p_body.friction_on, p_body.gravity_scale, variation = false, dir, roll, true, 0, variation or 0
    p_body.velocity = vec(a_roll.dir * (a_roll.vel + rand(-variation,variation)), 0)
    --sfx/vfx
    sfx(a_roll.sfx)
    set_animation_clip(actor,"roll")
    M_VFX.afterimage(actor, a_roll.duration, 20, a_roll.afimg_c)
    M_VFX.wind_streak(actor.position + vec_4 + vec(dir * 8,0), -dir, 15,3,a_roll.afimg_c)
    start_coroutine({
        a_roll.duration,
        function()
            actor.state, p_body.gravity_scale = default, 1
            p_body.velocity.x *= 0.2
        end
    })
    start_coroutine({
        a_roll.cd,
        function() a_roll.off_cd = true end
    })
end

function can_perform_attack(actor, a_att)
    return a_att.off_cd and actor.state == default
end

function perform_melee_attack(actor,p_body,a_att, input_x, input_y, layers, on_contact)
    a_att.off_cd, a_att.cd_timer, actor.state = false, a_att.cd, attack 
    local cd = a_att.cd
    --sfx/vfx
    sfx(a_att.swing_sfx)
    --Actual attack logic
    local vel, pb_size, hb_size, hb_pos = a_att.h_vel, p_body.size
    if(input_y == 0)then
        set_animation_clip(actor,"attack_h")
        hb_size = a_att.h_hitbox
        input_x = (input_x != 0 and input_x) or actor.flip_x
        hb_pos = actor.position +
            vec((input_x - 1) * (hb_size.x/2 - pb_size.x/2),
                (8 - hb_size.y)/2)
    else
        set_animation_clip(actor,"attack_v")
        if(input_x == 0)then
            hb_size = a_att.v_hitbox
            vel, hb_pos = 
            a_att.v_vel,
            actor.position + 
                vec((8 - hb_size.x)/2,
                    (input_y - 1) * (hb_size.y/2 - pb_size.y/2))
        else
            hb_size = a_att.d_hitbox
            vel, hb_pos = 
            a_att.d_vel,
            actor.position +
                vec((input_x - 1) * (hb_size.x+1)/2 + (input_x + 1) * (pb_size.x+1)/2,
                    (input_y - 1) * (hb_size.y+1)/2 + (input_y + 1) * (pb_size.y+1)/2)
        end
    end
    local dir = vec(input_x,input_y):normalized()
    --sweep vfx
    local angle = atan2(input_x,input_y)

    make_sweep_effect(actor, pb_size / 2, 0.12,
        5,7,
        0,5.5,
        angle-0.2, angle+0.4, angle,
        0.15, a_att.p_color, false)
    make_sweep_effect(actor, pb_size / 2, 0.16,
        6,12,
        0,0.5,
        angle-0.2, angle+0.3, angle,
        0.15, a_att.s_color, true)

    local hits = box_cast_all(hb_pos,hb_size, layers)
    local x_lunge = 1
    --remove rolling entities
    if(#hits > 0)then   
        --sfx/vfx
        m_cam.effect_adjust = dir * 10 + rand_vec(-2,2)
        for hit in all(hits)do
            local h_a = hit.actor
            if(hit.layer == 3) x_lunge = 0
            local impact = function()   
                sfx(a_att.hit_sfx)
                local pos = h_a.position + (hit.size * 0.6)
                pos.y -= 2
                local vari, length, width = 22, 200, 2
                make_streak_effect(pos + (dir * length),pos + (dir * -length),0.15,width + ((dir.x != 0 and dir.y != 0) and 1 or 0), a_att.streak_c,vari)
            end
            --target behavior
            if(h_a.damaged) h_a.damaged(h_a,actor, impact, dir)
            --refresh
            if(a_att.hit_cd) cd = a_att.hit_cd 
            ::cont::
        end
        --cd refresh
        --extra effects
        m_cam.effect_adjust = dir * 11 + rand_vec(-2.5,2.5)
        slow_time(0.12,0.0001)
    end

    --lunge physics
    p_body.friction_on, p_body.velocity, p_body.grounded = 
    true, vec(input_x * x_lunge,input_y) * vel, false
    p_body.velocity.y -= 0.1
    p_body.gravity_scale = p_body.velocity.y <= -0.2 and 6 or (p_body.velocity.y >= 0.2 and -4 or 0)
    --timer
    start_coroutine({
        a_att.duration,
        function() 
            actor.state, p_body.gravity_scale = default, 1
            p_body.velocity *= 0.55
        end
    })
    start_coroutine({
        cd,
        function() a_att.off_cd = true end
    })
    return #hits > 0
end

function humanoid_anims(actor, a_mvm, vel_x)
    if(actor.state != default) return
    if(default_ground_anim(actor,vel_x, a_mvm) == false)then
        if(a_mvm.wallhang_frames and a_mvm.wallhang_frames == 0)then
            actor.flip_x = -input_x
            set_animation_clip(actor,"wall_slide")
        elseif(actor.p_body.velocity.y > 0) then
            set_animation_clip(actor,"air_down")
        else
            set_animation_clip(actor,"air_up")
        end
    end
end

function default_ground_anim(actor, x_vel, a_mvm)
    if(actor.p_body.grounded)then
        if(abs(x_vel) > 0)then
            actor.animations.walk.frame_interval = 0.12 + 0.1*max(0,(1 - abs(x_vel)/a_mvm.move_speed))
            set_animation_clip(actor,"walk")
            return true
        else
            set_animation_clip(actor,"idle")
            return true
        end
    end
    return false
end

---Enemies---
function enemy_damaged(self, attacker, impact, dir)
    if(self.state == dead) return
    if(self.state == roll) then 
        sfx(15) 
        return
    end
    impact()
    self.state = dead
    M_VFX.blood(self.position + self.p_body.size/2, dir)
    start_coroutine({
        0.05,
        function() remove_actor(self) end
    })
end

function make_enemy(position, type, facing, left_patrol, right_patrol)
    local enemy = base_make_actor(position, base_enemy_update,base_draw_actor,enemy_layer)
    enemy.damaged = enemy_damaged
    enemy.flip_x = facing
    local close_behavior, mid_behavior, movement, roll, attack, ai = nil
    --animations
    if(type == ranged) then
        enemy.animations = {       
            idle = make_animation("sprite=80,sx=1,sy=1,frame_count=2,frame_interval=0.4"),
            attack = make_animation("sprite=80,sx=1,sy=1,frame_count=2,frame_interval=0.4"),
            air_up = make_animation("sprite=83,sx=1,sy=1,frame_count=1,frame_interval=100"),
            air_down = make_animation("sprite=84,sx=1,sy=1,frame_count=1,frame_interval=100"),
            walk = make_animation("sprite=81,sx=1,sy=1,frame_count=2,frame_interval=0.15")
        }
        close_behavior, mid_behavior, ai, movement, roll, attack = 
        ranged_enemy_close_behavior,
        ranged_enemy_mid_behavior,
        "dx=0,dy=0,target=nil,los=64~18,close_dist=13,mid_dist=48",
        "move_speed=25,walk_speed=20,accel=3,accel_air=2,walking=false,jump_vel=0~-155,jump_cd=0.4,jump_cd_up=true,jump_count=1,jump_control_ratio=0.4,jump_margin=6",
        "off_cd=true,cd=1.3,duration=0.16,vel=225,dir=0,sfx=11,afimg_c=8",
        "off_cd=true,cd=0.9"
    elseif(type == melee) then
        enemy.animations = {
            idle = make_animation("sprite=80,sx=1,sy=1,frame_count=2,frame_interval=0.4"),
            air_up = make_animation("sprite=83,sx=1,sy=1,frame_count=1,frame_interval=100"),
            air_down = make_animation("sprite=84,sx=1,sy=1,frame_count=1,frame_interval=100"),
            walk = make_animation("sprite=81,sx=1,sy=1,frame_count=2,frame_interval=0.15")
        }
        close_behavior, mid_behavior, ai, movement, roll, attack = 
        melee_enemy_close_behavior,
        melee_enemy_mid_behavior,
        "dx=0,dy=0,target=nil,los=64~24,close_dist=19,mid_dist=22",
        "move_speed=95,walk_speed=20,accel=3,accel_air=2,walking=false,jump_vel=0~-155,jump_cd=0.4,jump_cd_up=true,jump_count=1,jump_control_ratio=0.4,jump_margin=6",
        "off_cd=true,cd=1.35,duration=0.15,vel=215,dir=0,sfx=11,afimg_c=8",
        "off_cd=true,cd=0.7,hit_cd=0.6,duration=0.1,h_vel=310,v_vel=290,d_vel=245,h_hitbox=22~7,v_hitbox=7~22,d_hitbox=10~10,swing_sfx=10,hit_sfx=9,p_color=2,s_color=8,streak_c=8"
    elseif(type == boss) then
        enemy.animations = {
            idle = make_animation("sprite=64,sx=1,sy=1,frame_count=2,frame_interval=0.4"),
            air_up = make_animation("sprite=66,sx=1,sy=1,frame_count=1,frame_interval=100"),
            air_down = make_animation("sprite=67,sx=1,sy=1,frame_count=1,frame_interval=100"),
            walk = make_animation("sprite=68,sx=1,sy=1,frame_count=2,frame_interval=0.15"),
            roll = make_animation("sprite=71,sx=1,sy=1,frame_count=4,frame_interval=0.05"),
            attack_v = make_animation("sprite=75,sx=1,sy=1,frame_count=1,frame_interval=100"),
            attack_h = make_animation("sprite=76,sx=1,sy=1,frame_count=1,frame_interval=100"),
        }
        close_behavior, mid_behavior, ai, movement, roll, attack = 
        melee_enemy_close_behavior,
        melee_enemy_mid_behavior,
        "dx=0,dy=0,target=nil,los=64~24,close_dist=19,mid_dist=24",
        "move_speed=100,walk_speed=20,accel=3,accel_air=2,walking=false,jump_vel=0~-155,jump_cd=0.4,jump_cd_up=true,jump_count=1,jump_control_ratio=0.4,jump_margin=6",
        "off_cd=true,cd=0.25,duration=0.15,vel=215,dir=0,sfx=11,afimg_c=8",
        "off_cd=true,cd=0.4,hit_cd=0.4,duration=0.1,h_vel=310,v_vel=290,d_vel=245,h_hitbox=23~7,v_hitbox=7~23,d_hitbox=10~10,swing_sfx=10,hit_sfx=9,p_color=2,s_color=8,streak_c=8"
    
    end
    --Apply stats
    enemy.stats = {
        ai = concat_tbl(
            {
                close_behavior = close_behavior,
                mid_behavior = mid_behavior,
                left_patrol = position + vec(left_patrol,0),
                right_patrol = position + vec(right_patrol,0),
                should_patrol = left_patrol != 0 or right_patrol != 0
            },
            s2t(ai)
        ),
        movement = s2t(movement),
        roll = s2t(roll),
        attack = s2t(attack)
    }
    enemy.current_animation = enemy.animations.idle
    --physics
    add_p_body(enemy, humanoid_p_body_update, 2)
    return enemy
end

function melee_enemy_close_behavior(enemy, p_body, e_att, e_roll, input)
    if(can_perform_attack(enemy,e_att) == false) return
    e_att.off_cd = false
    enemy.state = attack
    p_body.velocity = vec()
    start_coroutine({
        0.02,
        function() if(enemy.state != dead) perform_melee_attack(enemy, p_body, e_att, input.x, input.y, {1}) end
    })
end

function melee_enemy_mid_behavior(enemy, p_body, e_att, e_roll, input)
    if(can_roll(enemy, e_roll, p_body.grounded) == false) return
    perform_roll(enemy, p_body, e_roll, sgn(rand(-1,1)) * enemy.flip_x, 30)
end

function ranged_enemy_close_behavior(enemy, p_body, e_att, e_roll, input)
    if(can_roll(enemy, e_roll, p_body.grounded) == false) return
    perform_roll(enemy, p_body, e_roll, sgn(rand(-1,1)) * enemy.flip_x, 30)
end

function ranged_enemy_mid_behavior(enemy, p_body, e_att, e_roll, input, diff)
    if(can_perform_attack(enemy,e_att) == false) return
    e_att.off_cd = false
    enemy.state = attack
    p_body.velocity = vec()
    set_animation_clip(enemy,"attack")
    start_coroutine({
        0.2,
        function() 
            if(enemy.state == dead) return
            for i = 0,3 do
                local dir = diff:normalized() + rand_vec(-0.2,0.2)
                M_VFX.enemy_muzzle_flash(enemy.position, dir)
                make_projectile(enemy.position + vec_4, dir:normalized(), 250 , 5, 1) 
            end
            enemy.state = default
        end,
        e_att.cd,
        function() e_att.off_cd = true end,
    })
end

function base_enemy_update(enemy)
    local sts = enemy.stats
    local p_body, e_mvm, e_roll, e_att, e_ai = enemy.p_body, sts.movement, sts.roll, sts.attack, sts.ai
    local grounded, input, target = p_body.grounded, vec(), e_ai.target
    e_mvm.jump_count = grounded and 0 or e_mvm.jump_count

    if(target) then
        e_mvm.walking = false
        local diff = target.position - enemy.position
        local dx, dy, dist = diff.x, diff.y, diff:length()
        input = round_to_8(diff)
        --Behavior
        if(target.state != dead) then
            if(dist <= e_ai.close_dist)then
                e_ai.close_behavior(enemy, p_body, e_att, e_roll, input, diff)
            end
            if(dist <= e_ai.mid_dist) then
                e_ai.mid_behavior(enemy,p_body, e_att, e_roll,input, diff)
            end
        else 
            input, dy = vec(), 0
        end
        if(enemy.state == default) then
            p_body.drop_down = input.y > 0
            p_body.friction_on = p_body_move(
                p_body, 
                input.x, 
                e_mvm) == false
            if(dy < -7 and e_mvm.jump_cd_up and can_jump(p_body, e_mvm)) then
                enemy_jump(enemy, p_body, e_mvm)
            end
        end
    else
        input.x = base_enemy_patrol(enemy, p_body, e_mvm, e_ai)
    end
    --animations
    if(input.x != 0) then
        enemy.flip_x = input.x
    end
    humanoid_anims(enemy, e_mvm, input.x)
    update_animation(enemy)
end

function enemy_jump(enemy, p_body, e_mvm)
    e_mvm.jump_cd_up = false
    start_coroutine({
        e_mvm.jump_cd,
        function() e_mvm.jump_cd_up = true end
    })
    p_body_jump(p_body, e_mvm, e_mvm.jump_vel)
    M_VFX.jump(enemy.position + vec(4,8), 0, 1)
end

function base_enemy_patrol(enemy, p_body, e_mvm, e_ai)
    if(enemy.state == dead) return
    --patrol
    local i_x = 0
    if(e_ai.should_patrol) then
        i_x = enemy.position.x < e_ai.left_patrol.x and 1 or (enemy.position.x > e_ai.right_patrol.x and -1 or enemy.flip_x)
        e_mvm.walking = true
        p_body.friction_on = p_body_move(
                p_body, 
                i_x, 
                e_mvm) == false
    end
    --search for targets
    local pos = vec(enemy.position)
    pos.x -= enemy.flip_x == -1 and e_ai.los.x or -8
    pos.y -= (e_ai.los.y - 7)/2
    local hits = box_cast_all(pos, e_ai.los, {1})
    
    if(hits[1] and map_cast(hits[1].actor.position + vec_4, enemy.position + vec_4) == false) then
        sfx(0)
        e_ai.target = hits[1].actor
    end
    return i_x
end

---Projectiles---

function make_projectile(pos, dir, speed, lifetime, t_layer)
    local streak = dir * (-4.5 + rand(-1.5,1.5))
    local p_hits, lx, ly = {}, streak.x, streak.y
    local projectile = base_make_actor( 
        pos,  
        function(self)
            lifetime -= delta_time
            if(lifetime <= 0) then
                remove_actor(self)
                return
            end
            local hits = box_cast_all(self.position,vec(2,2),{self.t_layer})
            local hit = hits[1]
            if(hit and p_hits[hit] == nil) then
                p_hits[hit] = true
                m_cam.effect_adjust = dir * 11 + rand_vec(-2.5,2.5)
                slow_time(0.15,0.0001)
                local h_a = hit.actor
                h_a.damaged(h_a,self,function()
                    sfx(14)
                end, dir)        
            end
        end,
        function(self)
            local pos = self.position
            line(pos.x - lx,pos.y -  ly,pos.x + lx, pos.y + ly, 10)     
        end,
        7
    )
    projectile.damaged = function() 
        sfx(13)
        dir *= -1
        M_VFX.deflect(projectile.position)
        projectile.p_body.velocity *= -1
        projectile.t_layer = 2
    end
    projectile.t_layer = t_layer
    local p_body = add_p_body(projectile,proj_p_body_update, 3)
    p_body.velocity, p_body.friction_on, p_body.gravity_scale, p_body.drop_down, p_body.size = 
    dir * speed, false, 0, true, vec(2,2)
end

---Exit doorway---

function make_level_exit(position)
    local can_end = true
    local exit = base_make_actor( 
        position or vec(0,0),  
        function(self)
            if(#actors[enemy_layer] == 0 and can_end) then
                if(position == nil) then
                    can_end = false
                    start_coroutine({
                        2,
                        function() start_transition(false, current_level.stats.next_state) end
                    })
                    return
                end
                self.sprite = 44
                if(#box_cast_all(position+vec_8,vec_1, {1}) > 0) then
                    can_end = false
                    remove_actor(player)
                    start_transition(false, current_level.stats.next_state)
                end
            end
        end,
        position and base_draw_actor or function() end,
        2
    )
    exit.sprite_size, exit.sprite = vec(2,2), 46    
end

---Physics Bodies---

GRAVITY_ACCELERATION = 325

--layers
-- 1 : player
-- 2 : enemies
-- 3 : enemy projectiles
-- 4: player projectiles
p_bodies = {}

function add_p_body(actor, update, layer)
    local p_body = {
        actor = actor,
        layer = layer,
        update = update
    }
    concat_tbl(p_body,s2t("velocity=0~0,h_dir=0,size=8~8,friction_scale=1,friction_on=true,friction=0.75,air_friction=0.9,gravity_scale=1,air_frames=0,grounded=false,wall_dir=0,drop_down=false"))
    actor.p_body = p_body
    add(p_bodies[layer],p_body)
    return p_body
end

function humanoid_p_body_update(p_body)
    --TEMPORARY
    if(p_body.actor.state == roll)then
        p_body.friction_scale = 0.25
    elseif(p_body.actor.state == attack)then
        p_body.friction_scale = 1.5
    else
        p_body.friction_scale = 1
    end
    --defaults
    base_p_body_update(p_body)
    --air frames
    if(p_body.grounded)then
        p_body.air_frames = 0
    else
        p_body.air_frames += 1
    end
    --updating values
    p_body.h_dir = (p_body.velocity.x == 0 and 0 or 1) * sgn(p_body.velocity.x)
end

function proj_p_body_update(p_body)
    local hit = base_p_body_update(p_body)
    if(hit) remove_actor(p_body.actor)
end

function base_p_body_update(p_body)
    --Gravity
    p_body.velocity.y += GRAVITY_ACCELERATION * p_body.gravity_scale * delta_time
    --friction
    local drag_factor = 1 - (FRAMERATE * delta_time * p_body.friction_scale * (1 - (p_body.grounded and p_body.friction or p_body.air_friction))) 
    if(p_body.friction_on) p_body.velocity.x *= drag_factor

    local h_speed = abs(p_body.velocity.x), abs(p_body.velocity.y)
    if(h_speed < 1) p_body.velocity.x = 0
    --transform using velocity
    local move_vector = p_body.velocity * delta_time
    local new_position = p_body.actor.position + move_vector
    --map collision  
    local interval = max(h_speed,v_speed) > 400 and 0.5 or 1
    return map_collision(p_body, new_position, interval)
end

--generic horizontal p_body movement with acceleration and max speed
function p_body_move(p_body, input_x, a_mvm)
    local accel = p_body.grounded and a_mvm.accel or a_mvm.accel_air
    local max_speed = a_mvm.walking and a_mvm.walk_speed or a_mvm.move_speed
    if(input_x == 0) return false
    local vel = p_body.velocity
    local vel_after = vel.x + input_x * accel
    if(abs(vel.x) < max_speed or p_body.h_dir != input_x) then
        if(abs(vel_after) <= max_speed or p_body.h_dir != input_x)then
            vel.x += input_x * accel
        else
            vel.x = max_speed * input_x
        end       
    end
    return true
end

function can_jump(p_body, a_mvm)
    return a_mvm.jump_count < 1 and (p_body.air_frames < a_mvm.jump_margin or a_mvm.is_wall_hanging)
end

function p_body_jump(p_body, a_mvm, jump_vel)
    a_mvm.wallhang_frames = a_mvm.walljump_forgive
    a_mvm.jump_count += 1
    p_body.velocity.y = 0
    p_body.velocity += jump_vel
end

function update_p_bodies()
    for layer in all(p_bodies) do
        for p_body in all(layer) do
            p_body:update()
        end
    end
end

function remove_p_body(p_body)
    del(p_bodies[p_body.layer],p_body)
    p_body.actor.p_body = nil
end

---Collisions---

function map_collision(p_body, pos, interval)
    local p_a,vel, prev_pos, size, pre_x, pre_dy, resolved_pos = 
    p_body.actor,
    vec(p_body.velocity),
    vec(p_body.actor.position),
    p_body.size,
    pos.x,
    p_body.velocity.y,
    vec(pos)

    local xhit = check_horizontal_map_collision(prev_pos,pos,size,vel, interval, p_a)
    if(xhit != nil) then
        p_body.velocity.x, p_body.wall_dir, vel.x, resolved_pos.x = 
        0, sgn(vel.x), 0, xhit.p_x
    else
        p_body.wall_dir = 0
    end
    local yhit = check_vertical_map_collision(prev_pos,resolved_pos,size,vel, interval, p_a)
    local solid_y_hit = yhit != nil and (yhit.type != 1 or p_body.drop_down == false)
    if(solid_y_hit) then
        p_body.velocity.y, resolved_pos.y = 0, yhit.p_y
    end

    p_body.grounded, p_a.position = 
    solid_y_hit and pre_dy >= 0, resolved_pos
    return solid_y_hit or xhit
end

function check_vertical_map_collision(prev_pos, position, size, vel, interval, actor)
    local offset, flags = 0, 0

    if(vel.y > 0)then
        offset = size.y
    elseif(vel.y == 0)then
        return nil
    end

    --checks at intervals in a partial sweep, to resist speed tunneling a lil bit
    for c = interval, 1, interval do
        local sweep_pos = vec_lerp(prev_pos,position,c)
        for i=0,1 do
            local pos = sweep_pos + vec(i * (size.x - 1), offset)
            local celType = mget_pos(pos)  
            if(fget(celType,0)) then
                return {
                    type = 0,
                    p_y = flr(pos.y/8 - sgn(vel.y)) * 8
                }
            elseif(fget(celType,1)) then
                --platforms
                local hit_data = calc_coll_dists(prev_pos,size,pos_round_to_tile(pos),vec_8)
                if(hit_data.y >= 0 and vel.y >= 0) then
                    return {
                        type = 1,
                        p_y = flr(pos.y/8 - sgn(vel.y)) * 8
                    }
                end
            elseif(fget(celType,2)) then
                --ded
                actor.damaged(actor,nil,function() sfx(16) end,vec())
            end
        end
    end
    return nil
end

function check_horizontal_map_collision(prev_pos, position, size, vel, interval, actor)
    local offset = 0
    if(vel.x > 0)then
        offset = size.x
    elseif (vel.x == 0) then
        return nil
    end

    --checks at intervals in a partial sweep, to resist speed tunneling a lil bit(causes performance problems)
    for c = interval, 1, interval do
        local sweep_pos = vec_lerp(prev_pos,position,c)
        for i=0,1 do
            local pos = sweep_pos + vec(offset,i * (size.y - 1))
            local celType = mget_pos(pos)
            if(fget(celType,0)) then
                --avoid ceiling hits
                local hit_data = calc_coll_dists(prev_pos,size,pos_round_to_tile(pos),vec_8)
                if(hit_data.x >= 0 and hit_data.y <= 0) then
                    return {
                        type = 0,
                        p_x = flr(pos.x/8 - sgn(vel.x)) * 8
                    }
                end
            elseif(fget(celType,2)) then
                --hazard
                actor.damaged(actor,nil,function() sfx(16) end,vec())
            end
        end
    end

    return nil
end

---Camera System---

function make_camera(a_target)
    local cam = {
        camera_target= a_target,
        update=update_camera,
    }
    concat_tbl(cam, s2t("position=0~0,aim_adjust=0~0,aim_mag=16,aim_speed=0.08,effect_adjust=0~0,cam_x=0,cam_y=0"))
    return cam
end

function world_to_cam(pos)
    return pos - vec(m_cam.cam_x,m_cam.cam_y)
end

function update_camera(cam) 
    if(cam.camera_target == nil) return
    local pos = cam.position
    --follow
    local target_pos = cam.camera_target.position + vec(-64, -64)
    --effect resolve
    cam.effect_adjust *= 0.9
    if(cam.effect_adjust:length() < 2)cam.effect_adjust = vec()
    --apply values to the final camera position
    pos = target_pos
    pos += cam.aim_adjust
    cam.cam_x = pos.x + cam.effect_adjust.x
    cam.cam_y = pos.y + cam.effect_adjust.y
    cam.position = pos
end

---Level/Cutscene Data & Utils

function init_scene_data()
    scene_data = {
        cutscene_controls = {
            stats = s2t("type=cutscene,next_state=level_1_data,music=15"),
            dialogue = {
                s2t("text=\nwelcome to *ninja run*.,color=7"),
                s2t("text=the controls are as follows:\n⬅️ - move left \n➡️ - move right\n⬇️ - roll,color=7"),
                s2t("text=\n🅾️ - attack\n❎/spacebar - jump,color=7"),
                s2t("text=you are able to deflect bullets\nwith your attack\nand dodge attacks with your roll,color=7"),
            }
        },
        cutscene_victory = {
            stats = s2t("type=cutscene,next_state=cutscene_controls,music=15"),
            dialogue = {
                s2t("text=\nyou have achieved victory!,color=7"),
                s2t("text=\nin the future we plan to have\nmore levels and maybe a story,color=7"),
            }
        },
        level_1_data = {
            stats = s2t("type=gameplay,next_state=cutscene_victory,player_spawn=84~110,music= 0,exit_door=264~71"),
            enemies = {
                s2t("pos=257~78,type=ranged,facing=-1,l_patrol=0,r_patrol=0"),
                s2t("pos=255~23,type=melee,facing=1,l_patrol=-54,r_patrol=2"),
                s2t("pos=150~24,type=melee,facing=-1,l_patrol=-45,r_patrol=0"),
                s2t("pos=184~46,type=ranged,facing=-1,l_patrol=0,r_patrol=0"),
            }
        },
        level_2_data = {
            stats = s2t("type=gameplay,next_state=cutscene_1_data,player_spawn=308~135,music= 0,exit_door=381~155"),
            enemies = {
                s2t("pos=420~120,type=boss,facing=-1,l_patrol=0,r_patrol=0"),
            }
        }
    }
end

function load_scene(scene)
    if(type(scene) == "string") scene = scene_data[scene]
    local type = scene.stats.type
    if(type == gameplay) load_level(scene)
    if(type == cutscene) load_cutscene(scene)
end

function load_level(level_data)
    local stats = level_data.stats
    game_state = gameplay
    start_transition(true)
    reset_actors_pbodies()
    music(stats.music)
    player = make_player(stats.player_spawn)
    m_cam = make_camera(player)
    --load enemies
    for enemy in all(level_data.enemies) do
        make_enemy(enemy.pos, enemy.type, enemy.facing, enemy.l_patrol, enemy.r_patrol)
    end
    make_level_exit(stats.exit_door)
    current_level = level_data
end

function load_cutscene(cutscene_data)
    local stats = cutscene_data.stats
    game_state = cutscene
    start_transition(true)
    reset_actors_pbodies()
    music(stats.music)
    m_cam = make_camera()
    current_cutscene = cutscene_data
    load_dialogue_block(cutscene_data.dialogue, stats.next_state)
end

---Game States---

--States
--cutscene, gameplay

game_state = nil

---Game Loop---

time_scale = 1
FRAMERATE = 60
current_frame = 0

function _init()
    palt(14, true)
    palt(0, true)
    prev_time, current_time, delta_time, game_time = time(), time(), 1/FRAMERATE, 0
    vec_1, vec_4, vec_8 = vec(1,1), vec(4,4), vec(8,8)
    reset_actors_pbodies()
    setup_input() 
    init_scene_data()
    load_scene(scene_data.cutscene_controls)
end

function reset_actors_pbodies()
    for i=1,10 do
        actors[i] = {}
        p_bodies[i] = {}
    end
end

function _update60()
    update_time()
    update_input()
    update_coroutines()
    if(game_state == gameplay) gameplay_update()
    if(game_state == cutscene) cutscene_update()
    transition:update()
end

function update_time()
    current_time = time()
    raw_delta_time = (current_time - prev_time)
    delta_time = raw_delta_time * time_scale
    game_time += delta_time
    prev_time = current_time
    current_frame += 1
end

function _draw()
    if(game_state == gameplay) gameplay_draw()
    if(game_state == cutscene) cutscene_draw()
    transition:draw()
    --debug
    draw_debug()
end

function cutscene_draw()
    cls(1)
    camera(0,0)
    draw_actors()
    if(dialogue) then
        rectfill(0,96,128,128, 0)
        local data = dialogue.text[dialogue.index]
        print(data.text, 0, 100, data.color)
        print(">", 120, 120, data.color)
    end
end

function cutscene_update()
    if(get_input_down("attack")) progress_dialogue()
end

function gameplay_draw()
    --camerawork
    m_cam:update()
    camera(m_cam.cam_x, m_cam.cam_y)
    cls(0)
    map(0,0,0,0,128,128)
    draw_actors()
    --draw cursor
    local m_pos = get_mouse_position()
    cursor_x, cursor_y, cursor_size =  
    m_pos.x + m_cam.cam_x - 2,
    m_pos.y + m_cam.cam_y - 2,
    vec(5,5)
    rect(cursor_x, cursor_y, cursor_x + 1, cursor_y +1)
end

function gameplay_update()
    update_p_bodies()
    update_actors()
    if(get_input_down("tab")) then
        local e_ai = make_enemy(vec(cursor_x,cursor_y), melee,1, -16, 16).stats.ai
    elseif(get_input_down("tilda")) then
        local e_ai = make_enemy(vec(cursor_x,cursor_y), ranged,1, -16, 16).stats.ai
    end
end

function draw_debug()
    print(game_time, m_cam.cam_x + 105, m_cam.cam_y + 1,9)
    print("debug", m_cam.cam_x, m_cam.cam_y)
    print("fps " .. stat(7))
    print("crouts " .. #coroutines)
    local c = 0
    for layer in all(p_bodies)do
        c += #layer
    end
    print("pb count " .. c)
    c = 0
    for layer in all(actors)do
        c += #layer
    end
    print("act count " .. c)
    print("cpu " .. stat(1))
    print("cursor " .. flr(cursor_x) .. " " .. flr(cursor_y))
    print(test)
end
--Dialogue--
--only one block is loadable at a time(doesnt stack)
function load_dialogue_block(block, next_state)
    dialogue = {
        text = block,
        index = 1,
        next = function()
            start_transition(false, next_state)
        end
    }
end

function progress_dialogue()
    if(dialogue == nil) return
    dialogue.index += 1
    if(dialogue.index > #dialogue.text) then
        dialogue:next()
        dialogue = nil
    end
end

--VFX--

M_VFX = 
{
    sliding = function(pos)
        local size = vec(1,2)
        if(current_frame % 3 == 0) make_particle(pos,size,size,rand_vec(-1,1),1,0.2,7,0)
    end,
    deflect = function(pos)
        local size = vec(1.5,1.5)
        for i = 0,7 do
            make_particle(pos + vec(-4,1), size, size, rand_vec(-50,50):normalized() * 80, 0.5, 0.6 + rand(-0.3,0.1), 9, 0.7 , 8)
            --if M_VFX.deflect.pos == fget(n,f) then
            --M_VFX.deflect.pos += rand_vec(2,2)
            --end
        end
    end,
    enemy_muzzle_flash = function(pos, dir, color)
        local tby_size = vec(2,1)
        local mw_size = vec(4,1)
        for i = 0,7 do
            make_particle(pos + vec(-2,2), tby_size, tby_size, dir * 150 + vec(), 0, 0.2 + rand(-0.1,0.1), 7, 0.5, 8)
            make_particle(pos + vec(-3,3), mw_size, mw_size, dir * 150 + vec(), 0, 0.2 + rand(-0.1,0.1), 7, 0.5, 8)
            make_particle(pos + vec(-2,4), tby_size, tby_size, dir * 150 + vec(), 0, 0.2 + rand(-0.1,0.1), 7, 0.5, 8)
            make_particle(pos + vec(-2,3), tby_size, tby_size, dir * 150 + vec(), 0, 0.2, 10, 0.5, 8)
        end
    end,
    blood = function(pos, dir, color)
        for i = 0,15 do
            local size = rand_vec(2,3)
            make_particle(pos + rand_vec(-6,6), size,size,dir * 150 + rand_vec(-100,100), 0.9, 2, color or 8, 1)
        end
    end,
    jump = function(pos, h_dir, color)
        local c, size = color or 7, h_dir == 0 and vec(2,1) or vec(1,2)
        for i = 0,15 do
            local vel = vec(cos(i/15),sin(i/15))
            if(h_dir == 0) then vel.y /= 3
            else vel.x /= 3 end
            make_particle(pos + vel * 2.5, size,size,vel * 100, 0.15, 0.4 + rand(-0.1,0.1), c, 0,3)
        end
        M_VFX.wind_streak(pos,h_dir,10, 5,c)
    end,
    wind_streak = function(pos, h_dir, len, width, c)
        if(h_dir != 0) then
            local size, size_end, vel = vec(h_dir*-len,1), vec(0,1), vec(h_dir*75,0)
            make_particle(pos + vec(rand(0,h_dir*16),width), size , size_end, vel, 0.8, 0.25, c, 0,3)
            make_particle(pos + vec(rand(0,h_dir*16),-width), size , size_end, vel, 0.8, 0.25, c, 0,3)
        else
            local size, size_end, vel =vec(1,len), vec(1,0), vec()
            make_particle(pos + vec(width,rand(-15,-5)), size, size_end,vel, 0.8, 0.25, c, -0.6,3)
            make_particle(pos + vec(-width,rand(-15,-5)), size, size_end,vel, 0.8, 0.25, c, -0.6,3)
        end
    end,
    afterimage = function(actor, duration, count, color)
        --don't look at this shit lmao
        local shadow = function() 
            local size = rand_vec(2,4)
            make_particle(actor.position + rand_vec(2,4), size,size,vec(), 0, 0.15, color, 0, 2) 
        end
        for i = 0,count do
            start_coroutine({
                duration/count * i,
                shadow
            })      
        end
    end
}

--particles are simple enough to not require a physics body
function make_particle(pos, size, size_end, velocity, drag, lifetime, color, grav_scale, layer)
    local lifetimer, b_size = lifetime, vec(size)
    local particle = base_make_actor( 
        pos,  
        function(self)
            lifetimer -= delta_time
            if(lifetimer <= 0) then
                remove_actor(self)
                return
            end
            local vel, t = velocity, 1 - lifetimer / lifetime
            vel.y += GRAVITY_ACCELERATION * grav_scale * delta_time
            vel = vel * drag
            size = vec_lerp(b_size,size_end,t)
            pos += vel * delta_time
        end,
        function(self)
            rectfill(pos.x,pos.y,pos.x+size.x - 1,pos.y+size.y - 1,color)     
        end,
        layer or 6
    )
end

function start_transition(fadein, next_state)
    if(fadein) then make_transition(0,128,128,128,1.8)
    else make_transition(0,0,0,128,1.8) end
    if(next_state == nil) return
    start_coroutine({
        1.75,
        function() 
            load_scene(next_state)
        end
    },true)
end

function make_transition(l1, l2, r1, r2, duration, color)
    input_enabled = false
    local timer, l, r = duration, l1, r1
    transition = {
        update = function(self)
            timer -= raw_delta_time
            if(timer <= 0) then
                l,r = -1,-1
                input_enabled = true
                return
            end
            local t = smooth(1 - timer / duration)
            l, r = lerp(l1,l2,t), lerp(r1,r2,t)
        end,
        draw = function(self)
            rectfill(l + m_cam.cam_x,m_cam.cam_y, m_cam.cam_x + r,m_cam.cam_y + 128 , 0)
        end,
    }
end

function make_streak_effect(pos_1,pos_2, duration, width, color,rand)
    local variation = rand_vec(-rand,rand)
    pos_1 += variation
    pos_2 -= variation
    local dist = (pos_2 - pos_1):length()
    local slash = base_make_actor(
        vec(),
        function(self) 
            self.timer -= delta_time
            if(self.timer <= 0) then 
                remove_actor(self) 
                return 
            end
            local t = self.timer / duration
            self.c_width = flr(width * t + 0.5)
            pos_2 = pos_1 + (self.dir * (t * dist))
        end,
        function(self) 
            base_draw_line(pos_1,pos_2,self.c_width,color)
        end,
        8
    )
    slash.timer, slash.c_width, slash.c = duration, width, vec(pos_2)
    slash.dir = (slash.c - pos_1):normalized()
end

function make_sweep_effect(tracked_actor, offset, duration,
    min_radius, max_radius,
    min_width, max_width,
    start_angle, end_angle,mid_angle,
    start_t, color, sharp)
    local sweep = base_make_actor(
        vec(),
        function(self) 
            self.timer -= delta_time
            if(self.timer <= 0) then 
                remove_actor(self) 
                return 
            end
            local t = start_t + (1 - self.timer / duration) * (1-start_t)
            self.c_angle = lerp(start_angle,end_angle,t)
        end,
        function(self) 
            draw_sweep_vfx(tracked_actor.position + offset,
            min_radius,max_radius,
            min_width,max_width,
            start_angle,end_angle,mid_angle, self.c_angle,
            color, sharp)
        end,
        7
    )
    sweep.timer, sweep.c_angle = duration, start_angle
end

--VFX draw functions--

function base_draw_line(pos_1,pos_2,width,color)
    if(width == 1)then
        line(pos_1.x,pos_1.y,pos_2.x,pos_2.y,color)
        return
    end
    width -= 1
    local perp = vec(pos_2.y - pos_1.y,pos_1.x-pos_2.x)
    local x_o, y_o = sgn(perp.x), sgn(perp.y)
    perp = perp:normalized()
    for i = -width/2, width/2-1, 1 do
        local pos1 = pos_1 + (perp * i)
        local pos2 = pos_2 + (perp * i)
        line(pos1.x,pos1.y,pos2.x,pos2.y,color)
        line(pos1.x,pos1.y+y_o,pos2.x,pos2.y+y_o,color)
        line(pos1.x+x_o,pos1.y,pos2.x+x_o,pos2.y,color)
    end
end

function draw_sweep_vfx(position,
    min_radius, max_radius,
    min_width, max_width,
    a_start,a_end, a_mid, a_current,
    color, sharp)
    local interval,px,py = 1/90 * sgn(a_end - a_start), position.x, position.y
    local draw_segment = function(_start,_end,_current, invert)
        for i = _start, min(_current,_end), interval do
            local t = (i - _start)/(_end-_start)
            t = invert and 1 - t or t
            radius = lerp(min_radius,max_radius,sharp and t or smooth(t))
            radius2 = radius + max(0,lerp(min_width,max_width,t))
            local x,y = cos(i), sin(i)
            if(radius2 != radius) line(x*radius + px,y*radius + py, flr(x*radius2 + px), flr(y*radius2 + py), color)
        end
    end
    draw_segment(a_start,a_mid,a_current, false)
    draw_segment(a_mid,a_end,a_current, true)
    
end

--Animation System--
--sprite, sx,sy , frame_count, frame_interval
function make_animation(data_string)
    local anim_clip = s2t(data_string)
    anim_clip.timer, anim_clip.current_frame, anim_clip.size = 0, 0, vec(anim_clip.sx,anim_clip.sy)
    return anim_clip
end

function update_animation(actor)
    local clip = actor.current_animation
    clip.timer += delta_time
    if(clip.timer >= clip.frame_interval) clip.timer, clip.current_frame = 0, (clip.current_frame + 1) % clip.frame_count
    actor.sprite = clip.sprite + clip.current_frame * clip.size.x
end

function set_animation_clip(actor, clip_name)
    local c_anim = actor.current_animation
    if(c_anim == actor.animations[clip_name] or actor.animations[clip_name] == nil) return
    c_anim = actor.animations[clip_name]
    c_anim.current_frame, c_anim.timer = 0,0
    actor.current_animation = c_anim
end

--Math & util functions--

function clamp(value,lower,upper)
    if(value < lower) then
        return lower
    elseif(value > upper) then
        return upper
    end
    return value
end

function lerp(a,b,t)
    t = clamp(t,0,1)
    return a + (b-a)*t
end

function rand(l,r)
    if(l > r) l,r = r,l
    local val = rnd(r-l) + l
    return val
end

function rand_vec(l,r)
    return vec(rand(l,r),rand(l,r))
end

function smooth(t)
    return t*t*t *(t * (6*t - 15) + 10)
end

function s2t(data)
    local res = {}
    local props = split(data,",")
    for prop in all(props)do
        local components = split(prop,"=")
        local rhs = components[2]
        if(type(rhs) == "number") then rhs = tonum(rhs)
        elseif(rhs == "false") then rhs = false
        elseif(rhs == "true") then rhs = true
        elseif(rhs == "nil") then rhs = nil
        else 
            local p_vec = split(rhs,"~")
            if(#p_vec == 2) rhs = vec(tonum(p_vec[1]),tonum(p_vec[2]))
        end
        res[components[1]] = rhs
    end
    return res
end

function concat_tbl(t1,t2)
    for k,v in pairs(t2) do t1[k] = v end
    return t1
end

--Vectors--

vec_mt = {}

function vec_lerp(a,b,t)
    return vec(lerp(a.x,b.x,t),lerp(a.y,b.y,t))
end

function vec(x,y)
    if(x == nil) return vec(0,0)
    local vec = {
		x=x,
		y=y,		
		length=function(self) return 100*sqrt((self.x/100)^2 + (self.y/100)^2) end,		
		normalized=function(self)        
            local len = self:length()
            if(len == 0) return vec()
			return self / len
		end
	}
    if(type(x) != "number") vec.x, vec.y = x.x, x.y
    setmetatable(vec,vec_mt)
	return vec
end

function vec_mt.__add(a, b)
    return vec(a.x + b.x, a.y + b.y)
end

function vec_mt.__sub(a,b)
    return vec(a.x - b.x, a.y - b.y)
end

function vec_mt.__mul(a, b)
    return vec(a.x * b, a.y * b)
end

function vec_mt.__div(a, b)
    return vec(a.x / b, a.y / b)
end

function pos_round_to_tile(position)
    local rounded = vec(position)
    rounded.x, rounded.y = flr(rounded.x / 8) * 8, flr(rounded.y / 8) * 8
    return rounded
end

r_tbl = {vec(1,0),vec(1,-1),vec(0,-1),vec(-1,-1),vec(-1,0),vec(-1,1),vec(0,1),vec(1,1),vec(1,0)}
function round_to_8(v)
    local round = flr(atan2(v.x,v.y) * 8 + 0.5) + 1
    return r_tbl[round]
end

function mget_pos(position)
    return mget(position.x/8,position.y/8)
end

function map_cast(pos1,pos2)
    local intervals = (pos1 - pos2):length() / 8 + 1
    for i = 0, intervals do 
        if(fget(mget_pos(vec_lerp(pos1,pos2,i/intervals)),0)) return true
    end
    return false
end

function AABintersection_check(pos_1, size_1, pos_2, size_2)
    if(pos_1.x + size_1.x < pos_2.x)then
        return false
    elseif(pos_2.x + size_2.x < pos_1.x)then
        return false
    end

    if(pos_1.y + size_1.y < pos_2.y)then
        return false
    elseif(pos_2.y + size_2.y < pos_1.y)then
        return false
    end
    return true
end

function box_cast_all(pos,size,layers)
    local hits = {}
    for layer in all(layers)do
        for body in all(p_bodies[layer])do
            if(AABintersection_check(pos,size,body.actor.position,body.size)) add(hits,body)
        end
    end
    return hits
end

function calc_coll_dists(pos_1, size_1, pos_2, size_2)
    local dx,dy, x1, x2, y1, y2 = 0,0, pos_1.x, pos_2.x, pos_1.y, pos_2.y
    if(x1 < x2)then
        dx = x2 - (x1 + size_1.x)
    elseif(x1 > x2) then
        dx = x1 - (x2 + size_2.x)
    end
    if(y1 < y2)then
        dy = y2 - (y1 + size_1.y)
    elseif(y1 > y2) then
        dy = y1 - (y2 + size_2.y)
    end
    return{
        x = dx,
        y = dy
    }
end

function calc_coll_time(pos_1, size_1, vel, pos_2, size_2)
    local dists = calc_coll_dists(pos_1,size_1,pos_2,size_2)

    local dx,dy = dists.x,dists.y

    local t_x,t_y, shortest_time, shortest_axis = 
    vel.x == 0 and 0 or abs(dx / vel.x),
    vel.y == 0 and 0 or abs(dy / vel.y),
    0, 0

    if(vel.x != 0 and vel.y == 0)then
        shortest_axis, shortest_time = 0, t_x
    elseif(vel.x == 0 and vel.y != 0)then
        shortest_axis, shortest_time = 1, t_y
    else
        if(t_x > t_y) shortest_axis = 1
        shortest_time = min(t_x,t_y)
    end
    return {time = shortest_time, axis = shortest_axis,dx = dx, dy = dy}
end

--Input System--

--raw keyboard mapping uses SDL keycodes, included a p8 cartridge that prints the keycode of whatever key you press (keycode.p8)
raw_keyboard_map = s2t("44=jump,43=tab,53=tilda,4=L,7=R,26=U,22=D,17=attack,16=jump")


default_input_map = {
    L = s2t("b=0,p=0"),
    R = s2t("b=1,p=0"),
    U = s2t("b=2,p=0"),
    D = s2t("b=3,p=0"),
    attack = s2t("b=4,p=0"),
    jump = s2t("b=5,p=0"),
}

--interface with this when getting input!
--value is a bitmap, (left_patrol to right_patrol) bit 1 is pressed in the last frame, bit 2 is currently pressed, bit 3 is pressed down in this update, bit 4 is released in this update

input_states = s2t("L=0,R=0,U=0,D=0,jump=0,attack=0,tab=0,tilda=0")

function setup_input()
    poke(0x5f2d, 1|2|4)
end

function update_input()
    --mouse position
    mouse_x = stat(32)
    mouse_y = stat(33)
    --reset all states, move pressed into "was pressed last frame" bit
    for input_map, state in pairs(input_states) do
        input_states[input_map] = (state << 1) & 8
    end
    --process raw keyboard inputs
    if(input_enabled)then
        for  keycode, input_map in pairs(raw_keyboard_map) do
            input_states[input_map] |= stat(28,keycode) and 4 or 0
        end
        --process default (btn) inputs
        for input_map, default_input  in pairs(default_input_map) do
            input_states[input_map] |= btn(default_input.b,default_input.p) and 4 or 0
        end
    end
    --calculates if it was pressed down or released in this frame
    for input_map, state in pairs(input_states) do
        if(state & 8 == 8) then
            --released this frame
            if(state & 4 != 4) input_states[input_map] |= 1
        else
            --down this frame
            if(state & 4 == 4) input_states[input_map] |= 2
        end
    end
end

function get_mouse_position()
    return vec(mouse_x,mouse_y)
end

function get_input_state(input_name, flag)
    local state = input_states[input_name]
    return (state & flag == flag)
end

function get_input_held(_input_name)
    return get_input_state(_input_name,4)
end

function get_input_down(_input_name)
    return get_input_state(_input_name,2)
end

function get_input_up(_input_name)
    return get_input_state(_input_name,1)
end


--Extremely Simplified Coroutine System--

coroutines = {}

function update_coroutines()
    for i = #(coroutines), 1, -1 do
        local corout = coroutines[i]
        corout.timer += corout.raw and raw_delta_time or delta_time
        --check if timer has elapsed through delay
        if(corout.timer >= corout.cList[corout.index]) then
            corout.timer = 0
            corout.index += 1
            --progress coroutien, if coroutine has ended, then kaboom
            if(progress_coroutine(corout) == false) del(coroutines,corout)     
        end        
    end
end

function progress_coroutine(corout)
    --iterates through coroutine commands and runs them, until a delay is found(or coroutine has ended)
    for i = corout.index, #(corout.cList) do
        local command = corout.cList[i]
        corout.index = i
        if(type(command) == "number")then
            break
        else
            command()
        end
    end
    if(corout.index >= #(corout.cList))then
        return false
    end
    return true
end

-- coroutine_list format - either floats(delay) or functions
function start_coroutine(coroutine_list, raw)
    local corout = {
        raw = raw,
        cList = coroutine_list,
        index = 1,
        timer = 0
    }
    --instantly run any starting functions to avoid single frame delays(unity you bitch)
    if(progress_coroutine(corout))then
        add(coroutines,corout)
    end   
    return corout 
end

function clear_all_coroutines()
    coroutines = {}
end

function stop_coroutine(coroutine)
    del(coroutines,coroutine)
end

function slow_time(duration, scale)
    stop_coroutine(time_slow)
    time_scale *= scale
    time_slow = start_coroutine({
        duration,
        function() time_scale = 1 end
    }, true)
end

__gfx__
000000004444444444444444dddddddddddddddd661111111111111111111166dddddddd66666666666666666555555600000000000000000000000000000000
000000004cccccccccccccc4dddddddddddddddd611111111111111111111116dddddddd66666666666666665777777500000000000000000000000000000000
000000004ccc11111111ccc4ddccccccccccccdd111111111111111111111111dddddddd66666666666666665777777500000000000000000000000000000000
000000004ccc1f0ff0f1ccc4ddccccccccccccdd111111111111111111111111dddddddd66666666666666665777777500000000000000000000000000000000
000000004ccc1ffffff1ccc4ddc0000cc00000dd111111111111111111111111dddddddd66666666666336665777777500000000000000000000000000000000
000000004ccc11111111ccc4ddcffffc00fff0dd111111111111111111111111dddddddd66666666663333665777777500000000000000000000000000000000
000000004ccc11111111ccc4ddcffffc0ffff0dd111111111111111111111111dddddddd66666666633333365777777500000000000000000000000000000000
000000004cccc111111cccc4ddcffffc0ffff0dd111111111111111111111111dddddddd66666666333333336555555600000000000000000000000000000000
888888884ccc11111111ccc4dd777777ceeeefdd44444444444444444444444466ccccc77ccccc66666556666666666600000000000000000000000000000000
999999994cc11111111115c4ddf7777000eeefdd4442222233333111116666446cccccc77cccccc6666556666666666600000000000000000000000000000000
aaaaaaaa4c11c111111c15c4ddf7777fffeecfdd444222223333311111666644ccccccc77ccccccc666556666666666600000000000000000000000000000000
77777777411cc11cc11c5554ddc1cc1fffeeeedd444227223373311711667644ccccccc77ccccccc666556666666666600000000000000000000000000000000
7777777741ccc11cc11cc6c4ddc1cf33333feedd444227223373311711667644ccccccc77ccccccc666556664444444400000000000000000000000000000000
aaaaaaaa4cccc11cc11cc6c4ddc1fc1333ccfcdd444227223373311711667644ccccccc77ccccccc666556664444444400000000000000000000000000000000
999999994cccc11cc11cc6c4dddddddddddddddd444227223373311711667644ccccccc77ccccccc666556664444444400000000000000000000000000000000
888888884444444444444444dddddddddddddddd444227223373311711667644ccccccc77ccccccc666556664444444400000000000000000000000000000000
5555555544444544444445444444454411111111444222223333311111666644ccccccc77ccccccc666666666666666644666555555666444466655555566644
5500005544444544444445444444454411111111444222223333311111666644ccccccc77ccccccc666666666666666646665bbbbbb566644666588888856664
5050050544466666666645444444454411111111444444444444444444444444ccccccc77ccccccc666666666666666666665bbbbbb566666666588888856666
50055005552222222222255555555555111111114444444444444444444444447777777777777777666655566555666666666555555666666666655555566666
50055005442222222222244444544444111111114444444444444444444444447777777777777777666544455444566666666666666666666666666666666666
5050050544222222222224444454444411111111444444444444444444444444ccccccc77ccccccc666544455444566666655555555556666665555555555666
5500005544222222222224444454444411111111444333111122220000555544ccccccc77ccccccc666544455444566666651110100056666665666656665666
5555555555666666666665555555555511111111444333111122220000555544ccccccc77ccccccc666655566555666666651111010056666665666656665666
6666666644222222222225444444ffffffff4544444333111122220000555544ccccccc77ccccccc666544455444566666651110100056666665666656665666
5555555544222222222225444ffff000000ffff4444373117127220700575544ccccccc77ccccccc666544455444566666651111010056666665666566665666
5466664544222222222225444ffffffffffffff4444373117127220700575544ccccccc77ccccccc666544455444566666651110100056666665666566665666
5644456555222222222225555ffffffffffffff5444373117127220700575544ccccccc77ccccccc666544455444566666651111010056666665666566665666
6555555644666666666664444ffffffffffffff4444333117127220700575544ccccccc77ccccccc666544455444566666651110100056666665666566665666
4454444444222222222224444ffffffffffffff4444333111122220000555544ccccccc77ccccccc666544455444566666651111010056666665666656665666
4454444444222222222224444ffffffffffffff44443331111222200005555447777777777777777666544455444566666651110100056666665666656665666
5555555555522222222255555ffffffffffffff54444444444444444444444447777777777777777666544455444566666651111010056666665666656665666
00101100000000000000000001100000100000000110110000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101110001101100000110000001110001101100100111001101100001101100000000000000010000000000000110a00010faa0000000000000000000000000
0101f100100111000011110000001110000111000001f10010111000111111000001101100040010000a00000011110a0101110a000000000000000000000000
000771000001f1000101f1fa40011f100001f100000771f0001f10a011111f00000111110004f011000f4000a101f1fa0101f1fa000000000000000000000000
000777fa000771fa0107714004477100444771f00007774af7710400000777f00001111f00f557f11f7755f0af07104a4407710a000000000000000000000000
0005574000077740444755000005774a0005574a4445570007774f004447774a4455774a000577f1117755000005570a0045574a000000000000000000000000
4445550044455500000555f000f5550000f555000005550055550000000555000f55770000057711011145f0004555a0000555a0000000000000000000000000
000f0f00000f0f0000f00000000000f0000000f00000ff00f550000000ff00f0000f00f00000af000001410044f000f000faaaf0000000000000000000000000
00808880000000000080888000008880008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088ff00080888000088ff0008888f00008888000e00e0000000000000000000000000000000000000000000000000000000000000000000000000000000000
0080888000088ff00080888000088f8000888f8000e00e0000000000000000000000000000000000000000000000000000000000000000000000000000000000
000885000080888000088500008885020f0088f000e00e0000000000000000000000000000000000000000000000000000000000000000000000000000000000
000858f20f08850000f858f2000858fd000885000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f0555d0000555f2ddd555d00f0555d0ddd555f000e00e0000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd888f0ddd888df0008880000d8888f00f888d2000ee00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00f000f000f000f0000ff000ddf00000000000f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000004000000010000000000000000000000010000000100000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
2323232323232323202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323202323232323232323232323232323232323232323232323232323202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323202323232323232323232323232323232323232323232323232323202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323202323232323232323232323232323232323232323232323232323202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323202323232320303030303020232323232320303030303030202323202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323202323232320232323232323232323232323232323232323202323202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323202323232320232323232323232323232323232323232323202323202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323202323232320232323303020202030302323232323232323202323202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323202323232320232323232320232023232323232323232323202323202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323202323232320232323202020232020202023232323232323232e2f202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323202323232320232323202323232323232023232323232323233e3f202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323202323232320232323202323232323232323232323232323242424202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323030423202323232323232323232323232323232323232323242424242424202020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323131423202323232321222323232323232323232323232424242424242424000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2323232323232323202323232331322323333423232323232324242424242424242424000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2424242424242424242424242424242424242424242424242424242424242424242424000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2424242424242424242424242424242424242424242424242424242424242424242424000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2424242424242424242424242424242424242424242424242424242424242424242424000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2424242424242424242424242424242424242424242424242424242424242424242424000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2424242424242424242424242424242424242424242424242424242424242424242424000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2424242424242424242424242424242424242424242424242424242424242424242424000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2424242424242424242424242424242424242424242424242424242424242424242424000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
27050000250412b041330413d04100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000200c0430000000000000000c0430000000000000000c0430000000000000000c0430000000000000000c0430000000000000000c0430000000000000000c0430000000000000000c043000000000000000
291000000000000000021400202502110020400212002015021400202502110020400212002015021400201002140020200211502040021200201002140020250211002040021250201002140020100214502013
9110000021040211201d11021040230201c11021140230201a0101a140211202301024040241202f1102d04021040211201d11021040230201c11021140230201a0101a140211202301024040241202f1102d040
011000000000000000280452302524015210452302523015280452302524015210452302523015280452302524015210452302523015280452302524015210452302523015280452302524015210452302523015
0701000028620276201b620275000b5001f5001e50021500254202542028420302203230032200321003d7003f7003f5003f7003f70034700327002e6002b2002820025200212001d2001a2001f7000000000000
9e0200000c2700e2701057011550130501505017740187401a7401c74000000000000000000000000000000000000000000000000000000003220032200322003220032200322003220032200312003120031200
0003000027050300501d7001d7001e7001e7001c7001c70021700207001e7001c7001b7001970018700167001470013700117000f7000d7000c70000000000000000000000000000000000000000000000000000
490f0000363502c35032350283502d34022340283301f330243201e32018320183101831000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4903000022670000001e640066000000000000000000000000000000000000000000000001e600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09030000116141f6222f7312f7412f5312f5212f5112f5112f5150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300000c6140c6210c631186311863118621186111861118611186110c6110c6150060000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01030000116141f6222f7312f7412f5312f5212f5112f5112f5150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
27030000390523f042390323902239012390000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01030000116241f652116421754217542116421753217521175150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300001811418121182312433124531246212431124311243112461118311183150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300000c1140c1210c231183311853118621183111831118311186110c3110c3150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 01464344
00 01024344
00 01024344
00 01024304
00 01024304
00 01424304
00 01424304
00 01420304
00 01420304
00 01020304
00 01020304
00 01020344
00 01020344
00 01420344
02 01420344
03 01424344


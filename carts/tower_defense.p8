pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
function choose_tower(id)
  selected_menu_tower_id = id
  get_active_menu().enable = false
  shop_enable = false
end
function display_tower_info(tower_id, position, text_color)
  local position_offset = position + Vec:new(-1, -31)
  local tower_details = global_table_data.tower_templates[tower_id]
  local texts = {
    {text = tower_details.name}, 
    {text = tower_details.prefix..": "..tower_details.damage}
  }
  local longest_str_len = longest_menu_str(texts)*5+4
  BorderRect.resize(
    tower_stats_background_rect,
    position_offset, 
    Vec:new(longest_str_len + 20,27
  ))
  BorderRect.draw(tower_stats_background_rect)
  print_with_outline(
    tower_details.name,
    combine_and_unpack({Vec.unpack(position_offset + Vec:new(4, 2))},
    text_color
  ))
  print_with_outline(
    texts[2].text,
    combine_and_unpack({Vec.unpack(position_offset + Vec:new(4, 14))},
    {7, 0}
  ))
  print_with_outline(
    "cost: "..tower_details.cost, 
    combine_and_unpack({Vec.unpack(position_offset + Vec:new(4, 21))},
    {(coins >= tower_details.cost) and 3 or 8, 0}
  ))
  spr(
    tower_details.icon_data, 
    combine_and_unpack(
      {Vec.unpack(tower_stats_background_rect.position + Vec:new(longest_str_len, 6))},
      {2, 2}
  ))
end
function display_tower_rotation(menu_pos, position)
  local tower_details = global_table_data.tower_templates[selected_menu_tower_id]
  local position_offset = position + Vec:new(0, -28)
  BorderRect.reposition(tower_rotation_background_rect, position_offset)
  BorderRect.draw(tower_rotation_background_rect)
  local sprite_position = position_offset + Vec:new(4, 4)
  if tower_details.disable_icon_rotation then 
    spr(tower_details.icon_data, combine_and_unpack({Vec.unpack(sprite_position)},{2, 2}))
  else
    draw_sprite_rotated(global_table_data.tower_icon_background,
      position_offset, 24, parse_direction(direction)
    )
    draw_sprite_rotated(tower_details.icon_data, sprite_position, 16, parse_direction(direction))
  end
end
function start_round()
  if (start_next_wave or #enemies ~= 0) return
  start_next_wave,enemies_active = true,true
  wave_round = min(wave_round + 1, #global_table_data.wave_data)
  if (wave_round == #global_table_data.wave_data) freeplay_rounds += 1
  enemies_remaining = #global_table_data.wave_data[wave_round]
  get_active_menu().enable = false
  shop_enable = false
end
function get_active_menu()
  for menu in all(menus) do
    if (menu.enable) return menu
  end
end
function get_menu(name)
  for menu in all(menus) do
    if (menu.name == name) return menu
  end
end
function swap_menu_context(name)
  get_active_menu().enable = false
  get_menu(name).enable = true
end
function longest_menu_str(data)
  local len = 0
  for str in all(data) do
    len = max(len, #str.text)
  end
  return len
end
function get_tower_data_for_menu()
  local menu_content = {}
  for i, tower_details in pairs(global_table_data.tower_templates) do
    add(menu_content, {
      text = tower_details.name,
      color = tower_details.text_color,
      callback = choose_tower, args = {i}
    })
  end
  return menu_content
end
function get_map_data_for_menu()
  local menu_content = {}
  for i, map_data in pairs(global_table_data.map_data) do
    add(menu_content, 
      {text = map_data.name, color = {7, 0}, callback = load_game, args = {i}}
    )
  end
  return menu_content
end
function load_game(map_id)
  pal()
  auto_start_wave = false
  wave_round = 0
  freeplay_rounds = 0
  loaded_map = map_id
  pathing = parse_path()
  for i=1, 3 do
    add(incoming_hint, Animator:new(global_table_data.animation_data.incoming_hint, true))
  end
  for y=0, 15 do 
    grid[y] = {}
    for x=0, 15 do 
      grid[y][x] = "empty"
      if (not placable_tile_location(Vec:new(x, y) + Vec:new(global_table_data.map_data[loaded_map].mget_shift))) grid[y][x] = "path" 
    end
  end
  music(15)
end
global_table_str="tower_icon_background=80,palettes={transparent_color_id=0,dark_mode={1=0,5=1,6=5,7=6},attack_tile={0=2,7=14},shadows={0=0,1=0,2=0,3=0,4=0,5=0,6=0,7=0,8=0,9=0,10=0,11=0,12=0,13=0,14=0,15=0}},sfx_data={round_complete=10},freeplay_stats={hp=2,speed=1,min_step_delay=3},map_meta_data={path_flag_id=0,non_path_flag_id=1},map_data={{name=curves,mget_shift={0,0},enemy_spawn_location={0,1},enemy_end_location={15,11},movement_direction={1,0}},{name=loop,mget_shift={16,0},enemy_spawn_location={0,1},enemy_end_location={15,11},movement_direction={1,0}},{name=straight,mget_shift={32,0},enemy_spawn_location={0,1},enemy_end_location={15,2},movement_direction={1,0}},{name=u-turn,mget_shift={48,0},enemy_spawn_location={0,1},enemy_end_location={0,6},movement_direction={1,0}}},animation_data={spark={data={{sprite=10},{sprite=11},{sprite=12}},ticks_per_frame=2},blade={data={{sprite=13},{sprite=14},{sprite=15}},ticks_per_frame=2},frost={data={{sprite=48},{sprite=49},{sprite=50}},ticks_per_frame=2},burn={data={{sprite=51},{sprite=52},{sprite=53}},ticks_per_frame=2},incoming_hint={data={{sprite=2,offset={0,0}},{sprite=2,offset={1,0}},{sprite=2,offset={2,0}},{sprite=2,offset={1,0}}},ticks_per_frame=5},blade_circle={data={{sprite=76},{sprite=77},{sprite=78},{sprite=79},{sprite=78},{sprite=77}},ticks_per_frame=3},lightning_lance={data={{sprite=108},{sprite=109}},ticks_per_frame=5},hale_howitzer={data={{sprite=92},{sprite=93}},ticks_per_frame=5},fire_pit={data={{sprite=124},{sprite=125},{sprite=126},{sprite=127},{sprite=126},{sprite=125}},ticks_per_frame=5},menu_selector={data={{sprite=6,offset={0,0}},{sprite=7,offset={-1,0}},{sprite=8,offset={-2,0}},{sprite=47,offset={-3,0}},{sprite=8,offset={-2,0}},{sprite=7,offset={-1,0}}},ticks_per_frame=3},up_arrow={data={{sprite=54,offset={0,0}},{sprite=54,offset={0,-1}},{sprite=54,offset={0,-2}},{sprite=54,offset={0,-1}}},ticks_per_frame=3},down_arrow={data={{sprite=55,offset={0,0}},{sprite=55,offset={0,1}},{sprite=55,offset={0,2}},{sprite=55,offset={0,1}}},ticks_per_frame=3},sell={data={{sprite=1},{sprite=56},{sprite=40},{sprite=24}},ticks_per_frame=3},manifest={data={{sprite=1},{sprite=57},{sprite=41},{sprite=9}},ticks_per_frame=3}},tower_templates={{name=sword circle,text_color={2,13},damage=4,prefix=damage,radius=1,animation_key=blade_circle,cost=25,type=tack,attack_delay=15,icon_data=16,disable_icon_rotation=True,cooldown=0},{name=lightning lance,text_color={10,9},damage=5,prefix=damage,radius=5,animation_key=lightning_lance,cost=45,type=rail,attack_delay=25,icon_data=18,disable_icon_rotation=False,cooldown=200},{name=hale howitzer,text_color={12,7},damage=5,prefix=delay,radius=2,animation_key=hale_howitzer,cost=30,type=frontal,attack_delay=35,icon_data=20,disable_icon_rotation=False,cooldown=25},{name=torch trap,text_color={9,8},damage=5,prefix=duration,radius=0,animation_key=fire_pit,cost=20,type=floor,attack_delay=10,icon_data=22,disable_icon_rotation=True,cooldown=0}},enemy_templates={{hp=12,step_delay=10,sprite_index=3,reward=3,damage=1,height=2},{hp=10,step_delay=8,sprite_index=4,reward=2,damage=2,height=6},{hp=25,step_delay=12,sprite_index=5,reward=3,damage=4,height=2},{hp=8,step_delay=12,sprite_index=64,reward=4,damage=1,height=2},{hp=40,step_delay=12,sprite_index=65,reward=5,damage=6,height=2},{hp=15,step_delay=6,sprite_index=66,reward=6,damage=4,height=6}},wave_data={{4,4,4},{1,4,1,4,1,4},{2,4,2,1,2,4,1},{1,2,2,4,2,2,1,2,2,2},{5,5,5,5,5,5,5,5},{3,3,3,3,2,2,2,2,4,2,3,1},{2,2,2,2,2,2,2,2,4,3,3,3,1,2,2,2,2,2,2},{6,6,6,6,6,6,6,6},{3,3,3,3,3,3,1,4,5,5,5,3,3,1,1,1,1,1},{3,3,3,1,1,1,1,1,1,2,2,5,5,5,5,5},{6,6,6,6,6,3,2,2,2,2,2,2,2,3,3,3,3,3},{5,5,5,5,3,3,2,3,3,3,3,2,2,4,1},{5,5,5,5,5,5,5,2,3,3,5,5,5,3,2,2,2,2,2},{2,2,3,6,6,6,2,4,4,2,2,6,6,6,6,6,6,6},{5,5,5,5,5,5,3,3,2,2,2,2,2,3,3,3,6,6,6,6,6,6,6}}"
function reset_game()
  global_table_data = unpack_table(global_table_str)
  menu_data = {
    {
      "main", nil,
      5, 63, 
      {
        {text = "towers", color = {7, 0}, callback = swap_menu_context, args = {"towers"}},
        {text = "misc", color = {7, 0}, callback = swap_menu_context, args = {"misc"}},
        {text = "rotate clockwise", color = {7, 0}, 
          callback = function()
            direction = Vec:new(-direction.y, direction.x)
          end
        },
        {text = "start round", color = {7, 0}, callback = start_round}
      },
      display_tower_rotation,
      5, 8, 7, 3
    },
    { "towers", "main", 5, 63, get_tower_data_for_menu(), display_tower_info, 5, 8, 7, 3 },
    {
      "misc", "main",
      5, 63, 
      {
        {text = "map select", color = {7, 0}, 
          callback = function()
            get_active_menu().enable = false
            reset_game()
            map_menu_enable = true
          end
        },
        {
          text="toggle mode", color={7, 0},
          callback = function()
            manifest_mode = not manifest_mode
            sell_mode = not sell_mode
          end
        }
      },
      nil,
      5, 8, 7, 3
    },
    { "map", nil, 5, 84, get_map_data_for_menu(), nil, 5, 8, 7, 3 }
  }
  selector = {
    position = Vec:new(64, 64),
    sprite_index = 1,
    size = 1
  }
  coins = 30
  player_health = 50
  enemy_required_spawn_ticks = 10
  lock_cursor = false
  
  manifest_mode = true
  sell_mode = false
  manifested_tower_ref = nil
  enemy_current_spawn_tick = 0
  map_menu_enable, enemies_active, shop_enable, start_next_wave, wave_cor = true
  direction = Vec:new(0, -1)
  grid, towers, enemies, particles, animators, incoming_hint, menus = {}, {}, {}, {}, {}, {}, {}
  music(-1)
  selected_menu_tower_id = 1
  for i, menu_dat in pairs(menu_data) do add(menus, Menu:new(unpack(menu_dat))) end
  tower_stats_background_rect = BorderRect:new(Vec:new(0, 0), Vec:new(20, 38), 8, 5, 2)
  tower_rotation_background_rect = BorderRect:new(Vec:new(0, 0), Vec:new(24, 24), 8, 5, 2)
  sell_selector = Animator:new(global_table_data.animation_data.sell)
  manifest_selector = Animator:new(global_table_data.animation_data.manifest)
  get_menu("map").enable = true
end
Enemy = {}
function Enemy:new(location, hp_, step_delay_, sprite_id, reward_, damage_, height_)
  obj = { 
    position = Vec:new(location),
    hp = hp_, 
    step_delay = step_delay_,
    current_step = 0,
    is_frozen = false,
    frozen_tick = 0,
    burning_tick = 0,
    gfx = sprite_id,
    reward = reward_,
    damage = damage_,
    height = height_,
    pos = 1
  }
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function Enemy:step()
  self.current_step = (self.current_step + 1) % self.step_delay
  if (self.current_step ~= 0) return false
  if self.burning_tick > 0 then 
    self.burning_tick -= 1
    if self.reward == 6 then
      self.hp -= 0.5
    elseif self.reward == 5 then
      self.hp -= 5
    else
      self.hp -= 2
    end
    local p, _ = Enemy.get_pixel_location(self)
    add(particles, Particle:new(p, true, Animator:new(global_table_data.animation_data.burn, false)))
  end
  if (not self.is_frozen) return true 
  if self.reward == 6 then
    self.frozen_tick = max(self.frozen_tick - 0.8, 0)
    self.hp -= 2
  elseif self.reward == 5 then
    self.frozen_tick = max(self.frozen_tick - 8, 0)
  else
    self.frozen_tick = max(self.frozen_tick - 1, 0)
  end
  if (self.frozen_tick ~= 0) return false
  self.is_frozen = false
  return true
end
function Enemy:get_pixel_location()
  local n, prev = pathing[self.pos], Vec:new(global_table_data.map_data[loaded_map].enemy_spawn_location)
  if (self.pos - 1 >= 1) prev = pathing[self.pos-1]
  local pos = self.position * 8
  if (not self.is_frozen) pos = lerp(prev*8, n*8, self.current_step / self.step_delay)
  return pos, n
end
function Enemy:draw(is_shadows)
  if (self.hp <= 0) return
  local p, n = Enemy.get_pixel_location(self)
  local theta = parse_direction(normalize(n-self.position))
  if is_shadows then
    draw_sprite_shadow(self.gfx, p, self.height, 8, theta)
  else
    draw_sprite_rotated(self.gfx, p, 8, theta)
  end
end
function kill_enemy(enemy)
  if (enemy.hp > 0) return
  del(enemies, enemy)
end
function update_enemy_position(enemy)
  if (not Enemy.step(enemy)) return
  enemy.position = pathing[enemy.pos]
  enemy.pos += 1
  if (enemy.pos < #pathing + 1) return
  player_health -= enemy.damage 
  del(enemies, enemy)
end
function parse_path()
  local map_dat = global_table_data.map_data[loaded_map]
  local map_shift = Vec:new(map_dat.mget_shift)
  local map_enemy_spawn_location = Vec:new(map_dat.enemy_spawn_location)
  local path_tiles = {}
  for iy=0, 15 do
    for ix=0, 15 do
      local map_cord = Vec:new(ix, iy) + map_shift
      if fget(mget(Vec.unpack(map_cord)), global_table_data.map_meta_data.path_flag_id) then 
        add(path_tiles, map_cord)
      end
    end
  end
  local path = {}
  local dir = Vec:new(map_dat.movement_direction)
  local ending = Vec:new(map_dat.enemy_end_location) + map_shift
  local cur = map_enemy_spawn_location + map_shift + dir
  while cur ~= ending do 
    local north,south,west,east = Vec:new(cur.x, cur.y-1),Vec:new(cur.x, cur.y+1),Vec:new(cur.x-1, cur.y),Vec:new(cur.x+1, cur.y)
    local state,direct = false
    if dir.x == 1 then -- east 
      state, direct = check_direction(east, {north, south}, path_tiles, path)
    elseif dir.x == -1 then -- west
      state, direct = check_direction(west, {north, south}, path_tiles, path)
    elseif dir.y == 1 then -- south
      state, direct = check_direction(south, {west, east}, path_tiles, path)
    elseif dir.y == -1 then -- north
      state, direct = check_direction(north, {west, east}, path_tiles, path)
    end
    assert(state, "Failed to find path at: "..cur.." in direction: "..dir.." end: "..ending)
    if state then 
      dir = normalize(direct - cur)
      cur = direct
    else 
    end
  end
  return path
end
function check_direction(direct, fail_directions, path_tiles, path)
  if (direct == nil) return
  local state, index = is_in_table(direct, path_tiles)
  if state then
    add(path, path_tiles[index] - Vec:new(global_table_data.map_data[loaded_map].mget_shift))
  else 
    return check_direction(fail_directions[1], {fail_directions[2]}, path_tiles, path)
  end
  return true, direct
end
function spawn_enemy()
  while enemies_remaining > 0 do 
    enemy_current_spawn_tick = (enemy_current_spawn_tick + 1) % enemy_required_spawn_ticks
    if (is_in_table(Vec:new(global_table_data.map_data[loaded_map].enemy_spawn_location), enemies, true)) goto spawn_enemy_continue
    if enemy_current_spawn_tick == 0 then
      local enemy_data = increase_enemy_health(global_table_data.enemy_templates[global_table_data.wave_data[wave_round][enemies_remaining]])
      add(enemies, Enemy:new(global_table_data.map_data[loaded_map].enemy_spawn_location, unpack(enemy_data)))
      enemies_remaining -= 1
    end
    ::spawn_enemy_continue:: 
    yield()
  end
end
Tower = {}
function Tower:new(pos, tower_template_data, direction)
  obj = { 
    position = pos,
    dmg = tower_template_data.damage,
    radius = tower_template_data.radius, 
    attack_delay = tower_template_data.attack_delay,
    current_attack_ticks = 0,
    cooldown = tower_template_data.cooldown,
    manifest_cooldown = -1,
    being_manifested = false,
    cost = tower_template_data.cost,
    type = tower_template_data.type,
    dir = direction,
    enable = true,
    animator = Animator:new(global_table_data.animation_data[tower_template_data.animation_key], true)
  }
  add(animators, obj.animator)
  setmetatable(obj, self)
  self.__index = self 
  return obj 
end
function Tower:attack()
  if (not self.enable) return
  if self.being_manifested and self.type == "tack" then 
    self.dmg = min(self.manifest_cooldown, 100) / 15
  end
  self.current_attack_ticks = (self.current_attack_ticks + 1) % self.attack_delay
  if (self.current_attack_ticks > 0) return
  if self.type == "tack" then
    Tower.apply_damage(self, Tower.nova_collision(self), self.dmg)
  elseif self.type == "floor" then 
    local hits = {}
    add_enemy_at_to_table(self.position, hits)
    foreach(hits, function(enemy) enemy.burning_tick += self.dmg end)
  elseif not self.being_manifested then
    if self.type == "rail" then
      Tower.apply_damage(self, raycast(self.position, self.radius, self.dir), self.dmg)
    elseif self.type == "frontal" then 
      Tower.freeze_enemies(self, Tower.frontal_collision(self))
    end
  end
end
function Tower:nova_collision()
  local hits, rad = {}, self.radius
  for y=-rad, rad do
    for x=-rad, rad do
      if (x ~= 0 or y ~= 0) add_enemy_at_to_table(self.position + Vec:new(x, y), hits)
    end
  end
  if (#hits > 0) nova_spawn(self.position, rad, global_table_data.animation_data.blade)
  return hits
end
function Tower:frontal_collision()
  local hits = {}
  local fx, fy, flx, fly, ix, iy = parse_frontal_bounds(self.radius, self.dir)
  for y=fy, fly, iy do
    for x=fx, flx, ix do
      if (x ~= 0 or y ~= 0) add_enemy_at_to_table(self.position + Vec:new(x, y), hits)
    end
  end
  if (#hits > 0) frontal_spawn(self.position, self.radius, self.dir, global_table_data.animation_data.frost)
  return hits
end
function Tower:apply_damage(targets, damage)
  for enemy in all(targets) do
    if (enemy.hp > 0) enemy.hp -= damage
  end
end
function Tower:freeze_enemies(targets)
  for enemy in all(targets) do
    if not enemy.is_frozen then 
      enemy.is_frozen = true
      enemy.frozen_tick = self.dmg
    end 
  end
end
function Tower:draw()
  if (not self.enable) return
  local p,sprite,theta = self.position*8,Animator.get_sprite(self.animator),parse_direction(self.dir)
  draw_sprite_shadow(sprite, p, 2, self.animator.sprite_size, theta)
  draw_sprite_rotated(sprite, p, self.animator.sprite_size, theta)
end
function Tower:cooldown()
  self.manifest_cooldown = max(self.manifest_cooldown-1, 0)
end
function Tower:get_cooldown_str()
  if (self.type == "floor") return "⬆️⬇️⬅️➡️ move"
  if (self.type == "tack") return "❎ activate ("..self.dmg.."d)"
  if (self.manifest_cooldown == 0) return "❎ activate"
  return "❎ activate ("..self.manifest_cooldown.."t)"
end
function Tower:manifested_lightning_blast()
  if (self.manifest_cooldown > 0) return 
  self.manifest_cooldown = self.cooldown
  local dir = (selector.position / 8 - self.position) / 8
  local anchor = self.position + Vec:new(1, 0)
  local damage = self.dmg * 2
  for i=1, 3 do 
    Tower.apply_damage(self, raycast(anchor, 64, dir), damage)
    anchor.x -= 1
  end
  anchor += Vec:new(2, 1)
  for i=1, 3 do
    Tower.apply_damage(self, raycast(anchor, 64, dir), damage)
    anchor.y -= 1
  end
end
function Tower:manifested_hale_blast()
  if (self.manifest_cooldown > 0) return
  self.manifest_cooldown = self.cooldown
  local pos = selector.position / 8
  local hits, locations = {}, {
    pos, -- center
    pos + Vec:new(0, 1),  -- south
    pos + Vec:new(0, -1), -- north
    pos + Vec:new(-1, 0), -- west
    pos + Vec:new(1, 0)   -- east
  }
  for location in all(locations) do 
    add_enemy_at_to_table(location, hits, true)
  end
  spawn_particles_at(locations, global_table_data.animation_data.frost)
  Tower.freeze_enemies(self, hits)
  Tower.apply_damage(self, hits, self.dmg\4)
end
function Tower:manifested_nova()
  self.manifest_cooldown = min(self.manifest_cooldown + 7, 110)
  self.dmg = round_to(min(self.manifest_cooldown, 100) / 15, 2)
end
function Tower:manifested_torch_trap()
  local sel_pos = selector.position / 8
  if (grid[sel_pos.y][sel_pos.x] == "empty") return
  
  local prev = Vec:new(Vec.unpack(self.position))
  if grid[sel_pos.y][sel_pos.x] == "tower" then
    local shift = Vec:new(global_table_data.map_data[loaded_map].mget_shift)
    if (fget(mget(Vec.unpack(sel_pos+shift)), 0) and prev ~= sel_pos) self.enable = false
    return
  end
  self.position = sel_pos
  grid[sel_pos.y][sel_pos.x] = "floor"
  grid[prev.y][prev.x] = "path"
  self.enable = true 
end
function raycast(position, radius, dir)
  if (dir == Vec:new(0, 0)) return
  local hits, particle_locations = {}, {}
  for i=1, radius do 
    local pos = Vec.floor(position + dir * i)
    add(particle_locations, pos)
    add_enemy_at_to_table(pos, hits)
  end
  if (#hits > 0 or manifested_tower_ref) spawn_particles_at(particle_locations, global_table_data.animation_data.spark)
  return hits
end
function manifest_tower_at(position)
  for tower in all(towers) do
    if tower.position == position then 
      tower.being_manifested = true 
      manifested_tower_ref = tower
      if tower.type == "tack" then
        lock_cursor = true
        tower.attack_delay = 10
        tower.dmg = 0
      end
    end
  end
end
function unmanifest_tower()
  manifested_tower_ref.being_manifested = false 
  if manifested_tower_ref.type == "tack" then
    lock_cursor = false
    local tower_details = global_table_data.tower_templates[1]
    manifested_tower_ref.attack_delay = tower_details.attack_delay
    manifested_tower_ref.dmg = tower_details.damage
  end
  manifested_tower_ref.enable = true
  manifested_tower_ref = nil
end
function place_tower(position)
  if (grid[position.y][position.x] == "tower") return false
  local tower_details = global_table_data.tower_templates[selected_menu_tower_id]
  if (coins < tower_details.cost) return false
  if ((tower_details.type == "floor") ~= (grid[position.y][position.x] == "path")) return false 
  add(towers, Tower:new(position, tower_details, direction))
  coins -= tower_details.cost
  grid[position.y][position.x] = "tower"
  return true
end
function refund_tower_at(position)
  for tower in all(towers) do
    if tower.position == position then
      grid[position.y][position.x] = "empty"
      if (tower.type == "floor") grid[position.y][position.x] = "path"
      coins += tower.cost \ 1.25
      del(animators, tower.animator) 
      del(towers, tower)
     end
  end
end
function draw_tower_attack_overlay(tower_details)
  local pos = selector.position/8
  palt(global_table_data.palettes.transparent_color_id, false)
  pal(global_table_data.palettes.attack_tile)
  local is_empty = grid[pos.y][pos.x] == "empty"
  local map_shift = Vec:new(global_table_data.map_data[loaded_map].mget_shift)
  if tower_details.type == "tack" and is_empty then 
    draw_nova_attack_overlay(tower_details.radius, pos, map_shift)
  elseif tower_details.type == "rail" and is_empty then 
    draw_ray_attack_overlay(tower_details.radius, pos, map_shift)
  elseif tower_details.type == "frontal" and is_empty then 
    draw_frontal_attack_overlay(tower_details.radius, pos, map_shift)
  elseif tower_details.type == "floor" and grid[pos.y][pos.x] == "path" then 
    spr(mget(Vec.unpack(pos+map_shift)), Vec.unpack(pos*8))
  end
  pal()
end
function draw_nova_attack_overlay(radius, pos, map_shift)
  for y=-radius, radius do
    for x=-radius, radius do
      if x ~=0 or y ~= 0 then 
        local tile_position = pos+Vec:new(x, y)
        spr(mget(Vec.unpack(tile_position+map_shift)), Vec.unpack(tile_position*8))
      end
    end
  end
end
function draw_ray_attack_overlay(radius, pos, map_shift)
  for i=1, radius do 
    local tile_position = pos+direction*i
    spr(mget(Vec.unpack(tile_position+map_shift)), Vec.unpack(tile_position*8))
  end
end
function draw_frontal_attack_overlay(radius, pos, map_shift)
  local fx, fy, flx, fly, ix, iy = parse_frontal_bounds(radius, direction)
  for y=fy, fly, iy do
    for x=fx, flx, ix do
      local tile_position = pos + Vec:new(x, y)
      spr(mget(Vec.unpack(tile_position+map_shift)), Vec.unpack(tile_position*8))
    end
  end
end
Particle = {}
function Particle:new(pos, pixel_perfect, animator_)
  obj = {
    position = pos,
    is_pxl_perfect = pixel_perfect or false,
    animator = animator_,
  }
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function Particle:tick()
  return Animator.update(self.animator)
end
function Particle:draw()
  if (Animator.finished(self.animator)) return 
  local pos = self.position
  if (not self.is_pxl_perfect) pos = pos * 8
  Animator.draw(self.animator, Vec.unpack(pos))
end
function destroy_particle(particle)
  if (not Animator.finished(particle.animator)) return
  del(particles, particle)
end
function spawn_particles_at(locations, animation_data)
  for location in all(locations) do 
    add(particles, Particle:new(location, false, Animator:new(animation_data, false)))
  end
end
function nova_spawn(position, radius, data)
  for y=-radius, radius do
    for x=-radius, radius do
      if (x ~= 0 or y ~= 0) add(particles, Particle:new(position + Vec:new(x, y), false, Animator:new(data, false)))
    end
  end
end
function frontal_spawn(position, radius, dir, data)
  local fx, fy, flx, fly, ix, iy = parse_frontal_bounds(radius, dir)
  for y=fy, fly, iy do
    for x=fx, flx, ix do
      if (x ~= 0 or y ~= 0) add(particles, Particle:new(position + Vec:new(x, y), false, Animator:new(data, false)))
    end
  end
end
Animator = {} -- updated from tower_defence
function Animator:new(animation_data, continuous_)
  obj = {
    data = animation_data.data,
    sprite_size = animation_data.size or 8,
    spin_enable = animation_data.rotation,
    theta = 0,
    animation_frame = 1,
    frame_duration = animation_data.ticks_per_frame,
    tick = 0,
    continuous = continuous_
  }
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function Animator:update()
  self.tick = (self.tick + 1) % self.frame_duration
  self.theta = (self.theta + 5) % 360
  if (self.tick ~= 0) return false
  if Animator.finished(self) then 
    if (self.continuous) Animator.reset(self)
    return true
  end
  self.animation_frame += 1
  return false
end
function Animator:finished()
  return self.animation_frame >= #self.data
end
function Animator:draw(dx, dy)
  local position,frame = Vec:new(dx, dy),self.data[self.animation_frame]
  if (frame.offset) position += Vec:new(frame.offset)
  if self.spin_enable then 
    draw_sprite_rotated(frame.sprite, position, self.sprite_size, self.theta)
  else
    spr(Animator.get_sprite(self),Vec.unpack(position))
  end
end
function Animator:get_sprite()
  return self.data[self.animation_frame].sprite
end
function Animator:reset()
  self.animation_frame = 1
end
BorderRect = {}
function BorderRect:new(position_, size_, border_color, base_color, thickness_size)
  obj = {
    position = position_, 
    size = position_ + size_,
    border = border_color, 
    base = base_color,
    thickness = thickness_size
  }
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function BorderRect:draw()
  rectfill(
    self.position.x-self.thickness, self.position.y-self.thickness, 
    self.size.x+self.thickness, self.size.y+self.thickness, 
    self.border
  )
  rectfill(self.position.x, self.position.y, self.size.x, self.size.y, self.base)
end
function BorderRect:resize(position_, size_)
  if (self.position ~= position_) self.position = position_
  if (self.size ~= size_ + position_) self.size = size_ + position_ 
end
function BorderRect:reposition(position_)
  if (self.position == position_) return
  local size = self.size - self.position
  self.position = position_
  self.size = self.position + size
end
Menu = {}
function Menu:new(
  menu_name, previous_menu, dx, dy, 
  menu_content, menu_info_draw_call, 
  base_color, border_color, text_color, menu_thickness)
  obj = {
    name = menu_name,
    prev = previous_menu,
    position = Vec:new(dx, dy),
    selector = Animator:new(global_table_data.animation_data.menu_selector, true),
    up_arrow = Animator:new(global_table_data.animation_data.up_arrow, true),
    down_arrow = Animator:new(global_table_data.animation_data.down_arrow, true),
    content = menu_content,
    content_draw = menu_info_draw_call,
    rect = BorderRect:new(
      Vec:new(dx, dy), 
      Vec:new(10 + 5*longest_menu_str(menu_content), 38),
      border_color,
      base_color,
      menu_thickness
    ),
    text = text_color,
    pos = 1,
    enable = false,
    ticks = 5,
    max_ticks = 5,
    dir = 0
  }
  setmetatable(obj, self)
  self.__index = self
  return obj
end
function Menu:draw()
  if (not self.enable) return
  local top, bottom = self.pos-1, self.pos+1
  if (top < 1) top = #self.content 
  if (bottom > #self.content) bottom = 1
  if (self.content_draw) self.content_draw(self.pos, self.position, self.content[self.pos].color)
  BorderRect.draw(self.rect)
  Animator.draw(self.selector, Vec.unpack(self.position + Vec:new(2, 15)))
  Animator.draw(self.up_arrow, self.rect.size.x/2, self.position.y-self.rect.thickness)
  Animator.draw(self.down_arrow, self.rect.size.x/2, self.rect.size.y-self.rect.thickness)
  local base_pos_x = self.position.x+10
  local menu_scroll_data = {self.dir, self.ticks / self.max_ticks, self.position}
  if self.ticks < self.max_ticks then 
    if self.dir > 0 then 
      print_with_outline(
        self.content[top].text, 
        combine_and_unpack(menu_scroll(12, 10, 7, unpack(menu_scroll_data)), 
        self.content[top].color)
      )
    elseif self.dir < 0 then 
      print_with_outline(
        self.content[bottom].text, 
        combine_and_unpack(menu_scroll(12, 10, 27, unpack(menu_scroll_data)), 
        self.content[bottom].color)
      )
    end 
  else
    print_with_outline(self.content[top].text, base_pos_x, self.position.y+7, unpack(self.content[top].color))
    print_with_outline(self.content[bottom].text, base_pos_x, self.position.y+27, unpack(self.content[bottom].color))
  end
  print_with_outline(
    self.content[self.pos].text, 
    combine_and_unpack(menu_scroll(10, 12, 17, unpack(menu_scroll_data)), 
    self.content[self.pos].color)
  )
end
function Menu:update()
  if (not self.enable) return
  Animator.update(self.selector)
  Animator.update(self.up_arrow)
  Animator.update(self.down_arrow)
  if (self.ticks >= self.max_ticks) return
  self.ticks += 1
end
function Menu:move()
  if (not self.enable) return
  if (self.ticks < self.max_ticks) return
  local _, dy = controls()
  if (dy == 0) return
  self.pos += dy 
  self.dir = dy
  if (self.pos < 1) self.pos = #self.content 
  if (self.pos > #self.content) self.pos = 1
  self.ticks = 0
end
function Menu:invoke()
  local cont = self.content[self.pos]
  if (cont.callback == nil) return
  if cont.args then
    cont.callback(unpack(cont.args))
  else
    cont.callback()
  end
end
function menu_scroll(dx1, dx2, dy, dir, rate, position)
  local dy1, dy3 = dy-10, dy+10
  local lx = lerp(position.x+dx1, position.x+dx2, rate)
  local ly = position.y + dy
  if dir < 0 then 
    ly = lerp(position.y + dy1, ly, rate)
  elseif dir > 0 then 
    ly = lerp(position.y + dy3, ly, rate)
  end
  return {lx, ly}
end
Vec = {}
function Vec:new(dx, dy)
  local obj = nil
  if type(dx) == "table" then 
    obj = {x=dx[1],y=dx[2]}
  else
    obj={x=dx,y=dy}
  end
  setmetatable(obj, self)
  self.__index = self
  self.__add = function(a, b)
    return Vec:new(a.x+b.x,a.y+b.y)
  end
  self.__sub = function(a, b)
    return Vec:new(a.x-b.x,a.y-b.y)
  end
  self.__mul = function(a, scalar)
    return Vec:new(a.x*scalar,a.y*scalar)
  end
  self.__div = function(a, scalar)
    return Vec:new(a.x/scalar,a.y/scalar)
  end
  self.__eq = function(a, b)
    return (a.x==b.x and a.y==b.y)
  end
  self.__tostring = function(vec)
    return "("..vec.x..", "..vec.y..")"
  end
  self.__concat = function(vec, other)
    return (type(vec) == "table") and Vec.__tostring(vec)..other or vec..Vec.__tostring(other)
  end
  return obj
end
function Vec:unpack()
  return self.x, self.y
end
function Vec:clamp(min, max)
  self.x, self.y = mid(self.x, min, max), mid(self.y, min, max)
end
function Vec:floor()
  return Vec:new(flr(self.x), flr(self.y))
end
function normalize(val)
  return (type(val) == "table") and Vec:new(normalize(val.x), normalize(val.y)) or flr(mid(val, -1, 1))
end
function lerp(start, last, rate)
  if type(start) == "table" then 
    return Vec:new(lerp(start.x, last.x, rate), lerp(start.y, last.y, rate))
  else
    return start + (last - start) * rate
  end
end
function _init() reset_game() end
function _draw()
  cls()
  if map_menu_enable then map_draw_loop() else game_draw_loop() end
end
function _update()
  if map_menu_enable then 
    map_loop()
  else 
    if (player_health <= 0) reset_game()
    if shop_enable then shop_loop() else game_loop() end
  end
end
function map_draw_loop()
  local map_menu = get_menu("map")
  pal(global_table_data.palettes.dark_mode)
  map(unpack(global_table_data.map_data[map_menu.pos].mget_shift))
  pal()
  Menu.draw(map_menu)
  print_text_center("map select", 5, 7, 1)
end
function game_draw_loop()
  local map_data = global_table_data.map_data[loaded_map]
  local tower_details = global_table_data.tower_templates[selected_menu_tower_id]
  map(unpack(map_data.mget_shift))
  if (manifested_tower_ref == nil and not sell_mode) draw_tower_attack_overlay(tower_details)
  foreach(towers, Tower.draw)
  foreach(enemies, function (enemy) Enemy.draw(enemy, true) end)
  foreach(enemies, Enemy.draw)
  foreach(particles, Particle.draw)
  if (shop_enable) foreach(menus, Menu.draw)
  if not shop_enable and not enemies_active and incoming_hint ~= nil then 
    for i=1, #incoming_hint do 
      Animator.draw(incoming_hint[i], Vec.unpack(
        (Vec:new(map_data.enemy_spawn_location) + Vec:new(map_data.movement_direction) * (i-1))*8
      ))
    end
  end
  ui_draw_loop(tower_details)
end
function ui_draw_loop(tower_details)
  print_with_outline("scrap: "..coins, 0, 1, 7, 0)
  print_with_outline("♥ "..player_health, 103, 1, 8, 0)
  local mode = manifest_mode and "manifest" or "sell"
  print_with_outline("mode: "..mode, 1, 108, 7, 0)
  if shop_enable and get_active_menu() then
    print_with_outline("game paused [ wave "..(wave_round+freeplay_rounds).." ]", 18, 16, 7, 0)
    local text = get_active_menu().prev and "❎ select\n🅾️ go back to previous menu" or "❎ select\n🅾️ close menu"
    print_with_outline(text, 1, 115, 7, 0)
  else -- game ui
    if manifest_mode and manifested_tower_ref then 
        Animator.update(manifest_selector)
        Animator.draw(manifest_selector, Vec.unpack(selector.position))
        print_with_outline("🅾️ unmanifest", 1, 122, 7, 0)
        local color = manifested_tower_ref.type == "tack" and 3 or (manifested_tower_ref.manifest_cooldown > 0 and 8 or 3)
        print_with_outline(Tower.get_cooldown_str(manifested_tower_ref), 1, 115, color, 0)
    else
      Animator.reset(manifest_selector)
      if (not manifested_tower_ref) print_with_outline("🅾️ open menu", 1, 122, 7, 0)
    end
    local tower_in_table_state = is_in_table(selector.position/8, towers, true)
    if (not manifested_tower_ref and manifest_mode) or (sell_mode and not tower_in_table_state) then 
      spr(selector.sprite_index, Vec.unpack(selector.position))
    end
    if tower_in_table_state and not manifested_tower_ref then 
      if manifest_mode then
        print_with_outline("❎ manifest", 1, 115, 7, 0)
      else
        Animator.update(sell_selector)
        Animator.draw(sell_selector, Vec.unpack(selector.position))
        print_with_outline("❎ sell", 1, 115, 7, 0)
      end
    else
      Animator.reset(sell_selector)
      if (not manifested_tower_ref and not sell_mode) ui_buy_and_place_draw_loop(tower_details)
    end
  end
end
function ui_buy_and_place_draw_loop(tower_details)
  local position, color, text = selector.position/8, 7, "❎ buy & place "..tower_details.name
  if tower_details.cost > coins then
    text, color = "can't afford "..tower_details.name, 8
  elseif (tower_details.type == "floor") ~= (grid[position.y][position.x] == "path") then 
    text, color = "can't place "..tower_details.name.." here", 8
  end
  print_with_outline(text, 1, 115, color, 0)
end
function map_loop()
  local map_menu = get_menu("map")
  Menu.update(map_menu)
  if btnp(❎) then
    Menu.invoke(map_menu)
    map_menu.enable = false
    map_menu_enable = false 
    return
  end
  Menu.move(map_menu)
end
function shop_loop()
  foreach(menus, Menu.update)
  
  if btnp(🅾️) then -- disable shop
    if get_active_menu().prev == nil then 
      shop_enable = false
      menus[1].enable = false
      return
    else
      swap_menu_context(get_active_menu().prev)
    end
  end
  if btnp(❎) then 
    Menu.invoke(get_active_menu())
  end
  foreach(menus, Menu.move)
end
function game_loop()
  if (auto_start_wave) start_round()
  if btnp(🅾️) then
    if manifested_tower_ref == nil then
      shop_enable = true
      menus[1].enable = true
      return
    else
      unmanifest_tower()
    end
  end
  if btnp(❎) then 
    if manifested_tower_ref then
      local type = manifested_tower_ref.type
      if type == "tack" then 
        Tower.manifested_nova(manifested_tower_ref)
      elseif type == "rail" then 
        Tower.manifested_lightning_blast(manifested_tower_ref)
      elseif type == "frontal" then 
        Tower.manifested_hale_blast(manifested_tower_ref)
      end
    else 
      local position = selector.position/8
      if is_in_table(position, towers, true) then 
        if manifest_mode then
          manifest_tower_at(position)
        else
          refund_tower_at(position)
        end
      else
        place_tower(position)
      end
    end
  end
  if not lock_cursor then
    selector.position += Vec:new(controls()) * 8
    Vec.clamp(selector.position, 0, 120)
    if manifested_tower_ref and manifested_tower_ref.type == "floor" then
      Tower.manifested_torch_trap(manifested_tower_ref)
    end
  end
  foreach(towers, Tower.cooldown)
  if enemies_active then 
    foreach(enemies, update_enemy_position)
    foreach(towers, Tower.attack)
    if start_next_wave then 
      start_next_wave = false
      wave_cor = cocreate(spawn_enemy)
    end
    if wave_cor and costatus(wave_cor) ~= 'dead' then
      coresume(wave_cor)
    else
      wave_cor = nil
    end
  end
  foreach(particles, Particle.tick)
  foreach(animators, Animator.update)
  if (not enemies_active and incoming_hint) foreach(incoming_hint, Animator.update)
  foreach(enemies, kill_enemy)
  foreach(particles, destroy_particle)
  if enemies_active and #enemies == 0 and enemies_remaining == 0 then 
    enemies_active = false 
    sfx(global_table_data.sfx_data.round_complete)
    coins += 15
  end
end
function print_with_outline(text, dx, dy, text_color, outline_color)
  ?text,dx-1,dy,outline_color
  ?text,dx+1,dy
  ?text,dx,dy-1
  ?text,dx,dy+1
  ?text,dx,dy,text_color
end
function print_text_center(text, dy, text_color, outline_color)
  print_with_outline(text, 64-(#text*5)\2, dy, text_color, outline_color)
end
function controls()
  if btnp(⬆️) then return 0, -1
  elseif btnp(⬇️) then return 0, 1
  elseif btnp(⬅️) then return -1, 0
  elseif btnp(➡️) then return 1, 0
  end
  return 0, 0
end
function increase_enemy_health(enemy_data)
  local stats = global_table_data.freeplay_stats
  return 
    {
      enemy_data.hp * ( 1 + (stats.hp - 1) * ((wave_round+freeplay_rounds)/15) ),
      max(enemy_data.step_delay-stats.speed*freeplay_rounds,stats.min_step_delay),
      enemy_data.sprite_index,
      enemy_data.reward,
      enemy_data.damage,
      enemy_data.height
    }
end
function is_in_table(val, table, is_entity)
  for i, obj in pairs(table) do
    if is_entity then 
      if (val == obj.position) return true, i 
    else
      if (val == obj) return true, i 
    end
  end
end
function placable_tile_location(coord)
  return fget(mget(coord.x, coord.y), global_table_data.map_meta_data.non_path_flag_id)
end
function add_enemy_at_to_table(pos, table, multitarget)
  for enemy in all(enemies) do
    if enemy.position == pos then
      add(table, enemy)
      if (multitarget) return
    end
  end
end
function draw_sprite_rotated(sprite_id, position, size, theta, is_opaque)
  local sx, sy = (sprite_id % 16) * 8, (sprite_id \ 16) * 8 
  local sine, cosine = sin(theta / 360), cos(theta / 360)
  local shift = size\2 - 0.5
  for mx=0, size-1 do 
    for my=0, size-1 do 
      local dx, dy = mx-shift, my-shift
      local xx = flr(dx*cosine-dy*sine+shift)
      local yy = flr(dx*sine+dy*cosine+shift)
      if xx >= 0 and xx < size and yy >= 0 and yy <= size then
        local id = sget(sx+xx, sy+yy)
        if id ~= global_table_data.palettes.transparent_color_id or is_opaque then 
          pset(position.x+mx, position.y+my, id)
        end
      end
    end
  end
end
function draw_sprite_shadow(sprite, position, height, size, theta)
  pal(global_table_data.palettes.shadows)
  draw_sprite_rotated(sprite, position + Vec:new(height, height), size, theta)
  pal()
end
function parse_direction(dir)
  if (dir.x > 0) return 90
  if (dir.x < 0) return 270
  if (dir.y > 0) return 180
  if (dir.y < 0) return 0
end
function parse_frontal_bounds(radius, position)
  local fx, fy, flx, fly, ix, iy = -1, 1, 1, radius, 1, 1
  if position.x > 0 then -- east
    fx, fy, flx, fly = 1, -1, radius, 1
  elseif position.x < 0 then -- west
    fx, fy, flx, fly, ix = -1, -1, -radius, 1, -1
  elseif position.y < 0 then -- north
    fx, fy, flx, fly, iy = -1, -1, 1, -radius, -1
  end
  return fx, fy, flx, fly, ix, iy
end
function combine_and_unpack(data1, data2)
  local data = {}
  for dat in all(data1) do
    add(data, dat)
  end
  for dat in all(data2) do
    add(data, dat)
  end
  return unpack(data)
end
function round_to(value, place)
  local places = 10 * place
  local val = value * places 
  val = flr(val)
  return val / places
end
function unpack_table(str)
  local table,start,stack,i={},1,0,1
  while i <= #str do
    if str[i]=="{" then 
      stack+=1
    elseif str[i]=="}"then 
      stack-=1
      if(stack>0)goto unpack_table_continue
      insert_key_val(sub(str,start,i), table)
      start=i+1
      if(i+2>#str)goto unpack_table_continue
      start+=1
      i+=1
    elseif stack==0 then
      if str[i]=="," then
        insert_key_val(sub(str,start,i-1), table)
        start=i+1
      elseif i==#str then 
        insert_key_val(sub(str, start), table)
      end
    end
    ::unpack_table_continue::
    i+=1
  end
  return table
end
function insert_key_val(str, table)
  local key, val = split_key_value_str(str)
  if key == nil then
    add(table, val)
  else  
    local value
    if val[1] == "{" and val[-1] == "}" then 
      value = unpack_table(sub(val, 2, #val-1))
    elseif val == "True" then 
      value = true 
    elseif val == "False" then 
      value = false 
    else
      value = tonum(val) or val
    end
    if value == "inf" then 
      value = 32767
    end
    table[key] = value
  end
end
function convert_to_array_or_table(str)
  local internal = sub(str, 2, #str-1)
  if (str_contains_char(internal, "{")) return unpack_table(internal) 
  if (not str_contains_char(internal, "=")) return split(internal, ",", true) 
  return unpack_table(internal)
end
function split_key_value_str(str)
  local parts = split(str, "=")
  local key = tonum(parts[1]) or parts[1]
  if str[1] == "{" and str[-1] == "}" then 
    return nil, convert_to_array_or_table(str)
  end
  local val = sub(str, #(tostr(key))+2)
  if val[1] == "{" and val[-1] == "}" then 
    return key, convert_to_array_or_table(val)
  end
  return key, val
end
function str_contains_char(str, char)
  for i=1, #str do
    if (str[i] == char) return true
  end
end
__gfx__
11221122888778880077000000a99a000001100000033000777000000000000000000000ccc11ccc70000000a0000000000000000000d000000d000000d00000
112211228000000807887000069999600001100000033000788770007777700000000000c000000c7a0a0000aa000a000000a000000d200000d2d00000d20000
221122118000000807888700061111600cc66cc000033000788887707888877077777770c000000c97aaa0007aa0aaa09a00aa0000d21d0000d12dd000d12ddd
22112211700000070078887000999900ccc11ccc0693396007888887078888870788888710000001097aaa007aaaaaaa097aa770d21002d00d20012d00200120
1122112270000007007888700099990000c11c00063333600788888707888887078888871000000100979aa07a07a0970097a0990d20012dd21002d002100200
112211228000000807888700069999600001100006333360788887707888877077777770c000000c0009097a970090070009700000d12d000dd21d00ddd21d00
221122118000000807887000068998600001100006333360788770007777700000000000c000000c0000009709000009000090000002d000000d2d0000002d00
2211221188877888007700000000000000c11c0006333360777000000000000000000000ccc11ccc000000090000000000000000000d00000000d00000000d00
00000d00001000000000000a0a000000000000000000000000080000000800808800008800077000000770000000000055555555555555555555555500000000
00000dd0011000000000007556000000000770777700777000880008888800888780087800077000000770000000000055666651556666515566665100000000
000002dd1110000000000655556a0000077777c7c77c766700800888998000080878878000077000000770000000000056666661566666615666666100000000
0000022dd110000000000aa55aaaa00007ccc76ccc667c7000008899998800000087780077777000000777770007777756666661566666615666666177777000
00000222dd10000000a99a9a9999940001667667c667cc1000888999a99800080087780077777000000777770007777756666651556666515566666177777000
11111d222dd222dd0a0aaa05500000a0011677c66677c1100888999aa99880880878878000000000000000000007700056666511511111115556666100077000
0111dd2002222dd000a7aaa7777770000116c7c7767cc110888999aaaa9988808780087800000000000000000007700055665166666666666655665100077000
001ddd000022dd000066777aaaa7660001166777c77c111088899aa7aa9998888800008800000000000000000007700051111160000000000611111100077000
00dd2200002dd100000000055000aa0001116c7cc7cc11108899aa77aaa9988888000088111dd111000000000000000055555560000770000655555500000000
0dd2222002dd11100009999999aaa0a00111cc7c77cc1110089aaa777aa998808788887810000001066666666666666055665160000770000655665100000000
dd222dd222d111110044aaa4444444a001111cc777c11110089aa77777aa99880870078010000001065555555555556056666160000770000656666100000000
000001dd222000000a0000055000000000111c7777c111000899a777777a998808000080d000000d065566515566516056666160000770000656666177777777
0000011dd2200000a07777aa7777770000111cccc7c111000889a777777a998008000080d000000d065666615666616056666160000770000656666177777777
00000111dd20000006aa77777777776000011cccc7c110000089aa77777a98800870078010000001065666615666616056666160000770000656666100000000
000001100dd000000a666666666a66a0000111cccc11100000089a7777a998008788887810000001065566515566516055665160000770000655665100000000
0000010000d00000aaaaaa0550aa0a0a0000111cc1110000000089a77a99800088000088111dd111065111115111116051111160000770000651111100000000
0c667670660007760000c00000800000000080008000008000000000000000008800008822266222065555555555556055555560000000000655555555555555
ccc66c7006777766066ccc0000088000000880080008880000077000077007708887788820000002065566515566516055665566666666666655665155666651
7c67ccc0677767700777c60000008808000888000088800000788700788778870800008020000002065666615666616056666555555555555556666156666661
76766c6707c777706c76776000888800008888000888880007888870788888870700007060000006065666615666616056666651556666515566666156666661
776777767ccc7c60ccc77760008998800889998008a9998078888887078888700700007060000006065566515566516056666661566666615666666156666661
766767c707c7ccc60c7676700899a980089aa98008aaa98078877887007887000800008020000002065111115111116056666661566666615666666156666661
67776ccc07777c7000067700089a7a8008a7aa80087a7a8007700770000770008887788820000002066666666666666055666651556666515566665155666651
007677c6006707770000000000877a8000877a000087780000000000000000008800008822266222000000000000000051111111511111115111111151111111
056cc65000c66c0000022000000000000000000000000000000000000000000000000000000000000000000000000000000000d0000200000d200000000000d0
0577765006666660002c6200000000000000000000000000000000000000000000000000000000000000000000000000d2210d2000dd20000d2210ddd2210d20
001111005676676502ccc6200000000000000000000000000000000000000000000000000000000000000000000000000d11d120001d11d000d11d220d11d120
00777600567667650288882000000000000000000000000000000000000000000000000000000000000000000000000000d00110021002dd0110012000d00110
00777600067667600282282000000000000000000000000000000000000000000000000000000000000000000000000001100d00dd2001200210011001100d00
057776500676676028288282000000000000000000000000000000000000000000000000000000000000000000000000021d11d00d11210022d11d00021d11d0
057777505676676522a9a92200000000000000000000000000000000000000000000000000000000000000000000000002d0122d0002dd00dd0122d002d0122d
0000000056066065200a90020000000000000000000000000000000000000000000000000000000000000000000000000d0000000000d000000002d00d000000
000770000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000067c606000ccc7000000000000000000
00788700000000000078870000000000000000000000000000000000000000000000000000000000000000000000000067ccc670077c77700000000000000000
078668700000000007866870000000000000000000000000000000000000000000000000000000000000000000000000607c77077777c7760000000000000000
0760067000000000076006700000000000000000000000000000000000000000000000000000000000000000000000000177c7107177c7160000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000117c110611771100000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111110011111100000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111110011111100000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111100001111000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090490a00a0940a00000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a09a00a090a90000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a05776009067750a0000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a90000009a0090000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000577600006775000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009aa900009aa9000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000006777550057776600000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000094000000490000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000080000000800000000800
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000698600006896000065890000659800
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000068a9160068a916006189a6006198960
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000589a9500598a950059a8850059a9850
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000059a7a50059a7a5005a7a95005a7a950
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000619a1600619a160061a9160061a9160
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000655600006556000065560000655600
__gff__
0000000000000000000000000000000000000000000000000001010102020201000000000000000000000202020102010000000000000000000002020202020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1d1d1d1d1d1d1d1d1d1d1d1d1e3f3f3f1d1d1d1d1d1d1d1d1d1d1d1d1e3f3f3f1d1d1d1d1d1d1d1d1d1e3f3f3f3f3f3f1d1d1d1d1d1d1d1e3f3f3f3f3f3f3f3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2f2f2f2f2f2f2f2f2f2f2f1f2e3f3f3f2f2f2f2f2f2f2f2f2f2f2f1f2e3f3f3f2f2f2f2f2f2f2f2f1f3a1d1d1d1d1d1d2f2f2f2f2f2f1f2e3f3f3f3f3f3f3f3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3d3d3d3d3d3d3d3d3d3d2b2d2e3f3f3f3d3d3d3d3d3d3d3d3d3d2b2d2e3f3f3f3d3d3d3d3d3d3d2b1a2f2f2f2f2f2f2f3d3d3d3d3d2b2d2e3f3f3f3f3f3f3f3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f2c2d2e3f3f3f3f3f3f3f3f3f3f3f3f3f2c2d2e3f3f3f3f3f3f3f3f3f3f3c3d3d3d3d3d3d3d3d3f3f3f3f3f2c2d2e3f3f3f3f3f3f3f3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f2c2d2e3f3f3f3f3f3f3f3f3f3f3f3f3f2c2d2e3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f2c2d2e3f3f3f3f3f3f3f3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f1c1d1d1d1d1d3b2d2e3f3f3f3f3f3f3f1c1d1d1d1d1d3b2d3a1d1d1e3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f1d1d1d1d1d3b2d2e3f3f3f3f3f3f3f3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f2c1b2f2f2f2f2f192e3f3f3f3f3f3f3f2c1b2f2f2f2f2f2d2f2f1f2e3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f2f2f2f2f2f2f192e3f3f3f3f3f3f3f3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f2c2d2a3d3d3d3d3d3e3f3f3f3f3f3f3f2c2d2a3d3d3d2b2d2a2b2d2e3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3d3d3d3d3d3d3d3e3f3f3f3f3f3f3f3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f2c2d2e3f3f3f3f3f3f3f3f3f3f3f3f3f2c2d2e3f3f3f2c2d2e2c2d2e3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f2c2d2e3f3f3f3f3f3f3f3f3f3f3f3f3f2c2d2e3f3f3f2c2d2e2c2d2e3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f2c2d3a1d1d1d1d1d1d1d1d1d3f3f3f3f2c2d3a1d1d1d3b2d2e2c2d3a3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f2c1a2f2f2f2f2f2f2f2f2f2f3f3f3f3f2c1a2f2f2f2f2f192e2c1a2f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3c3d3d3d3d3d3d3d3d3d3d3d3f3f3f3f3c3d3d3d3d3d3d3d3e3c3d3d3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f3f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01060000250512b051330513d05100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000200c0430000000000000000c0430000000000000000c0430000000000000000c0430000000000000000c0430000000000000000c0430000000000000000c0430000000000000000c043000000000000000
291000000000000000021400202502110020400212002015021400202502110020400212002015021400201002140020200211502040021200201002140020250211002040021250201002140020100214502013
9110000021040211201d11021040230201c11021140230201a0101a140211202301024040241202f1102d04021040211201d11021040230201c11021140230201a0101a140211202301024040241202f1102d040
011000000000000000280452302524015210452302523015280452302524015210452302523015280452302524015210452302523015280452302524015210452302523015280452302524015210452302523015
0601000028650276501b650275000b5001f5001e50021500254502545028450302503230032200321003d7003f7003f5003f7003f70034700327002e6002b2002820025200212001d2001a2001f7000000000000
9f0200000c2400e2401054011530130301503017720187201a7201c72000000000000000000000000000000000000000000000000000000003220032200322003220032200322003220032200312003120031200
0003000027050300501d7001d7001e7001e7001c7001c70021700207001e7001c7001b7001970018700167001470013700117000f7000d7000c70000000000000000000000000000000000000000000000000000
490f0000363502c35032350283502d34022340283301f330243201e32018320183101831000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
480300000a6500000006630000000000000000000000000000000000000000000000000001e600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011700000b2300000000000000000000000000000000000000230000000000000000000000000000000000000b230000000000000000000000000000000000000023000000000000000000000000000000000000
0117000010530105300b5301053010530105300b5301053013530135300e5301353013530135300e5301353010530105300b5301053010530105300b5301053013530135300e5301353013530135300e53013530
01170000131300b13000100001000e130001000010000100171300c130001000010011130151301713011130171300010000100001000e1300010000100001001713011130001000010015130171301513011130
01170000105301053017530105301053010530175301053013530135300e5301353013530135300e5301353010530175301053010530105301753010530105301053017530105301053010530175301053010530
011700000b0300000000000000000e0300000000000000000c030000000000000000110301503017030150300b030000000000000000000000000000000000000c0300000000000000000e030000000000000000
0117000018030000000000000000180300c030130300c030170300000000000000001703015030170301103013030000000000000000100300000000000000001003000000000000000007030000000000000000
011700000951010530095300953009510105100951009510095101053009530095300951010510095100951009510105300953009530095101053009530095300951010530095300953009510105300953009530
011700001803000000000000000018030180301f03018030230300000000000000002303021030230301d0301f0300000000000000001c030180301f030180301c0300000000000000001f030210302303021030
01170000155300000000000000001553015530135301553017530115301153000000000000c530115301353015530000000000015530005001553013530155300e53011530175301d53023530245302653015530
011700000c0300c030090300c0300c0300c030090300c0300b0300b030070300b0300b0300b030070300b0300c0300c030090300c0300c0300c030090300c0300b0300b030070300b0300b0300b030070300b030
0117000018530135300000000000175300e530000000000018530105301153000000185301c5301a530185301a53017530175301753017530175301a5301d5301d5301a53000000000001d530175300000013530
01170000050300003002030040300503005030000300903005030090300703005030000300b030090300703005030000000503000000050300000005030000000503005030050300503005030050300503005030
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
01 0a0b4344
00 0c0b4344
00 0e0d4344
00 11104344
00 100f4344
00 12134344
02 14154344


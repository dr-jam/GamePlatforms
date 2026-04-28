pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- everyone has solitaire
-- by real fancy fire

pile = nil
deck = nil
foundations = {}
tableau = {}
hand = nil

sel_row = 1
sel_column = 1
pickup_from = nil

start_time = 0
cool_lr = 0
cool_ud = 0
cool_x = 0
cool_o = 0

states = {
 title = 0,
 controls = 3,
 credits = 4,
 game = 1,
 finished = 2
}
state = states.title

render_queued = false

design_mode = false

function mod(a, b)
 return (a - 1) % b + 1
end

function clamp(val, lower, upper)
 return min(max(val, lower), upper)
end

function format_time(time)
 minutes = time \ 60
 seconds = flr(time) % 60
 decimal = flr((time % 1) * 100)
 if (minutes < 10) minutes = " " .. minutes
 if (seconds < 10) seconds = "0" .. seconds
 if (decimal < 10) decimal = "0" .. decimal
 return minutes .. ":" .. seconds .. "." .. decimal
end
--[[
-->8
--[[structs]]

sounds = {
 move = 0,
 draw = 5,
 error = 41,
 pickup = 1,
 putdown = 2,
 putback = 2,
 foundate = 4
}
musics = {
 title = 2,
 game = 8,
 finished = 4
}
music_on = true
current_music = 0
function update_music(track)
 if (track ~= nil) current_music = track
 if music_on then
  music(current_music)
 else
  music(-1)
 end
end

local card_struct = {
 width = 14,
 height = 20,
 faces = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 },
 suits = { 20, 21, 22, 23 },
 color = { 0, 8, 8, 0 },
 big_suits = { 36, 37, 38, 39 },
 back = 18
}
card_struct.__index = card_struct

function card_struct.new(suit, face)
 local self = setmetatable({}, card_struct)
 self.suit = suit
 self.face = face
 self.face_up = false
 return self
end

function card_struct:render(x, y)
 if self.face_up then
  rectfill(x, y, x + self.width - 1, y + self.height - 1, self.color[self.suit])
  spr(self.suits[self.suit], x + 7, y)
  spr(self.faces[self.face], x, y)
 else
  spr(self.back, x, y, 2, 3)
 end
end

function card_struct.render_nil(x, y)
 rect(x, y, x + card_struct.width - 1, y + card_struct.height - 1, 6)
end

-- card stack

local card_stack = {}
card_stack.__index = card_stack

function card_stack.new()
 local self = setmetatable({}, card_stack)
 self.cards = {}
 return self
end

function card_stack:len()
 return #self.cards
end

-- return the deepest card that is face up
-- assumes that facingness is not mixed
-- returns 0 if no cards are face up
function card_stack:last_face_up()
 for i = 1, #self.cards do
  if self.cards[i].face_up then
   return i
  end
 end
 return 0
end

function card_stack:get(index)
 if index > 0 then
  return self.cards[index]
 end
 return self.cards[#self.cards + index + 1]
end

function card_stack:render(x, y, dx, dy)
 card_struct.render_nil(x, y)
 if dx ~= 0 or dy ~= 0 then
  for i = 0, #self.cards - 1 do
   self.cards[i + 1]:render(x + i * dx, y + i * dy)
  end
 elseif #self.cards > 0 then
  self:get(-1):render(x, y)
 end
end

function card_stack:shuffle()
 d = self.cards
 for i = #d, 1, -1 do
  r = ceil(rnd(i))
  d[r], d[i] = d[i], d[r]
 end
end

function card_stack:push(card)
 add(self.cards, card)
end

function card_stack:pop()
 return deli(self.cards)
end

function card_stack:pushm(stack)
 for i = 1, #stack.cards do
  self:push(stack.cards[i])
 end
end

function card_stack:split(index)
 ret = self.new()
 for i = index, #self.cards do
  ret:push(self.cards[i])
  self.cards[i] = nil
 end
 return ret
end

--[[
-->8
--[[render functions]]

deck_x, deck_y = 12, 10
tableau_x, tableau_y = deck_x, deck_y + card_struct.height + 2
grid_dx = card_struct.width + 1
grid_fan = 4

function render()
 if state == states.title then
  render_title()
  return
 elseif state == states.controls then
  render_controls()
  return
 elseif state == states.credits then
  render_credits()
  return
 end

 cls(3)

 -- draw deck
 deck:render(deck_x, deck_y, 0, 0)

 -- drawn pile
 pile:render(deck_x + grid_dx, deck_y, 0, 0)

 -- foundations
 for s = 1, #foundations do
  x = deck_x + (s + 2) * grid_dx
  spr(card_struct.big_suits[s], x + 3, deck_y + 6)
  foundations[s]:render(x, deck_y, 0, 0)
 end

 -- tableau
 for s = 0, #tableau - 1 do
  tableau[s + 1]:render(tableau_x + s * grid_dx, tableau_y, 0, grid_fan)
 end

 x = deck_x + sel_column * grid_dx - grid_dx
 if sel_row > 0 then
  y = tableau_y + (sel_row - 1) * grid_fan
 else
  y = deck_y
 end
 if hand then
  -- holding cards
  hand:render(x, y + card_struct.height, 0, grid_fan)
 end
 -- render cursor
 spr(24, x - 1, y - 1, 2, 3)

 if state == states.finished then
  render_finished()
 end

 if design_mode then
  print("stock pile", deck_x + 3 * grid_dx, deck_y - 23, 9)
  line(deck_x + 9, deck_y - 1, deck_x + 3 * grid_dx - 3, deck_y - 21)
  rect(deck_x - 1, deck_y - 1, deck_x + card_struct.width, deck_y + card_struct.height)

  print("waste pile", deck_x + 3 * grid_dx, deck_y - 15, 12)
  line(deck_x + grid_dx + 9, deck_y - 1, deck_x + 3 * grid_dx - 3, deck_y - 13)
  rect(deck_x + grid_dx - 1, deck_y - 1, deck_x + grid_dx + card_struct.width, deck_y + card_struct.height)

  print("splitter", 4, -6, 7)

  print("foundation piles", deck_x + 3 * grid_dx, deck_y - 7, 11)
  rect(deck_x + 3 * grid_dx - 1, deck_y - 1, deck_x + 6 * grid_dx + card_struct.width, deck_y + card_struct.height)

  local tableau_bottom = tableau_y + 6 * grid_fan + card_struct.height
  print("tableau piles", 48, tableau_bottom + 2, 15)
  rect(tableau_x - 1, tableau_y - 1, tableau_x + 6 * grid_dx + card_struct.width, tableau_bottom)

  print("❎:pick/put", 1, tableau_bottom + 4, 0)
  print("🅾️:put back")
  print("quick stack")

  print("it's solitaire.", 48, 88, 7)
  print("what do you")
  print("want me to say?")
  spr(76, 100, 80, 4, 4)

  print("selector", x, y + card_struct.height + 2, 10)
 end
end

function render_title()
 cls(3)
 ovalfill(0x0, 0x10, 0x7f, 0x6f, 11)
 print("everybody has", 0x26, 0x25, 7)
 ovalfill(0x27, 0x2c, 0x58, 0x40, 3)
 sspr(0x00, 0x20, 0x30, 0x14, 0x28, 0x2d)
 print("it came free", 0x28, 0x42, 7)
 print("with your", 0x2e, 0x48, 7)
 sspr(0x30, 0x20, 0x28, 0x10, 0x2c, 0x4e)
end

function render_controls()
 cls(3)
 print("⬆️⬇️⬅️➡️:move selector", 4, 2, 7)
 print("")
 print("while hovering over tableau:")
 print("❎: pick up cards")
 print("🅾️: try move top card")
 print("    to foundation")
 print("")
 print("while hovering over stock:")
 print("❎: draw card")
 print("")
 print("while hovering over waste:")
 print("❎: pick up card")
 print("🅾️: try to move card")
 print("    to foundation")
 print("")
 print("while holding cards:")
 print("❎: try to put cards on ")
 print("    selected stack")
 print("🅾️: return cards to ")
 print("    original stack")
end

real_fancy_fire_sprites = { 26, 27, 28, 29, 42, 43, 44, 45 }
function render_fancy_fire()
 rectfill(0x38, 0x70, 0x40, 0x78, 1)
 spr(
  real_fancy_fire_sprites[flr(time() * 4) % #real_fancy_fire_sprites + 1],
  0x38, 0x70
 )
end
function render_credits()
 cls(1)
 print("credits", 0x30, 0x08, 7)

 print("programming", 0x07, 0x25, 7)
 print("music/sfx")
 print("legal council")
 print("")
 print("spritework")
 print("")
 print("")
 print("")
 print("sponsor")

 print("ellison song", 0x40, 0x25, 7)
 print("jake yasuhara")
 print("sarah chen")
 print("")
 print("ellison song")
 print("jake yasuhara")
 print("sarah chen")
 print("")
 print("josh mccoy")

 print("by real fancy fire", 0x1c, 0x68, 7)
end

function render_finished()
 -- rectfill(39, 55, 88, 72, 1)
 -- rect(39, 55, 88, 72, 11)
 ovalfill(0x27, 0x34, 0x58, 0x4c, 11)
 spr(102, 40, 56, 6, 2)
end

--[[
-->8
--[[data manipulation]]

function deal_cards()
 for tab = 1, 7 do
  stack = card_stack.new()
  for i = 1, tab do
   stack:push(deck:pop())
  end
  add(tableau, stack)
  stack:get(-1).face_up = true
 end
end

function pickup(column, row, no_sound)
 if row < 0 then
  -- pickup from pile
  if pile:len() > 0 then
   pickup_from = -2
   hand = pile:split(pile:len())
   render_queued = true
   if (not no_sound) sfx(sounds.pickup)
  elseif not no_sound then
   sfx(sounds.error)
  end
 else
  -- pickup from tableau
  tab_sel = tableau[column]
  if tab_sel:len() > 0 then
   hand = tab_sel:split(row)
   pickup_from = column

   if not no_sound then sfx(sounds.pickup) end
   render_queued = true
  elseif not no_sound then
   sfx(sounds.error)
  end
 end
end
function putdown(column, no_sound)
 if not hand then return end
 -- assumes placement is valid
 if column == -2 then
  -- put back onto draw pile
  pile:pushm(hand)
 else
  -- put onto tableau stack
  sel_row = max(1, tableau[column]:len() + 1)
  tableau[column]:pushm(hand)
 end
 hand = nil

 render_queued = true
end

function move_sel_tableau(delta)
 if not delta then return end
 sel_column = mod(sel_column + delta, #tableau)
 move_sel_row(0)
end

-- Move the selection up or down
function move_sel_row(delta)
 if not delta then return end
 column = tableau[sel_column]
 last = column:last_face_up(false)

 if delta == 0 then
  if sel_row > 0 then
   -- moving left/right across the tableau
   if hand then
    sel_row = column:len() + 1
   else
    -- make sure only face-up cards are selected
    sel_row = max(1, clamp(sel_row + delta, last, column:len()))
   end
  end
 elseif sel_row < 0 then
  -- when moving from special row, cycle to tableau
  sel_row = max(1, (hand or delta < 0) and column:len() or last)
  if (hand) sel_row += 1
 elseif hand then
  -- move up/down from tableau while holding
  sel_row = -1
 else
  -- move up/down along a tableau stack
  sel_row += delta
  if sel_row < last or sel_row > column:len() then
   -- cycle to special row
   sel_row = -1
  end
 end

 sfx(sounds.move)
 render_queued = true
end

-- can stack a card on a column
function can_stack(column_index, card)
 top = tableau[column_index]:get(-1)

 if not top then
  -- place on empty column
  return card.face == 13
 elseif not top.face_up then
  -- place on the column it was picked up from
  return true
 end

 return card.face == top.face - 1 and card.color[card.suit] ~= top.color[top.suit]
end

-- attempt to stack a card on a foundation
function foundate(foundation)
 if (not hand or hand:len() ~= 1) return false
 card = hand:get(1)
 foundation = foundation or card.suit

 if (card.suit ~= foundation) return false
 top = foundations[foundation]:get(-1)

 if (not top and card.face ~= 1) return false
 if (top and card.face ~= top.face + 1) return false
 foundations[foundation]:push(card)
 hand = nil

 sfx(sounds.foundate)
 render_queued = true

 return true
end

function reveal_tops()
 for column in all(tableau) do
  top = column:get(-1)
  if (top) top.face_up = true
 end
end

function draw_card()
 if deck:len() > 0 then
  card = deck:pop()
  card.face_up = true
  pile:push(card)
  sfx(sounds.draw)
 else
  -- flip cards back
  while pile:len() > 0 do
   card = pile:pop()
   card.face_up = false
   deck:push(card)
  end
 end

 render_queued = true
end

function is_finished()
 for foundation in all(foundations) do
  if foundation:len() ~= #card_struct.faces then
   return false
  end
 end
 return true
end

--[[
-->8
--[[menu]]

function goto_credits()
 credits_return_state = state
 state = states.credits
 render_queued = true
end

menuitem(
 1, "music: on", function()
  music_on = not music_on
  update_music()
  menuitem(nil, "music: " .. (music_on and "on" or "off"))
  -- don't close
  return true
 end
)
menuitem(2, "credits", goto_credits)
menuitem(
 3, "desgin docs: off", function()
  design_mode = not design_mode
  camera(0, design_mode and -16 or 0)
  render_queued = true
  menuitem(nil, "desgin docs: " .. (design_mode and "on" or "off"))
  -- don't close
  -- return true
 end
)
--[[
-->8
--[[main loop]]

function _init()
 palt(0x2000)
 deck = card_stack.new()
 for c = 1, 4 do
  add(foundations, card_stack.new())
  for i = 1, 13 do
   deck:push(card_struct.new(c, i))
  end
 end

 deck:shuffle()
 pile = card_stack.new()

 render_queued = true
 music(musics.title)
end

function btn_lr()
 if cool_lr < 0 and btn(0) ~= btn(1) then
  cool_lr = 4
  return btn(0) and -1 or 1
 end
end

function btn_ud()
 if cool_ud < 0 and btn(2) ~= btn(3) then
  cool_ud = 4
  return btn(2) and -1 or 1
 end
end

function btn_x()
 if cool_x < 0 and btn(5) then
  cool_x = 10
  return true
 end
end

function btn_o()
 if cool_o < 0 and btn(4) then
  cool_o = 10
  return true
 end
end

function _update()
 cool_lr -= 1
 cool_ud -= 1
 cool_x -= 1
 cool_o -= 1

 if state == states.credits then
  if btn_x() or btn_o() then
   state = credits_return_state
   render_queued = true
  end
 elseif state == states.title then
  if btn_x() then
   state = states.controls
   render_queued = true
  elseif btn_o() then
   state = states.game
   deal_cards()
   start_time = t()
   render_queued = true
   update_music(musics.game)
  end
 elseif state == states.controls then
  if btn_x() or btn_o() then
   state = states.game
   deal_cards()
   start_time = t()
   render_queued = true
   update_music(musics.game)
  end
 elseif state == states.game then
  move_sel_tableau(btn_lr())
  move_sel_row(btn_ud())

  if hand then
   if btn_o() then
    -- put back
    putdown(pickup_from)
    move_sel_row(0)
   elseif btn_x() then
    -- putdown

    -- put onto tableau
    if sel_row > 0 then
     if sel_column == pickup_from or can_stack(sel_column, hand:get(1)) then
      putdown(sel_column)
      reveal_tops()
      sfx(sounds.putdown)
     else
      sfx(sounds.error)
     end
    elseif sel_column > 3 then
     -- put onto foundations
     if foundate(sel_column - 3) then
      reveal_tops()
     else
      sfx(sounds.error)
     end
    elseif sel_column == 2 and pickup_from == -2 then
     putdown(pickup_from)
    else
     sfx(sounds.error)
    end
   end
  else
   --not hand
   if btn_o() then
    -- shortcut button
    if sel_row > 0 or sel_row < 0 and sel_column == 2 then
     -- shortcut from tableau
     pickup(sel_column, sel_row, true)
     if foundate(nil) then
      reveal_tops()
      move_sel_row(0)
     else
      putdown(pickup_from)
     end
    end
   end

   if btn_x() then
    -- pickup
    if sel_row > 0 then
     -- pickup from tableau
     pickup(sel_column, sel_row)
    else
     -- interact with technical
     if sel_column == 1 then
      -- draw card
      draw_card()
     elseif sel_column == 2 then
      pickup(sel_column, sel_row)
     end
    end
   end
  end

  if is_finished() then
   state = states.finished
   start_time = t() - start_time
   update_music(musics.finished)
  end
 elseif state == states.finished then
 end
end

function _draw()
 if render_queued then
  render_queued = false
  render()
 end

 if state == states.credits then
  render_fancy_fire()
 end

 if state == states.game then
  rectfill(0, 0, 32, 5, 0)
  print(format_time(t() - start_time), 0, 0, 11)
 elseif state == states.finished then
  rectfill(0, 0, 32, 5, 0)
  print(format_time(start_time), 0, 0, 12)
 end
end

__gfx__
0000000077777772777777727777777277777772777777727777777277777772777777727777777277777772733939727a7a7a727a7a7a720000000000000000
00000000777277727722277277222772772727727722277277277772772227727722277277222772727222727793937277a8a87277aaaa720000000000000000
0000000077272772777727727777277277272772772777727727777277772772772727727727277272727272771fff72771ff472771fff720000000000000000
0000000077222772772227727772277277222772772227727722277277772772772227727722277272727272744fff7277fff44277ffff720000000000000000
00000000727772727727777277772772777727727777277277272772777727727727277277772772727272727739397277e8e84277c1c1720000000000000000
000000007277727277222772772227727777277277222772772227727777277277222772772227727272227277393972778e8e42771c1c720000000000000000
00000000777777727777777277777772777777727777777277777772777777727777777277777772777777727739397277e8e87277c1c1720000000000000000
00000000222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222220000000000000000
0000000221222222777777777777772277777772777777727777777277777772aaaa22222222aaaa822228222228222282222222222222820000000000000000
000888021712222278eeee88eeee872277727772772727727772777277222772a22222222222222a266888822222228222292222222222220000000000000000
00888882177122227e8ee8ee8ee8e72277222772722222727722277272222272a22222222222222a628689822222288222222822292222220000000000000000
08888882177712227ee88eeee88ee72272222272722222727222227272222272a22222222222222a6886999882668882a2222882222882220000000000000000
08888882177771227ee88eeee88ee7227772777277222772772227727772777222222222222222222669a998268869a8226688822668882a0000000000000000
88888882177112227e8ee8ee8ee8e722772227727772777277727772772227722222222222222222689aa99826896a98268869a868869a820000000000000000
888888022117122278eeee88eeee872277777772777777727777777277777772222222222222222286aaa9988866aa9826896a986896a9980000000000000000
888888022222222278eeee88eeee872222222222222222222222222222222222222222222222222286aaa998869aaa988966aa98866aaa980000000000000000
88888002000000007e8ee8ee8ee8e722222662222662266222266222222662222222222222222222222228228228222222292222282228220000000000000000
08880002000000007ee88eeee88ee722226666226666666622666622226666222222222222222222822888822288822228222222222288820000000000000000
00000002000000007ee88eeee88ee722266666626666666626666662262662622222222222222222226699822266882928882228226689820000000000000000
22222222000000007e8ee8ee8ee8e722666666666666666666666666666666662222222222222222262869a82689688226688222262869820000000000000000
222222220000000078eeee88eeee872266666666666666666666666666666666222222222222222226286a98268969826896982226886a980000000000000000
222222220000000078eeee88eeee87222666666226666662266666622626626222222222222222222266aa982866a9986896a9822866aa980000000000000000
22222222000000007e8ee8ee8ee8e7222226622222666622226666222226622222222222222222222699aa98886aaa98866aa982869aaa980000000000000000
22222222000000007ee88eeee88ee722226666222226622222266222226666222222222222222222886aaa98869aaa9869aaa982896aaa980000000000000000
00000000000000007ee88eeee88ee722000000000000000000000000000000002222222222222222000000000000000000000000000000000000000000000000
00000000000000007e8ee8ee8ee8e722000000000000000000000000000000002222222222222222000000000000000000000000000000000000000000000000
000000000000000078eeee88eeee872200000000000000000000000000000000a22222222222222a000000000000000000000000000000000000000000000000
0000000000000000777777777777772200000000000000000000000000000000a22222222222222a000000000000000000000000000000000000000000000000
0000000000000000222222222222222200000000000000000000000000000000a22222222222222a000000000000000000000000000000000000000000000000
0000000000000000222222222222222200000000000000000000000000000000aaaa22222222aaaa000000000000000000000000000000000000000000000000
00000000000000002222222222222222000000000000000000000000000000002222222222222222000000000000000000000000000000000000000000000000
00000000000000002222222222222222000000000000000000000000000000002222222222222222000000000000000000000000000000000000000000000000
22222222222666666666222222222222222222222222222222555555555555555555555555555555555555520000000022222222222222222222222222222222
22222222222670777766666666622222222222222222222225555555555555555555555555555555558555520000000022222222222222000000022222222222
22222222222607077767877776666666662222222222222255555555555555555555555555555555597f55520000000022222222222200000000000222222222
22222222222600077768787776707777666666666222222255555555555555555555555555555555a777e5520000000022222222222007777777770002222222
220000000226070700088877760707776787777762222222555555555555555555555555555555555b7d11520000000022222222220077777777777700222222
200aaaaa002677770a0878777600077768787777622222225557777577775577755777755555777755c115520000000022222222200777777777777770022222
20aa000aa02677700a07777776070777688877776222222255771771577117711177177155557117155155520000000022222222007777777777777770022222
20a00200a02677000a07778776777777687877776222222255777771577157715577177177577777155555520000000022222222077777777777777777022222
20a02220002670000a07788876777000677777776222222255771111577157715577177151177117155555520000000022222222077777777777777777002222
20a00222222670000a07800086777000677878776222222255771555777757777577771155577777155555520000000022222220077777777777777777002222
20aa0002222677000a0000a086700000000888876222222255511555511115111151111555551111155555520000000022222220077777777777777777002222
200aaa00222677700a0a00a0067000000a0888776222222255555555555555555555555555555555555555220000000022222220077777777777777777002222
22000aa0002000000a000aaa00000000000000006000002255555555555555555555555555555555555552220000000022222220077777777777777770022222
222200aaa000aa000a0a00a000aaa0a00a0a0aa000aaa00222222222222222222222222222222222222222220000000022222222007777777777777770022222
22222000a00a00a00a0a00a00aa00aa00a0aa00a0a000a0222222222222222222222222222222222222222220000000022222222200777777777777700222222
20002220a0a0000a0a0a00a0aa0000a00a0a00000aaaaa0222222222222222222222222222222222222222220000000022222222220000777777777002222222
20a00200a0a0000a0a0a00a0aa0000a00a0a02200a00000222222222222222222222222222222222222222222222222222222222220000000000000022222222
20aa000aa00a00a00a0a00a00aa00aa00a0a02200a00000220002222200000000000220000022000000000000000002222222222220077700000002222222222
200aaaaa0000aa000a0a00a000aaa0aa0a0a022000aaaa0220a0222220a0aaaaa0a0020a0a0020a0aaaaaa0aaaaaa00222222222220777777777002222222222
22000000222000020000000020000000000002220000000220a0222220a000a000aa000a0aa000a0a000000a00000a0222222222220777777777002222222222
22222222222222222222222222222222222222222222222220a0222220a020a020aaa00a0aaa00a0a022220a02220a0222222222220777777777002222222222
22222222222222222222222222222222222222222222222220a0222220a020a020a0a00a0a0a00a0a022220a02220a0222222222220777777777022222222222
22222222222222222222222222222222222222222222222220a0222220a020a020a0a00a0a0a00a0a000000a00000a0222222222220777777770022222222222
22222222222222222222222222222222222222222222222220a0022200a020a020a0aa0a0a0aa0a0aaaaaa0aaaaaa00222222222200777777770022222222222
00000000000000000000000000000000000000000000000020aa00000aa020a020a00a0a0a00a0a0a000000aa000002222222222200777777770022222222222
000000000000000000000000000000000000000000000000200a00a00a0020a020a00a0a0a00a0a0a022220aaa00222222222222207777777770022222222222
000000000000000000000000000000000000000000000000220a00a00a0220a020a00aaa0a00aaa0a022220a0aa0022222222222207777777770222222222222
000000000000000000000000000000000000000000000000220a0aaa0a0220a020a000aa0a000aa0a022220a00aa002222222222207777777770222222222222
000000000000000000000000000000000000000000000000220aaa0aaa0000a000a0200a0a0200a0a000000a000aa00222222222007777777770222222222222
0000000000000000000000000000000000000000000000002200a000a000aaaaa0a0220a0a0220a0aaaaaa0a0200aa0222222222007777777770222222222222
00000000000000000000000000000000000000000000000022200020002000000000220000022000000000000220000222222222007777777770222222222222
00000000000000000000000000000000000000000000000022222222222222222222222222222222222222222222222222222222277777777772222222222222
__label__
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333333333
333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333333333333333333
3333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333333333333333
3333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333333333333
3333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333333333
33333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333333333
33333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333333
333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333
33333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333
333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333
3333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333
333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333
3333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333
333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333
33333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333
3333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333
33333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333
3333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333
333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333
33333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333
33333333333bbbbbbbbbbbbbbbbbbbbbbbbbbb777b7b7b777b777b7b7b777bb77b77bb7b7bbbbb7b7b777bb77bbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333
3333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbb7b7b7bbb7b7b7b7b7b7b7b7b7b7b7b7bbbbb7b7b7b7b7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333
333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbb77bb7b7b77bb77bb777b77bb7b7b7b7b777bbbbb777b777b777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333
33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbb777b7bbb7b7bbb7b7b7b7b7b7b7bbb7bbbbb7b7b7b7bbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333
3333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb777bb7bb777b7b7b777b777b77bb777b777bbbbb7b7b7b7b77bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333
3333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333
333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333
33333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333
33333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb66666666633333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333
3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33367077776666666663333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333
3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333360707776787777666666666333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333
333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333336000777687877767077776666666663333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333
333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000003360707000888777607077767877777633333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333
33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00aaaaa003677770a08787776000777687877776333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33
33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb30aa000aa03677700a077777760707776888777763333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33
33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb330a00300a03677000a0777877677777768787777633333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33
3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb330a03330003670000a0778887677700067777777633333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3
3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb330a00333333670000a0780008677700067787877633333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3
3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb330aa0003333677000a0000a08670000000088887633333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3
3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3300aaa00333677700a0a00a0067000000a088877633333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3
3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33000aa0003000000a000aaa000000000000000060000033bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33300aaa000aa000a0a00a000aaa0a00a0a0aa000aaa00bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333000a00a00a00a0a00a00aa00aa00a0aa00a0a000a0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0003330a0a0000a0a0a00a0aa0000a00a0a00000aaaaa0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0a00300a0a0000a0a0a00a0aa0000a00a0a03300a00000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0aa000aa00a00a00a0a00a00aa00aa00a0a03300a00000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00aaaaa0000aa000a0a00a000aaa0aa0a0a0bb000aaaa0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000bbb0000b000000003000000000000bbb0000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb777b777bbbbbb77b777b777b777bbbbb777b777b777b777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbb7bbbbbb7bbb7b7b777b7bbbbbbb7bbb7b7b7bbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbb7bbbbbb7bbb777b7b7b77bbbbbb77bb77bb77bb77bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7bbb7bbbbbb7bbb7b7b7b7b7bbbbbbb7bbb7b7b7bbb7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb777bb7bbbbbbb77b7b7b7b7b777bbbbb7bbb7b7b777b777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3
3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3
3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7b7b777b777b7b7bbbbb7b7bb77b7b7b777bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3
3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7b7bb7bbb7bb7b7bbbbb7b7b7b7b7b7b7b7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3
3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7b7bb7bbb7bb777bbbbb777b7b7b7b7b77bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3
33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb777bb7bbb7bb7b7bbbbbbb7b7b7b7b7b7b7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33
33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb777b777bb7bb7b7bbbbb777b77bbb77b7b7bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33
33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33
333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb5555555555555555555555555555555555555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333
333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55555555555555555555555555555555585555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333
3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55555555555555555555555555555555597f555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333
3333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55555555555555555555555555555555a777e55bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333
33333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555555555555555555555555555555555b7d115bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333
33333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb5557777577775577755777755555777755c1155bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333
333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb557717715771177111771771555571171551555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333
3333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb557777715771577155771771775777771555555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333
3333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb557711115771577155771771511771171555555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333
33333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb557715557777577775777711555777771555555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333
333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb555115555111151111511115555511111555555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333
3333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55555555555555555555555555555555555555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333
33333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb5555555555555555555555555555555555555bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333
33333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333
333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333
3333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333
33333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333
3333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333
33333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333
333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333
3333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333
333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333
3333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333
333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333
33333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333
333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333
33333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333333
33333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333333333333333333333333
3333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333333333
3333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333333333333
3333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333333333333333
3333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333333333333333333333333333333333333333
333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333
333333333333333333333333333333333333333333333333333333bbbbbbbbbbbbbbbbbbbb333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333

__sfx__
000000001507000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001d7701f7702177023770287702a7702a7001a20023200232002620026200232001a2001f2001720013200132001320013200232002320017200172001c20026200232001c20028200262001a20023200
00030000257701f7701d77019770167701a100001002310000100261001f1001a1001f100231001a1001f100101001010000100131001710017100001001c100001001f1001310000100171001c1002310017100
00100000001002015000100001000010000100201501e1501e1501e15020150201502015029150291502415024150241502715027150271502e1502e150291502915029150291502915029150291502915029150
001000001c150211502315025150281502a500265001a2001f20023200262001a200242001f200182001f2001520015200152001520017200172001a2001a2001f2001f200282001f20023200262001c20023200
000300001f5501f5501f55020550215502155018100101001c100241001f10028100241001f1001c100131000e1001210009100151000e1001a1001e100151002110026100211002a10026100151001a10026100
001000002215000100161501615016150161500010022150221502215024150241502415020150201502915029150291502c1502c1502c1501b1501b1502e1502e1502e1502e1502e1502e1502e1502e1502e150
001000001a2500020013250172501f2501f250262501a25023250232501a2501a2501f2501f25023250232501c2501c2501c2501c2501f2501f2501a2501a2501725017250152501f2501c25026250232501f250
00100000131501315017150171501f1501a15023150261501f1501a150231501f15026150261501a1501a15013150131501f150171501a1501f15026150231501a1501f15017150261501a1501f150231501f150
00100000000000a0500a05019050190500a0500a05003050030500000029150291502915024150241502015020150201500000018050180500000000000221502215022150221502215022150221502215022150
0010000013250132501725017250132501f250262501f2501a2501a250172501c250172501f250232501a250102501025013250132501725017250132501a250232501f25028250262501a2501f2501725023250
00100000000000a0500a05019050190500a0500a0500000000000120501205016050160500605006050000000000008050080501805018050080500805000000000000d0500d0501405014050000000000000000
001000001015010150101501015013150131501c1501c150181501f150241501c15028150181501c15024150151500e15012150091501a1501515000100121501a150211501e15026150211502a1501215021150
001000000a05000000000001605016050000000000000000000000f0500f0501605016050030500305005050050500505005050140501405018050180500a0500a05016050160500a0500a050160501605016050
001000002015027150201502015020150291500010025150251502e1502e150251502515024150241502c1502c150291502215022150221502515000000241502415027150271502415024150251502515000000
00100000291500020029150291502915009200201502e1502e15025150251502e1502e1502c1502c1502415024150000002715027150271500000027150271502715024150241502715027150000000000022150
0010000005050000000000014050140500505005050000000000012050120501605016050060500605000000000000805008050180501805008050080502c1502c15011050110502c1502c150050500505000000
00100000002000505005050180501805000000000000605006050000000000019050190500000000000080500805000000000001405014050000000000005050050502c1502c150180501805018000000000a050
001800001b1501b1501d1501d150201502015020150201502415024150271502715024150241502715024150241501d1501d1501d1501d1501d1501d1501d1501d15024150241502715029150291502915029150
0018000029150291502915029150291502715027150271502215022150241501b15024150241502415024150241502415024150241502415024150271502715029150291502915029150291502b1502b15029150
001800002715027150221502215024150241502715027150241502415022150221501d1501d1501d1501d1501b1501b1501d1501d150201502015020150201502415024150271502715024150241502715027150
00180000241501d1501d1501d1501d1501d1501d1501d150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00180000000000000000000000001405014050140501405014050140500f0500f0500f0500f0500f0500f0500f05011050110501105011050110501105011050110501105011050110500d0500d0500d0500d050
001800000d0500d0500f0500f0500f0500f0500f0500f0500f0500f05014050140501405014050140501405014050140501405014050140501405014050140500d0500d0500d0500d0500d0500f0500f0500f050
001800000f0500f0500f0500f050140501405014050140500f0500f0500f0500f05011050110501105011050110501105011050110500d0500d0500d0500d0500d0500d0500f0500f0500f0500f0500f0500f050
001800000f05011050110501105011050110501105011050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000029150291502c1502c15029150291502e1502e1502e1502e15000100001003115031150301503015030150301502e1502e1502c1502c15000100001000010000100271502715027150271502915029150
00100000001000010000100001000010000100001000010000100001002e1502e150001000010000100001000010000100001000010000100001002c1502c1502c1502c150001000010000100001000010000100
001000000000000000000000000000000000001e0501e05025050250502a0502a0502e0502e050200502005027050270502c0502c05030050300501d0501d05024050240501d0501d05020050200502205022050
0010000029150291502c1502c150291502915027150271502715027150271502715025150251502c1502c1502c1502c1502715027150271502715029150291502915029150291502915029150291502915029150
001000001d0501d05022050220501d0501d050190501905019050190501e0501e05022050220501b0501b0501b0501b0502005020050000000000019050190501905020050250502505027050270501d0501d050
0010000000000000000000000000000000000012050120501205012050000000000000000000001405014050140501405000000000001b0501b05000000000000000000000000000000000000000000000000000
0010000000000000002c1502c15029150291502e1502e1502e1502e15000000000003115031150301503015030150301502e1502e150301503015031150311503115031150381503815035150351500000000000
00100000291502915000000000000000000000251502515025150251502e1502e1500000000000271502715027150271500000000000000000000029150291502915029150000000000000000000003515035150
001000001d0501d05019050140500d0500d05006050060500d0500d0501205012050160501605008050080500f0500f050140501405018050180500a0500a0501105011050180501805019050190501d0501d050
0010000000000000003815038150000000000033150331503315033150331503315031150311502c1502c1502c1502c150301503015030150301502e1502e1502e1502e1502e1502e1502e1502e1502e1502e150
001000003515035150000000010035150351502a1502a1502a1502a1502a1502a1500000000000331503315033150331500000000000000000000000000000000000000000000000000000000000000000016050
00100000190501905011050110500a0500a0500d0500d0500d0500d050120501205016050160500f0500f0500f0500f050140501405000000000000a0500a0500a05011050110501905019050180501805011050
0010000000000000000000000000000000000006050060500605006050000000000000000000000805008050080500805000000000001b0501b05000000000000000000000000000000000000000000a05000000
001000002e1502e1502e1502215022150251502515000000000000000000000221502215000000000002715027150271502715000000000002715027150291502915029150291502415024150241502415022150
001000001605016050160500000000000000000000025150251502515025150000000000029150291500000000000000000000025150251500000000000000000000000000000000000000000000000000000000
000800001a070000001a0702300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000110501105011050160501605000000000000d0500d0500d0500d050000000000000000000000f0500f0500f0500f05000000000000000000000180501805018050180501d0501d050000000000011050
001000000a0500a0500a05000000000000a0500a0500605006050060500605000000000000000000000080500805008050080500000000000000000000011050110501105011050000000000000000000000a050
001000002215022150221500000000000201502015000000000000000000000221502215029150291500000000000000000000025150251502715027150000000000000000000002915029150000000000029150
0010000000000000000000022150221500000000000221502215022150221500000000000000000000027150271502715027150001000000000000000002915029150291502915024100241002c1502c15024000
00100000110501105011050000000000000000000000c0500c0500c0500c050120501205000000000000f0500f0500f0500f050140501405000000000000d0500d0500d0501405019050190501b0501b05020050
001000000a0500a0500a0500000000000000000000006050060500605006050000000000000000000000805008050080500805000000000000000000000000000000000000000000000000000000000000000000
0010000029150291502915000000000002c1502c150000000000000000000002c1502c15000000000002715027150271502715024000000002715027150000000000029150291500000000000271502715000000
00100000000000000000000291502915000000000002e1502e1502e1502e1500000000000291502915000000000000000000000251502515024000000002c1502c15024100241002915029150001000000022150
00100000200501d0501d05019050190500d0500d05006050060500d0500d0501205012050160501605000000000000f0500f0500000000000180501805000000000001805018050000000000000000000000a050
001000000000000000000000000000000000000000000000000000000000000000000000000000000000805008050000000000014050140500000000000110501105000000000001d0501d050000000000000000
0010000000100001000010022150221500010000100221502215022150001000010000100291502915000100001000010024150241502415000000000001d1501d1501d1501d1501d1501d1501d1501d1501d150
001000002215022150221500010000100201502015000100001000010025150251502515000100001002715027150271500010000100001002915029150221502215022150221502215022150221502215022150
001000000a050000000000016050160500000000000060500605006050000001205012050000000000008050080500805000000140501405014050140500a0500a0500a0501605016050160500a0500a05016050
00100000000001105011050000000000000000000000000000000000000d050000000000016050160500000000000000000f050000000000000000000001605016050160500a0500a0500a05016050160500a050
001000001d1501d1500000022150221500000000000221502215025150251502215022150001000010024150241502515000000000000010025150000002415024150291502915024150241502c1502c15025150
0010000022150221501d1500000000000241502415025150251502215022150251502515022150221502715027150000002715027150271500010027150291502915024150241502915029150241002410029150
00100000160501605016050000001105000000000001205012050000000000016050160500605006050000000000008050080501805018050080500805000000000001105011050140501405005050050500a050
001000000a0500a0500a0501605000000160501605006050060501205012050190501905000000000000805008050000000000014050140500000000000050500505000000000001805018050000000000000000
001000002515027150000000000000000221500000025150251502215022150251502515022150221502415024150251502415024150241502515000000201502015029150291502015020150221502215020150
0010000029150000002915029150291500000024150221502215025150251502215022150000000000027150271500000027150271502715000000271502915029150201502015029150291502c1502c15029150
001000000a05000000000001605016050000000000006050060500000000000120501205000000000000805008050000000000014050140500000000000010500105000000000001105011050010500105005050
__music__
00 01024348
00 04054648
01 07084948
02 0a0c4d48
01 12164348
00 13174348
00 14184348
02 15194348
01 1a1b1c48
00 1d1e1f48
00 20212248
00 23242526
00 27282b2c
00 2d2e2f30
00 31323334
00 35363738
00 393a3b3c
00 3d3e3f0b
00 0e0f1011
02 0306090d
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348
00 48494348


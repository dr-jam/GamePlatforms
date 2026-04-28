pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--credits for used code
--petal quest for room/camera ratio: https://www.lexaloffle.com/bbs/?tid=146496
--tweaning/teasing demo: https://www.lexaloffle.com/bbs/?tid=2464
--pico8 funkin: https://www.lexaloffle.com/bbs/?tid=42715
function _init()
music(24)
 game_start()
	snake_speed=0.8
	acc=0
	ignore_timer=0
 ignore_time=20
 detect_timer=0
 detect_time=10
 detect_dist=50
 animation_speed=0.5
 vent_locations={left="kitchen", right="kitchen"}
 maps={minigame={x=112,y=48},
 						black={x=96,y=48}}
 						
 last_l = 0
	offset = 0
	noise = 3
	
  fps=1
	transition_lock = 0
	walk_frame=0
	walk_timer=0
	facing_right=false

  default_room_w = 16
  default_room_h = 16

	rooms={
	-- bottom row (y=50)
	start={x=44, y=50, room_corner=true},
	checking={x=60, y=50, room_corner=true},
	bathroom={x=28, y=50, room_corner=true},

	-- second row 
	kitchen={x=28, y=34, room_corner=true},
	foodstore={x=12, y=34, room_corner=false},
	walkway={x=60, y=34, room_corner=false},
	playarea={x=76, y=34, room_corner=true},

	-- third row
	bridge={x=28, y=18, room_corner=false},
	partyarea={x=76, y=18, room_corner=true},

	-- top row
	TBD2={x=12, y=2, room_corner=true},
	TBD1={x=28, y=2, room_corner=true},
	puzzle={x=76, y=2, room_corner=true},
  
  vents={x=92, y=2, room_corner=false}}

	tile_types={[37]="vent",[52]="crowbar",[53]="idcard",
              [17]="crack",[33]="numpad",[12]="door",[8]="cube",
              [94]="slide", [125]="ddr", [5]="windoor"}
 
	current_message = ""
	message_timer = 0

  seq = {0, 3, 2, 1, 3, 0, 2, 3, 1, 0}
  arrow_chars = {"⬅️","⬇️","⬆️","➡️"}
  arrow_cols  = {8, 12, 11, 9}
  ddr_index = 1
  ddr_done  = false
  ddr_timer = 0
  ddr_spawned = {}

  ddr_sequences = {
  bathroom={0, 3, 2, 1, 3},
  start= {1,3, 2, 0, 2},
  checking={3, 2, 3, 2, 0},
  foodstore={3,2,0,1,2,0,1,2,0},
  kitchen={1,2,3,2,1,3,2,0,1},
  walkway={0,1,0,3,1,2,3,2},
  playarea={0,1,2,0,3,1,2,3},
  partyarea={1,2,0,3,1,0},  
  puzzle={3,2,1,3,0,1,0,2},
  }

  ddr_rewards = {
  --spawns ddr code player has to input based off of the rainbow colors
  bathroom = {char="⬆️", col=15},
  puzzle = {char="⬅️", col=14, 
  rect_change={x1=35, y1=22, x2=36, y2=29, new_spr=36},
  spr_changes={{x=34, y=26, new_spr=126}},},
  checking = {char="⬇️", col=13},
  foodstorage = {char="⬅️", col=12},
  kitchen = {char="➡️", col=11},
  walkway = {char="⬇️", col=10},
  playarea = {char="⬆️", col=9},
  partyarea = {char="➡️", col=8},
}

end

function game_start()
  p={x=24,y=80,speed=1}
 crowbar_picked_up = false
 idcard_picked_up = false
	s={{0,136,104},
	   {0,136,96},
	   {0,136,88},
	   {0,136,80},
	   {0,136,72}}
	mode=-2
	map_coords={x=44,y=50}
	mset(83,22,23)
 mset(84,22,23)
 objects={
	{id=52,name="crowbar",x=19,y=43,room="foodstore"},
	{id=53,name="idcard",x=88,y=11,room="puzzle"},
	{id=17,name="crack",x=47,y=55,room="start"},
	{id=17,name="crack",x=72,y=59,room="checking"},
	{id=17,name="crack",x=85,y=44,room="playarea"},
	{id=17,name="crack",x=34,y=60,room="bathroom"},
	{id=17,name="crack",x=19,y=40,room="foodstore"},
 {id=12,name="door",x=14,y=9,room="TBD1"}}
 bridge_ground_set(35)
 init_minigame()
 slide_state = nil
 slide_tw_x  = nil
 slide_tw_y  = nil

end

function _update()
 if mode==-2 then --title screen
  if (btn(❎)) then 
    music(0)
    mode=0
  end
 end
 if mode==0 then --rooms
    if slide_state ~= nil then
     update_slide()
     return
    end

	 move_player()
	 try_detect()
	 move_snake()
	 move_map()
	 if btnp(4) then
   local nearby = get_nearby_tile()
  	if is_interactable(nearby) then
   	interact(nearby)
  	end
  end
 elseif mode==1 then --minigame
	 minigame()
	--use mode=2 for game over animation before game over screen
	elseif mode==3 then --game over screen
	 if (btn(❎)) game_start()
	elseif mode==4 then --numpad screen
	 update_numpad()
	elseif mode==5 then --rubiks cube
	 update_cube()
 elseif mode==6 then --game end!
	 if (btn(❎)) game_start()
  elseif mode == 7 then
   ddr_update()
   if ddr_done then mode = 0 end
	end
	
	--what is this code doing?
	for i=1,#s do
		if s[i][2]==nil then s[i][2]=s[1] and s[1][2] or 24 end
		if s[i][3]==nil then s[i][3]=s[1] and s[1][3] or 64 end
	end

end

function _draw()
  local x1 = 16
  local x2 = 104
  local y1 = 32
  local y2 = 88
	cls()
	print(#exhaustlist, 1,1,7)
	if mode==-2 then --titlescreen
	 map(maps.black.x, maps.black.y)
  sspr(104,16, 16,16, 32,32, 64,64)
	 print("sh★pe sn♥ke",42,20,8)
	 pal(4,-14,1)
	 print("press ❎ to start",34,108,4)
	elseif mode==0 then --rooms
		map(map_coords.x, map_coords.y)
		spr(49+walk_frame,p.x,p.y, 1, 1, facing_right,false)
		draw_snake()
		if in_room("start") then
			pal(4,129)
			spr(10, newcord("x", 55), newcord("y", 55))
			pal(0)
		end
		for obj in all(objects) do
		 if in_room(obj.room) then
			 spr(obj.id, newcord("x",obj.x), newcord("y",obj.y))
		 end
		end
    if detect_timer>0 and ignore_timer==0 then
      pal(6,8)
      pal(13,142)
      pal(5,2)
    end
    local room = get_current_room()
    if room and room.room_corner then
      spr(38, x1, y1, 1,1, false, false)
      spr(38, x2, y1, 1,1, true,  false)
      spr(38, x1, y2, 1,1, false, true)
      spr(38, x2, y2, 1,1, true,  true)
    end

		camera()
	elseif mode==1 then --minigame
	 map(maps.minigame.x, maps.minigame.y)
	 draw_minigame()
	elseif mode==2 then --death animation
	 map(maps.black.x, maps.black.y)
	 game_end_animation()
	elseif mode==3 then --game over screen
	 map(maps.black.x, maps.black.y)
	 print("game over",48,60,8)
	 pal(4,-14,1)
	 if acc>7 then
	  print("press ❎ to retry", 32,100,4)
	 else
	  acc=acc+0.1
	 end
	elseif mode==4 then --numpad
	 draw_numpad()
	elseif mode==5 then --rubiks cube
	 cd()
	elseif mode==6 then --game end!
	 print("you made it out...?",23,60,7)
	 print("press ❎ to play again", 20,100,4)
  elseif mode == 7 then
    cls(0)
    ddr_draw()
	end
	
	draw_vhs()

	-- find and print current room name
	for name,coords in pairs(rooms) do
		if map_coords.x == coords.x and map_coords.y == coords.y then
			print(name, 0, 122, 7)
		end
	end

	local nearby = get_nearby_tile()
	if is_interactable(nearby) then
		-- little prompt box at the bottom
		rectfill(24, 118, 103, 127, 0)
		print("press z to interact", 26, 121, 7)
	end

	if message_timer > 0 then
		rectfill(0, 100, 127, 127, 0)
		print(current_message, 4, 108, 7)
		message_timer -= 1
	end

  for s in all(ddr_spawned) do
    if in_room(s.room) then
      print(s.char, 110, 10, s.col)
    end
  end
end
-->8
function move_player()
 local rev={x=p.x,y=p.y}
 local moving=btn(0) or btn(1) or btn(2) or btn(3)

 if not moving then
  walk_frame=0
  walk_timer=0
 end
	if ((do_move(⬅️) or do_move(➡️)) and (collide(0))) p.x=rev.x
	if ((do_move(⬆️) or do_move(⬇️)) and (collide(0))) p.y=rev.y
	--other collision checks
	if abs(p.x-s[1][2])<8and abs(p.y-s[1][3])<8 then
	 mode=2
   music(19)
	end
end

function do_move(n)
 if btn(n) then
  if (n<2) p.x=p.x+(n-.5)*2
  if (n>1) p.y=p.y+(n-2.5)*2
  -- direction tracker
  if (n==0) facing_right=false
  if (n==1) facing_right=true
  walk_timer += 1
  if walk_timer>8 then
	  walk_timer=0
	  walk_frame=(walk_frame+1)%2
  end
  return true
 end
 return false
end
 

function collide(flg)
 --returns tile id
 if (fget(f(1,1),flg)) return f(1,1)
 if (fget(f(6,1),flg)) return f(6,1)
 if (fget(f(1,6),flg)) return f(1,6)
 if (fget(f(6,6),flg)) return f(6,6)
	return false
	end

function f(n,m) return mget((p.x+n+map_coords.x*8)\8,(p.y+m+map_coords.y*8)\8) end

function move_map()
	if (transition_lock>0) then
		transition_lock-=1
		return
	end
	if (p.x >= 104) then
	 shift_objs(1,0)
	elseif (p.x <=16) then
	 shift_objs(-1,0)
	elseif (p.y >= 88) then
	 shift_objs(1,1)
	elseif (p.y <=32) then
	 shift_objs(-1,1)
	end
end

function shift_objs(n,orientation)
 if orientation==0 then
	 map_coords.x=map_coords.x+n*16
	 p.x=p.x-n*96
	 p.x=mid(20,p.x,100)
	 for i=1,#s do
	  s[i][2]=s[i][2]-n*96
	 end
	else
	 map_coords.y=map_coords.y+n*16
	 p.y=p.y-n*64
	 p.y=mid(36,p.y,84)
	 for i=1,#s do
	  s[i][3]=s[i][3]-n*64
	 end
	end
	transition_lock=10
end

function move_snake()
 if in_room("vents") then
  return
 end

 if (acc<8) then
  acc=acc+snake_speed
  return
 end
 acc=acc-8
 update_snake()

 if (ignore_timer>0) then
  ignore_timer=ignore_timer-1
  s_move_schedl()
  return
 end
  
 if (detect_timer==0) then
  s_move_schedl()
  return
 end
 
 detect_timer=detect_timer-1
 s_move_player()
end

function try_detect()
if not s[1] or s[1][2]==nil or s[1][3]==nil then return end
 if (((s[1][2]-p.x)^2+(s[1][3]-p.y)^2)^.5<detect_dist) then
  detect_timer=detect_time
 end
end

function s_move_schedl()
 s[1][2]=s[1][2]-8
 s[1][1]=3
 -- if too far off screen, clamp back to edge
  if s[1][2] < -64 then
    s[1][2] = 136
    s[1][3] = 32+rnd(40)\8*8
  end
  if s[1][2] > 192 then
    s[1][2] = -8
    s[1][3] = 32+rnd(40)\8*8
  end
  if s[1][3] < -64 then
    s[1][3] = 136
    s[1][2] = 24+rnd(60)\8*8
  end
  if s[1][3] > 192 then
    s[1][3] = -8
    s[1][2] = 24+rnd(60)\8*8
  end
end

function s_move_player()
 if not s[1] or s[1][2]==nil or s[1][3]==nil then return end
 if abs(p.x-s[1][2])>abs(p.y-s[1][3]) then
	 if (p.x>s[1][2]) then
	  move_block(1,0)
	 else move_block(-1,0)
	 end
	else
	 if (p.y>s[1][3]) then
	  move_block(0,1)
	 else move_block(0,-1)
	 end
	end
end

function move_block(a,b)
 s[1][2]=s[1][2]+a*8
 s[1][3]=s[1][3]+b*8
 if (a~=0) then
  s[1][1] = abs(a-2)
 elseif (b~=0) then
  s[1][1] = abs(b-1)
 else
  s[1][1] = 4
 end
end
-->8
function update_snake()
 for i=#s,2,-1 do
  for j=1,3 do
   s[i][j]=s[i-1][j]
  end
 end
end
 
function draw_snake()
 --if snake not on screen dont draw
 if (s[1][2]<-8or s[1][2]>128or s[1][3]<-8or s[1][3]>128) return
 --tail
 a=false
 b=#s-1
 if(s[b][1]>1) a = true
 if(s[b][1]%2==1) then
  b = 63
 else
  b = 47
 end
 draw_part(#s,b,a,a)
 --body
 for i=2,#s-1 do
  --pipe
  if s[i-1][1]==s[i][1] then
   a = 30
   if (s[i][1]%2==1) a = 31 
   draw_part(i,a,false,false)
  --angle
  else
   a=false
   b=false
   if (s[i-1][1]==1or s[i][1]==3) a=true
   if (s[i-1][1]==2or s[i][1]==0) b=true
   draw_part(i,29,a,b)
  end
 end
 --head
 local a = false
 local b = 14
 if (s[1][1]>1) a = true
 if (s[1][1]%2==1) b = 15 
 draw_part(1,b,a,a)
end
function draw_part(i,sprte,fliph,flipv)
 if (fget(mget(s[i][2]/8+map_coords.x,s[i][3]/8+map_coords.y),3)) return
 spr(sprte,s[i][2],s[i][3],1,1,fliph,flipv) 
end
-->8
function init_minigame()
 local cube={
  x=16,y=32,input={⬆️,⬅️,⬇️,➡️},
  loc={{13,14},{13,2},{2,2},{2,13},{13,13}}}
 local wtaf={
  x=80,y=48,input={➡️,{⬆️,⬅️},➡️,⬇️,{⬆️,➡️},⬅️,{⬇️,⬅️}},
  loc={{0,13},{9,13},{4,8},{11,8},{11,12},{14,3},{3,3},{1,13}}}
 local triangle={
  x=16,y=48,input={➡️,{⬆️,⬅️},{⬅️,⬇️}},
  loc={{0,13},{15,13},{8,2},{1,12}}}
 
 local fish={
  x=80,y=32,input={{⬇️,➡️},➡️,{⬆️,➡️},{⬇️,➡️},⬆️,{⬇️,⬅️},{⬆️,⬅️},{⬇️,⬅️}},
  loc={{1,7},{4,12},{6,12},{9,8},{13,12},{13,3},{10,6},{7,3},{2,7}}}
 local circle={
  x=32,y=32,input={➡️,{⬆️,➡️},⬆️,{⬆️,⬅️},⬅️,{⬅️,⬇️},⬇️,{⬇️,➡️}},
  loc={{4,13},{10,13},{13,10},{13,5},{10,2},{5,2},{2,5},{2,10},{4,12}}}
 local bigx={
  x=48,y=32,input={➡️,{⬆️,➡️},{⬇️,➡️},➡️,⬆️,{⬆️,⬅️},{⬆️,➡️},⬆️,⬅️,{⬇️,⬅️},{⬆️,⬅️},⬅️,⬇️,{⬇️,➡️},{⬇️,⬅️},⬇️},
  loc={{0,13},{4,13},{8,10},{11,13},{14,13},{14,10},{12,7},{14,5},{14,2},{11,2},{7,5},{4,2},{1,2},{1,5},{3,8},{1,10},{1,12}}}
 
 local rctngl={
  x=48,y=48,input={➡️,⬆️,⬅️,⬇️},
  loc={{3,13},{11,13},{11,2},{4,2},{4,12}}}
 local star={
  x=64,y=48,input={{⬇️,⬅️},⬅️,{⬇️,➡️},{⬇️,⬅️},➡️,{➡️,⬆️},{⬇️,➡️},{⬆️,⬅️},⬆️,➡️,{⬆️,⬅️}},
  loc={{8,1},{4,6},{1,7},{4,10},{1,13},{4,13},{8,10},{13,14},{11,8},{11,7},{14,7},{9,2}}}
 local crystal={
  x=32,y=48,input={➡️,{➡️,⬆️},⬆️,⬅️,{⬅️,⬇️},⬇️},
  loc={{0,13},{7,13},{14,6},{14,2},{8,2},{1,9},{1,12}}}
 
 local tri2={
 x=96,y=32,input={{⬇️,⬅️},⬆️,{⬇️,➡️},⬆️,➡️,{⬅️,⬇️}},
 loc={{8,8},{1,15},{1,2},{7,8},{7,2},{14,2},{9,7}}}
 globallist={cube,wtaf,triangle,
 fish,circle,bigx,
 rctngl,star,crystal,
 tri2}
 exhaustlist={cube,wtaf,triangle,
 fish,circle,bigx,
 rctngl,star,crystal,
 tri2}
 tracklist={}
 list_prog=0
 timer=time()+#tracklist*10
 next_track()
 acc=0
 frame_ignore=0
end

function load_minigame()
 tracklist={}
 local track
 for i=0,2 do
  if #exhaustlist==0 then
   track = rnd(globallist)
  else
   track = rnd(exhaustlist)
   del(exhaustlist,track)
  end
  add(tracklist,track)
 end
 list_prog=0
 timer=time()+#tracklist*10
 next_track()
 acc=0
 frame_ignore=0
end

function next_track()
 list_prog=list_prog+1
 t=tracklist[list_prog]
end

function minigame()
 if timer-time()<=0.1 then
  mode=2
  music(19)
  return
 end
 if check_btn(t.input[1]) then
  deli(t.input,1)
  deli(t.loc,1)
 end
 if(#t.input==0) then
  if frame_ignore<=20 then
   frame_ignore=frame_ignore+2
   return
  end
  if(list_prog==#tracklist) then
   mode = 0
   ignore_timer=ignore_time
   detect_timer=0
   current_message = "you stay hidden for a while"
   message_timer = 60
   return
  end
  next_track()
  frame_ignore=0
 end
end
 
function check_btn(n)--n=expected input
 if (frame_ignore>0) then
  if (frame_ignore==1) frame_ignore=0
  return
 else
 end
 
 if (type(n)=="table" and btn(n[1]) and btn(n[2])) then
  frame_ignore=1
  return true
 elseif (type(n)~="table" and btnp(n)) then
  frame_ignore=1
  return true
 end
 if wrong(⬅️,n)or wrong(⬆️,n)or wrong(⬇️,n)or wrong(➡️,n) then
  acc=acc+1
  if (acc>3) then
  mode=2
  music(19)
  else
  music(15+acc)
  end
  return false
 end
end

function wrong(dir,tbl)
 if (type(tbl)~="table") return btnp(dir)
 return btnp(dir) and tbl[1]~=dir and tbl[2]~=dir
end

function draw_minigame()
 --timer
 print(flr(timer-time()),14,41,7)
 --progress ui (right side icons)
 for i=1,#tracklist do
  if (i>=list_prog) palt(0b1001000100010000)
  spr(9,105,7+i*16)
  pal()
 end
 --bottom ui
 for i=8,32-acc*8,8 do
 sspr(i,0,8,8, -28+i*4,96, 24,24)
 end
 sspr(120,0,8,8, 130-acc*32,96, 24,24,true)
 for i=0,acc do
  sspr(120,8,8,8, 130-acc*32+24+i*24,96,24,24)
 end
 --main minigame
 --yellow bg
 fillp(0b0100011111100010)
 rectfill(26,6,100,80, 0x35)
 --sspr(0,48,16,16,31,11,64,64)
 --frame
 fillp(█)
 rect(26,6,100,80,2)
 --draw crimson
 for i=16-#t.input%13,15 do
  pal(i,2)
 end
 --draw navy
 for i=3,15-#t.input%13 do
  pal(i,1)
 end
 sspr(t.x+#t.input\13*16,t.y,16,16,31,11,64,64)
 pal()
 --draw character
 sspr(10,1,1,1,31+t.loc[1][1]*4,11+t.loc[1][2]*4,4,4)
 --draw next location
 if #t.loc>1 then
  sspr(10,3,1,1,31+t.loc[2][1]*4,11+t.loc[2][2]*4,4,4)
 end
end
-->8
function game_end_animation()
 --acc counter starts at 4 for animation
 pal()
 if acc<5 then
  ignore_color("11,6,7,3")
  sspr(104,16, 16,16, 32,32, 64,64)
 elseif acc<8 then
 ignore_color("6,7,3")
  pal(11,3)
  sspr(104,16, 16,16, 32,32, 64,64)
 elseif acc<10 then
  sspr(104,16, 16,16, 32,32, 64,64)
 else
  local k=6*(acc-10)
  sspr(80,8, 24,24, 52-k*11,52-k*11, 24*k,24*k)
 end
 if (acc>=16) then
  mode=3 
  acc=0
 end
 acc=acc+animation_speed
end

function ignore_color(tbl)
 for i in all(split(tbl)) do pal(i,0) end
end

-->8
function draw_vhs()
    -- 1. jitter band
    local l = flr(time()*-9) % 128
    if l != last_l then offset = rnd(3) end
    for h=0,3 do
        local pixels = {}
        for i=0,127 do add(pixels, pget(i,l+h)) end
        for i=0,127 do pset(i+offset, l+h, pixels[i+1]) end
    end
    last_l = l

    -- 2. noise
    for i=1,noise do
        pset(rnd(128), rnd(128), rnd(2))
	end
end
-->8
function newcord(where, target)
  if where == "x" then
    return (target - map_coords.x) * 8
  elseif where == "y" then
    return (target - map_coords.y) * 8
  end
end

function interact(tile)
  local type_ = tile_types[tile]
  if type_ == "vent" then
    if not crowbar_picked_up then
      current_message = "you can't pry it open by hand"
      message_timer = 60
      return
    end
    if in_room("vents") then
      ignore_timer=0
      if (p.x<64) then
        teleport(vent_locations.left)
      elseif (p.x>64) then
        teleport(vent_locations.right)
      end
      return
    end
    ignore_timer=1000
    if in_room("playarea") then 
      vent_locations={left="kitchen",
      															right="playarea"}
    elseif in_room("partyarea") then 
      vent_locations.left ="walkway"
      vent_locations.right="partyarea"
    elseif in_room("puzzle") then
      vent_locations.left ="kitchen"
      vent_locations.right="puzzle"
    elseif in_room("foodstore") then
      --p.x=24
      --p.y=64
      vent_locations.left ="TBD1"
      vent_locations.right="foodstore"
    end
    teleport("vents")
  elseif type_ == "crowbar" then
    crowbar_picked_up = true
    current_message = "got a crowbar!"
    message_timer = 70
  elseif type_ == "idcard" then
    idcard_picked_up = true
    current_message = "got an id card!"
    message_timer = 70
    bridge_ground_set(36)
  elseif type_ == "crack" then
    load_minigame()
    mode=1
  elseif type_ == "numpad" then
    init_numpad()
    mode=4
  elseif type_ == "cube" then
    init_cube()
    mode=5
  elseif type_ == "door" then
    if idcard_picked_up then
     if #exhaustlist==0 then
      --game end!!!
      mode=6
     else
      current_message = (#globallist-#exhaustlist).."/"..#globallist.."shapes filled"
      message_timer = 60
     end
    else
     current_message = "the door needs a keycard"
     message_timer = 60
    end
  elseif type_ == "slide" then
    if in_room("playarea") then
      start_slide()
    end
  elseif type_ == "ddr" then
    local room = get_current_room_name()
    ddr_init(room)
    mode = 7
  end

  for i,obj in pairs(objects) do
   if type_==obj.name and in_room(obj.room) and obj.name~="cube" and obj.name~="door" then
    deli(objects,i)
   end
  end
end

function is_interactable(tile)
  return tile_types[tile] ~= nil
end

function get_nearby_tile()
  local px = (p.x+4+map_coords.x*8)\8
  local py = (p.y+4+map_coords.y*8)\8
  
  local neighbors = {
    mget(px+1,py),  -- right
    mget(px-1,py),  -- left
    mget(px,py+1),  -- below
    mget(px, py-1), -- above
  }
  
  for tile in all(neighbors) do
    if is_interactable(tile) then
      return tile
    end
  end

  for i,obj in pairs(objects) do
	  if abs(p.x-newcord("x",obj.x))<12
	  and abs(p.y-newcord("y",obj.y))<12 then
	   return obj.id
	  end
	 end
	
  return nil
end

function in_room(name)
  return map_coords.x==rooms[name].x and map_coords.y==rooms[name].y
end

function teleport(room_name,x,y)
  local vent_coords={
  ["vents"]={95, 56},
  ["playarea"]={24, 80},
  ["partyarea"]={24, 80},
  ["puzzle"]={24,48},
  ["kitchen"]={80, 40},
  ["foodstore"]={80, 80},
  ["walkway"]={56,56},
  ["TBD1"]={96,80}}
  local px=x or vent_coords[room_name][1]
  local py=y or vent_coords[room_name][2]
  shift_objs(map_coords.x-rooms[room_name].x, map_coords.y-rooms[room_name].y)
  map_coords = {x=rooms[room_name].x, y=rooms[room_name].y}
  p.x=px
  p.y=py
end

function bridge_ground_set(tile)
 for i=35,36 do
  for j=22,29 do
   mset(i,j,tile)
  end
 end
end

function get_current_room()
  for name,coords in pairs(rooms) do
    if map_coords.x == coords.x and map_coords.y == coords.y then
      return coords
    end
  end
end

-->8
function init_numpad()
 select_loc={x=0,y=0}
 str=""
 rightstr="2141"
 clr=7
 clr_timer=0
end

function update_numpad()
 if btnp(❎) and btnp(🅾️) then
  pal()
  mode=0
  music(0)
  return
 end
 if clr_timer>0 then
  clr_timer=clr_timer-1
  return
 else
  if clr==11 then
   numpad_unlocked()
   return
  end
  clr=7
 end
 if(btnp(➡️)and select_loc.x<2)select_loc.x+=1
 if(btnp(⬅️)and select_loc.x>0)select_loc.x-=1
 if(btnp(⬇️)and select_loc.y<3)select_loc.y+=1
 if(btnp(⬆️)and select_loc.y>0)select_loc.y-=1
 if(btnp(🅾️)) then
  if select_loc.x==0 and select_loc.y==3 then
   str=""
  elseif select_loc.x==2 and select_loc.y==3 then
   if str==rightstr then
		  clr=11
		  return
		 else
		  clr=8
		  return
		 end
   clr_timer=20
  else
   add_num()
  end
 end
end

function add_num()
 if (#str>3) return
 str=(select_loc.y<3) and str..select_loc.x+select_loc.y*3+1 or str..0
end

function numpad_unlocked()
 current_message="a door opens"
 message_timer = 180
 mset(83,22,48)
 mset(84,22,48)
 pal()
 mode=0
 music(0)
 return
end

function draw_numpad()
 cls()
 --print exit statement
 print("🅾️+❎ to exit",3,113,5)
 --print numpad & labels
 pal()
 pal(2,12)
 for rows=0,3 do
  for cols=0,2 do
   sspr(16,16,8,8, 39+cols*16,47+rows*16, 16,16)
   if (rows<3) print(rows*3+cols+1,46+cols*16,53+rows*16,7)
  end
 end
 --print last row labels
 print("❎" ,44,101,7)
 print(0   ,62,101,7)
 print("➡️",76,101,7)
 --top input screen
 pal()
 pal(12,1)
 pal(2,12)
 for i=0,3 do
  sspr(16,16,8,8, 39+i*12,31, 12,12)
  if #str>i then
   print(str[i+1],44+i*12,35,clr)
  end
 end
 --select box
 pal()
 pal(1,10)
 palt(12,true)
 palt(2,true)
 sspr(16,16,8,8, 39+select_loc.x*16, 47+select_loc.y*16, 16,16)
end
-->8
function init_cube()
 local w,e,r=split("7,11,8,12,9,10"),split("1,6,3,5,2,4"),split("2,3,4,5,1,2,6,4,3,1,5,6")
 q,v={},{}
 for i=1,6 do
  add(q,{}) add(v,{})
  for _=1,8 do
   add(q[i],w[i])
  end
  add(v[i],i-1)
  add(v[i],e[i])
  for j=0,3 do
   add(v[i],r[ceil(i/2)*4-3+abs(j-(i+1)%2*3)])
end end cd()end

function update_cube()
 if btnp(❎) and btnp(🅾️) then
  mode=0
  music(0)
  return
 end
 for p,w in pairs(v) do
  if(btnp(w[1])) then
   local o=v[p]
		 for _=1,2 do
		  add(q[o[2]],deli(q[o[2]],1))
		 end
		 for i=0,2 do
		  local s,z=q[o[3]][(0+i)%8+1],{0,6,2,4}
		  for j=1,3 do
		   q[o[j+2]][(z[j]+i)%8+1] = q[o[j+3]][(z[j+1]+i)%8+1]
		  end
		  q[o[6]][(4+i)%8+1] = s
end cd()end end end

function cd()
local dy,dx="7,3|0,4|0,5&6|8,2|0,13|0,6&5|9|1,1,1|0,8,2|0,7,3&4|2,0,8|0,0,10|0,0,4&3,0,7|0,0,6|0,0,5","0,5|0,6|3,7&0,4|0,14|2,8|4&0,3,7|0,2,8|1,1,1|12|5&0,0,6|0,0,11|8,0,2|6&0,0,5|0,0,4|7,0,3"
cls()parse(dy,16,1)parse(dx,80)end
function parse(s,x,e)
 for j,i in pairs(split(s,"&")) do
  local z=48+2*abs(j-3)
  for g,h in pairs(split(i,"|")) do
   for j3,b in pairs(split(h)) do
		  if(b>0)pal(j3,b>8and b-2or(b~=0and e)and q[j3][b]or b~=0and q[j3==1and 6 or j3+2][b])palt(j3%3+1,true)palt((j3+1)%3+1,true)spr(20,x+j*4,z+g*4,1,1,false,b>8and not e or(not e)and true)
    pal()end end end
print("r=⬆️,l=⬇️,u=⬅️,d=➡️,f=🅾️,b=❎",3,3,7)print("🅾️+❎ to exit",3,110,5)end
-->8
-- tween system

function tween(from, to, secs, ease_fn)
  return {
    val   = from,
    from  = from,
    delta = to - from,
    dur   = flr(secs * fps),
    t     = 0,
    done  = false,
    ease  = ease_fn or tween_linear,
  }
end

function tween_tick(tw)
  if tw.done then return end
  tw.val = tw.ease(tw.t, tw.from, tw.delta, tw.dur)
  tw.t += 1
  if tw.t >= tw.dur then
    tw.val  = tw.from + tw.delta
    tw.done = true
  end
end

-- easing functions
function tween_linear(t,b,c,d)
  return c*t/d + b
end
function tween_in_quad(t,b,c,d)
  t/=d return c*t*t+b
end
function tween_out_quad(t,b,c,d)
  t/=d return -c*t*(t-2)+b
end
function tween_in_out_quad(t,b,c,d)
  t/=d/2
  if t<1 then return c/2*t*t+b end
  t-=1 return -c/2*(t*(t-2)-1)+b
end
function tween_in_cubic(t,b,c,d)
  t/=d return c*t*t*t+b
end
function tween_out_cubic(t,b,c,d)
  t/=d t-=1 return c*(t*t*t+1)+b
end
function tween_in_out_cubic(t,b,c,d)
  t/=d/2
  if t<1 then return c/2*t*t*t+b end
  t-=2 return c/2*(t*t*t+2)+b
end
function start_slide()
  if slide_state ~= nil then return end  
  slide_tw_x = tween(p.x, 88, 2, tween_out_quad)
  slide_tw_y = tween(p.y, 44, 2, tween_out_quad)
  slide_state = "approach"
end
function update_slide()
  if slide_state == nil then return end
 
  tween_tick(slide_tw_x)
  tween_tick(slide_tw_y)
 
  -- drive the player position from the tweens
  p.x = slide_tw_x.val
  p.y = slide_tw_y.val
 
  -- goes to next step
  if slide_tw_x.done and slide_tw_y.done then
 
    if slide_state == "approach" then
      --climb up the ladder 
      slide_tw_x = tween(p.x-4, newcord("x", 88), 60, tween_linear)
      slide_tw_y = tween(p.y+4, newcord("y", 40), 60, tween_linear)
      slide_state = "climb"
 
    elseif slide_state == "climb" then
      slide_tw_x = tween(newcord("x", 88), newcord("x", 88), 60, tween_linear)
      slide_tw_y = tween(newcord("y", 40), newcord("y", 39), 60, tween_linear)
      slide_state = "slide"
 
    elseif slide_state == "slide" then
      slide_tw_x = tween(p.x, newcord("x", 86), 60, tween_out_cubic)
      slide_tw_y = tween(p.y, newcord("y", 40), 60, tween_out_cubic)
      slide_state = "done"

    elseif slide_state == "done" then
      p.x = 86-4
      p.y = 44-4
      slide_state = nil
      slide_tw_x  = nil
      slide_tw_y  = nil
    end
  end
end
-->8
--ddr puzzle
-- 0=left 1=down 2=up 3=right
function ddr_init(room)
  seq = ddr_sequences[room] or {0, 1, 2, 3}
  ddr_index = 1
  ddr_done = false
  ddr_timer = time() + 10
end

function ddr_update()
  if time() > ddr_timer then
    ddr_done = true  -- ran out of time, fail
    return
  end
  if btnp(⬅️) then ddr_check(0) end
  if btnp(⬇️) then ddr_check(1) end
  if btnp(⬆️) then ddr_check(2) end
  if btnp(➡️) then ddr_check(3) end
  if btnp(❎) and btnp(🅾️) then ddr_done = true end
end

function ddr_check(dir)
  if dir == seq[ddr_index] then
    ddr_index += 1
    if ddr_index > #seq then
      ddr_spawn_reward()
      ddr_done = true
    end
  else
    ddr_index = 1
  end
end

function ddr_draw()
  print(flr(ddr_timer - time()), 60, 40, 7)
  for i=1,#seq do
    local col = 5
    if i < ddr_index then
      col = 3        -- already hit, dim it
    elseif i == ddr_index then
      col = arrow_cols[seq[i]+1]  -- current, highlight
    end
    print(arrow_chars[seq[i]+1], 10 + (i-1)*12, 60, col)
  end
end

function get_current_room_name()
  for name,coords in pairs(rooms) do
    if map_coords.x == coords.x and map_coords.y == coords.y then
      return name
    end
  end
end

function ddr_spawn_reward()
  local room = get_current_room_name()
  local r = ddr_rewards[room]
  if r then
    add(ddr_spawned, {char=r.char, col=r.col, x=r.x, y=r.y, room=room})
    if r.spr_change then
      mset(r.spr_change.x, r.spr_change.y, r.spr_change.new_spr)
    end
  end
  if r.rect_change then
    local rc = r.rect_change
    for x=rc.x1,rc.x2 do
      for y=rc.y1,rc.y2 do
        mset(x, y, rc.new_spr)
      end
    end
  end
  if r.spr_changes then
    for sc in all(r.spr_changes) do
      mset(sc.x, sc.y, sc.new_spr)
    end
  end
end
__gfx__
0000000000000000088888800aaaaaa00cccccc0666666666666666666666666555566660000000055556666555566666666666655556666003bb30000000000
0000000000cccc0087777778a777777ac777777cdddddddd6dddd7766dddddd655577666006666005555666655556666dddddddd5555666603bbbb3003333000
007007000cccccc087700778a770007ac770007cd555555d6ddd77d66dddddd6577777760677b3605555666655556666d555555d5555666603bbbb303bbb8330
000770000c1cc1c087770778a777707ac777007cd5bbbb5d6dd777d66dddddd65bb77886067bb3605555646655556666d588885d5555666603bbbb30bbbbbb30
000770000cccccc087770778a770777ac777707cd5bbb75d6d777dd66dddddd66bbb8885067b33606666545566665555d588875d66665555038bb830bbbbbb38
007007000cc11cc087700078a770007ac770007cd5bbb75d6777ddd66dddddd66bbb888506b333606666545566665555d588875d64444445003bb3003bbb8330
0000000000cccc0087777778a777777ac777777cd5bbbb5d67ddddd66dddddd6666b8555006666006644445544444444d588885d447ff7440033330003333000
0000000000000000088888800aaaaaa00cccccc065000056666666666666666666665555000000006646545546665554650000564ffffff40008000000000000
4444444400000500655555555555555500011000666666666dddddd666666666666666666666666600000000000000000000000000000000003bb30000000000
2499999400d050006555555555555555011111106dddddd66dddddd6dddddddddddddddd6ddddddd00000000000000000000000000000000003bb30000000000
29499994000d05006555555555555555000110006d6666d66dddddd6dddddddddddddddd6ddddddd0000000000bbbb300000000033333300003bb30033333333
29949994000d00556555555555555555022003306d5505d66dddddd6dddddddddddddddd6ddddddd000000000bbbbbb300000000bbbbb300003bb300bbbbbbbb
2999299405550d006555555555555555022233306d6066d66dddddd6dddddddddddddddd6ddddddd00000000bbbbb33330000000bbbbb300003bb300bbbbbbbb
299992945000d0006555555555555555022233306d5555d66dddddd6dddddddddddddddd6ddddddd000000033bb3333333000000333bb300003bb30033333333
2999992400000d006555555555555555000230006dddddd66dddddd6dddddddddddddddd6ddddddd000000333300003333300000003bb300003bb30000000000
2222222200000dd0655555555555555500000000666666666dddddd6666666666dddddd666666666000003337000000733330000003bb300003bb30000000000
bbbbbbbb666666661111111101111110011111106666666666666666444566666dddddd666666666000033376000000073333000000000000000000000000000
3bb3bbbbdddddddd1cccccc110011001100110016dddddd66ddddddd554566666dddddd6ddddddd6000333070000000077033000000000000000000000033000
bbbbbbbbdddddddd1cccccc110011001170117016d6666d66ddddddd554566666dddddd6ddddddd6000330070000000076003000000000000000000000033000
b3bb6b3bdddccddd1cccccc101111110011111106d5505d66ddddddd554566666dddddd6ddddddd6000330077000000070003000000000000000000000033000
bbb655bbddd11ddd1cccccc101111110011111106d6066d66ddddddd664655556dddddd6ddddddd60003000070000000700030000000000000000000003b3300
666655bbddd1bddd1cccccc101011010010110106d5555d66ddddddd664655556dddddd6ddddddd60003000070000000700030000000000000000000003bb300
66665555dddddddd1222222111000011110000116dddddd66ddddddd444444446dddddd6ddddddd60003000000022000000330000008000000080003003bb300
6666555566666666111111110110011001100110666666666dddddd64666555466666666666666660000330000022000003300000000003330000003003bb300
55556666000000000cccc00055500600000688000000000044456666666666665554466666666666000003300002800000300000000033bbbb30003300000000
5555666600cccc00cccccc00555550000006688000bbbb005545666610011001555446666dddddd60000003000028800030000000033bbbbb333333000000000
555566660cccccc0c1cc1c00555506000000008000b0bb005545666617011701555446666dddddd60000003330088803330000000333bb333333333000003333
555566660c1cc1c0cccccc00555566060000088000b6bb0055456666d111111d554444666dddddd60000000333888833300000000333b3333333330003333bbb
666655550cccccc0cc11cc00666605000000880000bb0b0066465555d111111d666655556dddddd600000000038838300000000000333333333330000333bbbb
666655550cc11cc00cccc000666005000088800000b06b0066465555d1d11d1d666655556dddddd6000000000080080000000000000633333336000000003333
6666555500cccc0000000000666000500880000000b6bb006646555511dddd11666655556dddddd6000000000000000000000000000700000006000000000000
6666555500000000000000006666550055000000000000004446555566666666666655556dddddd6000000000000000000000000000700000006000000000000
1111111155556666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b822222222220
1c611cc155556a660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e7c2dddd2aaaaa0
1cc116c14444444400dddddddddddc0000000cccccb000000bbba00000088870022220000002222000000000000000000b00000deeeeeee00ca82dddd2aa0a00
1c7117c145b5666400e0000000000c000000d000000b00000c000a000090007002002200002000200000000e00000c000bc0000d00000f0006c92dddd2a20000
1c7117c14444444400e0000000000c00000d00000000b0000c0000a009000070020000200200002000000ff0e000dc000b0c000d0000f0000b22eedd22220808
1cc11c6141665d5400e0000000000c0000d0000000000a000c0000099000006002000002200000200000f0000e0d0c000b00c00d000f00000c2eee222a200008
16c11cc14444444400e0000000000c0000e0000000000a0000d00000000006000020000000000200000f000000d00c000b000c0d00f000000b2eee29cb800808
100110014666555400e0000000000c0000e0000000000a00000d000000005000000200000000200000f0000000000c000b0000cd0f0000000f2eee2a7ec08888
555566665555666600e0000000000c0000e0000000000a00000d000000005000000200000000200000800000aa000c000b00000ca000000022eee2cd9200cccc
555566665555666600e0000000000c0000e0000000000a0000e0000000000500002000000000020000800000a0b00c000b00000a00000000eeee228e2c08cccc
555566665555666600e0000000000c0000e00000000009000e000001100000400200000ee00000200008000a000b0c000b0000a000000000eee220b00008cccc
555566665555666600e0000000000c00000f0000000090000f00001001000040020000e00f0000200000800a0000bc000b000a0000000000ee22a0008888cccc
66f655956600005500e0000000000c000000f000000900000f0001000010004002000e0000f000200000899000000b000b00a0000000000022208088cccc8888
0000000060cccc0500effffffffffc00000008888880000001111000000133300dddd000000f222000000000000000000b0a000000000000ccc00088cccc8888
0660055060cccc05000000000000000000000000000000000000000000000000000000000000000000000000000000000ba0000000000000cccc8888cccc8888
06600550605c5c05000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000
0770a7060888cccc000000000000000000000000000000000000000000000000000000000000000000000000000000005555666658888666bbbbbbb355777766
079077060888cccc000000000000000000000000000000000000000000000000000000005000000000000000000000005555666658778666bb3bbbbb57888876
500500660888cccc00000000e000000000000000ddddddc00000eeeeeeed0000000000005f00000000000000000000005aaaa99998778cccb3bbb33378888887
544444660888cccc0000000fe00000000000000e000000c00000f000000d00000000000500f00000000eeeeeeeeeeed05a77a90098888cbcbbbb3bbb78888887
649994550ccc8888000000f00e000000000000e0000000c00000f000000d000000000050000f0000000f0000000000d06a77a9009bbbbcbcbbb37b3b78888887
644444550ccc8888000000f00e00000000000e00000000c00000f000000d0000000005000000f00000f00000000000d06aaaa9999b77bcccbbbbb3bb78888887
666655550ccc888800000f0000e000000000e000000000b00000f000000d00000066500000000f0000f00000000000d0666655556b77b5553bbb33bb67888875
666655550ccc88880000f000000e0000000e000000000b000000f000000d000006700000000deee000f0000000000d00666655556bbbb555b7bbbbbb66777755
555006660888cccc000f00000000e00000e000000000b0000000f000000d000000070000000d00000ff0abbbbbbb0d0055556666666666665000066660555506
550bb0660888cccc000f00000000e0000e000000000b00000000f000000d000000007000000c00000f000a00000c0d00555566666ddccdd655556666d055550d
550bbb060888cccc00f0000000000e000f00000000b000000000f000000d00000000700aa000c0000f0000a0000cd000555566666acccce650506666d055550d
550bbb060888cccc0f000000000000e00f0000000b0000000000f000000d0000000800a00b00c0000f00000a000cd00055444466aaacceee50556666d055570d
60bbbb050ccc88880f000000000000e00f000000b00000000000f000000d000000800a0000b00c000f000000a00c000066444455aaa99eee00665555d055570d
60bb00550ccc88881ddddddddddddddd0aaaaaaa000000000001cccccccc000008999000000bbc000999999999000000666445556a9999e660060055d055550d
660055550ccc88880000000000000000000000000000000000000000000000000000000000000b000000000000000000666445556dd99dd666005555d055550d
66665555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066644555666666666006555560555506
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000007071717171717170000000006271717171c0c0715171717200000000000000000000000000000000000000000000
00000000000000000000000000006271717192030391717171000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000061040404040404610000000061030303030303030303036100000000000000000000000000000000000000000000
0000000000000000000000000000610703070307030716e4f4610000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000061030303d00303700000000082039171717171717192036100000000000000000000000000000000000000000000
000062517171d773719200000000820703030307030317e5f5610000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000610303d00303030300000000030306060606b0a01403036100000000000000000000000000000000000000000000
00006103030303030303000000000303030303070303030303610000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000061141414140303030000000003030303030303030303036100000000000000000000000000000000000000000000
00006103030303030303000000000303030303070303c6d603610000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000610303d00303d0700000000093050503030303030303146100000000000000000000000000000000000000000000
00006103036271717192000000009314141414030303c6d603610000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000061141414030314610000000061151515030303031403036100000000000000000000000000000000000000000000
000061030361000000000000000061d7030303030303030303610000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000070717171526071700000000063717171920303717171717300000000000000000000000000000000000000000000
00008203038200000000000000000052717171717171717171000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000062717171920303917171717200000000007171127171717171717172000000006271
71717103037171717100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000061f7f7f7f70303141414d761000000006103140314030314140606610000000061d7
03030303030303030361000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000061030303030303030303036100000000820303030303030303030382000000006172
b0b0b0b0b0b003030361000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000061030303030303030303030300000000030303030303030303030303000000000303
0303b0b0b0b072030361000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000061030303030303030303030300000000030303030303030303030303000000000303
03030303030303030361000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000006103030303030303030303610000000093c70303030303030303c793000000006103
03030303030303030361000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000061f7f7f7f7f7f715151515610000000061d00303030303030303d761000000006103
030303b0b0b0b0b0b061000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000063717160607171716060717300000000637171606071717160607173000000000071
71717171717171717173000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000008808080000800008880888000000880880008808800808088800000000000000000000000000000000000
00000000000000000000000000000000000000000080008080008880008080800000008000808008888800808080000000000000000000000000000000000000
00000000000000000000000000000000000000000088808880888888808880880000008880808008888800880088000000000000000000000000000000000000
00000000000000000000000000000000000000000000808080088888008000800000000080808000888000808080000000000000000000000000000000000000
00000000000000000000000000000000000000000088008080080008008000888000008800808000080000808088800000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000088880000000000000000000000000000888800000000000033330000000000000000000000000000
00000000000000000000000000000000000000000000000088880000000000000000000000000000888800000000000033330000000000000000000000000000
00000000000000000000000000000000000000000000000088880000000000000000000000000000888800000000000033330000000000000000000000000000
00000000000000000000000000000000000000000000000088880000000000000000000000000000888800000000000033330000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000033333333333300000000000000000000000033330000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000033333333333300000000000000000000000033330000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000033333333333300000000000000000000000033330000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000033333333333300000000000000000000000033330000000000000000000000000000
000000000000000000000000000000000000000000000000000033333333bbbbbbbbbbbbbbbb3333000000000000333333330000000000000000000000000000
000000000000000000000000000000000000000000000000000033333333bbbbbbbbbbbbbbbb3333000000000000333333330000000000000000000000000000
000000000000000000000000000000000000000000000000000033333333bbbbbbbbbbbbbbbb3333000000000000333333330000000000000000000000000000
000000000000000000000000000000000000000000000000000033333333bbbbbbbbbbbbbbbb3333000000000000333333330000000000000000000000000000
0000000000000000000000000000000000000000000033333333bbbbbbbbbbbbbbbbbbbb33333333333333333333333300000000000000000000000000000000
0000000000000000000000000000000000000000000033333333bbbbbbbbbbbbbbbbbbbb33333333333333333333333300000000000000000000000000000000
0000000000000000000000000000000000000000000033333333bbbbbbbbbbbbbbbbbbbb33333333333333333333333300000000000000000000000000000000
0000000000000000000000000000000000000000000033333333bbbbbbbbbbbbbbbbbbbb33333333333333333333333300000000000000000000000000000000
0000000000000000000000000000000000000000333333333333bbbbbbbb33333333333333333333333333333333333300000000000000000000000000000000
0000000000000000000000000000000000000000333333333333bbbbbbbb33333333333333333333333333333333333300000000000000000000000000000000
0000000000000000000000000000000000000000333333333333bbbbbbbb33333333333333333333333333333333333300000000000000000000000000000000
0000000000000000000000000000000000000000333333333333bbbbbbbb33333333333333333333333333333333333300000000000000000000000000000000
0000000000000000000000000000000000000000333333333333bbbb333333333333333333333333333333333333000000000000000000000000000000000000
0000000000000000000000000000000000000000333333333333bbbb333333333333333333333333333333333333000000000000000000000000000000000000
0000000000000000000000000000000000000000333333333333bbbb333333333333333333333333333333333333000000000000000000000000000000000000
0000000000000000000000000000000000000000333333333333bbbb333333333333333333333333333333333333000000000000000000000000000000000000
00000000000000000000000000000000000000000000333333333333333333333333333333333333333333330000000000000000000000000000000000000000
00000000000000000000000000000000000000000000333333333333333333333333333333333333333333330000000000000000000000000000000000000000
00000000000000000000000000000000000000000000333333333333333333333333333333333333333333330000000000000000000000000000000000000000
00000000000000000000000000000000000000000000333333333333333333333333333333333333333333330000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000066663333333333333333333333333333666600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000066663333333333333333333333333333666600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000066663333333333333333333333333333666600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000066663333333333333333333333333333666600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000077770000000000000000000000000000666600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000077770000000000000000000000000000666600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000077770000000000000000000000000000666600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000077770000000000000000000000000000666600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000077770000000000000000000000000000666600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000077770000000000000000000000000000666600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000077770000000000000000000000000000666600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000077770000000000000000000000000000666600000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000iii0iii0iii00ii00ii000000iiiii000000iii00ii000000ii0iii0iii0iii0iii000000000000000000000000000
0000000000000000000000000000000000i0i0i0i0i000i000i0000000ii0i0ii000000i00i0i00000i0000i00i0i0i0i00i0000000000000000000000000000
0000000000000000000000000000000000iii0ii00ii00iii0iii00000iii0iii000000i00i0i00000iii00i00iii0ii000i0000000000000000000000000000
0000000000000000000000000000000000i000i0i0i00000i000i00000ii0i0ii000000i00i0i0000000i00i00i0i0i0i00i0000000000000000000000000000
0000000000000000000000000000000000i000i0i0iii0ii00ii0000000iiiii0000000i00ii000000ii000i00i0i0i0i00i0000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0800000000090909000000090900040400000000000909090009000000000000000900000009090909090000000000000000000000000909090900000000000000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000900000000000000000000000009000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000006e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000006e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000026171717171717171717172700006e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e000000000000000000000000000000000000000000000000000000000000000000000017171717171717171717000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000016303030303030303030301600006e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e0000000000000000000000000000000000000000000000000000000000000000000016303030087d7008303030160000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000016303030303030303030302800006e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e000000000000000000000000000000000000000000000000000000000000000000001630303030303030303030160000000039171717171717171717173900000000000000000000000000000000000000000000
000000000000000000000000000016303030303030303030303000006e6e6e6e6e6e6e05056e6e6e6e6e6e6e000000000000000000000000000000000000000000000000000000000000000000001630303030303030303030160000000016131213121312131213122500000000000000000000000000000000000000000000
000000000000000000000000000016303030303030303030303000006e6e6e6e6e6e6e6e6e6e6e6e6e6e6e6e000000000000000000000000000000000000000000000000000000000000000000001630303030303030303030160000000025131213121312131213121600000000000000000000000000000000000000000000
000000000000000000000000000016303030303030303030303900006e6e6e6e6e6e6e6e206e6e6e6e6e6e6e000000000000000000000000000000000000000000000000000000000000000000001630303030303030303030160000000028171717171717171717172800000000000000000000000000000000000000000000
000000000000000000000000000016303030303030303030301600006e6e6e6e6e6e203030206e6e6e6e6e6e000000000000000000000000000000000000000000000000000000000000000000002530303030303030303030160000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000361717171717171717171737000000000717171729303019171717070000000000000000000000000000000000000000000000000000000000000000000000000017171729303017171717000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000002217270015232315000000000000000000000000000000000000000000000000000000000000000000000000000000002617171729303021171717000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000163711001523231500000000000000000000000000000000000000000000000000000000000000000000000000000000167c7c7c7c3030307c7c7d160000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000103008001523231500000000000000000000000000000000000000000000000000000000000000000000000000000000166f6f6f6f3030306f6f30160000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000003030330015232315000000000000000000000000000000000000000000000000000000000000000000000000000000001638383838303038386f30160000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000303030331523231500000000000000000000000000000000000000000000000000000000000000000000000000000000167c7c7c7c303030306f30160000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000273339001523231500000000000000000000000000000000000000000000000000000000000000000000000000000000166f6f6f6f30306f303030160000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000309160015232315000000000000000000000000000000000000000000000000000000000000000000000000000000002538383838303038383838160000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000003611070015232315000000000000000000000000000000000000000000000000000000000000000000000000000000000017171729303017171717370000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010a001f00000035200352005530055300553005530045300452002520025000f5000950007500235032350302502035300252002520025200252005530055300553006530045000850009500065000550000000
490a00200c0233f2003f2003f2001d6253f2003f200130000c0233f2000c023140000c0233f200000000c0230c02300000000003f2001a62500000000000c0230c023000000c023000000c0233f200000000c023
010a00000415004150041500000007150061500515005150041700417000000000000000000000000000000004150041500000000000071500615005150051500417004170000000000000000000000000000000
0110002029115250002411526005015050150529115291152411524105291050010524100241001d1052411529115001052411520105201050010529115291152411524105291050010524100241001d10524115
011000200941509405084150840500005084150841500005094150941508415000050840000000084000000509415094050841508405000050841508415000050941509415084150000508400000000840000005
010e002029014250042401426004010040100429014290142401424004240140000424004240041d0042401429014000042401420004200040000429014290142401424004240140000424004240041d00424014
010e00200941509415084160840500005094160941608416094150941508415000050840009416094150841509416094150841508405000050941509415084150941509416084150000508400094150941608415
000900200942509425084260842500025094260942608426094250942508425000250842009426094250842509426094250842508425000250942509425084250942509426084250002508420094250942608425
001000000285002850018500285002850038500185004850048500485004850048500385003850028500385000850058500585006850068500285002850058500285005850058500485000850008500085000850
010a00000415404154041540000407154061540515405154041740417400004000040000400004000040000404154041540000400004071540615405154051540417404174000040000400004000040000400004
490a00000412004120041200000007120061200512005120041200412000000000000000000000000000000004120041200000000000071200612005120051200412004120000000000000000000000000000000
010a00000412004120041200000007120061200512005120041200412000000000000000000000000000000004120041200000000000071200612005120051200412004120000000000000000000000000000000
010a001f00702037020552205522055220552205522045220452202522025220270209702077020b7020b702047020270203522025220252202522025220552205522055220652236702367022d7022a70229702
190a001f00701037010551105511055110551105511045110451102511025110251102d01077010b7010b701035000351103511025110251102511025110551105511055110651106901367012d7012a70100001
8f020a180060013650146501565015650166501665017650176501c6501d6501e6501f6501f6501f6501f6501d6501d6501e6501d6501d6501c6501b6501a650186501d6501c6501a6501b6501d6501c65000600
010200001e6501f6501f6501f6501f650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 01454546
00 01024344
00 01024344
00 01024044
01 010a4344
02 010b4046
02 01424046
03 41424046
00 01024546
02 01444546
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
03 03044344
03 05064344
03 07084344
00 0e424344
03 0e424344
00 41424344
00 41424344
00 41424344
03 004c0d44


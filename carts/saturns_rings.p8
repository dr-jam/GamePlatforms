pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
--saturn's rings
--cdm176w23 mc/cg/al/sy/md/nm

function m_player(x,y)
  
  local p=
  {
    x=x,
    y=y,
    dx=0,
    dy=0,
    w=16,
    h=16,
    max_dx=1,--max x speed
    max_dy=2,--max y speed
    jump_speed=-1.5,--jump velocity
    acc=0.05,--acceleration
    dcc=0.4,--decceleration
    air_dcc=0.9,--air decceleration
    grav=0.15,
    jump_button=
    {
        update=function(self)
            self.is_pressed=false
            if btn(5) then
                if not self.is_down then
                    self.is_pressed=true
                end
                self.is_down=true
                self.ticks_down += 1
            else
                self.is_down=false
                self.is_pressed=false
                self.ticks_down=0
            end
        end,
        is_pressed=false,--pressed this frame
        is_down=false,--currently down
        ticks_down=0,--how long down
    },
    jump_hold_time=0,--how long jump is held
    min_jump_press=5,--min time jump can be held
    max_jump_press=15,--max time jump can be held
    grounded=false,--on ground
    airtime=0,--time since grounded
    
    dash_hold_time=0,   --how long dash is held
    max_dash_press=10,   --max time dash can be held
    max_dash_dtime=10,  --max time dash dx can be applied
    max_dash_dx=6,--max x speed while dashing
    max_dash_dy=6,--max y speed while dashing
    dash_speed=-1.75,--dash velocity
    dash_dirx = 0,
    dash_diry = 0,
    can_dash=true,
    dash_button=
    {
        update=function(self)
            self.is_pressed=false
            if btn(4) then
                if not self.is_down then
                    self.is_pressed=true
                end
                self.is_down=true
                self.ticks_down+=1
            else
                self.is_down=false
                self.is_pressed=false
                self.ticks_down=0
            end
        end,
        is_pressed=false,--pressed this frame
        is_down=false,--currently down
        ticks_down=0,--how long down
    },
    anims=
    {
        ["stand"]=
        {
            ticks=30,--how long is each frame shown.
            frames={68},--what frames are shown.
        },
        ["walk"]=
        {
            ticks=5,
            frames={100,102},
        },
        ["jump"]=
        {
            ticks=15,
            frames={104},
        },
        ["slide"]=
        {
            ticks=11,
            frames={102},
        },
    },
    curanim="walk",--currently playing animation
    curframe=1,--curent frame of animation.
    animtick=0,--ticks until next frame should show.
    flipx=false,--should sprite be flipped?
    set_anim=function(self,anim)
      if(anim==self.curanim)then return--early out.
      end
      local a=self.anims[anim]
      self.animtick=a.ticks--ticks count down.
      self.curanim=anim
      self.curframe=1
    end,
  
    
    star_loc = {{41, 54}, {36, 46}, {45, 40}, {45, 36}, {45, 32}, 
    {40, 48}, {38, 30}, {40, 24}, {39, 16}, {44,13}, {43, 6}},
    star_anims=
    {
        ["solid"]=
        {
            ticks=200,--how long is each frame shown.
            frames={82},--what frames are shown.
        },
        ["disappearing"]=
        {
            ticks=4,--how long is each frame shown.
            frames={87, 71, 70, 0},--what frames are shown.
        },
        ["gone"]=
        {
            ticks=200,--how long is each frame shown.
            frames={0},--what frames are shown.
        },
        ["appearing"]=
        {
            ticks=4,--how long is each frame shown.
            frames={0, 70, 71, 87},--what frames are shown.
        },
    },
    star_global_ticks = 0, --a global timer that determines what stage the star platforms are in
    star_curanim="solid",--currently playing animation
    star_curframe=1,--curent frame of animation.
    star_animtick=0,--ticks until next frame should show.
    star_set_anim=function(self,star_anim)
      if(star_anim==self.star_curanim)then return--early out.
      end
      local a=self.star_anims[star_anim]
      self.star_animtick=a.ticks--ticks count down.
      self.star_curanim=star_anim
      self.star_curframe=1
    end,
    update=function(self)
      bl=btn(0) --left
      br=btn(1) --right
      bu=btn(2) --up
      bd=btn(3) --down
      if bl==true then
        self.dx-=self.acc
        br=false--handle double press
      elseif br==true then
        self.dx+=self.acc
      else
        if self.grounded then
          self.dx*=self.dcc
        else
          self.dx*=self.air_dcc
        end
      end
      if self.dash_hold_time>0 and self.dash_hold_time<self.max_dash_dtime then
        self.dx=mid(-self.max_dash_dx,self.dx,self.max_dash_dx)
      else
        self.dx=mid(-self.max_dx,self.dx,self.max_dx)
      end
      
      self.x+=self.dx
      
      collide_side(self)
      self.jump_button:update()
      if self.jump_button.is_down then
        local on_ground=(self.grounded or self.airtime<5)
        local new_jump_btn=self.jump_button.ticks_down<10
        if self.jump_hold_time>0 or (on_ground and new_jump_btn) then
          if self.jump_hold_time==0 then --new jump snd
            if self.jump_speed==-3 then
              sfx(snd.cloud)
            else
              sfx(snd.jump)
            end
          end
          self.jump_hold_time+=1
          if self.jump_hold_time<self.max_jump_press then
            self.dy=self.jump_speed--keep going up while held
          end
          p1.cloud_jump=false
        end
      else
          self.jump_hold_time=0
      end
      if state >= 4 then
        if btnp(4) and 
        can_dash and 
        self.dash_hold_time==0 then
            cam:shake(15,2)
        end
        if bl and not br then dash_dirx = 1
        elseif br and not bl then dash_dirx = -1
        else dash_dirx = 0
        end
        if bd and not bu then dash_diry = -1
        elseif bu and not bd then dash_diry = 1
        else dash_diry = 0
        end
        self.dash_button:update()
        if self.dash_button.is_down then
          if can_dash then
            if(self.dash_hold_time==0)sfx(snd.dash)--new dash snd
            self.dash_hold_time+=1
            if self.dash_hold_time<self.max_dash_press then
              self.dy=self.dash_speed*dash_diry
              self.dx=self.dash_speed*dash_dirx
            else
              can_dash=false
            end
          end
        else
          self.dash_hold_time=0
        end
      end
      self.dy+=self.grav
      if self.dash_hold_time>0 and self.dash_hold_time<self.max_dash_dtime then
        self.dy=mid(-self.max_dash_dy,self.dy,self.max_dash_dy)
      else
        self.dy=mid(-self.max_dy,self.dy,self.max_dy)
      end
      self.y+=self.dy
      if not collide_floor(self) then
        self:set_anim("jump")
        self.grounded=false
        self.airtime+=1
      else
        can_dash=true
      end
      collide_roof(self)
      if self.grounded then
        if br then
          if self.dx<0 then
              self:set_anim("slide")
          else
              self:set_anim("walk")
          end
        elseif bl then
          if self.dx>0 then
            self:set_anim("slide")
          else
            self:set_anim("walk")
          end
        else
          self:set_anim("stand")
        end
      end
      if bl then
        self.flipx=false
      elseif br then
        self.flipx=true
      end
      self.animtick-=1
      if self.animtick<=0 then
        self.curframe+=1
        local a=self.anims[self.curanim]
        self.animtick=a.ticks--reset timer
        if self.curframe>#a.frames then
            self.curframe=1--loop
        end
      end
      self.star_global_ticks+=1
      self.star_animtick-=1
      if self.star_animtick<=0 then
        self.star_curframe+=1
        local a=self.star_anims[self.star_curanim]
        self.star_animtick=a.ticks--reset timer
        if self.star_curframe>#a.frames then
            self.star_curframe=1--loop
        end
      end
      if self.star_global_ticks < 200 then
        self:star_set_anim("solid")
      elseif self.star_global_ticks < 216 then
        self:star_set_anim("disappearing")
      elseif self.star_global_ticks < 416 then
        self:star_set_anim("gone")
      elseif self.star_global_ticks < 432 then
        self:star_set_anim("appearing")
      else
        self.star_global_ticks = 0
      end
    end,
    draw=function(self)
      local a=self.anims[self.curanim]
      local frame=a.frames[self.curframe]
      spr(frame,
        self.x-(self.w/2),
        self.y-(self.h/2),
        self.w/8,self.h/8,
        self.flipx,
        false)
    end,
    draw_star_platforms=function(self)
      local a=self.star_anims[self.star_curanim]
      local frame=a.frames[self.star_curframe]
      
      local width = 1
      for s in all(self.star_loc) do
        if(self.star_curanim == "solid") then
          width = 2
          mset(s[1], s[2], 82)        
          mset(s[1]+1, s[2], 83)
        else
          mset(s[1], s[2], 0)
          mset(s[1]+1, s[2], 0)
        end
        spr(frame, s[1] * 8, s[2] * 8, width, 1, false, false)
      end
    end,
  }
  return p
end
function m_cam(target, levelx)
  local c=
    {
      tar=target,--target to follow.
      pos=m_vec(target.x,target.y),
        
      pull_threshold=16,
      pos_min=m_vec(levelx,64),
      pos_max=m_vec(levelx,448),
        
      shake_remaining=0,
      shake_force=0,
      update=function(self)
        self.shake_remaining=max(0,self.shake_remaining-1)
            
        if self:pull_max_x()<self.tar.x then
            self.pos.x+=min(self.tar.x-self:pull_max_x(),4)
        end
        if self:pull_min_x()>self.tar.x then
            self.pos.x+=min((self.tar.x-self:pull_min_x()),4)
        end
        if self:pull_max_y()<self.tar.y then
            self.pos.y+=min(self.tar.y-self:pull_max_y(),4)
        end
        if self:pull_min_y()>self.tar.y then
            self.pos.y+=min((self.tar.y-self:pull_min_y()),4)
        end
        if(self.pos.x<self.pos_min.x)self.pos.x=self.pos_min.x
        if(self.pos.x>self.pos_max.x)self.pos.x=self.pos_max.x
        if(self.pos.y<self.pos_min.y)self.pos.y=self.pos_min.y
        if(self.pos.y>self.pos_max.y)self.pos.y=self.pos_max.y
      end,
      cam_pos=function(self)
          local shk=m_vec(0,0)
          if self.shake_remaining>0 then
              shk.x=rnd(self.shake_force)-(self.shake_force/2)
              shk.y=rnd(self.shake_force)-(self.shake_force/2)
          end
          return self.pos.x-64+shk.x,self.pos.y-64+shk.y
      end,
      pull_max_x=function(self)
          return self.pos.x+self.pull_threshold
      end,
      pull_min_x=function(self)
          return self.pos.x-self.pull_threshold
      end,
      pull_max_y=function(self)
          return self.pos.y+self.pull_threshold
      end,
      pull_min_y=function(self)
          return self.pos.y-self.pull_threshold
      end,
      
      shake=function(self,ticks,force)
          self.shake_remaining=ticks
          self.shake_force=force
      end
    }
  return c
end
function m_vec(x,y)
  local v=
  {
    x=x,
    y=y
  }
  return v
end
function collide_side(subject)
  local offset=subject.w/3
  for i=-(subject.w/3),(subject.w/3),2 do
    if fget(mget((subject.x+(offset))/8,(subject.y+i)/8),0) then
      subject.dx=0
      subject.x=(flr(((subject.x+(offset))/8))*8)-(offset)
      return true
    end
    if fget(mget((subject.x-(offset))/8,(subject.y+i)/8),0) then
      subject.dx=0
      subject.x=(flr((subject.x-(offset))/8)*8)+8+(offset)
      return true
    end
  end
  return false
end
function collide_floor(subject)
  if subject.dy<0 then
      return false
  end
  local landed=false
  for i=-(subject.w/3),(subject.w/3),2 do
    local tile=mget((subject.x+i)/8,(subject.y+(subject.h/2))/8)
    if fget(tile,0) or (fget(tile,1) and subject.dy>=0) then
      subject.dy=0
      subject.y=(flr((subject.y+(subject.h/2))/8)*8)-(subject.h/2)
      if (not subject.grounded) sfx(snd.land)
      subject.grounded=true
      subject.airtime=0
      landed=true
    end
    if fget(tile,5) then
      p1.jump_speed=-3
    else
      p1.jump_speed=-1.5
    end
  end
  return landed
end
function collide_roof(subject)
  for i=-(subject.w/3),(subject.w/3),2 do
    if fget(mget((subject.x+i)/8,(subject.y-(subject.h/2))/8),0) then
      subject.dy=0
      subject.y=flr((subject.y-(subject.h/2))/8)*8+8+(subject.h/2)
      subject.jump_hold_time=0
    end
  end
end
function printo(str,startx,starty,col,col_bg)
  print(str,startx+1,starty,col_bg)
  print(str,startx-1,starty,col_bg)
  print(str,startx,starty+1,col_bg)
  print(str,startx,starty-1,col_bg)
  print(str,startx+1,starty-1,col_bg)
  print(str,startx-1,starty-1,col_bg)
  print(str,startx-1,starty+1,col_bg)
  print(str,startx+1,starty+1,col_bg)
  print(str,startx,starty,col)
end
function printc(str,x,y,col,col_bg,special_chars)
  local len=(#str*4)+(special_chars*3)
  local startx=x-(len/2)
  local starty=y-2
  printo(str,startx,starty,col,col_bg)
end
stars={}
stars.bright=7
stars.dark=5
stars.init=function()
    stars.all={}
    for i=0,32 do
        s = {}
        s.x = rnd(128)
        s.y = rnd(100)+10
        s.c = i/32
        s.col = stars.dark
        if s.c>0.75 then s.col=stars.bright end
        add(stars.all,s)
    end
end
stars.draw=function()
    for s in all(stars.all) do
        pset(s.x,(s.y+ticks*s.c)%128,s.col)
    end
end
function game_update()
	ticks+=1
  p1:update()
  cam:update()
  if p1.y > 500 then
    sfx(snd.ouch)
    laststate=state
    state=10
  elseif p1.y < -12 then
    sfx(snd.meow)
    laststate=state
    state=9
  end
end
function game_draw()
  if (state==2) cls(14)
  if (state==4) cls(13)
  if (state==6) cls(2)
  stars.draw()
  camera(cam:cam_pos())
  map(0,0,0,0,128,128)
  p1:draw_star_platforms()
  p1:draw()
  camera(0,0)
  if state==2 then
    printc("press ❎ to jump!",64,4,7,0,0)
  elseif state==4 then
    printc("press 🅾️ to rocket dash!",64,4,7,0,0)
  else
    printc("you're almost there!",64,4,7,0,0)
  end
end
function pause_update(death)
	if death==0 then
    if btnp(4) or btnp(5) then
      if laststate==2 then
        state=3
      elseif laststate==4 then
        state=5
      elseif laststate==6 then
        state=7
      end
    end
  else
    if btnp(4) or btnp(5) then
      if (laststate==2) reset(l.one)
      if (laststate==4) reset(l.two)
      if (laststate==6) reset(l.three)
      state=laststate
    end
  end
end
function pause_draw(death)
  music(-1)
  cls(1)
  if death==0 then
    if laststate==2 then
      printc("you have broken the atmosphere",64,49,7,0,0)
    elseif laststate==4 then
      printc("you're farther in the milky way",64,49,7,0,0)
    else
      printc("you are now at saturn :)",64,49,7,0,0)
    end
    spr(104,57,57,2,2,true)
    printc("press ❎ or 🅾️ to continue",60,77,7,0,0)
  else
    printc("you have fallen back down",64,49,7,0,0)
    spr(100,57,57,2,2,true)
    printc("press ❎ or 🅾️ to try again",60,77,7,0,0)
  end
end
function title_update()
  if not musplay then
    music(mus.menu,0)
    musplay=true
  end
  if btnp(2) and titleloc > 0 then
    sfx(snd.adv)
    titleloc-=1
  elseif btnp(3) and titleloc < 2 then
    sfx(snd.adv)
    titleloc+=1
  end
  if btnp(5) and titleloc==0 then
    sfx(snd.confirm)
    music(-1)
    musplay=false
    laststate=state
    state=1
  elseif btnp(5) and titleloc==1 then
    sfx(snd.confirm)
    music(-1)
    musplay=false
    laststate=state
    state=8
  elseif btnp(5) and titleloc==2 then
    cls(0)
    stop("see you, space meowboy",0,0,7)
  end
end
function title_draw(frame)
  cls(1)
  map(112,0,0,0,128,128)
  local ypos = 0
  if titleloc==0 then
    ypos = 72
  elseif titleloc==1 then
    ypos = 88
  else
    ypos = 104
  end
  
  spr(2,32,ypos,1,1)
  
  spr(17+(2*(frame%4)),48,8,2,2)
  spr(17+(2*(frame%4)),8,54,2,2)  
  spr(17+(2*(frame%4)),90,108,2,2)
end
function cutscene_update(cs)
  if not musplay then
    music(cs.music,0)
    musplay=true
  end
  if btnp(4) or btnp(5) then
    sfx(snd.adv)
    textnum+=1
    if textnum > #cs.t - 1 then
      musplay=false
      if (cs.nextstate==2) reset(l.one)
      if (cs.nextstate==4) reset(l.two)
      if (cs.nextstate==6) reset(l.three)
      state=cs.nextstate
    end
  end
end
function cutscene_draw(cs)
  if (state==1) cls(14)
  if (state==3) cls(13)
  if (state==5) cls(2)
  if (state==7) cls(1)
  if state==1 then
    spr(74,88,56,2,2)
    if textnum<=12 then -- normal cat
      spr(108,24,56,2,2,true)
    elseif textnum>12 then -- helmet cat
      spr(68,24,56,2,2,true)
    end
    if textnum==12 then
      spr(98,56,40,2,2)
    end
  elseif state==3 then
    spr(68,24,56,2,2,true)
    if textnum>=19 then -- draw jetpack
      spr(65,56,40,1,1)
    end
  elseif state==5 then
    spr(68,24,56,2,2,true)
    if textnum>=2 then -- draw cow
      spr(76,88,56,2,2)
    end
  else
    circfill(4,48,48,9)
    line(0,48,70,46,7)
    line(0,46,67,52,7)
    line(0,50,73,42,7)
    if textnum>=14 then -- draw frens
      spr(74,104,56,2,2)
      spr(76,104,40,2,2)
      spr(78,104,24,2,2)
    end
  end
  map(cs.map_x,cs.map_y,0,0,128,128)
  printo(cs.t[textnum][1],4,92,7,0,0)
  printo(cs.t[textnum][2],4,104,7,0,0)
  print("❎|🅾️",99,123,2)
end
function credits_update()
  if btnp(4) or btnp(5) then
    textnum=1
    state=0
    prevstate=nil
  end
end
function credits_draw()
  cls(0)
  map(56,36,0,0,128,128)
  printc("design by morgan creek",64,32,7,0,0)
  printc("art by clarissa gutierrez",64,40,7,0,0)
  printc("and siyuan guo",64,48,7,0,0)
  printc("audio by alex ling",64,56,7,0,0)
  printc("programming by michael dinh",64,64,7,0,0)
  printc("and nicholas mueller",64,72,7,0,0)
  printc("thank you for playing! :)",64,88,7,0,0)
end
snd=
{
  ouch=0,
  meow=8,
  jump=28,
  dash=29,
  cloud=30,
  land=31,
  adv=25,
  confirm=26
}
mus=
{
  cs1=8,
  l1=32,
  cs2=24,
  l2=40,
  cs3=16,
  l3=0,
  cs4=56,
  menu=63
}
l=
{
  one=
  {
    px=32,  --where to spawn player x
    py=480, --where to spawn player y
    lx=72,   --camera limit x (y is always the same)
    music=mus.l1 --music track to play
  },
  two=
  {
    px=168,  
    py=480,
    lx=208,
    music=mus.l2
  },
  three=
  {
    px=376,
    py=490,
    lx=344,
    music=mus.l3
  }
}
sce=
{
  one=
  {
    map_x=64, -- x location of cutscene on tilemap
    map_y=0,  -- y location of cutscene on tilemap
    nextstate=2, -- point to next level
    music=mus.cs1, --music track to play
    t={
      {"friend bunny","so... i guess this is it.\nyou're finally doing it!"},
      {"cat","i know... i've been waiting\nfor this my whole life..."},
      {"friend bunny","yeah, this has been your dream\nfor as long as we've been\nfriends. are you excited?"},
      {"cat","of course! but i'm also\nnervous... what if something\nhappens?"},
      {"friend bunny","yeah, space is pretty scary...\nand unpredictable...\nand big..."},
      {"friend bunny","and there's black holes...\nand supernovas...\nand aliens!"},
      {"cat","..."},
      {"friend bunny","i'm kidding! mostly. you'll\nbe fiiiine. i'm sure you'll\nfind help along the way!"},
      {"friend bunny","...but just between you and me\ni'd avoid any suspicious ufos."},
      {"cat","uh, if you say so..."},
      {"cat","okay, i think i'm good to go!"},
      {"friend bunny","alright! here's your space\nhelmet. you're officially\nready to see saturn's rings!"},
      {"friend bunny","good luck, cat-stronaut o7"},
      {"cat (now a stronaut)","thanks, bunny. i can't wait\nto tell you all about it when\ni get back!"},
      {"",""}
    }
  },
  two=
  {
    map_x=80,
    map_y=0,
    nextstate=4,
    music=mus.cs2,
    t={
      {"some kinda unicorn","hello~"},
      {"cat-stronaut","uh, hi?"},
      {"space unicorn, apparently","hi there~ i'm *space unicorn*"},
      {"cat-stronaut","woah, hi. i'm cat-stronaut."},
      {"space unicorn","nice to meet you,\ncat-stronaut! ~yaaaay~"},
      {"cat-stronaut","uhh, why so excited?"},
      {"space unicorn","well, not that many people\ntravel out to space so i've\nbeen suuuper bored out here"},
      {"space unicorn","but now i have you, my new\n~space bestie~"},
      {"cat-stronaut","haha... okay...\ni can't stay too long though,\ni'm trying to get to saturn!"},
      {"space unicorn","*dang* that's far. is all you\nbrought that space helmet...?"},
      {"cat-stronaut","...uh, yeah?"},
      {"space unicorn","that's cool, that's cool...\nyou're never gonna make it\nlike that though."},
      {"cat-stronaut","huh? what? why?"},
      {"space unicorn","there's a bunch of arduous\nplatforming gaps and weird\nplatform-type shapes up ahead!"},
      {"cat-stronaut","...oh."},
      {"space unicorn","yeah, sorry bestie."},
      {"cat-stronaut","...well, i guess i'll head ba-"},
      {"space unicorn","wait hold on a second"},
      {"space unicorn","i forgot i had this jetpack"},
      {"cat-stronaut","for real?"},
      {"space unicorn","yeah, it's rad, dude. it lets\nyou boost in *any* direction!"},
      {"cat-stronaut","well, that sounds like 1) fun,\nand 2) just what i need to\ntraverse the next level"},
      {"space unicorn","for real, bro. alright, i'll\nlet you borrow it under one\ncondition."},
      {"cat-stronaut","alright, what is it?"},
      {"space unicorn","we gotta be\nspace besties\n~forever~"},
      {"cat-stronaut","haha, that sounds like a fair\ntrade."},
      {"",""}
    }
  },
  three=
  {
    map_x=64,
    map_y=16,
    nextstate=6,
    music=mus.cs3,
    t={
      {"cat-stronaut","oh boy... that's a lot of\nshooting stars."},
      {"unspecified cow","..."},
      {"cat-stronaut","..."},
      {"unspecified cow","...hey dude."},
      {"cat-stronaut","...hey. you got any idea\nwhat's up with all those\nstars ahead?"},
      {"unspecified cow","oh, yeah. see, those are\nlocalized star fields."},
      {"unspecified cow","they sorta appear and\ndisappear on a regular\ninterval."},
      {"cat-stronaut","...huh."},
      {"unspecified cow","you can even stand on 'em, but\ndon't get caught with your\nstars down."},
      {"unspecified cow","because then you'll fall."},
      {"unspecified cow","all the way back down."},
      {"unspecified cow","to not saturn."},
      {"cat-stronaut","...huh. how do you know all\nthis?"},
      {"the moober cow","oh you know, i run a small\nlittle space travel operation\ncalled moober."},
	  {"the moober cow","that's why all the ufos are\nout and stuff."},
      {"the moober cow","you might've heard of me or\nsomething."},
      {"cat-stronaut","...i don't think i have,\nbut thanks for the advice?"},
      {"",""}
    }
  },
  four=
  {
    map_x=80,
    map_y=16,
    nextstate=8,
    music=mus.cs4,
    t={
      {"cat-stronaut","wow... i've finally made it...\ni made it to saturn's rings!"},
      {"cat-stronaut","it's everything i could have\nimagined! :o"},
      {"cat-stronaut","saturn is so beautiful from\nhere...and the rings are so\nmesmerizing."},
      {"cat-stronaut","it looks like they're made of\nglitter!"},
      {"cat-stronaut","and it's so giant! i feel so\nsmall compared to it..."},
      {"cat-stronaut","..."},
      {"cat-stronaut","...huh. you know, saturn is\nmuch more peaceful than i\nimagined."},
      {"cat-stronaut","it's actually so calm... and\nquiet. there's really nobody\nelse out here!"},
      {"cat-stronaut","almost kind of lonely when\nyou think about it..."},
      {"cat-stronaut","...but i guess its okay to be\na little lonely. it's good to\nbe by yourself sometimes."},
      {"cat-stronaut","i couldn't have made it this\nfar without everyone's help."},
      {"cat-stronaut","i can't wait to tell them\nabout this trip!"},
      {"???","nah you don't gotta do that\nwe're all here lmao"},
      {"cat-stronaut","! you're all here!"},
      {"friend bunny (can breathe)","we sure are, pal. how about we\ncelebrate with a picture?"},
      {"cat-stronaut","oh heck yes"},
      {"","\n             end             "},
      {"",""}
    }
  }
}
function reset(level)
    ticks=0
    delay_count=0
    delay_on=false
    p1=m_player(level.px,level.py)
    p1:set_anim("walk")
    stars.init()
    cam=m_cam(p1,level.lx)
    textnum=1
    music(level.music,0,14)
end
function _init()
    palt(0, false)
    palt(3, true)
    poke(0x5f5c, 255)
    state=0
    prevstate=nil
    musplay=false
    titleloc=0
    textnum=1
end
function _update60()
    if state==2 or state==4 or state==6 then
      game_update()
    elseif state==0 then
      title_update()
    elseif state==1 then
      cutscene_update(sce.one)
    elseif state==3 then
      cutscene_update(sce.two)
    elseif state==5 then
      cutscene_update(sce.three)
    elseif state==7 then
      cutscene_update(sce.four)
    elseif state==8 then
      credits_update()
    elseif state==9 then
      pause_update(0)
    else --state 10
      pause_update(1)
    end
end

frame = 0
tick = 0

function _draw()
    if state==2 or state==4 or state==6 then
      game_draw()
    elseif state==0 then
      title_draw(frame)
      if(tick%8==0) frame += 1
      tick += 1
    elseif state==1 then
      cutscene_draw(sce.one)
    elseif state==3 then
      cutscene_draw(sce.two)
    elseif state==5 then
      cutscene_draw(sce.three)
    elseif state==7 then
      cutscene_draw(sce.four)
    elseif state==8 then
      credits_draw()
    elseif state==9 then
      pause_draw(0)
    else --state 10
      pause_draw(1)
    end
end
__gfx__
3333333300000000333333333333a3333a33337333333333373333333377773333777733333333333333333333333333333333333333333aaaa3333333377733
333333330000000033333333333aaa33a7a3333a333373337773333337733373377333733333333333333333333337733333333333333aaaaaaa333337733373
33333333000000003337333333aa7aa33a33333333333333373333333773333337733373333333333333333333377777333333333333aaaaaaaaa33337733333
3333333300000000337773333aa777aa3a3333333333333333333733377333333773337333333333333333333377677733333333333aaaaaaaaaaa3337733333
33333333000000003777773333aa7aa333333a333733333333333733377377333777773333333337733333337777667777333333333aaaaa3333aa3337733333
333333330000000033777333333aaa333333a7a3337333333333777337733373377333333333377777773333336777776663333333aaaaa33333333337733333
3333333300000000333733333333a33337333a33333333733333373337733373377333333337777777773333333666663333333333aaaa333333333337733373
3333333300000000333333333333a333a3333333333333333333373333777733377333333337777766777333333333333333333333aaaa333333333333377733
3773337333333333333333333333333333333333333333333333333333333333333333333377777666677733333333333337733333aaaa333333333377777777
3773337333733333333373333333333333773333333333333333373333333333733333333377777777667773333333333377777333aaaa33333333a322222227
3777337333333333333337333333333377333333333333333333333333333333333333336677767777766776333333333667776633aaaaa333333aa300000027
37737373333333333333337333333377333333333333373333333333333333333333333336666677766666633337777333366633333aaaaa3333aaa300000027
37737373333333333733337333333733333333733333333333333333333333333333333333666666666633333777777733333333333aaaaaaaaaaa3300000027
377337733333333333333373333373333333333333333333333333333333333333333373333333666633333337777767633333333333aaaaaaaaaa3300000027
3773337333333333333337333333333333333333333733333333333333333333333333333333333333333333667776663333333333333aaaaaaaa33300000027
3773337333333333a337733333333333a333333333373333a333333333333333a3333333333333333333333333666633333333333333333a3333333300000027
377333733333333aaa7333333333333aaa3333333373333aaa3333333373333aaa73333333333333333333333333333333333333377333337777777700000027
37733373333333aa7aa33333373333aa7aa33333373333aa7aa33333333333aa77a3333333337733333333333333333337777333377333332222222200000027
377333733333333aaa3333333333333aaa3333333733333aaa3333333333333a7a33333333377673333333333333333367777773377333330000000000000027
3377373333333333a333333333333333a333333373333333a337333333333337a333333337776777733333333333333336677766377333330000000000000027
33377333333333333333373333333333333333333733333333333333333333733333333367777777777333333333333333366633377333330000000000000027
33377333333733333333333333333333333333333733333333333333333337333733333336777666333333337333333333333333377333330000000000000027
33377333333333333333333333333333373333333333333333333333337773333333333333666333333333336777733333333333377333330000000022222227
33377333333333333333333333333333333333333333333333333333333333333333333333333333333333336667733333333333337777730000000077777777
33777733333773333377773333777733373333733337773333777733337777733337733333333333333733337777766377733333373333730000000000000000
37777773337777333773337337777773373333733373377337733373373333333773373333333773377777337777776677777333373333730000000000000000
33377333377737733773333333377333373333733773337337733373373333333773337333377777777777337777777777773333373333730000000000000000
33377333377333733377733333377333373333733773337337733733377733333773337333366777766777776777777777776633373333730000000000000000
33377333377333733337773333377333373333733773737337777333373333333773337333777667777777736667777777777663373333730000000000000000
33377333377777733333377333377333373333733773777337737733373333333773337336777777777777766666666666666666373333730000000000000000
33377333377333733733377333377333337777333373377337733733377777733773373333666677777666633333366666633333377777732222222200000000
33377333377333733377773337777773337777333337773737733773377777733337733333333366666333333333333333333333337777337777777700000000
777777773566665333112250115022333337777733333333333333333cc3333333333bbbbb3333333333333333333333333333333333333333eeeee330a03333
72222222365dd56331122001100221133373333a73333333333333333ac333333555555555555533333333333333333333333333333333333ee000ee0aa03333
72000000365dd5633322051105221133379a33a9a733333373333733aaa333336b66b66b66b66b6333363336333333333300330033333333eec070000a033333
72000000365dd56333333333333333337a97aa99a3733333337333333a3333333555555555555533336e636e6333333330f0330f03333333ecc0777770033333
7200000036dddd633333333333333333797999999a73333373333333333333333333333333333333336e636e6333333300f0000f00333333ecc0777077033333
72000000356666533333333333333333799999999a73333333333733333333333333333333333333336e636e633333330555577770333333eec0777077703333
72000000338338333333333333333333790999909a7333333733333333333333333333333333333333676667633336663050570703333333eec0777777703333
72000000339339333333333333333333790999909a73aa3333333333333333333333333333333333367777777666667630507707033333333ec0770000033333
72000000333333333ccaccaccccacaaaa7999999873a99a3333333333ccaccac0400400400400403677777777767766607eeeee7703333333ee0777033333333
72000000333333333acccccccacccccc3a79999a733a99a3333336333acccccc4004004004004003677077707776776307e0ee077000003333e077770000eee3
7200000033333333aaaccacccccaaaaa33a665669a33a99a33333633aaaccacc0040040040040043677077707776776330eeeee70577550333e0777777770cee
72000000333333333a3333333333333333a98c8a99a3a99a333555333a33333304004004004004036777777777777763330000005577770033307777777770ce
7200000033333333333333333333333333a9aa99a9aa999a3335b53333333333333333333333333367777e77777777633307777557777500333077777777703c
7200000033333333333333333333333333a9aa9999a999a33335853333333333333333333333333366777777777777633305577777755700333077000007703c
7200000033333333333333333333333333a9a99999a9aa3333355533333333333333333333333333366777777777763333050000700007033330770333077033
72000000333333333333333333333333333aaaaaaaaa333333333333333333333333333333333333336776776677763333003333003330033330770333077033
00000027333333333337777733333333333777773333333333377777333333333777777773333333333333333333333333333333333333337333333333333333
000000273333333333733333733333333373333a733333333373333a73333333779a33a977333333333333333333333333a3333a333333333337333333333733
00000027333333333733333337333333379a33a9a7333333379a33a9a73333337a99aa99a733333333777776777767733a9a33a9a33333333333333333733333
000000273333333373373333337333337a97aa99a37333337a97aa99a3733333799999999733333337673677637776333a99aa99a33333333733733333333337
00000027333333337373333333733333797999999a73aa33797999999a7aa33379099990973333333333333333333733a99999999a3333333373333333333733
00000027333333337333333333733333799999999a7a99a3799999999a799a3379999999973333333373333333373337a99999999a3333337333333337333333
00000027333333337333333333733333790999909a7a99a3790999909a799a3378999999873aa3337333337333333333a90999909a3333333333333333337333
00000027333333337333333333733333790999909a73a99a790999909a7a99a33776066773a99a333333333333333333a90999909a33aa333333333333333333
72000000000000003733333337333333a79999998733a99aa7999999873a99a33a98c899a3a99a333333333333333333a89999998a3a99a30000000000000000
720000000000000033733333733333333a7999997aaa999a3a7999997aaa99a33a999999a33a99a333333333333333333aa9999aa33a99a30000000000000000
7200000000000000333665663333333333a66566999999a333a6656699999a333a9a99a9a33a99a333333bbbbb33333333a999999a33a99a0000000000000000
7200000000000000333333333333333333a98c899999aa3333a98c899999a3333a9a99a9aaa999a3335555555555533333a9a9aa99a3a99a0000000000000000
720000000000000033333333333333333a999999999aa33333a999999999a3333a999999a9999a33686686686686686333a9aa99a9aa999a0000000000000000
72000000000000003333333338c33333a99a99999999a33333a9a9999999a3333a999999a9aaa333335555555555533333a9aa9999a999a30000000000000000
7222222200000000566335663333333333a99aaaa9a99a3333a9a9aaa99a33333a99aa99aa333333333333333333333333a9a99999a9aa330000000000000000
77777777000000005663356638c333333a99a3333a9a9a33333a9a9a99a333333a9a33a9a33333333333333333333333333aaaaaaaaa33330000000000000000
16000000008595000000000000000000001600000000000000000000005000000000160000000000000000500025350000000016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
160000000000005000000000000000b0c01600005000600000859500200000000000162000000000000000000000000000002016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
160050000000000000000085950000b1c11620000000000000000000000000000000160000000000849400000000000000000016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1600000000000092a200000000000000001600000000000000000000002434150020160030000000000000000000000084940016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1620000000000093a300000000500000201600000000000000000000000000000000160000000000006000000025350000000016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16008595000000000000000000000085951600000000000050000000000060000000160000000000000000000000000000000016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1600000000000000000000000000b0c0001660000000000000000000000000000000160000243415000000000000000050000016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1600000000000000005000000000b1c1001600000000000085950000000000000000160000000000000040000000000000000016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16000090a08595000000000085950000001600005000200000000000000000000000162000005000000000000025350000002016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16005091a10000000000000000000000001600000000000000000000002000500000160000000000000000000000000000600016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16000000000000000000000000000000001600859500000060000000000000000020160060000000849400000000000000000016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16000000005000008595000000000050001620000000000000000000000000000000160000000000000000003000000000000016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
160000000000000000000000b0c00000001600000000000000000000006000000000160000000000000000000000000000000016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
160000000000000000000000b1c10000001600000000859500000000000000000000160000000040000000000050000000000016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1620000000859593a300859500000000201650000000000050000000000000000050160025350000000000600000000084940016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15000000000000000000000050000000001600000020000000000000000085950020162000000000000000000000000000002016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15000000000000000000000000000000001600000000000000000000000000000000160000000000253500000000000000000016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15859500500000000090a00085950000001660000000000000000000000060000000160000000000000000000000004000000016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15b0c000000000000091a10000000050001600000000000000208595000000000000160000300000000000008494000000500016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15b1c1000000008595000000000092a2001600000000000000000000002000005000160000000000000000000000000000000016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
150000000000000000000000000093a3a21500000000000000500000000000000000160000000050000000000000000000000016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15000000000000000000005000000000001550000000006000000000000085950000160000000000000000000000600000000016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15000085950000000000000000000000001500000000000000000000000000000020162000000000002535000000300000002016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15000000000000500000000000000000501520000000000085950050006000000000160024341500000000600000000000000016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
150000000000000000008595b0c00000001500000060000000000000000000000000160000000040000000000000000000000016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15500090a000000000000000b1c10000001500000000000000200000005000000000160000000000000000000000000084940016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15000091a10000000000000000000000001500000000000000000085950000000060160060000000008494000000000000000016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15000000008595000000500000000085951500000000000060000050000000000000160000000000000000000050000000400016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
15000000000000000000000000000000001500000050000000000000005000600000160000000000000000000000000060000016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
168595c2000092a20092a2008595b0c0201660000000859500b0c000006093a3a250162084940000000060000000000000002016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16b2c28595b0c092a2c290a0b192b190a016b2c2859590a092a2c190a092a290a0c0160000000000300000000000000000000016000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
16b3c392a2b1c193a30091a10093a391a116b3c393a391a193a39291a193a391a1c1160000005000000000000000849400000016000000000000000000000000
__label__
111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a1111111111111111111
11111111111111111111111111117111111111111111111111111111111111111111111111111111111111111111111111111111111aaa111111111111111111
1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111aa7aa11111111111111111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111aa777aa1111111111111111
1111111111111111111111111711111111111111111111111111111111111111111111111111111111111111111111111111111111aa7aa11111111111111111
11111111111111111111111111711111111111111111111111111111111111111111111111111111111111111111111111111111111aaa111111111111111111
111111111111111111111111111111711111111111111111111111111111111111111111111111111111111111111111111111111111a1111111111111111111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a1111111111111111111
1111a111111111111111111111111111111111111111111111111111111111111111111111111111171111111111111111111111111111111111111111111111
111aaa11111111111111111111111111111111111111111111111111111117111111111111111111777111111111111111111111111111111111111111111111
11aa7aa1111111111111111111111111111111111111111111111111111111111111111111111111171111111111111111111111111111111111111111111111
1aa777aa111111111111111111111111111111111111111111111711111111111111111111111111111117111111111111111111111111111111111111111111
11aa7aa1111111111111111771111111111111111111111111111111111111111111111111111111111117111111111111111111111111111111111111111111
111aaa11111111111111177777771111111111111111111111111111111111111111111111111111111177711111111111111111111111111111111111111111
1111a111111111111117777777771111111111111111111111171111111111111111111111111111111117111111111111111111111111111111111111111111
1111a111111111111117777766777111111111111111111111171111a11111111111111111111111111117111111111111111111111111111111111111111111
1111111111111111117777766667771111111111111111111171111aaa1111111111111111111111111111111111111111111111111111111111111111111111
111111111111711111777777776677711111111111111111171111aa7aa111111111111111111111111111111111111111111111111111111111111111117111
1111111111111111667776777776677611111111111111111711111aaa1111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111666667776666661111111111111111171111111a11711111111111111111111111111111111111111111111111111111111111111111111
11111111171111111166666666661111111111111111111117111111111111111111111111111111111111111111111111111111111111111111111117111111
11111111117111111111116666111111111111111111111117111111111111111111111111111111111111111111111111111111111111111111111111711111
11111111111111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111171
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111171111111111111111111111111111111111111111111111111111111111111111111111177777777111111111111111
11111111111111111111111111111111777111111111111111111111111111111111711111111111111111111111111111111111779a11a97711111111111111
111111111111111111111111111111111711111111111111111111111111111111111111111111111111111111111111111111117a99aa99a711111111111111
11111111111111111111111111111111111117111111111111111111111111111111111111111111111111111111111111111111799999999711111111111111
11111111111111111111111111111111111117111111111111111111111111111711111111111111111111111111111111111111790999909711111111111111
11111111111111111111111111111111111177711111111111111111111111111171111111111111111111111111111111111111799999999711111111111111
1111111111111111111111111111111111111711111111111111111111111111111111711111111111111111111111111111111178999999871aa11111111111
111111111111111111111111111111111111171111111111111111111111111111111111111111111111111111111111111111111776066771a99a1111111111
11111111111111111111111111111111111111111a111171111111111111111111111111111111111111111111111111111111111a98c899a1a99a1111111111
1111111111111111111111111111111111111111a7a1111a111111111111111111111111111111111111111111111111111111111a999999a11a99a111111111
11111111111111111111111111111111111111111a111111111111111111111111111111111111111111111111111111111111111a9a99a9a11a99a111111111
11111111111111111111111111111111111111111a111111111111111111111111111111111111111111111111111111111111111a9a99a9aaa999a111111111
111111111111111111111111111111111111111111111a11111111111111111111111111111111111111111111111111111111111a999999a9999a1111111111
11111111111111111111111111111111111111111111a7a1111111111111111111111111111111111111111111111111111111111a999999a9aaa11111111111
111111111111111111111111111111111111111117111a11111111111111111111111111111111111111111111111111111111111a99aa99aa11111111111111
1111111111111111111111111111111111111111a1111111111111111111111111111111111111111111111111111111111111111a9a11a9a111111111111111
111111111111a1111177771111177111117777111711117111777711177111711177771111111111117777111177771117711171117777111177771111111111
11111111111aaa111771117111777711177777711711117117711171177111711771117111111111177111711777777117711171177111711771117111111111
1111111111aa7aa11771111117771771111771111711117117711171177711711771111111171111177111711117711117771171177111111771111111111111
111111111aa777aa1177711117711171111771111711117117711711177171711177711111777111177117111117711117717171177111111177711111111111
1111111111aa7aa11117771117711171111771111711117117777111177171711117771117777711177771111117711117717171177177111117771111111111
11111111111aaa111111177117777771111771111711117117717711177117711111177111777111177177111117711117711771177111711111177111111111
111111111111a1111711177117711171111771111177771117711711177111711711177111171111177117111117711117711171177111711711177111111111
111111111111a1111177771117711171111771111177771117711771177111711177771111111111177117711777777117711171117777111177771111111111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a1111711111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a7a1111a1111111111111111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a1111111111111111111111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a1111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a7a11111111111111111
1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117111a111111111111111111
11111111111111111111171111111111111111111111111111111111111111111111111111111111111111111111111111111111a11111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111711111111111111
11111111111117111111111111111111111111111111111111111111111171111111111111111111111111111111111111111111111111117771111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111711111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111171111111111
11111111111711111111111111111111111111111111111111111111171111111111111111111111111111111111111111111111111111111111171111111111
1111111111171111a111111111111111111111111111111111111111117111111111111111111111111111111111111111111111111111111111777111111111
111111111171111aaa11111111111111111111111111111111111111111111711111111111111111111111111111111111111111111111111111171111111111
11111111171111aa7aa1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111171111111111
111111111711111aaa1111111111111111111111111111111111111111111111111111111111a111111111111111111111111111111111111111111111111111
1111111171111111a1171111111111111111111111111111111111111111111111111111111aaa11111111111111111111111111111111111111111111111111
11111111171111111111111111111111111111111111111111111111111111111111111111aa7aa1111111111111111111111111111111111111111111111111
1111111117111111111111111111111111111111111111111111111111111111111111111aa777aa111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111aa7aa1111111111111111771111111111111111111111111111111
111111111111111111111111111111111111111111111111111111111111111111111111111aaa11111111111111177777771111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111117777777771111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111117777766777111111111111111111111111111
11111111111111111111111111111111111111111177771117711111111771111771117111111111111111111177777666677711111111111111111111111111
11111111111111111111111111111111111111111771117117711111117777111771117111111111111111111177777777667771111111111111111111111111
11111111111111111111111111111111111711111771117117711111177717711771117111111111111111116677767777766776111111111111111111111111
11111111111111111111111111111111117771111771117117711111177111711177171111111111111111111666667776666661111111111111111111111111
11111111111111111111111111111111177777111777771117711111177111711117711111111111111111111166666666661111111111111111111111111111
11111111111111111111111111111111117771111771111117711111177777711117711111111111111111111111116666111111111111111111111111111111
11111111111111111111111111111111111711111771111117711111177111711117711111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111771111111777771177111711117711111111111111111111111111111111111111111111111111111111111
17111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
77711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111711111111111
17111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111711111111111111
11117771111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111171111111111111
11111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111117111111111
11111711111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111a111111111111111111111111111111777111177771111777771111771111177771111777711117777111111111111111111111111111111a111
11111111111aaa1111111111111111111111111117711171177111711711111117711711177777711777777117711171111111111111111111111111111aaa11
1111111111aa7aa11111111111111111111111111771111117711171171111111771117111177111111771111771111111111111111111111111111111aa7aa1
111111111aa777aa111111111111111111111111177111111771171117771111177111711117711111177111117771111111111111111111111111111aa777aa
1111111111aa7aa11111111111111111111111111771111117777111171111111771117111177111111771111117771111111111111111111111111111aa7aa1
11111111111aaa1111111111111111111111111117711111177177111711111117711171111771111117711111111771111111111111111111111111111aaa11
111111111111a111111111111111111111111111177111711771171117777771177117111117711111177111171117711111111111111111111111111111a111
111111111111a111111111111111111111111111111777111771177117777771111771111777777111177111117777111111111111111111111111111111a111
1111111111111111111111111111111111111111111111111111111111111111111111111a111171111111111111111111111111171111111111111111111111
111111111111111111111111111111111111111111111111111111111111111111111111a7a1111a111111111111111111111111777111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111111171111111111111111111111
1111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111111111117111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111a11111111111111111111111111111117111111111111111111
1111111111111111111111111111111111111111111111111111111111111111111111111111a7a1111111111111111111111111111177711111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111117111a11111111111111111111111111111117111111111111111111
111111111111111111111111111111111111111111111111111111111111111111111111a1111111111111111111111111111111111117111111111111111111
11111111111111111111111111111111111111111117771117111171117777111177771111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111171177117111171177777711777777111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111771117117111171111771111117711111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111771117117111171111771111117711111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111771717117111171111771111117711111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111771777117111171111771111117711111111111111111111111111111111117111111111111111111111111
11111111111111111111111111111111111111111171177111777711111771111117711111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111117771711777711177777711117711111111111111111111111111711111111111111111111111111111111
1111111aaaa111111111111117111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111aaaaaaa11111111111177711111111111111111111111117111111111111111111111111111111111111111111111111111111111111111111111117111
1111aaaaaaaaa1111111111117111111111111111111111111111111111111111111111111111111111111111111171111111111111111111111111111111111
111aaaaaaaaaaa111111111111111711111111111111111111111111111111111111111111111111111111111111171111a11111111111111111111111111111
111aaaaa1111aa11111111111111171111111111111111111711111111111111111111111111111111111111111171111aaa1111111111111111111117111111
11aaaaa11111111111111111111177711111111111111111117111111111111111111111111111111111111111171111aa7aa111111111111111111111711111
11aaaa1111111111111111111111171111111111111111111111117111111111111111111111111111111111111711111aaa1111111111111111111111111171
11aaaa11111111111111111111111711111111111111111111111111111111111111111111111111111111111171111111a11711111111111111111111111111
11aaaa111111111111111111111111111111111111111111111111111111a1111111111111111111111111111117111111111111111111111111111111111111
11aaaa11111111a11111111111111111111111111111111111111111111aaa111111111111117111111111111117111111111111111111111111111111111111
11aaaaa111111aa1111111111111111111111111111111111111111111aa7aa11111111111111111111111111111111111111111111111111111111111111111
111aaaaa1111aaa111111111111111111111111111111111111111111aa777aa1111111111111111111111111111111111111111111111111111111111111111
111aaaaaaaaaaa11111111111111111111111111111111111111111111aa7aa11111111117111111111111111111111111111111111111111111111111111111
1111aaaaaaaaaa111111111111111111111111111111111111111111111aaa111111111111711111111111111111111111111111111111111111111111111111
11111aaaaaaaa11111111111111111111111111111111111111111111111a1111111111111111171111111111111111111111111111111111111111111111111
1111111a1111111111111111111111111111111111111111111111111111a1111111111111111111111111111111111111111111111111111111111111111111

__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002222000000000202000000000000002002020000000002020000000000000001000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
6100000500000000000000000000000005610500000005000000000000000000050061050000040000000000000000000003006100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005000000000000000000030000
6100000000585900000500000058590000610002000000000500000002000000000061000000000000424351000600000000006100000000000000000000000000000000292a0000000000050000000000000000000400000300000400000000000000000000000000000000000000000300090a000000000000060000000000
6100000000000000000000000000292a00610000000000000000000000060000000461000600000000000000000000000000006100000000000000000000000000000000393a00000b0c0000090a000000000000050000000000000005000000000000000000000000000000000000000005191a000000000000000000000005
6158590000050000000000000000393a00610600000000000600004243510000050061000000000000000000000048490000006100000000000000000000000000090a00000000001b1c0000191a0000000000050000000000000000000500000000000000000000000000000000000000000000060000000500000000686900
6100000000000000005859000500000000610000000005000000000000000000000061000000000000050000000000000000006100000000000000000000000000191a002b2c00000000000000000000000005000006000000000006000005000000000000000000000000000000000000000000000400000000000000787900
6102000b0c0000000000000000000000026102000000000000000500000000000002610200000006000000000000000000000261000000000000000000000000000000003b3c00000000000500050000000500000000000000000000000000050000000000000000000000000000000000033231303436103202363310073200
6100001b1c000000000500000000000000610000000000000000585900020000000661000000000000000052530004000000006100000000000000000000000000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000040000
610000000058590000000000000000000061000500000000000000000000000500006100000000000000000000000000000600610000000000000000000000000000000000000000000000000000000000000000000000000000004e4f0000000000000000000000000000000000000000000000000000050000000000000600
610000000000000000000000000000050061000000020000000005000600000000006100000300000000000000000000000000610000000000000000000000000000000000000000000000000000000000000000000000000000005e5f000000000000000000000000000000000000000000000000000000000300090a000000
610000000500000000000058590000000061060000000042435100000000585900006100000000000000000000000000000000610000000000000000000000000000005859000000000000585900000000000042430000000000004243000005000000000000000000000000000000000000000000082d31200000191a000000
6100000000000000000000000000000000610000000000000000000000000000060061000000000042435100000000050000006100000000000000000000000000050000000000050000000000050000000500000000050005000000000500000000000000000000000000000000000006000000000000000000000000000500
61000000000000000000292a0000000000610000000000000000000200000000000061000000060000000004000000000000006100000000000000000000000000000000050000000005000500000005000000000500000005000005000000050000000000000000000000000000000000030000000f36373833303200000003
61020000000000000000393a00000000026102000000000000000000000000000002610200000000000000000000000006000261000000000000000000000000402e2e2e2e2e2e2e2e2e2e2e2e2e2e1f402e2e2e2e2e2e2e2e2e2e2e2e2e2e1f0000000000000000000000000000000000000000000000000004000000060000
6100000000000000585900000500000000610500000000000000000000000000000061000000000000000000525300000000006100000000000000000000000050010101010101010101010101010160500101010101010101010101010101600000000000000000000000000000000000000000003534333000000000000000
610000000000000000000000000058590061000000000002585906000000000000006100000500000000000000000000000000610000000000000000000000005001010101010101010101010101016050010101010101010101010101010160000000000000000000000000000000000d0e0006000005000000000000000005
6100000000000500000000000000000b0c6100424351000000000000424351000000610000000000000000000000030000000061000000000000000000000000703e3e3e3e3e3e3e3e3e3e3e0101012f703e3e3e3e3e3e3e3e3e3e3e0101012f000000000000000000000000000000001d1e0000000000030005000000000000
6100585900090a00000000000000001b1c610000000600000000000000000000000061000000005253000000000000000000006100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6100000000191a00000000000000000000610000000000000000000000000500000061000600000000000000000000000005006100000000000000000000000000000000000000000000040000000000000000000000000000000500000000050000000000000000000000000000000000000000000000000000000000000000
6100000000000000000058590000000000610000000000585900000200000000000061000000000004000000000000000000006100000000000000000000000000000600000000000000000000000000000000000000000000060000040000000000000000000000000000000000000000000000000000000000000000000000
6100000000000000000000000000585900610000000000000005000000000000000261020000000000000000484900000000026100000000000000000000000000000000000400000500000000000000000000000000000000000006000000050000000000000000000000000000000000000000000000000000000000000000
6102000000000000000000000500000000610600000002000000000000000000060061000048490000000600000000000000006100000000000000000000000000060000000000000000000500030000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000
610000000058590000090a000000000002610200000000000000585900000000000061000000000000000000000000000000006100000000000000000000000000000000000000000000000000000000000000000000000000060000000500050000000000000000000000000000000000000000000000000000000000000000
610000050000000000191a000000000000610000000000000200000000000000000061000000000000000000050000000000006100000000000000000000000000000005000000000003000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000000000000000
6100000000000000000000005859000000610000000000000000000000000000000061000500000000000000000400004243516100000000000000000000000005000000000000000000000000000500000000000000000000060000050000050000000000000000000000000000000000000000000000000000000000000000
6100000000000000000000000000090a00610200000058590000000000000000000061000000000052530000000000000000006100000000000000000000000000030000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000
6158590000000000000000050000191a00610000000000000000000000000000000261000000000000000000000000000000006100000000000000000000000000000052530000000000005253000000000000000000000000000000004445000000000000000000000000000000000000000000000000000000000000000000
6100000000000b0c000000000000000000610000000000000000000006000000000061020000000400000000000000000300026100000000000000000000000000050000000000060000000000000600000000000000000000000500005455000000000000000000000000000000000000000000000000000000000000000000
6105005859001b1c000000000000000000610058590000000000000000004243510061004849000000000048490000000000006100000000000000000000000000000000000000000500000000000000000000000000000004000000000000040000000000000000000000000000000000000000000000000000000000000000
61000000000000005859000000000005006100000002000000000000000000000000610000000000000600000000000000000061000000000000000000000000402e2e2e2e2e2e2e2e2e2e2e2e2e2e1f402e2e2e2e2e2e2e2e2e2e2e2e2e2e1f0000000000000000000000000000000000000000000000000000000000000000
6100000000050000000000000000000000610500000000000000000000000200000061000000000000000000000000000500006100000000000000000000000050010101010101010101010101010160500101010101010101010101010101600000000000000000000000000000000000000000000000000000000000000000
610000090a000000000000000000585900610000000000585900000000000000000061000600525300000000000000000000006100000000000000000000000050010101010101010101010101010160500101010101010101010101010101600000000000000000000000000000000000000000000000000000000000000000
610000191a0000000000000500000000006100000000000000000600000000000000610000000000000004000000000000000061000000000000000000000000703e3e3e3e3e3e3e3e3e3e3e0101012f703e3e3e3e3e3e3e3e3e3e3e0101012f0000000000000000000000000000000000000000000000000000000000000000
__sfx__
010200000e150111501315013150101500d1500a1500a1500b1500c1500e15010150111500d1500a1500b1500d1500e1500f1500a150081500a1500d1500e150101500a1500a1500b1500d1500f150101500e150
000200002d0503005034050380503a0503d0501915022150261502a15032150361503a150332502e25029250222502d350303503335026450224501b450265502b5502f55023750207501e750147501075000000
00060020129560c9560b9560c956119560a9560a956089560a95605956099560c9560a9560995612956129560b9560995609956079560b95606956099560d956099560b95609956089560a956129560895609956
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000298702c8702e8702f87030870308702d8702a87025870218701d87016870108700b87007870008700f800078000580000800008000080000800008000080000800008000080000800008000080000800
000600001f05524055000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
000300001f0501f0501f0001f0001f00011600366003a600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
160600000a0500c0500f050130501b0501f05022050270502e050350503a0503f05033000310003f0000080000800008000080000800008000080000800008000080000800008000080000800008000080000800
000200003c6503b650396503665033650306502b65023650196501065006650006500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
541000200061000611006110161102611036110462105621066310763108631096410a6510a6510a6510966108661076610566104651036410263102631016310062100621006210061100611006110061100610
040300001265614656196561f65621656296562b6562d6562a65627656246561e65616656106560a6560765601655106060c60607606046060000600006000060000600006000060000600006000060000600006
28050000225501e5501b55017550135500d5500455003500005000050005500005000350002500005000250000500005000150001500005000050000500005000050003500005000150000500005000050000500
2808000022550275502b55027550335503a5503f5503f5003f5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060020107501075110751107511075110751117511375114751177511a7511e7512075125751297512b7512c7512a75126751217511f7511a75117751147511175110751107511075110751107511075110751
040300003b7553a7503a751387513875136751357513475132751307512e7512d751297512775123751217511e7511c751197511675113751107510d7510a75107751037510075118701117010c7010870104701
000800002b65628656296562b6562c6562d6563165636656000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006
5704000036621366213762134621346212d62126621186210f6210c6210a621096210762106621046210362101621006210760106601056010460103601026010060100601000010000100001000010000100001
00060000240551f055000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
4e0a0000129560c9560b9560c956119560a9560a956089560a95605956099560c9560a9560995612956129560b9560995609956079560b95606956099560d956099560b95609956089560a956129560895609956
000800200295005950059500695006950059500495004950059500495005950089500595005950089500295003950099500495007950039500395006950049500495006950049500495006950039500595005950
002700000015000150001500015000150001500015000150001500015000150001500015000150001500015000150001500015000100001000010000100001000010000100001000010000100001000010000100
be050000181351c1351f1352413500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105
bf060000181551c1551f1551c1551f155241550010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105001050010500105
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f02000013051180511b0511f05124051270512b05100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001
5d04000036631366313763134631346312d63126631186310f6310c6310a631096310763106631046310363101631006310760106601056010460103601026010060100601000010000100001000010000100001
6903000014550125501155010550115501355016550185501c550235502a5502e550375003f500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000c00000162200615000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
492100000007200072000720007200072000720207204072040720407204072040720407205072040720007202072020720207202072020720207202072040720507204072000720207207072070720507205072
d32100003c515375153551534515355153451535515375153c515375153551534515355153451535515375153c515375153551534515355153451535515375153c51537515355153451535515345153551537515
4921000000052000520005200052000520005202052040520405204052040520405218022130520c052070520a0520a0520a0520a0520a0520a0520a052040520505204052000520705205052050520405204052
d70b001e2b71428714247142b71428714247142b71428714247142b71428714247142b71428714247142b71428714247142b71428714247142b71428714247142b71428714247142b71428714247140070400700
8e3300200001000011000210003100031000410005100051000510006100071000710007100071000710007100071000710007100071000610006100051000510004100041000310002100021000110001100016
d72c00003000030004300003000030000240003000024000300443000430034300003002424000300142405424000240442400024034240002402424000240142b0002c0002b0002c0002b0002b0001f00000000
49210000000520005200052000520005202052000520205204052040520405204052040520005204052070520c0520805205052000520c052080520505200052080520505201052080520a05205052020520a052
d32100003c515375153551534515355153451535515375153c515375153551534515355153451535515375153c515385153751535515375153551537515385153d51538515355153151533515315153351535515
d32100003c515375153551534515355153451535515375153c515375153551534515355153451535515375153a515355153451532515345153251534515355153c51537515355153451535515345153551537515
492100000077300703007030077300655007030070300773007730070300773007030065500703007030070300773007030070300773006550070300703007730077300703007730070300655007030070300703
492100000055200555005002150000555005550255504552045550450004500045000455505555045550055202552025550250002500025000250002500045550555504555005550255507552075550555205555
c911001e2b71428714247142b71428714247142b71428714247142b71428714247142b71428714247142b71428714247142b71428714247142b71428714247142b71428714247142b71428714247140070500700
4921000000552005550050500505005520055502555045520455504500045000450018525135550c555075550a5520a5550a5000a5000a5000a5000a500045550555504555005550755505552055550455204555
__music__
01 64212320
00 64232822
00 64212320
02 69272326
00 41424360
00 41424366
00 41424367
00 41424360
03 41242b44
00 41646b44
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 4124292a
02 4124292c
00 4142436c
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 41242123
02 41242823
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
03 64612324
01 64236822
00 64612320
02 69672326
00 41424344
00 41424344
00 41424344
00 41424344
01 64212329
00 64232829
00 64212329
02 69272329
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 29212320
00 29232822
00 29212320
02 29272326
00 41424344
00 41424344
00 41646569
03 64246129


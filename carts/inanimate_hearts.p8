pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

-- inanimate hearts
--global variables
player = {}
player.x = 15
player.y = 35
player.sprite = 64
player.solid = false
player.flip = false
player.timer = 0
scenery = 0
scene = {}
scene.active = 0
scene.update = {}
scene.draw = {}
points = {}
overworld_playing = false
dialogue_playing = false
title_playing = false
track_4_playing = false
track_5_playing = false
tiletype=0
choice = true
choice_1 = false
choice_2 = false
next_scene = 0
time =0
scene_end = false
counter = 0
b_flag = 0
b_scene = 1
f_flag = 0
f_scene = 1
l_flag = 0
l_scene = 1
boss_flag=0
sprite_timer=0
sprite_color=248
clock_timer = 0
clock_number = 234
title_playing = false

function _init()
 cam={
  x=0,
  y=0
 }
camera_x = 0
camera_y = 0
j = 1
end

function dtb_init(numlines)
	dtb_queu={}
	dtb_queuf={}
	dtb_numlines=5
	if numlines then
		dtb_numlines=numlines
	end
	_dtb_clean()
end

-- this will add a piece of text to the queu. the queu is processed automatically.
function dtb_disp(txt,callback)
	local lines={}
	local currline=""
	local curword=""
	local curchar=""
	local upt=function()
		if #curword+#currline>29 then
			add(lines,currline)
			currline=""
		end
		currline=currline..curword
		curword=""
	end
	for i=1,#txt do
		curchar=sub(txt,i,i)
		curword=curword..curchar
		if curchar==" " then
			upt()
		elseif #curword>28 then
			curword=curword.."-"
			upt()
		end
	end
	upt()
	if currline~="" then
		add(lines,currline)
	end
	add(dtb_queu,lines)
	if callback==nil then
		callback=0
	end
	add(dtb_queuf,callback)
end

-- functions with an underscore prefix are ment for internal use, don't worry about them.
function _dtb_clean()
	dtb_dislines={}
	for i=1,dtb_numlines do
		add(dtb_dislines,"")
	end
	dtb_curline=0
	dtb_ltime=0
end
function _dtb_nextline()
	dtb_curline+=1
	for i=1,#dtb_dislines-1 do
		dtb_dislines[i]=dtb_dislines[i+1]
	end
	dtb_dislines[#dtb_dislines]=""
	--sfx(2)
end
function _dtb_nexttext()
	if dtb_queuf[1]~=0 then
		dtb_queuf[1]()
	end
	del(dtb_queuf,dtb_queuf[1])
	del(dtb_queu,dtb_queu[1])
	_dtb_clean()
	--sfx(2)
end

-- make sure that this function is called each update.
function dtb_update()
	if #dtb_queu>0 then
		if dtb_curline==0 then
			dtb_curline=1
		end
		local dislineslength=#dtb_dislines
		local curlines=dtb_queu[1]
		local curlinelength=#dtb_dislines[dislineslength]
		local complete=curlinelength>=#curlines[dtb_curline]
		if complete and dtb_curline>=#curlines then
		 if btnp(4) then
				_dtb_nexttext()
				return
		 end
		elseif dtb_curline>0 then
			dtb_ltime-=1
			if not complete then
				if dtb_ltime<=0 then
					local curchari=curlinelength+1
					local curchar=sub(curlines[dtb_curline],curchari,curchari)
					dtb_ltime=1
					if curchar~=" " then
						--sfx(0)
					end
					if curchar=="." then
						dtb_ltime=6
					end
					dtb_dislines[dislineslength]=dtb_dislines[dislineslength]..curchar
				end
				--if btnp(4) then
					dtb_dislines[dislineslength]=curlines[dtb_curline]
			--	end
			else
				--if btnp(4) then
					_dtb_nextline()
				--end
			end
		end
	end
end
-- make sure to call this function everytime you draw.

function dtb_draw()
	if #dtb_queu>0 then
		local dislineslength=#dtb_dislines
		local offset=0
		if dtb_curline<dislineslength then
			offset=dislineslength-dtb_curline
		end
 --   if options == true then
		rectfill(2,125-dislineslength*8,125,125,0)
--    rectfill(55,125,)
		if dtb_curline>0 and #dtb_dislines[#dtb_dislines]==#dtb_queu[1][dtb_curline] then
			print("\x8e",118,120,1)
		end
		for i=1,dislineslength do
			print(dtb_dislines[i],4,i*8+119-(dislineslength+offset)*8,7)
		end
	end
end

function update_music()
    --title music
    if scenery < 1 and not
    title_playing then
    	music(22)
    	title_playing = true
    end

    --overworld music
    if not overworld_playing and not dialogue_playing and not track_3_playing and not track_4_playing and not track_5_playing then
     music(0)
     overworld_playing = true
    end

    --dialogue music
    --if scene.active > 0 and
    --not dialog_playing then
    	--overworld_playing = false
    	--dialogue_playing = true
    	--music(8)
    --end

    --sfx to play when you collide with an object
    --if scene.active == 4 then
    	--music(-1) --clears music playing
    	--sfx(5)
    --end

end

function camera_reset()
  cam.x=0
  cam.y=0
end
-- choice is a three digit number(xyz) that indicates
-- x = scene number
-- y = option number
-- z = choice to choose (1 or 2)
function go_to_map()
  if (btn(5)) then
    scene.active = 0
  end
  if scene_end == true then
    scene.active = 0
  end
end

scene.cycle = function()
	if scene.active < 3 then
		scene.active += 1
	else
		scene.active = 0
	end
end

scene.reset = function()
	scene.active = 0
end

scene.updates = function()
	if scene.update[scene.active] != nil then
		scene.update[scene.active]()
	end
end

scene.drawing = function()
	if scene.draw[scene.active] != nil then
		scene.draw[scene.active]()
	end
end

function scene_updates(param)
-- bookcase
  if param == 1 then
    if b_scene < 3 then
      if (btnp(5)) then
        b_scene += 1
      --  b_flag = 0
        scene.active = 0
      end
    --  scene.active = 0
    else
      if (btnp(5)) then
        if b_flag == 8 then
          scene.active = 5
        end
      end
          b_scene = 3
    end
  elseif param == 2 then
    if l_scene < 3 then
      if (btnp(5)) then
        l_scene += 1
      --  b_flag = 0
        scene.active = 0
      end
    --  scene.active = 0
    else
      if (btnp(5)) then
        if l_flag == 8 then
          scene.active = 5
        end
      end
      l_scene = 3
    end
  elseif param == 3 then
  end

end
-- map scene
scene.update[0] = function()
	input()
  local screenshakes = 0
  if(clock_timer<500) then
      clock_timer +=1
    if clock_timer<150 then
      clock_number =234
    elseif clock_timer <250 then
      clock_number = 202
    elseif clock_timer <450 then
      clock_number = 204
      screenshakes = 1
    end
  end
  camera(cam.x,cam.y)
  update_music()
  if screenshakes == 1 then
    --screenshake()
  end
end

scene.draw[0] = function()
	map(0,0,0,0)
  --debug_info()
  spr(clock_number,8,8,2,2)
  spr(player.sprite, player.x, player.y, 2, 2,player.flip)
  --print('press \x97 to go back to main menu',10,66,9)
  --camera(cam.x,cam.y)
end

function reset_choices()
	choice_1 = false
	choice_2 = false
end

function diag_input()
	if btnp(2) then
		choice_1 = true
		choice_2 = false
	elseif btnp(3) then
		choice_2 = true
		choice_1 = false
	end
end

-- scene bookcase
function bookcase_dialogue()
  --  diag_input()
  if btn(2) then
    choice_1 = true
    choice_2 = false
  elseif btn(3) then
    choice_1 = false
    choice_2 = true
  end
  if b_scene == 1 then
    if b_flag == 0 then
      dtb_disp("player: hmm… what is this big thing doing here?")
      dtb_disp("chesterfield: excuse me? i am not simply a 'big thing' as you so crudely put it. i am a creature of class, of decadence! my name is chesterfield and it will do you good to remember it!")
      dtb_disp("player: …haha. talking bookcase. very funny…haha.")
      dtb_disp("are you all right my dear human? you seem to be acting quite peculiar.")
      dtb_disp("1a: haha the funny furniture is speaking. i need something to drink.")
      dtb_disp("1b: this all must be from a lack of sleep. still…maybe i should just roll with it. could be interesting.")
      b_flag =1
    elseif b_flag == 1 then
      if choice_1 == true then
        dtb_disp("player: please excuse me while i go find some coffee.")
        dtb_disp("chesterfield: coffee? i much rather prefer tea myself. i find it gives a healthier wood stain glow.")
        b_flag = 2
      elseif choice_2 == true then
        dtb_disp("player: i think im ok, just a little caught off guard.")
        dtb_disp("chesterfield: well if you say so. i do hope i did not startle you too much.")
        b_flag = 2
      end
    elseif b_flag ==2 then
      dtb_disp("player: by the way, arent chesterfields what they call couches up in canada?")
      dtb_disp("chesterfield: hm? oh, it is an old family name. you see, we come descended from the estate of the great earl chesterfield himself!")
      dtb_disp("player: uhh, i see.")
      dtb_disp("chesterfield: but now that you have mentioned it. i do have a distant canadian relative who is a couch. could people possibly be getting us confused? how dreadful!")
      dtb_disp("2a: whats wrong with couches?2b: i dont think anyone would confuse you for a couch.")
      if choice_1 == true then
        dtb_disp("chesterfield: oh, nothing of course. it is just well, they are meant to be sat on. while i hold up the timeless works of the cultured past, they merely hold up possibly soiled rears.")
        dtb_disp("player: well, i suppose that is one way of looking at it.")
        b_flag = 3
      elseif choice_2 == true then
        dtb_disp("chesterfield: oh, thank heavens. that last thing i need is that futon fellow thinking we were long lost cousins.")
        b_flag = 3
      end
      --scene_updates(1)
      --b_scene == 2
    end
    scene_updates(1)
  elseif b_scene == 2 then
  if b_flag == 3 then
      dtb_disp("chesterfield: hello friend, have you acclimated to your new work environment?")
      --printc(sub(text,1,frame),1,1)
      dtb_disp("1): yeah, i wasn't sure i would, but this all seems kind of like a dream come true for me.")
      dtb_disp("2): are you kidding me?! i'm still not convinced i'm not living through some sort of nightmare.")
      b_flag = 4
  elseif b_flag == 4 then
    if choice_1 == true then
        dtb_disp("chesterfield: oh? i can't say i've met many humans who wanted to talk to us furnishings.")
        dtb_disp("player: i don't think it's something many humans think about.")
        dtb_disp("chesterfield: i take it you're not like most humans then.")
        --reset_choices()
        counter += 1
        b_flag = 5
    elseif choice_2 == true then
        dtb_disp("chesterfield: i can assure you that you're very much awake.")
        dtb_disp("player: really? then maybe i just have some screws loose.")
        dtb_disp("chesterfield: l-l-loose screws? do your base boards feel unsteady? do you feel like you might come apart at any second? this is a very serious condition.")
        dtb_disp("player: err, i think i'll be okay.")
        --reset_choices()
        counter += 1
        b_flag = 5
    end
  elseif (b_flag == 5) then
    choice_1 = false
    choice_2 = false
    dtb_disp("chesterfield: well regardless, i hope we'll see more of you in the days to come.")
    dtb_disp("chesterfield: tell me friend, how do you pass the time?")
    dtb_disp("1): i usually like to settle in with a good book.")
    dtb_disp("2): yo man, i go nuts at those weekend ragers.")
    counter += 1
    b_flag = 6
  elseif (b_flag ==6) then
    --diag_input()
    if choice_1 == true then
      dtb_disp("chesterfield: ah, i see you're a connoisseur of the fine arts as well.")
      dtb_disp("chesterfield:  that can't be said for most of the other residents here. i swear, those woodchips-for-brains wouldn't know a good book if it scuffed at their veneer.")
      --scene_end = true
      counter += 1
      reset_choices()
      b_flag = 7
    elseif choice_2 == true then
      dtb_disp("chesterfield: oh! how detestable! you're no better than that deranged lamp. and here i thought you'd be different.")
      --scene_end = true
      counter += 1
      reset_choices()
      b_flag = 7
    end
  --else
  --  dtb_display"thanks.. press x to exit...")
  end
  scene_updates(1)
  elseif b_scene == 3 then
    if (b_flag == 7) then
    dtb_disp("hey, now you have locked yourself in this conversation. let's see where you are able to take this conversation. to a good end or a bad one. so choose wizely")
    dtb_disp("chesterfield: hello again my friend! i am glad to see you have decided to stick around.")
    dtb_disp("player: well chesterfield, i think bonding over our mutual love of literature will help make these long nights go by more easily")
    dtb_disp("chesterfield: an excellent suggestion! you do not know how long i have waited to have an enlightened conversation with someone that was not going on about mass produced drivel.")
    dtb_disp("chesterfield: so, what have you been reading lately?")
    dtb_disp("1a: harry hardwood and the sappy surprise")
    dtb_disp("1b: the jokes on those gum wrappers i found on the bus.")
    if choice_1 == true then
    dtb_disp("chesterfield: you read harry hardwood? i love harry hardwood! did not the part where oakdore dies just leave you speechless? i must have read that part at least 20 times!")
    dtb_disp("player: …")
    dtb_disp("chesterfield: …ahem. i-i am sorry you had to see that. i assure you i am usually much more composed than that.")
    dtb_disp("player: oh, dont be ashamed. i understand perfectly well how excited people can get over harry hardwood.")
    dtb_disp("chesterfield: i-i am glad i got to meet a fellow fan.")
    b_flag = 8
  elseif choice_2 == true then
    dtb_disp("chesterfield: excuse me, but… did you say gum wrappers?")
    dtb_disp("player: yeah! someone left them on the bus. boy, i bet they sure do feel silly for leaving them behind!")
    dtb_disp("chesterfield: hmm. yes, quite silly.")
    dtb_disp("player: hey, check this one out! what did the bar stool say after being thrown out of the bar?")
    dtb_disp("chesterfield: …i must go.")
    dtb_disp("player: wait! it said, 'i couldnt chair less!''")
    b_flag =8
  end
  end
end
end
scene.update[1] = function()
  --music(3)
  camera(0,0)
  dtb_update()
  diag_input()
  --counter+=1
  if b_flag == 2 then
    choice_1 = false
    chocie_2 = false
  end
  bookcase_dialogue()
  --debug_info()
  --dtb_init()
  -- add text to the queu, this can be done at any point in time.
end
scene.draw[1] = function()
	--rectfill(0,0,128,128,0)
  for j = 0,127,16 do
    for i = 0,127,16 do
      	spr(192,i,j,2,2)
    end
  end
  spr(128, 10, 40, 4, 4)
    rectfill(50,20,124,65,0)
    debug_info()
  print('press \x97 to go back to main menu',0,10,5)
	dtb_draw()
end

-- scene lamp
function lamp_dialogue()
  if btn(2) then
    choice_1 = true
    choice_2 = false
  elseif btn(3) then
    choice_1 = false
    choice_2 = true
  end
 if l_scene == 1 then
   if l_flag == 0 then
     dtb_disp("player: let me just… find the switch…")
     dtb_disp("joules: hey, now! at least buy me a shot first!")
     dtb_disp("player: woah! is this some kind of siri-lamp-combination? are you a voice-activated lamp-bot or something?")
     dtb_disp("joules: uh, not so much, no.")
     dtb_disp("1a what the hell! siri would never respond with that kind of attitude! how are you talking to me?")
     dtb_disp("1b  damn, i was really hoping to get a kind of scarlet johansson in her thing going…")
     l_flag = 1
   elseif l_flag == 1 then
     if choice_1 == true then
       dtb_disp("joules: thats such a boring question! lets get to the interesting stuff: did you see next years electric daisy carnival line-up?")
       dtb_disp("player: yes, it looks awesome and i got my tickets last week, but, please! enlighten me! how are you talking?")
       dtb_disp("joules: enough with the lame q and a! do you have a spare ticket? they sold out in a total flash!")
       dtb_disp("player: maaaybe…")
       l_flag = 2
     elseif choice_2 == true then
       dtb_disp("joules: well, thats not totally off the table… i have been told ive got scar jos legs! well, leg")
       dtb_disp("player: you know, i can kind of see the resemblance…")
       l_flag = 2
     end
   elseif l_flag == 2 then
     dtb_disp("joules: im joules! not that you asked, which is totally rude, by the way. who are you? whats with the uniform?")
     dtb_disp("player: oh, sorry! im the new security guard!")
     dtb_disp("joules: ugh, security guard? so are you, like, a stickler for the rules and stuff?")
     dtb_disp("2a i mean, i do like to follow rules...")
     dtb_disp("2b i like to think of them less as rules and more as guidelines, ya know?")
     l_flag = 3
   elseif l_flag == 3 then
     if choice_1 == true then
       dtb_disp("joules: oh, come on! rules are there to be broken! live a little!")
       dtb_disp("player: i think, technically speaking, rules are there to be followed…")
       dtb_disp("joules: ugh! boring")
       l_flag = 4
     elseif choice_2 == true then
       dtb_disp("joules: thats what i like to hear! im super into your energy!")
       dtb_disp("player: honestly, i really feel like we are vibing!")
       dtb_disp("joules: we are! totes on the same wavelength!")
       l_flag = 4
     end
     dtb_disp("joules: oo! new notification! my favorite edm producer just started a livestream! i cannot miss this - hes doing a giveaway! ttyl!")
   end
   scene_updates(2)
 elseif l_scene == 2 then
  if l_flag == 4 then
    dtb_disp("l: omg you're back! so, did you meet some of the other furniture? total bores, right?")
    dtb_disp("1): they're all totally lame!")
    dtb_disp("2): i don't know, i thought they were pretty nice...")
    --diag_input()
    l_flag = 5
  elseif l_flag == 5 then
    if choice_1 == true then
  	   dtb_disp("l: finally, somebody who agrees with me! the guy who had your job before you was all buddy-buddy with them and kept trying to shut down my parties because they were ��\"too lit\"�� - as if that's even possible.")
  	   dtb_disp("player: what? that's wild! i would never get in the way of somebody gettin turnt! rule #1 of being cool is never shut down a sick party!")
  	   dtb_disp("l: exactly! killing the vibe like that is way more of a crime that �\"repeated noise violations,\"� if you ask me!")
       l_flag = 6
      reset_choices()
    elseif choice_2 == true then
		   dtb_disp("l: seriously? they're so lame! they totally don't know how to party.")
		   dtb_disp("player: partying's not that important...")
		   dtb_disp("l: um, excuse me? name just one thing that's more important than partying! i'll wait!")
		   dtb_disp("player: oxygen's pretty important.")
		   dtb_disp("l: for you, maybe! dubstep's my oxygen! but also i don't need to breathe.")
       l_flag = 6
       reset_choices()
    end
  elseif l_flag == 6 then
         dtb_disp("l: oh, by the way, did i mention? there's a rave tonight! you should totes come!")
		      --reset_choices()
		     dtb_disp("1): sick! i never pass up a chance to party!")
		     dtb_disp("2): i don't know, raves aren't really my cup of tea...")
         l_flag = 7
       elseif l_flag == 7 then
		     if choice_1 == true then
			         dtb_disp("l: oh my god yaaaas! we are so in sync! i live for parties! raves, festivals, discos - as long as there's dancing and hella people, i'm down!")
			         dtb_disp("player: me, too! and when the dancefloor is crowded, nobody can tell i've got two left feet!")
			         dtb_disp("l: lucky! i've just got the one!")
               l_flag = 8
               reset_choices()
         elseif choice_2 == true then
			         dtb_disp("l: ugh, are you for real? don't tell me you're some boring normie or something.")
			         dtb_disp("player: i'm not boring!")
			         dtb_disp("l: if you weren't boring, you'd be going to the rave tonight")
			         dtb_disp("i'll think about it...")
               l_flag = 8
               reset_choices()
	        end
     end
     scene_updates(2)
   elseif l_scene == 3 then
   end
 end
scene.update[2] = function()
  dtb_update()
  camera(0,0)
  --diag_input()
  --debug_info()
  lamp_dialogue()
	--camera_reset()
end
scene.draw[2] = function()
  for j = 0,127,16 do
    for i = 0,127,16 do
       spr(224,i,j,2,2)
    end
  end

  spr(132, 10, 20,4,4)
    rectfill(50,20,124,65,0)
      debug_info()
	--print('scene lamp!',40,60,9)
  print('press \x97 to go back to the map',0,10,15)
  dtb_draw()
end

function futon_dialogue()
  diag_input()
  if f_flag == 0 then
  dtb_disp("sawyer futon: woaaaaah there dude. watch where you're planting that thing.")
  dtb_disp("1): oh great, a talking couch. what's next? a footrest that barks?")
  dtb_disp("2): ah! where are you all coming from?!")
  if choice_1 == true then
    dtb_disp("sawyer: dude. i'm not a couch.")
  	dtb_disp("player: great, the couch is having an existential crisis.")
  	dtb_disp("sawyer: ...")
  	dtb_disp("the name's sawyer, sawyer futon.")
  	dtb_disp("player: futon? isn't that a type of couch?")
  	dtb_disp("sawyer: ...")
  	dtb_disp("dude. you're saying it wrong. it's futon, like fut-ton")
  	dtb_disp("player: ...")
    f_flag = 1
    reset_choices()
  elseif choice_2 == true then
  	  dtb_disp("sawyer: woah woah woah bro relaaaaaax. you look like you've seen a ghost!")
  	  dtb_disp("player: ...")
  	  dtb_disp("i'm going insane")
  	  dtb_disp("sawyer: you really look like you need some r&r dude.")
  	  dtb_disp("player: i'm getting a psych eval...from a talking couch...")
  	  dtb_disp("sawyer: futon dude. sawyer futon.")
      f_flag = 1
      reset_choices()
    end
  end
end
-- scene futon
scene.update[3] = function()
  dtb_update()
  camera(0,0)
  --reset_choices()
  futon_dialogue()
  --camera_reset()
end

scene.draw[3] = function()

  for j = 0,127,16 do
    for i = 0,127,16 do
       spr(194,i,j,2,2)
    end
  end
  spr(136, 10, 40, 4, 4)
    rectfill(50,20,124,65,0)
      debug_info()
	--print('scene futon!',40,60,9)
  dtb_draw()
end

scene.update[4] = function()
  --screenshake()
  if(btn(4)) then
    if (next_scene == 1) then
      scene.active = 1
    elseif(next_scene ==2) then
      scene.active = 2
    elseif(next_scene == 3) then
      scene.active = 3
    end
  end
  if (btn(5)) then
    scene.active = 0
  end
end

scene.draw[4] = function()
  map(0,0,0,0)
  spr(player.sprite,player.x,player.y,2,2)
  if next_scene == 1 then
    if cam.y <15 then
      rectfill(cam.x+150,85,cam.y,145,0)
      spr(54,77,103)
      print("press z to talk",cam.x,95,15)
      print("press x to go to map",cam.x,105,15)
    else
      rectfill(cam.x+150,125,cam.y,165,0)
      spr(54,164,80)
    --print('press \x97 to go back to the map',0,10,15)
      print("press z to talk",cam.x,135,15)
      print("press x to go to map",cam.x,145,15)
    end
  elseif next_scene == 2 then
    rectfill(cam.x+150,100,cam.y,130,0)
    spr(54,200,0)
    print("press z to talk",cam.x,105,15)
    print("press x to go to map",cam.x,115,15)
  elseif next_scene == 3 then
    rectfill(cam.x+150,100,cam.y,130,0)
    spr(54,298,18)
    print("press z to talk",cam.x,105,15)
    print("press x to go to map",cam.x,115,15)
  end
  camera(cam.x,cam.y)
end

-- bookcase options
scene.update[5] = function()

end
scene.draw[5] = function()
  rectfill(0,0,0,0)
  map(60,4,40,60,16,16)
end

-- lamp options
scene.update[6] = function()
end
scene.draw[6] = function()
end

-- futon options
scene.update[7] = function()
end
scene.draw[7] = function()
end
function select_an_option()
  curr_option_flag = 1
end
function printing_choice()
  if curr_option_flag == 1 then
    print("you need to choose an option:-",10,20,9)
    curr_option_flag = 0
  end
end
scene.update[8] = function()
  dtb_update()
  diag_input()
  camera(0,0)
  if boss_flag == 0 then
  dtb_disp("boss: hey there kid, ready to start your first night on the job?")
  dtb_disp("i guess so.")
  dtb_disp("boss: hey, hey, hey! where's that enthusiasm? where's that spunk? you think many people get a chance to work at frank's furniture and friends discount emporium?")
  dtb_disp("oh sorry boss. it's just that i've been feeling kinda lonely lately.")
  dtb_disp("boss: hey kid. i know things can get tough, especially when it comes to getting close to people. the important thing to remember is to always pay close attention to what the other person is saying, to figure out what they wanna hear")
  dtb_disp("choice 1: could you repeat that? i wasn't paying attention.")
    select_an_option()
  dtb_disp("choice 2: you mean like, not being a wet blanket?")
 --choice 1
  dtb_disp("1: boss: grr...hey kid, i would start wising up if i were you. otherwise, you might just miss out on something truly beautiful.")
 --choice 2
  dtb_disp("2: boss: exactly! no one likes a wet blanket! especially not moisture damage prone furnishings.")
  dtb_disp("huh?")
  dtb_disp("boss: fogettaboutit kid. you'll see what i mean soon enough.")
  --back to main
  dtb_disp("by the way boss, how come you only got three pieces of furniture for sale here?")
  dtb_disp("well, i've always been a firm believer in quality over quantity. anyways, have a good night kid!")
  boss_flag = 1
  end

end
scene.draw[8] = function()
  for j = 0,127,16 do
    for i = 0,127,16 do
        spr(236,i,j,2,2)
    end
  end

  spr(77, 10, 40, 3, 4)
  rectfill(50,20,124,65,0)
  print('press \x97 to go back to main menu',0,10,5)
  debug_info()
  dtb_draw()
end



function scene_manager(x)
  dtb_init()
  --  _dtb_clean()
  if (x == 1) then
    next_scene = 1
    scene.active = 4
  elseif(x==2) then
    next_scene = 2
    scene.active = 4
  elseif (x==3) then
    next_scene = 3
    scene.active = 4
  elseif(x==4) then
    scene.active =8
    --next_scene = 4
end
end
-- animations
function screenshake()
   time=time+1
   camera(cos(time/3), cos(time/2)) --:d :d
   if (time>10) then
   camera(cam.x,cam.y)
 end
end

function animations_down()
   player.moving = true
   player.timer = player.timer+1 -- interal timer to activate waiting animations
   player.flip = false
    --player.timer = player.timer+1 -- interal timer to activate waiting animations
    --player.flip = false
    if player.timer>=10 then -- after 1/3 of sec, jump to sprite 6
  		player.sprite = 64
  	end
  	if player.timer >= 30 then -- after 2 sec jump frame 8
  		player.sprite = 66
  	end
    if player.timer >= 60 then
      player.sprite = 68
    end
  	if player.timer >= 62 then -- and jump back to frame 6,
  		player.sprite = 64
  		player.timer = 0 -- restart timer
  	end
    if (player.sprite == 64) then
      player.sprite = 66
    elseif (player.sprite == 66) then
      player.sprite = 68
    elseif (player.sprite == 68) then
      player.sprite = 64
    end
    if player.sprite > 68 then
      player.sprite = 64
    end
end

function animations_up()
   player.moving = true
   player.timer = player.timer+1 -- interal timer to activate waiting animations
   player.flip = false

    if player.timer>=10 then -- after 1/3 of sec, jump to sprite 6
  		player.sprite = 96
  	end
  	if player.timer >= 30 then -- after 2 sec jump frame 8
  		player.sprite = 98
  	end
    if player.timer >= 60 then
      player.sprite = 100
    end
  	if player.timer >= 62 then -- and jump back to frame 6,
  		player.sprite = 96
  		player.timer = 0 -- restart timer
  	end
    if (player.sprite == 96) then
      player.sprite = 98
    elseif (player.sprite == 98) then
      player.sprite = 100
    elseif (player.sprite == 100) then
      player.sprite = 96
    end
    if player.sprite > 100 then
      player.sprite = 96
    end
    if player.sprite < 96 then
      player.sprite = 96
    end
end

function animations_right()
  player.moving = true
  player.timer = player.timer+1 -- interal timer to activate waiting animations
  player.flip = false

    if player.timer>=10 then -- after 1/3 of sec, jump to sprite 6
  		player.sprite = 70
  	end
    if player.timer >= 60 then
      player.sprite = 72
    end
  	if player.timer >= 62 then -- and jump back to frame 6,
  		player.sprite = 70
  		player.timer = 0 -- restart timer
  	end
    if (player.sprite == 70) then
      player.sprite = 72
    elseif (player.sprite == 72) then
      player.sprite = 70
    end
    if player.sprite > 72 then
      player.sprite = 70
    end
    if player.sprite < 70 then
      player.sprite = 72
    end
end

function animations_left()
  player.moving = true
  player.timer = player.timer+1 -- interal timer to activate waiting animations
  player.flip = false

    if player.timer>=10 then -- after 1/3 of sec, jump to sprite 6
  		player.sprite = 102
  	end
    if player.timer >= 60 then
      player.sprite = 104
    end
  	if player.timer >= 62 then -- and jump back to frame 6,
  		player.sprite = 102
  		player.timer = 0 -- restart timer
  	end
    if (player.sprite == 102) then
      player.sprite = 104
    elseif (player.sprite == 104) then
      player.sprite = 102
    end
    if player.sprite != 102 and player.sprite!= 104 then
      player.sprite = 102
    end
end

function tile_type(x,y)
  local tilex = ((x - (x %8))/8)
  local tiley = ((y - (y %8))/8)
  --solid
  if (fget(mget(tilex,tiley),0)) then
    tiletype = 0
    -- bookcase
    if(fget(mget(tilex,tiley),1)) then
      tiletype = 1
      -- lamp
    elseif(fget(mget(tilex,tiley),2)) then
      tiletype = 2
      -- futon
    elseif(fget(mget(tilex,tiley),3)) then
      tiletype = 3
    -- boss
    elseif(fget(mget(tilex,tiley),4)) then
      tiletype = 4
    end
  else
    tiletype = -1
  end
  return tiletype
end

function input ()
	local allowance = 28
	local speed = 2.50
	local playerdiff= 5
	player.moving = false
	--move left
	if btn(0) then
		player.flip = false
		if(tile_type(player.x-1,player.y) == -1) then
			player.x -= speed
    else
      scene_manager(tile_type(player.x-1,player.y))
		end
		if(player.x - cam.x<(64 - allowance - playerdiff)) then
			cam.x-=speed
		end
    player.timer = 0
    animations_left()
	-- move right
elseif btn(1) then
    player.flip = false
		if(tile_type(player.x+8+1,player.y) == -1) then
			player.x += speed
    else
      scene_manager(tile_type(player.x+8+1,player.y))
		end
		if(player.x - cam.x>(64 + allowance)) then
			cam.x+=speed
		end
		--move()
    player.timer = 0
    animations_right()
	-- move up
elseif btn(2) then
    player.flip = false
    if(tile_type(player.x,player.y-1) == -1) then
			player.y -= speed
    else
      scene_manager(tile_type(player.x,player.y-1))
		end
		if(player.y - cam.y<(64 - allowance - playerdiff)) then
			cam.y-=speed
		end
    player.timer = 0
    animations_up()
		--move()
	-- move down
elseif btn(3) then
    player.flip = false -- set deafult direction of sprite
		if(tile_type(player.x,player.y+8+1) == -1) then
			player.y += speed
    else
      scene_manager(tile_type(player.x,player.y+8+1))
    end
		if(player.y - cam.y>(64 + allowance)) then
			cam.y+=speed
		end
    player.timer = 0 -- reset internal timer
    animations_down()
	end
end

function debug_info()
  --print(tile_type(player.x,player.y),player.x,(player.y - 18),7)
  --print(scene.draw,0,0,8)
  --print(scene.active,0,6,8)
  --print("x co-ordinate",)
  --[[print("player_sprite"..player.sprite,player.x,player.y-30,7)
  print("cam_x "..cam.x,player.x,player.y-24,7)
  print("cam_y "..cam.y,player.x,player.y-18,7)
  print("playerx "..player.x,player.x,player.y-6,7)
  print("playery "..player.y,player.x,player.y-12,7)
]]--
--print(clock_timer,0,40,15)
local integer1
local integer2
if (choice_1 == true) then
  integer1 = "selected"
print ("1 is "..integer1,60,30,9)
elseif (choice_1 == false) then
  integer1 = "not selected"
end

if (choice_2 == true) then
  integer2 = "selected"
  print ("2 is "..integer2,60,30,8)
elseif(choice_2 == false) then
  integer2 = "not selected"
end
print("lamp_scene"..l_scene,60,40,9)
--print (counter,10,20,15)
--print (b_flag,10,30,15)
end

-- pico -----------------------
function titleupdate()

  sprite_timer +=1
  if sprite_timer<10 then
    sprite_color =248
  elseif sprite_timer < 20 then
    sprite_color = 249
  elseif sprite_timer<23 then
    sprite_color = 248
    sprite_timer = 0
  end

  if (btn(5)) then
		scenery = 1
		scene.reset()
	end
end

function titledraw()
	--local titletxt = "inanimate hearts"
	local starttxt = "press \x97 to start"
	rectfill(0,0,screenwidth, screenheight, 3)
  --writing the term inanimate hearts
    --map(48,1,30,127/4,7,4)
    spr(226,30,127/4+5)
    spr(227,30+8,127/4+5)
    spr(242,30+8+8,127/4+5)
    spr(243,30+8+8+8,127/4+5)
    spr(245,38+8,127/4+8+5)
    spr(246,38+8+8,127/4+8+5)
    spr(247,38+8+8+8,127/4+8+5)

    spr(sprite_color,38+8,127/4-10)
    spr(sprite_color,38+2,127/4-10-6-2)
    spr(sprite_color,38-4,127/4-10-6-6-2)
    spr(sprite_color,38-4-6-3,127/4-10-6-6-4)
    spr(sprite_color,38-4-6-2-6-4,127/4-10-6-6-1)
    spr(sprite_color,38-4-6-2-6-2-6-2,127/4-10-6-6+6)
    spr(sprite_color,38-4-6-2-6-2-6-6,127/4-10-6-6+6+2+6)
    spr(sprite_color,38-4-6-2-6-2-6-6,127/4-10-6-6+6+2+6+4+1+4)
    spr(sprite_color,38-4-6-2-6-2-6-2,127/4-10-6-6+6+2+6+6+4+6+1)
    spr(sprite_color,38-4-6-2-6-5,127/4-10-6-6+6+2+6+6+4+6+4+4)
    spr(sprite_color,38-4-6-6,127/4-10-6-6+6+2+6+6+4+6+4+6+4)
    spr(sprite_color,38-8,127/4-10-6-6+6+2+6+6+4+6+4+6+6+4)
    spr(sprite_color,38,127/4-10-6-6+6+2+6+6+4+6+4+6+6+6+4)
    spr(sprite_color,38+8,127/4-10-6-6+6+2+6+6+4+6+4+6+6+6+10)

    --right side--

    spr(sprite_color,54-2,127/4-10-6-2)
    spr(sprite_color,54+4,127/4-10-6-6-2)
    spr(sprite_color,54+4+6+3,127/4-10-6-6-4)
    spr(sprite_color,54+4+6+2+6+4,127/4-10-6-6-1)
    spr(sprite_color,54+4+6+2+6+2+6+2,127/4-10-6-6+6)
    spr(sprite_color,54+4+6+2+6+2+6+6,127/4-10-6-6+6+2+6)
    spr(sprite_color,54+4+6+2+6+2+6+6,127/4-10-6-6+6+2+6+4+1+4)
    spr(sprite_color,54+4+6+2+6+2+6+2,127/4-10-6-6+6+2+6+6+4+6+1)
    spr(sprite_color,54+4+6+2+6+5,127/4-10-6-6+6+2+6+6+4+6+4+4)
    spr(sprite_color,54+4+6+6,127/4-10-6-6+6+2+6+6+4+6+4+6+4)
    spr(sprite_color,54+8,127/4-10-6-6+6+2+6+6+4+6+4+6+6+4)
    spr(sprite_color,54,127/4-10-6-6+6+2+6+6+4+6+4+6+6+6+4)
	print(starttxt, 35, (127/4)+(127/2),7)
end

function _update()
	if (scenery == 0) then
		titleupdate()
  elseif scene.active == 0 then
    scene.updates()
  elseif scene.active !=0 then
    --go_to_map()
	  scene.updates()
	end
end

function _draw()
	cls()

	if (scenery == 0) then
		titledraw()
  else
	   scene.drawing()
	end
end
--scene.update[0]
-- printing different colors in the dialogue box
-- ^0..^f: set color
-- ^l: linebreak
--[[function printc(t,x,y)
 local l=x
 local s=7
 local o=1
 local i=1
 local n=#text+1
 while i<=n do
  local c=sub(t,i,i)
  if c=="^" or c=="" then
   i+=1
   local p=sub(t,o,i-2)
   print(p,l,y,s)
   l+=4*#p
   o=i+1
   c=sub(t,i,i)
   if c=="l" then
    l=x
    y+=6
   else
    for k=1,16 do
     if c==sub("0123456789abcdef",k,k) then
      s=k-1
      break
     end
    end
   end
  end
  i+=1
 end
end]]--

--printc(sub(text,1,frame),1,1)
--text="hell yeah^l^8colors!^l^bcolors!!^l^ccolors!!!"
--frame=0
__gfx__
000000005555555555500000000006656666666500000000555666555666555d0000000000000000555555555555555555555555555555550000000055555555
000000006666666656600000000006656666666500000000555666555666555d0000000000000000777777777777777756666666666666650000000055555555
007007006666666656600000000006656666666500000000555666555666555d0000000000000000ee888888888888ee56444444444444650000000055555555
00077000dddddddd56600000000006656666666500000000777ddd666444777d0000000000000000e88888888888888e56444444444444650000000055555555
000770006666666656600000000006656666666500000000777ddd666444777d0000000000000000e87788788788777e56444444444444650000000055555555
007007006666666656600000000006656666666500000000777ddd666444777d0000000000000000e78887878788788e56444444444444650000000055555555
000000006666666656600000000006656666666500000000555666000666555d0000000000000000e78887878788788e564444444444446500000000dddddddd
000000006666666656600000000006656666666500000000555666000666555d0000000000000000e87887778788778e56444444444444650000000055555555
000000006666666656600000000006655666666600000000555666000666555d0000000066666666e88787878788788e56444444444444650000000066666666
000000006666666656600000000006655666666600000000777444666ddd777d00000000666b3666e88787878788788e56444444444444650000000066666666
000000006666666656600000000006655666666600000000777444666ddd777d0000000066633b66e77887878778777e56444444444444650000000066666666
000000006666666656600000000006655666666600000000777444666ddd777d000000006666bb66e88888888888888e56444444444444650000000066666666
000000006666666656600000000006655666666600000000555666555666555d0000000063666366ee888888888888ee56444444444444650000000077777777
000000006666666656600000000006655666666600000000555666555666555d00000000663666367777777777777777564444444444446500000000dddddddd
000000006666666656600000000006655666666600000000555666555666555d00000000636663666666666666666666564444444444446500000000dddddddd
000000006666666656600000000006655666666600000000dddddddddddddddd0000000063666366666666666666666656444444444444650000000055555555
00000000555555555660000000000000000006650000000056666666666666665355535553355335000000005555555556444444444444651111111111111111
0000000066666666566000000000000000000665000000005666666666666666bb66b366b3666366000000006666666656444444444444651111111111111111
00000000dddddddd566000000000000000000665000000005666666666666666db343dddd3ddd3bd000000006666666655644444444444655555555555555555
00000000dddddddd566000000000000000000665000000005666666666666666ddb4dddbdd3dd3dd000000006666666677564444444444666666666666666666
00000000dddddddd566000000000000000000665000000005666666666666666bddd43bddd3d3ddd000000006666666677556444444444444444444444444444
00000000dddddddd566000000000000000000665000000005666666666666666bbdd4bdddd4d3ddb000000006666666677545644444444444444444444444444
00000000dddddddd566666666666666666666665000000005666666666666666d3d4dddddd4d4d3d000000006666666655544564444444444444444444444444
00000000dddddddd555555555555555555555555000000005555555566666666dd34dddddd4d4d4d000000006666666615544456444444444444444444444444
00000000dddddddd555555555555555555555555000000000000000000000000ddd4ddddddd4dddd000000000000000055544445644444444444444444444444
00000000dddddddd566666666666666666666665000000000099900000000000ddd4ddddddd4dddd000000007777777777644444564444444444444444444444
00000000dddddddd5660000000000000000006650000000000999000000000004433334444333344000000005555555577764444456444444444444444444444
00000000dddddddd5660000000000000000006650000000000999000000000004444444444444444000000005555555577756444445666666666666666666666
00000000dddddddd5660000000000000000006650000000000999000000000004444444444444444000000005555555555555644444555555555555555555555
00000000dddddddd566000000000000000000665000000000099900000000000d444444dd444444d000000005555555555566664444444444444444444444444
00000000555555555660000000000000000006650000000000000000000000005544445555444455000000005555555555566656444444444444444444444444
000000000000000056600000000000000000066500000000009990000000000000444400004444000000000055555555ddddddddd55555555555555555555555
00000cccccc0000000000cccccc0000000000cccccc0000000000ccccc00000000000ccccc00000000000000ddddddb33bdddddd000000b33b00000000000000
0000cccccccc00000000cccccccc00000000cccccccc00000000ccccc9c000000000ccccc9c0000000000000ddddbbb33bbbdddd0000bbb33bbb000000000000
000cccc99cccc000000cccc99cccc000000cccc99cccc000000ccccc9a900000000ccccc9a9000000dd07600ddddbffbbffbdddd000bbbb33bbbb00000000000
000ccc9aa9ccc000000ccc9aa9ccc000000ccc9aa9ccc00000044446666660000004444666666000d1171160ddd33ffffff33ddd0033ffb33bff330000000000
0004466666644000000446666664400000044666666440000004f4f2ff2000000004f4f2ff200000d1711160dddf88888888fddd003ffffbbffff30000000000
00004f2ff2f4000000004f2ff2f4000000004f2ff2f400000004f4fffff000000004f4fffff000000d171600dddf388ff883fddd028888ffff88882000000000
0000ffffffff00000000ffffffff00000000ffffffff000000044fff22f0000000044fff22f0000000d170005555bffffffb55550f288888888882f000000000
00004ff22ff4000000004ff22ff4000000004ff22ff4000000004fffff90000000004fffff9000000007000000000ff22ff000000f32888ff88823f000000000
0000ccffffcc00000000ccffffcc00000000ccffffcc000000000cccf900000000000cccf9000000000000001111ddffffdd1111003feeffffeef30000000000
000ccccc19acc000000ccccc1c9ac000000cccc1c9acc00000000cccc1a0000000000cccc1a0000000000000111fdddffdddf111000bfffeefffb00000000000
000ffccc1ccff000000ffccc1cccf000000fccc1cccff0000000ccccc1c00000000005cfffc0000000dd0dd0555ffddddddff5550000f2ffffff000000000000
000ff5c51c5ff000000ff5c515c0f000000f0c515c5ff0000000ff51515000000000051fff5000000d00d00d666ff666666ff6660000ff2222ff000000000000
0000011111100000000001111110000000000111111000000000ff111110000000021111111000000d00000d444ff444444ff44400000ffffff0000000000000
0000011111100000000022111110000000000111112200000000011111102000000211001110000000d000d044444444444444440005ddffffdd500000000000
00000110011000000000222001100000000001100222000000002110001220000002200001100000000d0d0044444444444444440f5ddddffdddd5f000000000
000002200220000000000220022000000000022002200000000022000000000000000000022200000000d0004444444444444444ff5dddddddddd5ff00000000
00000cccccc0000000000cccccc0000000000cccccc00000000000ccccc00000000000ccccc0000000000000555666555666555dff5dddddddddd5ff00000000
0000cccccccc00000000cccccccc00000000cccccccc000000000c9ccccc000000000c9ccccc000000000000555666555666555dfff5dddddddd5fff00000000
000cccccccccc000000cccccccccc000000cccccccccc000000009a9ccccc000000009a9ccccc00000000000555666555666555dfff05dddddd50fff00000000
000ccc5555ccc000000ccc5555ccc000000ccc5555ccc0000006666664444000000666666444400000000000777ddd666444777d0ff05dddddd50ff000000000
00044cccccc4400000044cccccc4400000044cccccc44000000002ff2f4f4000000002ff2f4f400000000000777ddd666444777d0ff00dddddd00ff000000000
00004444444400000000444444440000000044444444000000000fffff4f400000000fffff4f400000000000777ddd666444777d0ff0155665510ff000000000
0000f444444f00000000f444444f00000000f444444f000000000f22fff4400000000f22fff4400000000000555666000666555d0f011111111110f000000000
00004f4444f4000000004f4444f4000000004f4444f40000000009fffff40000000009fffff4000000000000555666000666555dff011110011110ff00000000
0000ccffffcc00000000ccffffcc00000000ccffffcc00000000009fccc000000000009fccc00000000000000666555d55566600ff011100001110ff00000000
000cccccccccc000000cccccccccc000000cccccccccc00000000a1cccc0000000000a1cccc00000000000006ddd777d77744466ff011100001110ff00000000
000ff5cccc5ff000000ff5cccc50f000000f05cccc5ff00000000c1ccccc000000000cfffc500000000000006ddd777d77744466000111000011100000000000
000ff515515ff000000ff5155150f000000f0515515ff0000000051515ff0000000005fff1500000000000006ddd777d77744466000011000011000000000000
0000011111100000000001111110000000000111111000000000011111ff00000000011111112000000000005666555d55566655000011000011000000000000
00000111111000000000022111100000000001111220000000020111111000000000011100112000000000005666555d55566655000011000011000000000000
00000110011000000000222001100000000001100222000000022100011200000000011000022000000000005666555d55566655007888000088870000000000
0000022002200000000022000220000000000220002200000000000000220000000022200000000000000000dddddddddddddddd007777000077770000000000
00001111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000011111111111111110000000000000000
00001444444444444441222221000000000000000000000000000000000000000000000000000000000000000000000014444444441222210000000000000000
00001444444444444441222221000000000000000000099999900000000000000000000000000000000000000000000014111111141222210000000000000000
000014111111111111412222210000000000000000009aaaaaa90000000000000000000000000000000000000000000014122222141222210000000000000000
0000141d26222e3291412222210000000000000000009aaaaaa90000000000000000000000000000000000000000000014111111141222210000000000000000
0000141d96222e3d9141222221000000000000000009aaaaaaaa9000000000000000000000000000000000000000000014444444441222210000000000000000
0000141d96222e3d9141222221000000000000000009aaaaaaaa9000000000000000000000000000000000000000000014111111141222210000000000000000
0000141111111111114122222100000000000000009aaaaaaaaaa900000000000000bbbbbbbbbbbbbbbbbbbbb000000014122222141222210000000000000000
0000144444444444444122222100000000000000009aaaaaaaaaa9000000000000bbb3333333333333333333bbb0000014122222141222210000000000000000
000014111111111111412222210000000000000009aaaaaaaaaaaa90000000000bb33333333333333333333333bb000014111111141222210000000000000000
0000141222222222314122222100000000000000999999999999999900000000b33333333333333333333333333b000014444444441222210000000000000000
0000141222222222314122222100000000000000900902922920900900000000b33333333333333333333333333bb00014111111141222210000000000000000
0000141222222222314122222100000000000000900902922920900900000000b333333333333333333333333333b00014122222141222210000000000000000
0000141111111111114122222100000000000000000002222220000000000000b333333333333333333333333333b00014122222141222210000000000000000
0000144444444444444122222100000000000000000002e2e2e0000000000000b333333333333333333333333333b00014111111141222210000000000000000
000014111111111111412222210000000000000000000e2e2e20000000000000bbbbbbb333333333333333333bbbbb0014444444441222210000000000000000
0000141232222222214122222100000000000000000002e2e2e0000000000000bbbb333b3333333333333333bbb3333014111111141222210000000000000000
0000141e3222222221412222210000000000000000000e2e2e20000000000000bbb3333b3333333333333333bbb3333b14122222141222210000000000000000
0000141e32222222214122222100000000000000000002e2e2e0000000000000bbb3333b3333333333333333bbb3333b14122222141222210000000000000000
000014111111111111412222210000000000000000000e2e2e20000000000000bbb3333b3333333333333333bbb3333b14111111141222210000000000000000
0000144444444444444122222100000000000000000002e2e200000000000000bbb3333b3333333333333333bbb3333b14444444441222210000000000000000
000014111111111111412222210000000000000000000e2e2e00000000000000bbb3333bbbbbbbbbbbbbbbbbbbb3333b14444444441222210000000000000000
0000141222222222214122222100000000000000000002e2e000000000000000bbb3333b333333333333333333b3333b11111111111111110000000000000000
000014122222222221412222210000000000000000000e2e2000000000000000bbb3333b333333333333333333b3333b1666dddddd1666d10000000000000000
0000141222222222214122222100000000000000000002e2e800000000000000bbb3333b333333333333333333b3333b00000000000000000000000000000000
000014111111111111412222210000000000000000008e2e8800000000000000bbb3333b333333333333333333b3333b00000000000000000000000000000000
0000144444444444444122222100000000000000000088e28800000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000
00001444444444444441222221000000000000000008888888000000000000000000000000000000000000000000000000000000000000000000000000000000
00001444444444444441222221000000000000000088888888000000000000000000000000000000000000000000000000000000000000000000000000000000
00001111111111111111111111000000000000000888888088000000000000000000000000000000000000000000000000000000000000000000000000000000
00001000000000000001000001000000000000008888880088000000000000000000000000000000000000000000000000000000000000000000000000000000
00001000000000000001000001000000000000008888000088000000000000000000000000000000000000000000000000000000000000000000000000000000
ddddddd66ddddddda9aaaaaaaaaaaaaa000000005555559999555555555555555555555555555555777777777777777777777777777777770eee000e00ee0000
dddddd6dd6dddddd9a99aaaaaaaaaaaa00000000666669aaaa966666666666666666666666666666766666666666666776666666666666670e00e0e0e0e0e000
ddddd6dddd6ddddda99aaaaaaaaaaaaa00000000dddd9aaaaaa9dddddddddddddddddddddddddddd76ccaccccaccca6776111111111111670e00e0e0e0e00e00
dddd6dd66dd6ddddaa99aaaaaaa3a3aa00000000ddd9aaaaaaaa9ddddddddddddddddddddddddddd76ccccacccccac677611a1777111a1670eee00e0e0e00e00
ddd6dd6666dd6ddd99aaaaaa33a3aaaa00000000dd999999999999dddddddddddddddddddddddddd76ccccccaaaccc6776111771111111670e00e0eee0e00e00
dd6dd666666dd6dda9a9aaaaaa3a333a00000000dd9dd922229dd9dddddddddddddddddddddddddd76cccccaaaaacc6776117711111111670e00e0e0e0e0e000
d6dd66666666dd6d9aaaaaaa33a33aaa00000000dddddd2222dddddddddddddddddddddddddddddd76cacacaaaaaca6776a17711111a11670eee00e0e0ee0000
6dd6666666666dd6aaaaaaaaa333a3aa00000000dddddd2e2eddddddddddbbbbbbbbbbbbbbbddddd76cccccaaaaacc6776117711111111670000000000000000
6dd6666666666dd6aaaaaaaa3a3aaaaa00000000dddddde2e2ddddddddbbb33333333333333bdddd76ccccccaaaccc6776117711a1111167000ee0ee00ee0000
d6dd66666666dd6daaaaaaaaaaaaa9a900000000dddddd2e2edddddddbb3333333333333333bbddd76ccccacccccac67761117711111116700e000e0e0e0e000
dd6dd666666dd6ddaa3aaaaaaaaa9a9a00000000dddddde2e2ddddddb3333333333333333333bddd76cccacccaccca67761a11777111a16700e000e0e0e00e00
ddd6dd6666dd6dddaaa3aaaaaaa9a9a900000000dddddd2e2eddddddb3333333333333333333bbdd76c777cccccccc67761111111111116700ee00e0e0e00e00
dddd6dd66dd6ddddaa33a3aaaaaa999a00000000dddddde2edddddddb33333333333333333333bdd7677777ccacccc6776111a111a11116700e000e0e0e00e00
ddddd6dddd6ddddda33a3aaaaaaaa9a900000000dddddd2e28ddddddb33333333333333333333bdd76c777cccccccc67761111111111116700e000e0e0e0e000
dddddd6dd6ddddddaaa33aaaaaaaaa9a00000000555558e288555555bbbbbb333333333333bbbbb57666666666666667766666666666666700eee0e0e0ee0000
ddddddd66ddddddda3a3a3aaaaaaaaaa000000000000888888000000bbb33b33333333333bbb333b777777777777777777777777777777770000000000000000
7e777777777b7777e0ee000e00ee00e0000000005668888888566655bb3333b3333333333bbb333b0000000000000000cccccccccccccccceee00ee00e0e00ee
7e777777777b7c77e0e0e0e0e0e0e0e0000000005688888588566655bb3333b3333333333bbb333b0000000000000000cccaaaaaaaaaaccc0e00e0e00e0e0e00
777c7777e7777c77e0e0e0e0e0e0e0e000000000568888d588566655bb3333bbbbbbbbbbbbbb333b0000000000000000ccca99999999accc0e00eee00e0e0e00
777c7777e7777777e0e0e0e0e0e0e0e0000000008eeeeeeeeeeeeee8bb3333b333333333333b333b0000000000000000cca99999999acccc0e00e00e0e0e0ee0
7a777777777e7777e0e0e0eee0e0e0e0000000008eeeeeeeeeeeeee8bb3333b333333333333b333b0000000000000000cca9999999accccc0e00e00e0e0e0e00
7a77e777777e7777e0e0e0e0e0e0e0e0000000008eeeeeeeeeeeeee8bb3333b333333333333b333b0000000000000000ca9999999acccccc0e00e00e0e0e0e00
7777e777a7777777e0e0e0e0e0e0e0e0000000008eeeeeeeeeeeeee8bb3333b333333333333b333b0000000000000000ca999999aaaacccc0e00e00e0eee0eee
77777777a77777a70000000000000000000000008eeeeeeeeeeeeee8bbbbbbbbbbbbbbbbbbbbbbbb0000000000000000a9999999999acccc0000000000000000
77777777777777a70e0e000e00eee00ee0000000e0e00ee00e000ee00eee00ee00000000000000000000000000000000aaaaa99999accccc0e000ee00e0e00ee
7c77777777777777e0e0e0e0e00e00e000000000eee0e000e0e0e0e000e00e0000000000000000000000000000000000cccca9999acccccc0e00e00e0e0e0e00
7c777777b7777777e0e0e0e0e00e00e000000000e0e0e000e0e0eee000e00e0000ee0ee00ee0ee000000000000000000ccca9999accccccc0e00e00e0e0e0e00
77777777b7777777e000e0e0e00e00ee00000000e0e0ee00e0e0e00e00e00eee0e00e00ee88e88e00000000000000000ccca999acccccccc0e00e00e0e0e0ee0
77777e7777777c77e000e0eee00e00e000000000e0e0e000eee0e00e00e0000e0e00000ee88888e00000000000000000cca999accccccccc0e00e00e0e0e0e00
7b777e77777e7c77e000e0e0e00e00e000000000e0e0e000e0e0e00e00e0000e00e000e00e888e000000000000000000cca99acccccccccc0e00e00e0eee0e00
7b777777777e7777e000e0e0e00e00eee0000000e0e0eee0e0e0e00e00e00eee000e0e0000e8e0000000000000000000ca99accccccccccc0eee0ee000e00eee
77777777777777770000000000000000000000000000000000000000000000000000e000000e00000000000000000000caaacccccccccccc0000000000000000
__gff__
0001010101000000000001010101000100010101010000000001010101010101000101010100010501010001010101010001010101000000010100010111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000010100000000000000000000000000000101000000
0303030300050500000000000303000003030303000505000909090903030000030303030005050009090909030300000303030300050500090909090000000000000000000505090909000000000000000000000005050909090000000000000000000000050509090900000000000000000000000000000000000000000000
__map__
01010101010101010101010a0b011400000301010101010a0b010101010101010101010101010a0b010101010101120000000000dfdf0000000000000000000000000000000000000000000000c4c4c0c1c0c1c0c1c0c1c0c1c0c1c0c1000000c2c3c2c3c2c3c2c3c2c3c2c3c2c3000000e0e1e0e1e0e0e0e0e0e0e0e0e0e100
11cacb11111119111111111a1b111400001311111111111a1b111111111111111111111111111a1b11111911111108080808080808000000000000000000000000000000000000000000000000c4c4d06a6a4a5a4a6a6a4a5a4a6a6ad1000000d26a6a4a5a4a6a6a4a5a4a6a6ad3000000f06a6a4a5a4a6a6a4a5a4a6a6af100
21dadb21282129210c0d21212121140000132128212121c5c621212121212121212121212121c7c8c92129282121120808080808080000dfdf0000000000000000000000000000000000000000c4c4c06a5a6a00005a5a006a6a5a6ac1000000c26a5a6a00005a5a006a6a5a6ac3000000e06a5a6a00005a5a006a6a5a6ae100
31313131383139311c1d314b4c31143535133138313131d5d631313131313131313131313131d7d8d9313938313112080808080800eeeeeeec0000000000000000000000000000000000000000c4c4d04ac46ac480818287c46a6a4ad1000000d24ac46ac488898a8bc46a6a4ad3000000f04ac46ac484858687c46a6a4af100
04070607060706072c2d2e5b5c2f143500130607060706e5e607060706070607060706070607e7e8e9070607066c120808080808eeeeeeeedfdf0000cecf00eeef000000000000000000000000c4c4c05a6a6a0090919297c4c46a5ac1000000c25a6a6a0098999a9bc4c46a5ac3000000e05a6a6a0094959697c4c46a5ae100
04171617161716173c3d3e3f3e3f143500131617161716171617161716171617161716171617161716171617167b120808080808e2e2eeeedf000000dedf00feff000000000000000000000000c4c4d05a6ac46aa0a1a2a700c46a5ad1000000d25a6ac46aa8a9aaab00c46a5ad3000000f05a6ac46aa4a5a6a700c46a5af100
040706070607060706070607066c1435001306070607060706070607066c6b6c6b6c06070607060706070607066c120808080808e2e2eeeeec0000000000000000000000000000000000000000c4c4c04a6a6a6ab0b1b2b700c46a4ac1000000c24a6a6a6ab8b9babb00c46a4ac3000000e04a6a6a6ab4b5b6b700c46a4ae100
041716171617161716171617167b1435001316171617161716171617167b3233333416171617161716171617167b120808080808eeeeee00000000000000000000000000000000000000000000c4c4d06a5a6a000000000000005a6ad1000000d26a5a6a000000000000005a6ad3000000f06a5a6a000000000000005a6af100
040706070607060706070607066c1435001306070607060706070607066c1200001306070607060706070607066c120800080008eeee0000000000000000000000000000000000000000000000c4c4c06a6a5a00cecfdedf005a006ac1000000c26a6a5a00cecfdedf005a006ac3000000e06a6a5a00cecfdedf005a006ae100
041716171617161716171617167b1435001316171617161716171617167b1200001316171617161716171617167b12000000000800ee0000000000000000000000000000000000000000000000c4c4d06ac46a4ac4c4c4c44ac4006ad1000000d26ac46a4ac4c4c4c44ac4006ad3000000f06ac46a4ac4c4c4c44ac4006af100
040706070607060706070607066c2623232406070607060706070607066c1200001306070607060706070607066c120000000000df000000000000000000000000000000000000000000000000c4c4c0c16a6a6a5a6a6a5a6a6a6ac0c1000000c2c36a6a6a5a6a6a5a6a6a6ac2c3000000e0e16a6a6a5a6a6a5a6a6a6ae0e100
041716171617161716171617167b010a0b011617168c8d1716171617167b1200001316171617161716171617167b12000000000000000000000000000000000000000000000000000000000000c4c4d0d1d06a6a6a4a4a6a6a6ad1d0d1000000d2d3d26a6a6a4a4a6a6a6ad3d2d3000000f0f1f06a6a6a4a4a6a6a6af1f0f100
040706070607060706070607066c111a1b110607069c9d0706070607066c1200001306070607060706070607066c12000000000000000000000000000000000000000000000000000000000000c4c4c0c1c0c1c0c1c0c1c0c1c0c1c0c1000000c2c3c2c3c2c3c2c3c2c3c2c3c2c3000000e0e1e0e1e0e1e0e1e0e1e0e1e0e100
041716171617161716171617161721282121161716acad1716171617167b1200001316171617161716171617167b12000000000000000000000000000000000000000000000000000000000000c4c4d0d1d0d1d0d1d0d1d0d1d0d1d0d1000000d2d3d2d3d2d3d2d3d2d3d2d3d2d3000000f0f1f0f1f0f1f0f1f0f1f0f1f0f100
04070607060706070607060706073138313106070607060706070607066c1200001306070607060706070607066c12000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
04171617161716171617161716171617161716171617161716171617167b1200001316171617161716171617167b120000000000000000000000000000c0c1e0e1c2c3c0c1e0e1c2c3c0c100000000c0c1c0c1c0c1c0c1c0c1c0c1c0c1000000c2c3c2c3c2c3c2c3c2c3c2c3c2c3000000e0e1e0e1e0e0e0e0e0e0e0e0e0e100
04070607060706070607060706070607060706070607060706070607066c1200001306070607060706070607066c120000000000000000000000000000d0d1c4c4c4c4c4c4c4c4c4d3d0d100000000d06a6af9f8f96a6af9f8f96a6ad1000000d26a6af9f8f96a6af9f8f96a6ad3000000f06a6af9f8f96a6af9f8f96a6af100
047b7c7b7c7b7c7b7c7b7c7b1617161716177c7b7c7b7c7b7c7b7c7b7c7b120000137c7b7c7b7c7b7c7b7c7b7c7b120000000000000000000000000000c0c1c4f9e2e3f2f3f4c4c4c3c0c100000000c06af86a0000f8f8006a6af86ac1000000c26af86a0000f8f8006a6af86ac3000000e06af86a0000f8f8006a6af86ae100
3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b3b020000000000000000000000000000d0d1c4c4c4c4f5f6f7f8c4d3d0d100000000d0f9c46ac480818287c46a6af9d1000000d2f9c46ac488898a8bc46a6af9d3000000f0f9c46ac484858687c46a6af9f100
0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f020000000000000000000000000000c0c1c4c4c4c4c4c4c4c4c4c3c0c100000000c0f86a6a0090919297c4c46af8c1000000c2f86a6a0098999a9bc4c46af8c3000000e0f86a6a0094959697c4c46af8e100
1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f1f120000000000000000000000000000d0d1f0f1d2d3d0d1f0f1d2d3d0d100000000d0f86ac46aa0a1a2a700c46af8d1000000d2f86ac46aa8a9aaab00c46af8d3000000f0f86ac46aa4a5a6a700c46af8f100
35353535353535353535353535353535353535353509353535353535353509090909090900000000000000000000000000000000000000000000000000c0c1c4c4c4c4c4c4c4c4c4c3c0c100000000c0f96a6a6ab0b1b2b700c46af9c1000000c2f96a6a6ab8b9babb00c46af9c3000000e0f96a6a6ab4b5b6b700c46af9e100
c0c1c0c1c0c1c0c1c0c1e0e1e0e1e0e1e0e1e0e1c2c3c2c3c2c3c2c3c2c300000000000000000000000000000000000000000000000000000000000000d0d1c4c4c4c4c4c4c4c4c4d3d0d100000000d06af86a00c4eeef000000f86ad1000000d26af86a0000eeef000000f86ad3000000f06af86a00c40000000000f86af100
d0d1d0d1d0d1d0d1d0d1f0f1f0f1f0f1f0f1f0f1d2d3d2d3d2d3d2d3d2d300000000000000000000000000000000000000000000000000000000000000c0c1e0e1c2c3c0c1e0e1c2c3c0c100000000c06a6af800c4feffc400f8006ac1000000c26a6af800c4feffc400f8006ac3000000e06a6af8c4c4eeefc400f8006ae100
c0c1c0c1c0c1c0c1c0c1e0e1e0e1e0e1e0e1e0e1c2c3c2c3c2c3c2c3c2c300000000000000000000000000000000000000000000000000000000000000d0d1f0f1d2d3d0d1f0f1d2d3d0d100000000d06ac46af9c4c4c4c4f9c4006ad1000000d26ac46af9c4c4c4c4f9c4006ad3000000f06ac46af9c4feffc4f9c4006af100
d0d1d0d1d0d1d0d1d0d1f0f1f0f1f0f1f0f1f0f1d2d3d2d3d2d3d2d3d2d300000000000000000000000000000000000000000000000000000000000000c0c1e0e1c2c3c0c1e0e1c2c3c0c100000000c0c16a6a6af86a6af86a6a6ac0c1000000c2c36a6a6af86a6af86a6a6ac2c3000000e0e16a6a6af86a6af86a6a6ae0e100
c0c1c0c1c0c1c0c1c0c1e0e1e0e1e0e1e0e1e0e1c2c3c2c3c2c3c2c3c2c300000000000000000000000000000000000000000000000000000000000000d0d1f0f1d2d3d0d1f0f1d2d3d0d100000000d0d1d06a6a6af9f96a6a6ad1d0d1000000d2d3d26a6a6af9f96a6a6ad3d2d3000000f0f1f06a6a6af9f96a6a6af1f0f100
d0d1d0d1d0d1d0d1d0d1f0f1f0f1f0f1f0f1f0f1d2d3d2d3d2d3d2d3d2d300000000000000000000000000000000000000000000000000000000000000c0c1e0e1c2c3c0c1e0e1c2c3c0c100000000c0c1c0c1c0c1c0c1c0c1c0c1c0c1000000c2c3c2c3c2c3c2c3c2c3c2c3c2c3000000e0e1e0e1e0e1e0e1e0e1e0e1e0e100
c0c1c0c1c0c1c0c1c0c1e0e1e0e1e0e1e0e1e0e1c2c3c2c3c2c3c2c3c2c300000000000000000000000000000000000000000000000000000000000000d0d1f0f1d2d3d0d1f0f1d2d3d0d100000000d0d1d0d1d0d1d0d1d0d1d0d1d0d1000000d2d3d2d3d2d3d2d3d2d3d2d3d2d3000000f0f1f0f1f0f1f0f1f0f1f0f1f0f100
d0d1d0d1d0d1d0d1d0d1f0f1f0f1f0f1f0f1f0f1d2d3d2d3d2d3d2d3d2d30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0014001014010150101c0100c010140100c0101c0100c01014010150101c0101a010140101a0101c0101a01014000150001c0000c000140000c0001c0000c00014000150001c0000c000140000c0001c0000c000
0010000007155000050e55500005141550000514155115550e1550000507155000050e55500005141550000514155115550e1550000507155000050e55500005141550000014155115550e155000000000000000
001e000e18615186101461514610146051461013605146101b6052b005106101260514610146051660515605166051b605176051960500005000051b6051b6051b60500000000001b60300000000001b6031b600
001e0020180103e0001c010000001d010000000000010010180103e0001c010000001d010000000000010010180103e0001c010000001d01000000000001001018010000001c010000001d010000000000010010
00100000161501d1501f150221501f100221002210027100041001450000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000800002703500000000002b035000002c0002e0352b000000003003500000000003103500000000003003500000000002e03500000000002c035320002c0002e03500000230003003521000360002c0351d000
001000003614035150371603817000000351000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000b15009140081300612000000231000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001e15035130111502a17000002000010000100001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0110000026050260502e000240502500026050260502700024050240502c00021050210501f0002405024050000002b0502b05000000000000000000000000000000000000000000000000000000000000000000
011000000c5150c5150c50018500185000c5150c5150c5000c5150c5150c51518500185000c5150c5150c5000c5150c5150c50018500185000c5150c5150c5000c5150c5150c51518500185000c5150c5150c500
011000001051510515000000000000000105151051500000105151051510515000000000010515105150000010515105150000000000000001051510515000001051510515105150000000000105151051500000
001000001351513515000000000000000135151351500000135151351513515000000000013515135150000013515135151351500000000001351513515000001351513515135150000000000135151351500000
011e00001e0551e050210551905526005210550c0001e0551a0551a0551a05500000000000000000000190511a0551e05521055250552200521055000001e0552805028050280502705026055260400000000000
011e00000000000000000000000015025150201602516020170251702017020160251702517020170201702017020170201502516025170251e0251e020190251702517020170201602517025170201702017020
011e0000205552055019055120551750019555000001f05513500195551c50013051120550000010055000001805518055180550000000000000001805518055180550000000000000000f0550f0500e0550e040
011e00000702507010070100701007025070100701007010070250701007010070100702507010070100701007025070100701007010070250701007010070100702507010070100701007025070100701007010
001e00001701517010170101701017015170101701017010170151701017010170101701517010170101701017015170101701017010170151701017010170101701517010170101701017015170101701017010
001e00000e0150e0100e0100e0100e0150e0100e0100e0100e0150e0100e0100e0100e0150e0100e0100e0100e0150e0100e0100e0100e0150e0100e0100e0100e0150e0100e0100e0100e0150e0100e0100e010
01200000085500c5500f5501155000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011e0000190551905021055250550000021055000001e0551c0551c0551c0550000028055280552805500000000001e06521055250550000021055000001e0552505525050250502505023055230502305000000
001412201a0551a0551a0550000000000000000000000000000000000000000000000000000000000001805517055150550000000000000000000000000000000000000000000001805517055150550000000000
011e000000000000001f0501f0501f0501f05026050260502605026050000001f0002b0502b0502b0502b050260502605000000000002b0502b0502b0502b05026050260501a0002405023050240502105021050
001e1d1d0000000000000000000017020170200000000000170201702000000000000c0200c0200c0200c020170201702017020170200c0200c0200c0200c0201702017020170201502015020150201502015020
001e1d1d0000000000000000000013020130200000000000130201302000000000001302013020130201302013020130201302013020130201302013020130201302013020130201102011020120201202012020
001412201a0551a0501a0550000000000000000000000000000000000000000000000000000000000001805517055150550000000000000000000000000000000000000000000001805517055150550000000000
001e0000000000000017025170201702517020170251702017025170200c0250c0200c0250c020170251702017025170200c0250c0200c0250c02017025170201702517020000000000000000000000000000000
001e000000000000001302513020130251302011025110201102511020100251002010025100200e0250e0200e0250e020100251002010025100200e0250e0200e0250e020000000000000000000000000000000
011e0000230551f0551a0551905019050230551f05519055210551e0551805517050170501d0551a055150551c0551c0551c05500000000000000000000220512305525051260552a0512d055150000000000000
011e000017020170201702017020170251702016025160201902519020190201802519025190201902019020190201902019025180251902520020200201b0201902019020190201b02017020170201702019025
011e00001703517030000000000000000000000000000000130351303513035000000000000000000001003112035000000000000000000000000000000000001403514020140201303500000000000000000000
011e000015035150301c0350000000000100350000015035000001c0350000013031120350000000000000000e0350e0350e0350000000000000000e0350e0350e03500000000000000000000000000000000000
011e0000000000000000000000000000017035000001a03520035200352003500000000000000000000000000b0350b0300000017030000000b0350000000000100301003010030100300e0350e0300000000000
001e000010030100302303015030150301903019030190300e0300e030210301303013030230302303023030100351003510035000000000000000000000d0310e0351f03122035250312b0350c0000c00000000
011e0000000000d0310e0351f0312203531031370350c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001e00000000000000000000000000000000000000000000100401004013040170401704013040130400d04015040130401304010040100401004017040170400e0400e04021040150401504021040210400d040
011e00000e0401e0401e0401504015040150401e0401e0402004020040230400d0400d0402204022040110401204022040220400d0400d0400d04022040220401e0401e040210401704017040210402104021005
00180000085300d5400f550145600000000000000001c500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001800000f560105600f5600c5600f502105020f5000c500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001800000755006551045410453000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001800000555004550055500655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000024750297502d7502b75000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0010000013750107500d7500d7502c700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00100000107500d750027500475000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000c7500c7500c7500c75000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01320000190301e0402005021050200401e0301a0201a0201a0201a0301e0402005021050200401e0301902019020190301e0402005021050200401e0301a02023020210502005021050200501e0501905019050
013200001501015010150101501015010150101701017010170101c0101c0101c0101c0101c0101c0101501015010150101501015010150101501015010170101c0101c0101c0101c0101c0101c0101501015010
013200000000000000200102001020010200100000000000150101501000000170101701017010170100000014010120100000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 0d1e5152
00 0f1f5152
00 14205152
00 1c215152
00 0e235152
02 1d245152
00 15161718
00 19161a1b
03 03454344
00 05424344
00 04424344
00 07424344
00 08424344
00 06424344
00 25424344
00 27424344
00 26424344
00 28424344
00 29424344
00 2b424344
00 2a424344
00 2c424344
03 2d2e6f44

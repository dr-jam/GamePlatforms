pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--[[

tasks:
-add two more items to the cart
-add a selection graphic to the items
-make a store
--make silver as a currency
--give the items a value
--have 🅾️ purchase the selected item
--manage the player's silver
-using printh, log the transactions

]]

--classic debugging tech
--always print(debug), assign
--whatever you care about to it
debug=""

function _init()
	selection = 1
	
	--debug varaibles
	debug_selection = false
	
	
	items = {}
	
	potion = {}
	potion.name = "giant growth"
	potion.x = 33
	potion.y = 25
	potion.spr = 1
	
	dagger = {}
	dagger.name = "shortsword"
	dagger.x = 50
	dagger.y = 56
	dagger.spr = 2
	
	coin = {}
	coin.name = "dabloon"
	coin.x = 20
	coin.y = 97
	coin.spr = 3
	
	add(items, potion)
	add(items, dagger)
	add(items, coin)
	
	
	
end

function _update()
	if btnp(⬅️) then
		selection -= 1
	end
	
	if btnp(➡️) then
		selection += 1
		if selection > #items then
			selection = 1
		end
 	printh("item selection is now " .. selection, "debug.txt", false, true)
 end
 
 
 if btnp(❎) then
 	debug_selection = not debug_selection
 end
 
 assert(0 < selection, "seleciton too low")
	assert(selection <= #items, "selection  too high")
end

function _draw()
 cls(13)
 
 --the other end of the classic
 debug = selection
 print(debug, 15)
	for item in all(items) do
		spr(item.spr, item.x, item.y)
	end
	
	if debug_selection then
		item = items[selection]
		line(item.x+8, item.y, item.x+12, item.y-6, 8)
		print(item.name, item.x+13, item.y-8, 15)
		print(item.x)
		print(item.y)
	end
end
__gfx__
00000000000440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000000065000999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007b370000006560099aa990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700007333b700006560009aaaa90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000733b333700956000099aa990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007007b333b370049000009999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000007333b3370400000000999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

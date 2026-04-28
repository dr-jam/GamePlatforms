pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- poack isolated game a
max_hand_cards = 4
crit_min = 20
crit_max = 35

card_w = 16
card_h = 24
face_sprite_x = 8
face_sprite_y = 0
back_sprite_x = 8
back_sprite_y = 48

players = {}
deck = {}
turn_index = 1
winner = nil
game_over_text = nil
victory_timer = 0
message = ""
message_timer = 0
message_style = "center"

selected_card = 1
swap_target_index = 1
swap_player_index = 1
input_mode = "main"

card = {}
card.__index = card

-- card object
function card:new(rank, suit)
	local obj = {
		rank = rank,
		suit = suit,
		is_locked = false,
		locked_value = nil
	}
	setmetatable(obj, card)
	return obj
end

-- interpret face card names
function card:get_name()
	if self.rank <= 10 then
		return "" .. self.rank
	elseif self.rank == 11 then
		return "j"
	elseif self.rank == 12 then
		return "q"
	elseif self.rank == 13 then
		return "k"
	end
	return "jk"
end

-- return every value this card could currently represent
function card:get_values()
	if self.is_locked and self.locked_value ~= nil then
		return { self.locked_value }
	end

	if self.rank == 0 then
		return { 0 }
	elseif self.rank == 11 then
		return { 1, 5 }
	elseif self.rank == 12 then
		return { 2, 6 }
	elseif self.rank == 13 then
		return { 3, 7 }
	end

	return { self.rank }
end

-- create a player
function make_player(name, is_human, x, y)
	return {
		name = name,
		is_human = is_human,
		x = x,
		y = y,
		crit = 0,
		last_set_value = 0,
		is_out = false,
		cards = {}
	}
end

-- reset all game state and deal fresh hands
function start_card_game()
	players = {
		make_player("you", true, 4, 86),
		make_player("bot a", false, 8, 8),
		make_player("bot b", false, 68, 8)
	}

	generate_deck()
	shuffle_deck()
	generate_players_crit_numbers()
	draw_starting_cards()

	turn_index = 1
	winner = nil
	game_over_text = nil
	victory_timer = 0
	selected_card = 1
	swap_target_index = 1
	swap_player_index = 1
	input_mode = "main"
	set_message("match your crit", "normal")
	check_for_winner()
end

-- standard deck
function generate_deck()
	deck = {}
	for suit = 1, 4 do
		for rank = 1, 13 do
			add(deck, card:new(rank, suit))
		end
	end
	add(deck, card:new(0, 0))
	add(deck, card:new(0, 0))
end

-- fisher-yates shuffle
function shuffle_deck()
	for i = #deck, 2, -1 do
		local j = flr(rnd(i)) + 1
		deck[i], deck[j] = deck[j], deck[i]
	end
end

-- assign each player a visible target number
function generate_players_crit_numbers()
	for player in all(players) do
		player.crit = crit_min + flr(rnd(crit_max - crit_min + 1))
	end
end

-- deal four cards to each player
function draw_starting_cards()
	for player in all(players) do
		player.cards = {}
		for i = 1, max_hand_cards do
			add(player.cards, draw_from_deck())
		end
	end
end

-- draw from the top of the deck, rebuilding it if needed
function draw_from_deck()
	if #deck <= 0 then
		generate_deck()
		shuffle_deck()
	end
	local card = deck[#deck]
	deli(deck, #deck)
	return card
end

-- discarded cards go to the bottom of the deck
function place_on_bottom(card)
	add(deck, card, 1)
end

-- per-frame update loop; human and bot turns use separate handlers
function card_game_update()
	-- game end
	if is_game_over() then
		if winner ~= nil and victory_timer > 0 then
			victory_timer -= 1
		end
		return
	end

	-- message flow
	if message_timer > 0 then
		message_timer -= 1
	end

	-- turn flow
	local player = players[turn_index]
	if player.is_human then
		update_player_turn(player)
	else
		update_bot_turn(player)
	end
end

-- handle the player's normal turn and swap-target sub-mode
function update_player_turn(player)
	-- pre swap
	if input_mode == "main" then
		-- swap between cards using left right
		if btnp(0) then
			selected_card = wrap_index(selected_card - 1, #player.cards)
			sfx(0)
		elseif btnp(1) then
			selected_card = wrap_index(selected_card + 1, #player.cards)
			sfx(0)
		end

		-- o is deck draw
		if btnp(4) then
			if replace_card(player, selected_card) then
				after_action()
			end
			return
		end

		-- x enters swap mode
		if btnp(5) then
			begin_player_swap(player)
			return
		end

		-- up/down set cards
		if btnp(2) or btnp(3) then
			if reveal_card(player, selected_card) then
				after_action()
			end
		end
	else
		update_player_swap_target(player)
	end
end

-- second step of swapping: choose a hidden card from the counterclockwise player
function update_player_swap_target(player)
	local target = get_counterclockwise_player(player)

	-- choose player
	if swap_player_index >= 1 and swap_player_index <= #players then
		target = players[swap_player_index]
	end
	local options = get_swap_candidate_indexes(target)

	if #options <= 0 then
		advance_swap_target_player(player)
		return
	end

	-- move between that player's hidden cards
	if btnp(0) then
		swap_target_index = wrap_index(swap_target_index - 1, #options)
		sfx(0)
	elseif btnp(1) then
		swap_target_index = wrap_index(swap_target_index + 1, #options)
		sfx(0)
	end

	-- swap between players
	if btnp(5) then
		advance_swap_target_player(player)
		return
	end

	-- confirm swap
	if btnp(4) then
		local target_card_index = options[swap_target_index]
		if swap_specific_card(player, selected_card, target, target_card_index) then
			input_mode = "main"
			after_action()
		end
	end
end

-- bots instant turn
function update_bot_turn(player)
	perform_bot_action(player)
end

-- replace one unset card with the top card from the deck
function replace_card(player, card_index)
	local card = player.cards[card_index]
	if card == nil then
		return false
	end
	-- ignore set cards
	if card.is_locked then
		set_message(player.name .. " can't replace set", "normal")
		return false
	end

	place_on_bottom(card)
	player.cards[card_index] = draw_from_deck()
	-- that card is now the top card
	set_message(player.name .. " drew from deck", player.is_human and "normal" or "center")
	return true
end

-- lock a card in place and freeze its current best value
function reveal_card(player, card_index)
	local card = player.cards[card_index]
	if card == nil then
		return false
	end
	if card.is_locked then
		set_message(player.name .. " already set", "normal")
		return false
	end

	-- evaluate first so flexible cards freeze to the value that best fits the hand now
	local hand_state = evaluate_hand(player)
	card.is_locked = true
	if card.rank == 0 then
		card.locked_value = player.last_set_value
	else
		card.locked_value = hand_state.values[card_index]
	end
	player.last_set_value = card.locked_value
	set_message(player.name .. " set " .. card:get_name(), player.is_human and "normal" or "center")
	return true
end

-- enter the player's swap-selection mode
function begin_player_swap(player)
	local own_card = player.cards[selected_card]
	if own_card == nil or own_card.is_locked then
		set_message("pick an unset card", "normal")
		return
	end

	local target = get_counterclockwise_player(player)
	local options = get_swap_candidate_indexes(target)
	if #options <= 0 then
		set_message(target.name .. " has no hidden cards", "normal")
		return
	end

	input_mode = "swap_target"
	swap_player_index = get_player_index(target)
	swap_target_index = 1
	set_message("x next player  o take card", "normal")
end

-- swap two specific cards if neither card has been set
function swap_specific_card(source_player, source_index, target_player, target_index)
	local source_card = source_player.cards[source_index]
	local target_card = target_player.cards[target_index]

	if source_card == nil or target_card == nil then
		return false
	end
	if source_card.is_locked or target_card.is_locked then
		set_message("set cards can't swap", "normal")
		return false
	end

	source_player.cards[source_index], target_player.cards[target_index] = target_player.cards[target_index], source_player.cards[source_index]
	set_message(source_player.name .. " swapped with " .. target_player.name, source_player.is_human and "normal" or "center")
	return true
end

-- bot-only random swap action
function swap_random_card(player)
	local target = pick_random_other_player(player)
	if target == nil then
		return false
	end

	local source_index = random_unlocked_index(player.cards)
	local target_index = random_unlocked_index(target.cards)
	if source_index == nil or target_index == nil then
		set_message("swap blocked", "normal")
		return false
	end

	return swap_specific_card(player, source_index, target, target_index)
end

-- end the current turn, then hand control to the next player
function after_action()
	check_for_eliminations()
	check_for_winner()
	if is_game_over() then
		return
	end

	turn_index = get_next_active_player_index(turn_index)

	selected_card = 1
	swap_target_index = 1
	swap_player_index = 1
	input_mode = "main"
end

-- lightweight bot logic: sometimes set, sometimes swap, otherwise redraw
function perform_bot_action(player)
	local total = get_hand_total(player)
	local diff = player.crit - total
	local reveal_index = find_reveal_index(player)
	local replace_index = find_best_replace_index(player)

	if diff == 0 then
		check_for_winner()
		return
	end

	if abs(diff) <= 4 and reveal_index ~= nil and rnd(1) < 0.6 then
		if reveal_card(player, reveal_index) then
			after_action()
			return
		end
	end

	if rnd(1) < 0.3 then
		if swap_random_card(player) then
			after_action()
			return
		end
	end

	if replace_index ~= nil then
		if replace_card(player, replace_index) then
			after_action()
			return
		end
	end

	if reveal_index ~= nil then
		if reveal_card(player, reveal_index) then
			after_action()
		end
	end
end

-- choose which unset card is safest to throw away
function find_best_replace_index(player)
	local best_index = nil
	local best_score = 999
	local hand_state = evaluate_hand(player)
	local current_total = hand_state.total

	for i = 1, #player.cards do
		local card = player.cards[i]
		if not card.is_locked then
			local value = hand_state.values[i]
			local simulated = abs(player.crit - (current_total - value))
			if simulated < best_score then
				best_score = simulated
				best_index = i
			end
		end
	end

	return best_index
end

-- find the first card that can still be set
function find_reveal_index(player)
	for i = 1, #player.cards do
		if not player.cards[i].is_locked then
			return i
		end
	end
	return nil
end

-- pick any opponent for the bot swap action
function pick_random_other_player(player)
	local options = {}
	for other in all(players) do
		if other ~= player and not other.is_out then
			add(options, other)
		end
	end
	if #options <= 0 then
		return nil
	end
	return options[flr(rnd(#options)) + 1]
end

-- player swaps always target the player to the left/counterclockwise
function get_counterclockwise_player(player)
	local index = get_player_index(player)
	for i = 1, #players do
		index -= 1
		if index < 1 then
			index = #players
		end
		if not players[index].is_out then
			return players[index]
		end
	end
	return player
end

-- advance the swap target counterclockwise, skipping the human player
function advance_swap_target_player(source_player)
	local next_index = swap_player_index
	for i = 1, #players do
		next_index -= 1
		if next_index < 1 then
			next_index = #players
		end
		if players[next_index] ~= source_player and not players[next_index].is_out then
			swap_player_index = next_index
			swap_target_index = 1
			set_message("target " .. players[swap_player_index].name, "normal")
			return
		end
	end
end

-- find a player's array position so turn order can wrap cleanly
function get_player_index(target)
	for i = 1, #players do
		if players[i] == target then
			return i
		end
	end
	return 1
end

-- only hidden, unset cards are legal swap targets
function get_swap_candidate_indexes(player)
	local indexes = {}
	for i = 1, #player.cards do
		if not player.cards[i].is_locked then
			add(indexes, i)
		end
	end
	return indexes
end

-- helper for bots that need a random unset card
function random_unlocked_index(cards)
	local indexes = {}
	for i = 1, #cards do
		if not cards[i].is_locked then
			add(indexes, i)
		end
	end
	if #indexes <= 0 then
		return nil
	end
	return indexes[flr(rnd(#indexes)) + 1]
end

-- public hand total used by ui and win detection
function get_hand_total(player)
	return evaluate_hand(player).total
end

-- evaluate the whole hand at once so j/q/k choose the best overall combination
function evaluate_hand(player)
	local state = {
		total = -999,
		diff = 999,
		values = {}
	}
	local current_values = {}

	evaluate_hand_recursive(player, 1, 0, current_values, state)
	return state
end

-- recursively test every valid value combination for the hand
function evaluate_hand_recursive(player, card_index, total, current_values, best_state)
	if card_index > #player.cards then
		local diff = abs(player.crit - total)
		if diff < best_state.diff or (diff == best_state.diff and total > best_state.total) then
			best_state.total = total
			best_state.diff = diff
			best_state.values = copy_values(current_values)
		end
		return
	end

	local card = player.cards[card_index]
	local values = get_card_values_for_hand(card)

	for value in all(values) do
		current_values[card_index] = value
		evaluate_hand_recursive(player, card_index + 1, total + value, current_values, best_state)
	end
end

-- jokers are 0 in hand unless they were previously frozen by setting
function get_card_values_for_hand(card)
	if card.is_locked and card.locked_value ~= nil then
		return { card.locked_value }
	end

	if card.rank == 0 then
		return { 0 }
	end

	return card:get_values()
end

-- reveal a winning bot hand and freeze each card to the exact value used in the winning total
function reveal_winner_hand(player)
	local hand_state = evaluate_hand(player)
	for i = 1, #player.cards do
		player.cards[i].is_locked = true
		player.cards[i].locked_value = hand_state.values[i]
	end
end

-- pico-8 tables are references, so copy the chosen value set before returning it
function copy_values(values)
	local result = {}
	for i = 1, #values do
		result[i] = values[i]
	end
	return result
end

-- the first player whose hand total exactly matches crit wins immediately
function check_for_winner()
	for player in all(players) do
		if not player.is_out and get_hand_total(player) == player.crit then
			winner = player
			victory_timer = 90
			if not player.is_human then
				reveal_winner_hand(player)
			end
			set_message(player.name .. " wins", "center")
			return
		end
	end
end

-- eliminate players whose whole hand is locked but still misses crit
function check_for_eliminations()
	for player in all(players) do
		if not player.is_out and all_cards_locked(player) and get_hand_total(player) ~= player.crit then
			player.is_out = true
			set_message(player.name .. " is out", player.is_human and "normal" or "center")
		end
	end

	if count_active_players() <= 0 and winner == nil then
		game_over_text = "no winner"
		set_message(game_over_text, "center")
	end
end

-- true when every card in a hand has been set
function all_cards_locked(player)
	for i = 1, #player.cards do
		if not player.cards[i].is_locked then
			return false
		end
	end
	return true
end

-- count players who are still eligible to take turns
function count_active_players()
	local count = 0
	for player in all(players) do
		if not player.is_out then
			count += 1
		end
	end
	return count
end

-- move turn order forward until an active player is found
function get_next_active_player_index(current_index)
	local next_index = current_index
	for i = 1, #players do
		next_index += 1
		if next_index > #players then
			next_index = 1
		end
		if not players[next_index].is_out then
			return next_index
		end
	end
	return current_index
end

-- winner or no-winner elimination state both freeze the game until restart
function is_game_over()
	return winner ~= nil or game_over_text ~= nil
end

-- short on-screen status message shown near the footer
function set_message(text, style)
	message = text
	message_timer = 120
	message_style = style or "normal"
end

-- wrap selection cursors left/right through a fixed list size
function wrap_index(index, size)
	if size <= 0 then
		return 1
	end
	if index < 1 then
		return size
	elseif index > size then
		return 1
	end
	return index
end

-- draw the full game screen
function card_game_draw()
	cls(1)
	draw_header()
	draw_player_area(players[2])
	draw_player_area(players[3])
	draw_player_area(players[1])
	draw_footer()
	draw_center_status()
end

function card_game_finished()
	return is_game_over()
end

function card_game_won()
	return winner ~= nil and winner.is_human
end

-- top status bar
function draw_header()
	rectfill(0, 0, 127, 7, 0)
	print("poack", 2, 1, 7)
	print("deck " .. #deck, 90, 1, 6)
end

-- render one player's label, crit, optional sum, and hand
function draw_player_area(player)
	local text_x, text_y = get_player_text_pos(player)
	print(player.name, text_x, text_y, 7)
	print("crit " .. player.crit, text_x, text_y + 6, 10)

	if player.is_human then
		print("sum " .. get_hand_total(player), text_x, text_y + 12, 11)
		local option_text = get_selected_card_option_text(player)
		if option_text ~= nil then
			print(option_text, text_x, text_y + 18, 6)
		end
	elseif winner == player then
		print("sum " .. get_hand_total(player), text_x, text_y + 12, 8)
	end

	if player.is_out then
		print("out", text_x, text_y + 18, 8)
	end

	for i = 1, #player.cards do
		draw_card(player, i, player.cards[i])
	end
end

-- choose between face-up and hidden card rendering and draw selection highlights
function draw_card(player, index, card)
	local x, y = get_card_draw_pos(player, index)
	local is_selected = false
	local is_swap_target = false

	if player.is_human and turn_index == 1 and input_mode == "main" and selected_card == index and winner == nil then
		is_selected = true
	end

	if turn_index == 1 and input_mode == "swap_target" then
		local target = players[swap_player_index]
		local options = get_swap_candidate_indexes(target)
		if player == target and options[swap_target_index] == index then
			is_swap_target = true
		end
	end

	if is_selected or is_swap_target then
		rect(x - 1, y - 1, x + card_w, y + card_h, 9)
		rect(x - 2, y - 2, x + card_w + 1, y + card_h + 1, 10)
	end

	if player.is_human or card.is_locked then
		draw_card_face(x, y, card)
	else
		draw_card_back(x, y)
	end

	if card.is_locked then
		print("set", x + 5, y + 16, 8)
	end
end

-- keep labels separate from cards so the player's text never overlaps their hand
function get_player_text_pos(player)
	if player.is_human then
		return player.x, player.y
	end

	return player.x, player.y
end

-- show the selected card's possible values under the player's sum readout
function get_selected_card_option_text(player)
	if not player.is_human or input_mode ~= "main" then
		return nil
	end

	local card = player.cards[selected_card]
	if card == nil then
		return nil
	end

	if card.is_locked and card.locked_value ~= nil then
		return card:get_name() .. "=" .. card.locked_value
	elseif card.rank == 11 then
		return "j: 1 or 5"
	elseif card.rank == 12 then
		return "q: 2 or 6"
	elseif card.rank == 13 then
		return "k: 3 or 7"
	elseif card.rank == 0 then
		return "jk: 0/" .. player.last_set_value
	end

	return nil
end

-- lay out bot hands in a 2x2 grid and the player hand in a single row above the footer
function get_card_draw_pos(player, index)
	if player.is_human then
		return 46 + ((index - 1) * 19), 86
	end

	local col = (index - 1) % 2
	local row = flr((index - 1) / 2)
	return player.x + (col * 21), player.y + 18 + (row * 27)
end

-- copy a face card directly from the imported sprite sheet
function draw_card_face(x, y, card)
	local sx, sy = get_face_sprite_xy(card.rank)
	if sx ~= nil then
		sspr(sx, sy, card_w, card_h, x, y)
	else
		rectfill(x, y, x + card_w - 1, y + card_h - 1, 7)
		rect(x, y, x + card_w - 1, y + card_h - 1, 0)
		print(card:get_name(), x + 7, y + 8, 1)
	end
end

-- draw the shared hidden-card back sprite
function draw_card_back(x, y)
	sspr(back_sprite_x, back_sprite_y, card_w, card_h, x, y)
end

-- map rank values onto the two-row sprite layout described in the pitch
function get_face_sprite_xy(rank)
	if rank >= 1 and rank <= 7 then
		return face_sprite_x + ((rank - 1) * card_w), face_sprite_y
	elseif rank >= 8 and rank <= 13 then
		return face_sprite_x + ((rank - 8) * card_w), face_sprite_y + 24
	elseif rank == 0 then
		return face_sprite_x + (6 * card_w), face_sprite_y + 24
	end
	return nil, nil
end

-- draw bot actions and winner text in a centered banner
function draw_center_status()
	if winner ~= nil and victory_timer <= 0 then
		return
	end

	if winner == nil and game_over_text == nil and (message_timer <= 0 or message_style ~= "center") then
		return
	end

	local text = winner ~= nil and (winner.name .. " wins") or (game_over_text or message)
	rectfill(16, 46, 111, 69, 1)
	rect(16, 46, 111, 69, 7)
	rect(15, 45, 112, 70, 10)
	draw_large_center_text(text, 53, winner ~= nil and 11 or 7)
end

-- fake a larger font by layering the built-in font into a thicker centered title
function draw_large_center_text(text, y, color)
	local x = flr((128 - (#text * 4)) / 2)
	print(text, x - 1, y, 0)
	print(text, x + 1, y, 0)
	print(text, x, y - 1, 0)
	print(text, x, y + 1, 0)
	print(text, x, y, color)
	print(text, x, y + 8, color)
end

-- bottom ui with controls, turn info, win state, and messages
function draw_footer()
	rectfill(0, 112, 127, 127, 0)

	if is_game_over() then
		-- misc
	else
		if message_timer > 0 and message_style ~= "center" then
			print(message, 4, 114, 9)
		elseif message_style ~= "center" then
			print("turn " .. players[turn_index].name, 4, 114, 7)
		end
		if turn_index == 1 then
			if input_mode == "main" then
				print("l/r pick  o draw", 4, 121, 7)
				print("x swap  u/d set", 62, 121, 7)
			else
				print("pick " .. players[swap_player_index].name, 4, 121, 7)
				print("x next  o confirm", 62, 121, 7)
			end
		elseif message_style ~= "center" then
			print("bot turn", 62, 121, 6)
		end
	end
end
-->8
state_casino_locked = "casino_locked"
state_casino_open = "casino_open"
state_cards = "cards"
state_slots = "slots"
state_victory = "victory"

solid_tag = 0
cards_tag = 1
slots_tag = 2
door_tag = 3

casino_spawn_x = 8
casino_spawn_y = 16
casino_player_speed = 1
victory_map_x = 32
victory_map_y = 0
starting_balance = 1000
escape_balance = 3000
card_game_cost = 100
card_game_win_reward = 1000

casino_player = {
	money = starting_balance,
	x = casino_spawn_x,
	y = casino_spawn_y,
	w = 8,
	h = 8,
	spr = 119
}

game_state = state_casino_locked
active_minigame = nil
casino_status_text = ""

function _init()
	init_casino_state()
end

function init_casino_state()
	casino_player.money = starting_balance
	casino_player.x = casino_spawn_x
	casino_player.y = casino_spawn_y
	casino_player.spr = 119
	active_minigame = nil
	casino_status_text = ""
	refresh_casino_state()
end

function refresh_casino_state()
	if casino_player.money >= escape_balance then
		game_state = state_casino_open
	else
		game_state = state_casino_locked
	end
end

function _update()
	if game_state == state_casino_locked or game_state == state_casino_open then
		update_casino()
	elseif game_state == state_cards then
		card_game_update()
		if card_game_finished() and btnp(5) then
			finish_minigame("cards", card_game_won())
		end
	elseif game_state == state_slots then
		slots_game_update()
		if slots_game_finished() then
			finish_minigame("slots", slots_game_won())
		end
	elseif game_state == state_victory then
		update_victory()
	end
end

function _draw()
	if game_state == state_casino_locked or game_state == state_casino_open then
		draw_casino()
	elseif game_state == state_cards then
		card_game_draw()
		if card_game_finished() then
			print("press x to return", 26, 120, 7)
		end
	elseif game_state == state_slots then
		slots_game_draw()
	elseif game_state == state_victory then
		draw_victory()
	end
end

function update_casino()
	local dx = 0
	local dy = 0

	if btn(0) then
		dx -= casino_player_speed
	elseif btn(1) then
		dx += casino_player_speed
	end

	if btn(2) then
		dy -= casino_player_speed
	elseif btn(3) then
		dy += casino_player_speed
	end

	move_casino_player(dx, dy)
	update_casino_player_animation(dx, dy)
	check_casino_trigger()
end

function draw_casino()
	cls(0)
	map(0, 0, 0, 0, 16, 16)
	spr(casino_player.spr, casino_player.x, casino_player.y)
	print("$" .. casino_player.money, 88, 4, 11)

	if game_state == state_casino_open then
		print("touch the door tile", 50, 120, 11)
	else
		print("reach $" .. escape_balance .. " to escape", 28, 120, 6)
	end

	if casino_status_text != "" then
		print(casino_status_text, 22, 112, 11)
	end
end

function completion_text(done)
	if done then
		return "win"
	end
	return "--"
end

function move_casino_player(dx, dy)
	if game_state == state_victory then
		return
	end

	if dx != 0 then
		local next_x = casino_player.x + dx
		if not casino_hits_solid(next_x, casino_player.y) then
			casino_player.x = next_x
		end
	end

	if dy != 0 then
		local next_y = casino_player.y + dy
		if not casino_hits_solid(casino_player.x, next_y) then
			casino_player.y = next_y
		end
	end

	casino_player.x = mid(0, casino_player.x, 120)
	casino_player.y = mid(0, casino_player.y, 120)
end

-- 103 up sprite, 118 left sprite, 120 right sprite, 135 down sprite
function update_casino_player_animation(dx, dy)
	if dx == 0 and dy == 0 then
		casino_player.spr = 119
		return
	end

	casino_player.spr = 119

	if dy < 0 then
		casino_player.spr -= 16
	elseif dy > 0 then
		casino_player.spr += 16
	elseif dx < 0 then
		casino_player.spr -= 1
	elseif dx > 0 then
		casino_player.spr += 1
	end
end

function casino_hits_solid(px, py)
	return casino_point_has_flag(px, py, solid_tag)
			or casino_point_has_flag(px + casino_player.w - 1, py, solid_tag)
			or casino_point_has_flag(px, py + casino_player.h - 1, solid_tag)
			or casino_point_has_flag(px + casino_player.w - 1, py + casino_player.h - 1, solid_tag)
end

function check_casino_trigger()
	if game_state == state_casino_open and casino_body_has_flag(door_tag) then
		enter_victory()
		return
	end

	if casino_body_has_flag(cards_tag) then
		enter_minigame("cards")
		return
	end

	if casino_body_has_flag(slots_tag) then
		enter_minigame("slots")
		return
	end

end

function casino_body_has_flag(flag)
	return casino_point_has_flag(casino_player.x, casino_player.y, flag)
			or casino_point_has_flag(casino_player.x + casino_player.w - 1, casino_player.y, flag)
			or casino_point_has_flag(casino_player.x, casino_player.y + casino_player.h - 1, flag)
			or casino_point_has_flag(casino_player.x + casino_player.w - 1, casino_player.y + casino_player.h - 1, flag)
end

function casino_point_has_flag(px, py, flag)
	local tx = flr(px / 8)
	local ty = flr(py / 8)
	local tile = mget(tx, ty)
	return fget(tile, flag)
end

function enter_minigame(game_id)
	if game_id == "cards" then
		if casino_player.money < card_game_cost then
			casino_status_text = "need $" .. card_game_cost .. " for cards"
			return
		end
		casino_player.money -= card_game_cost
		active_minigame = game_id
		start_card_game()
		game_state = state_cards
	elseif game_id == "slots" then
		if casino_player.money < cost_to_play then
			casino_status_text = "need $" .. cost_to_play .. " for slots"
			return
		end
		active_minigame = game_id
		start_slots_game()
		game_state = state_slots
	end
end

function finish_minigame(game_id, did_win)
	if game_id == "cards" and did_win then
		casino_player.money += card_game_win_reward
	end

	active_minigame = nil
	casino_player.x = casino_spawn_x
	casino_player.y = casino_spawn_y
	casino_player.spr = 119
	refresh_casino_state()
end

function enter_victory()
	game_state = state_victory
	casino_player.x = 32
	casino_player.y = casino_spawn_y
	casino_player.spr = 119
	casino_status_text = "you escaped the casino!"
end

function update_victory()
	if btnp(5) then
		init_casino_state()
	end
end

function draw_victory()
	cls(0)
	map(victory_map_x, victory_map_y, 0, 0, 16, 16)
	spr(casino_player.spr, casino_player.x, casino_player.y)
	print("you escaped!", 36, 8, 11)
	print("x restart", 42, 120, 7)
end

-->8
cost_to_play = 10

slots_map_x = 16
slots_map_y = 0
slots_map_w = 16
slots_map_h = 16
slots_spin_timer = 0
slots_spin_frames = 30

slot_a_value = nil
slot_b_value = nil
slot_c_value = nil
slots_last_payout = 0
slots_total_winnings = 0
slots_last_result_text = ""
slots_session_won = false
slots_exit_requested = false

-- sound
slots_sfx_channel = 0
queued_slots_sfx = {}

-- 8x16 per slot icon
-- 3x3 slot icon grid to represnt one of three rolls
slot_card_width = 8
slot_card_height = 16
slot_grid_start_x = 17
slot_grid_start_y = 24
slot_reel_spacing = 24
slot_repeat_cols = 3
slot_repeat_rows = 3

-- (29,3) to (30,6) is bounding box for slot lever, holds
-- we animate it down by switchnig the top and bottom sprites
-- 131 132 147 148 is down sprite one
-- 133 134 149 50 is down sprite two
-- new: lever map bounds and simple pull-down animation settings
lever_map_x = 29
lever_map_y = 3
lever_w = 2
lever_h = 4
lever_pull_frames = 6
lever_up_tiles = nil
lever_down_tiles = {
	{ 133, 134 },
	{ 149, 150 },
	{ 131, 132 },
	{ 147, 148 }
}

reels = { 1, 2, 3 }

-- plus 16 to get the lower half of the sprite
slot_symbols = {
	banana = {
		name = "banana",
		spr = 192,
		value = 2,
		weight = 14
	},
	seven = {
		name = "seven",
		spr = 193,
		value = 12,
		weight = 5
	},
	diamond = {
		name = "diamond",
		spr = 194,
		value = 5,
		weight = 9
	},
	cherry = {
		name = "cherry",
		spr = 195,
		value = 3,
		weight = 13
	},
	orange = {
		name = "orange",
		spr = 196,
		value = 3,
		weight = 13
	},
	barone = {
		name = "bar one",
		spr = 197,
		value = 1,
		weight = 14
	},
	bartwo = {
		name = "bar two",
		spr = 198,
		value = 5,
		weight = 8
	},
	barthree = {
		name = "bar three",
		spr = 199,
		value = 10,
		weight = 5
	},
	sans = {
		name = "sans",
		spr = 200,
		value = 50,
		weight = 1
	},
	sus1 = {
		name = 'red sus',
		spr = 201,
		value = 1,
		weight = 8
	},
	sus2 = {
		name = 'green sus',
		spr = 202,
		value = 2,
		weight = 8
	},
	sus3 = {
		name = 'yellow sus',
		spr = 203,
		value = 3,
		weight = 7
	},
	sus4 = {
		name = 'orange sus',
		spr = 204,
		value = 4,
		weight = 7
	},
	sus5 = {
		name = "pink sus",
		spr = 205,
		value = 5,
		weight = 6
	},
	sus6 = {
		name = "blue sus",
		spr = 206,
		value = 6,
		weight = 6
	},
	sus7 = {
		name = "white sus",
		spr = 207,
		value = 7,
		weight = 5
	},
	sus8 = {
		name = "purple sus",
		spr = 224,
		value = 8,
		weight = 5
	},
	sus9 = {
		name = "brown sus",
		spr = 225,
		value = 9,
		weight = 4
	},
	sus10 = {
		name = "teal sus",
		spr = 226,
		value = 10,
		weight = 4
	},
	sus11 = {
		name = "grey sus",
		spr = 227,
		value = 11,
		weight = 4
	}
}

slot_symbol_list = {
	slot_symbols.banana,
	slot_symbols.seven,
	slot_symbols.diamond,
	slot_symbols.cherry,
	slot_symbols.orange,
	slot_symbols.barone,
	slot_symbols.bartwo,
	slot_symbols.barthree,
	slot_symbols.sans,
	slot_symbols.sus1,
	slot_symbols.sus2,
	slot_symbols.sus3,
	slot_symbols.sus4,
	slot_symbols.sus5,
	slot_symbols.sus6,
	slot_symbols.sus7,
	slot_symbols.sus8,
	slot_symbols.sus9,
	slot_symbols.sus10,
	slot_symbols.sus11
}

function draw_slot_symbol(symbol, x, y)
	palt(0, false)
	spr(symbol.spr, x, y)
	spr(symbol.spr + 16, x, y + 8)
	palt()
end

function draw_reel(reel_index, screen_x, screen_y)
	local symbol = slot_symbol_list[reels[reel_index]]
	for row = 0, slot_repeat_rows - 1 do
		for col = 0, slot_repeat_cols - 1 do
			draw_slot_symbol(symbol, screen_x + (col * slot_card_width), screen_y + (row * slot_card_height))
		end
	end
end

function get_slot_symbol_weight(symbol)
	if symbol == nil or symbol.weight == nil or symbol.weight < 1 then
		return 1
	end
	return symbol.weight
end

function pick_weighted_symbol_index()
	local total_weight = 0

	for symbol in all(slot_symbol_list) do
		total_weight += get_slot_symbol_weight(symbol)
	end

	local roll = rnd(total_weight)
	local running_weight = 0

	for i = 1, #slot_symbol_list do
		running_weight += get_slot_symbol_weight(slot_symbol_list[i])
		if roll < running_weight then
			return i
		end
	end

	return #slot_symbol_list
end

function start_slots_game()
	slots_spin_timer = 0
	reels[1] = 1
	reels[2] = 2
	reels[3] = 3
	slot_a_value = reels[1]
	slot_b_value = reels[2]
	slot_c_value = reels[3]
	slots_last_payout = 0
	slots_total_winnings = 0
	slots_last_result_text = "press down to spin $" .. cost_to_play
	slots_session_won = false
	slots_exit_requested = false
	queued_slots_sfx = {}
	-- new: cache the lever's resting tiles once so they can be restored after each pull
	if lever_up_tiles == nil then
		cache_lever_up_tiles()
	end
end

-- if x pressed roll
function slots_game_update()
	update_slots_sfx_queue()

	if btnp(5) then
		slots_exit_requested = true
		return
	end

	if slots_spin_timer > 0 then
		slots_spin_timer -= 1
		reels[1] = pick_weighted_symbol_index()
		reels[2] = pick_weighted_symbol_index()
		reels[3] = pick_weighted_symbol_index()

		if slots_spin_timer == 0 then
			slot_a_value = reels[1]
			slot_b_value = reels[2]
			slot_c_value = reels[3]
			slots_last_payout = evaluate_slots_result()
			if slots_last_payout > 0 then
				casino_player.money += slots_last_payout
				slots_total_winnings += slots_last_payout
				slots_session_won = true
				slots_last_result_text = "won $" .. slots_last_payout .. " d=spin x=leave"
			else
				slots_last_result_text = "no payout d=spin x=leave"
			end
		end
		return
	end

	if btnp(3) then
		if casino_player.money < cost_to_play then
			slots_last_result_text = "need $" .. cost_to_play .. " x=leave"
			return
		end
		sfx(6)
		casino_player.money -= cost_to_play
		slots_spin_timer = slots_spin_frames
		slots_last_payout = 0
		slots_last_result_text = "spinning..."
	end
end

-- evaluate money won based on slot values
-- any combo of 3 sus guys equals a win, with payout based on each symbol's value added
-- sus1 + sus2 + sus3 = 1 + 2 + 3 = payout of 6
function evaluate_slots_result()
	local symbol_a = slot_symbol_list[slot_a_value]
	local symbol_b = slot_symbol_list[slot_b_value]
	local symbol_c = slot_symbol_list[slot_c_value]

	if symbol_a == nil or symbol_b == nil or symbol_c == nil then
		return 0
	end

	local all_match = slot_a_value == slot_b_value and slot_b_value == slot_c_value
	local all_sus = is_sus_symbol(symbol_a) and is_sus_symbol(symbol_b) and is_sus_symbol(symbol_c)

	if all_sus then
		play_slots_sfx_chain({ 10, 11 })
		return (symbol_a.value + symbol_b.value + symbol_c.value) * 5
	end

	if all_match and symbol_a == slot_symbols.sans then
		play_slots_sfx_chain({ 2, 3, 4, 5 })
		return symbol_a.value * 150
	end

	if all_match then
		sfx(1)
		return symbol_a.value * 100
	end

	return 0
end

function is_sus_symbol(symbol)
	return sub(symbol.name, -3) == "sus"
end

function play_slots_sfx_chain(sequence)
	if sequence == nil or #sequence <= 0 then
		return
	end

	sfx(sequence[1], slots_sfx_channel)
	queued_slots_sfx = {}
	for i = 2, #sequence do
		add(queued_slots_sfx, sequence[i])
	end
end

function update_slots_sfx_queue()
	if #queued_slots_sfx > 0 and stat(16 + slots_sfx_channel) == -1 then
		sfx(queued_slots_sfx[1], slots_sfx_channel)
		deli(queued_slots_sfx, 1)
	end
end

-- new: remember the original lever tiles from the map as the default "up" frame
function cache_lever_up_tiles()
	lever_up_tiles = {}
	for y = 0, lever_h - 1 do
		lever_up_tiles[y + 1] = {}
		for x = 0, lever_w - 1 do
			lever_up_tiles[y + 1][x + 1] = mget(lever_map_x + x, lever_map_y + y)
		end
	end
end

-- new: write one lever frame into the slots map before drawing it
function set_lever_frame(frame)
	for y = 1, lever_h do
		for x = 1, lever_w do
			mset(lever_map_x + x - 1, lever_map_y + y - 1, frame[y][x])
		end
	end
end

-- new: keep the lever down briefly at the start of a spin, then return it to the resting frame
function get_current_lever_frame()
	if slots_spin_timer > slots_spin_frames - lever_pull_frames then
		return lever_down_tiles
	end
	return lever_up_tiles
end

function slots_game_draw()
	-- new: swap the lever tiles before drawing the slot-machine map
	set_lever_frame(get_current_lever_frame())
	cls(0)
	map(slots_map_x, slots_map_y, 0, 0, slots_map_w, slots_map_h)
	draw_reel(1, slot_grid_start_x, slot_grid_start_y)
	draw_reel(2, slot_grid_start_x + slot_reel_spacing, slot_grid_start_y)
	draw_reel(3, slot_grid_start_x + (slot_reel_spacing * 2), slot_grid_start_y)
	print("$" .. casino_player.money, 88, 4, 11)
	print("d spin  x leave", 4, 112, 7)
	print(slots_last_result_text, 4, 120, 6)
end

function slots_game_finished()
	return slots_exit_requested
end

function slots_game_won()
	return slots_session_won
end

function get_slots_last_payout()
	return slots_last_payout
end

function get_slots_total_winnings()
	return slots_total_winnings
end
__gfx__
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000
00000000fddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddf00000000
00700700fd88dddddddddddffd88dddddddddddffd88dddddddddddffd88dddddddddddffd88dddddddddddffd88dddddddddddffd88dddddddddddf00000000
00077000fd8ddddddddddddffd8ddddddddddddffd8ddddddddddddffd8ddddddddddddffd8ddddddddddddffd8ddddddddddddffd8ddddddddddddf00000000
00077000fdddd5555ddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddf00000000
00700700fdddd5555ddddddffddddd5555dddddffddddddddddddddffdddd5ddddd5dddffddd55555555dddffdd555555555dddffddddddddddddddf00000000
00000000fdddddd55ddddddffddd5555555ddddffdddd555555ddddffddd55dddd55dddffdd555555555dddffdd555555555dddffddd555555555ddf00000000
00000000fdddddd55ddddddffdd55dd55555dddffddd55555555dddffddd55dddd55dddffdd55ddddddddddffdd55ddddddddddffddd555555555ddf00000000
00000000fdddddd55ddddddffdd55dddd555dddffddd55dddd55dddffddd55dddd55dddffdd55ddddddddddffdd55ddddddddddffddddddddd555ddf00000000
00000000fdddddd55ddddddffdd55ddddd55dddffddd5ddddd55dddffddd55dddd55dddffdd55ddddddddddffdd55ddddddddddffddddddddd555ddf00000000
00000000fdddddd55ddddddffddddddddd55dddffddddddddd55dddffddd55dddd55dddffdd55ddddddddddffdd55ddddddddddffddddddddd55dddf00000000
00000000fdddddd55ddddddffddddddddd5ddddffddddddddd55dddffddd55555555dddffdd55ddddddddddffdd5555555dddddffddddddddd55dddf00000000
00000000fdddddd55ddddddffdddddddd55ddddffdddddd55555dddffddd55555555dddffdd55555555ddddffdd555555555dddffdddddddd555dddf00000000
00000000fdddddd55ddddddffddddd5555dddddffddddd555555dddffddddddddd55dddffddd55555555dddffdd55ddd55555ddffdddddddd555dddf00000000
00000000fdddddd55ddddddffddd555ddddddddffddddddddd55dddffddddddddd55dddffddddddddd55dddffdd55ddddd555ddffddddddd555ddddf00000000
00000000fdddddd55ddddddffdd55ddddddddddffddddddddd55dddffddddddddd55dddffddddddddd55dddffdd555ddddd55ddffddddddd555ddddf00000000
00000000fdddd555555ddddffdd5dddddddddddffddddddddd55dddffddddddddd55dddffddddddddd55dddffdd555ddddd55ddffddddddd55dddddf00000000
00000000fdddd555555ddddffdd555555555dddffddddddddd55dddffddddddddd55dddffdd55ddddd55dddffddd55ddddd55ddffdddddd555dddddf00000000
00000000fddddddddddddddffdd555555555dddffdddd5555555dddffddddddddd55dddffdd555555555dddffddd555555555ddffdddddd555dddddf00000000
00000000fddddddddddddddffddddddddddddddffdddd555555ddddffddddddddd55dddffdd55555555ddddffddd555555555ddffdddddd55ddddddf00000000
00000000fdddddddddddd8dffdddddddddddd8dffdddddddddddd8dffdddddddddddd8dffdddddddddddd8dffdddddddddddd8dffdddddd55dddd8df00000000
00000000fddddddddddd88dffddddddddddd88dffddddddddddd88dffddddddddddd88dffddddddddddd88dffddddddddddd88dffddddddddddd88df00000000
00000000fddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddf00000000
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00000000
00000000fddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddf00000000
00000000fd88dddddddddddffd88dddddddddddffd88dddddddddddffd88dddddddddddffd88dddddddddddffd88dddddddddddffd88dddddddddddf00000000
00000000fd8ddddddddddddffd8ddddddddddddffd8ddddddddddddffd8ddddddddddddffd8ddddddddddddffd8ddddddddddddffd8ddddddddddddf00000000
00000000fddddddddddddddffddddd5555dddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddf00000000
00000000fddddd5555dddddffddd5555555ddddffddd5ddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddf00000000
00000000fddd55555555dddffdd55ddddd55dddffdd55ddd5555dddffdd555555555dddffddddd5555dddddffddd55ddd55ddddffddddddddddddddf00000000
00000000fdd55ddddd55dddffdd55dddddd55ddffddd5dd5dddd5ddffdddddd5dddddddffdddd5dddd5ddddffdddd5dddd5ddddffddd8ddddd8ddddf00000000
00000000fdd55dddddd55ddffdd55dddddd55ddffddd5dd5dddd5ddffdddddd5dddddddffddd5dddddd5dddffdddd5dddd5ddddffdd888ddd888dddf51111115
00000000fdd5ddddddd55ddffdd55dddddd55ddffddd5d5dddddd5dffdddddd5dddddddffddd5dddddd5dddffdddd5dddd5ddddffddd8ddddd8ddddf51111115
00000000fdd5ddddddd55ddffdd55dddddd55ddffddd5d5dddddd5dffdddddd5dddddddffdd5dddddddd5ddffdddd5ddd55ddddffddd8ddddd8ddddf51111115
00000000fddd5dddddd5dddffddd555dddd55ddffddd5d5dddddd5dffdddddd5dddddddffdd5dddddddd5ddffdddd5dd55dddddffdddddd8dddddddf51111115
00000000fddd55dddd55dddffddddd5555555ddffddd5d5dddddd5dffdddddd5dddddddffdd5dddddddd5ddffdddd5555ddddddffddddd888ddddddf51111115
00000000fddddd55555ddddffdddddddd555dddffddd5d5dddddd5dffdddddd5dddddddffdd5dddddddd5ddffdddd5555ddddddffddddd888ddddddf51111115
00000000fdddd555555ddddffddddddddd55dddffddd5d5dddddd5dffdddddd5dddddddffdd5dddd55dd5ddffdddd55dd55ddddffdddddd8dd88dddf51111115
00000000fddd55dddd55dddffdddddddd55ddddffddd5d5dddddd5dffdddddd5dddddddffddd5dddd555dddffdddd5dddd5ddddffd888dddd88d8ddf51111115
00000000fdd55dddddd5dddffdddddddd55ddddffddd5dd5dddd5ddffdddddd5dddddddffddd5ddddd55dddffdddd5dddd5ddddffd88d8888ddd8ddf11111111
00000000fdd5ddddddd5dddffddddddd555ddddffddd5dd5dddd5ddffdd55dd5dddddddffdddd5dddd555ddffdddd5dddd5ddddffdd88dddddd88ddf11111111
00000000fdd5ddddddd5dddffddddddd55dddddffddd5ddd5555dddffddd5555dddddddffddddd5555dd55dffddd55dddddddddffddd88dd8888dddf11111111
00000000fdd55ddddd55dddffdddddd55ddddddffdd555dddddddddffddddddddddddddffddddddddddddddffddddddddddddddffdddd8888ddddddf11111111
00000000fdd55555555dd8dffdddddd55dddd8dffdddddddddddd8dffdddddddddddd8dffdddddddddddd8dffdddddddddddd8dffdddddddddddd8df11111111
00000000fddd55555ddd88dffddddddddddd88dffddddddddddd88dffddddddddddd88dffddddddddddd88dffddddddddddd88dffddddddddddd88df11111111
00000000fddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddffddddddddddddddf11111111
00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff11111115
00000000ffffffffffffffff22220000222200002222000051111115044444400000000011111111222666666666666666666666666660001111111111111111
00000000fddddddddddddddf2222000022288888888880005111111544ffff440000000011111111226555555555555555555555555555001111111111111111
00000000fddddddddddddddf22220000222899a9aa998000511111154f5ff5f40000000011111111265555555555555555555555555555501111111111111111
00000000fd5ddddddddd5ddf2222000022289a9a9a9a800051111115fff44fff0000000011111111655533333333333733333333333355551166666666666611
00000000fddddd555ddddddf000022220002222222222222511111150ffffff00000000011111111555333333333733733333333333335551677777777777761
00000000fdddd55555dddddf00002222000099999999222251111115f8d8d8df0000000011111111555333333333733333333333333335551155555555555511
00000000fdddd55555dddddf000022220088888888888822511111150d8d8d800000000011111111555773333333333333333333333775551111111111111111
00000000fdddd55555dddddf000022220089aaaaaaaa982251111115010000100000000011111111555333873333333333333333783335555555555555555555
00000000fdddd55555dddddf11111111228977a77a77980004444400044444400044444055555555555773783333333333333333873775555dddddd55dddddd5
00000000fdd555555555dddf11111111228988a88a88980044444440444444440444444400000000555333333333333333333333333335555dddddd55dddddd5
00000000fd55555555555ddf11111111228978a78a7898004fffff404ffffff404fffff40000000055533373333333333373333333333555566666d55dd66665
00000000fd55555555555ddf11111111228927a27a27980005ff5ff0ff5ff5ff0ff5ff5000000000556333773373333733733337333335555666666556666665
00000000fd55555555555ddf111111110089aaaaaaaa98220f44ff000ff44ff000ff44f000000000555633373373333733333337333365555666666556666665
00000000fdd555555555dddf111111110022222222222222fd8d8df0f8d8d8df0fd8d8df00000000055566666666666666666666666655525666655555566665
00000000fdddd55555dddddf111111110003bb5555bb322208d8d8000d8d8d80008d8d8000000000005555555555555555555555555555225666666556666665
00000000fdddd55555dddddf55555555000333333333322210000010010000100100000100000000000555555555555555555555555552225666666556666665
00000000fdddd55555dddddf99999544445999999999999999999999044444409999999999999999999999999999999999999999999999990000000000000000
00000000fdddd55555dddddf99999544445999999999999999999999444444449999999999999999999999999999999999999999999999990000000000000000
00000000fdddd55555dddddf999995444459999999999999999999994ffffff49999999999999999999999999999999999999999999999990000000000000000
00000000fddddd555ddddddf99999544445999999999999999999999ffffffff9999999999999999999999999999999999999999999999990000000000000000
00000000fd5ddddddddddddf994444444444449999999999999999990f5ff5f09995555555555555555555555555555555555555555559990000000000000000
00000000fdddddddddddd5df99444444444444999999995555999999fff44fff9950000000000000000000000000000000000000000005990000000000000000
00000000fddddddddddddddf994444444444449999999500005999990d8d8d809950000000000000000000000000000000000000000005990000000000000000
00000000ffffffffffffffff99000000000000999999950000599999010000109950000000000000000000000000000000000000000005990000000000000000
00000000000000000000000099999500005999999999950000599999000000009950000000000000000000000000000000000000000005990000000000000000
00000000000000000000000099999500005999999999954004599999000000009950000000000000000000000000000000000000000005990000000000000000
00000000000000000000000099999500005999999999950004599999000000009950000000000000000000000000000000000000000005990000000000000000
00000000000000000000000099999955559999999999954040599999000000009995555555555555555555555555555555555555555559990000000000000000
00000000000000000000000099999999999999999999950440599999000000009999999999999999999999999999999999999999999999990000000000000000
00000000000000000000000099999999999999999999954444599999000000009999999999999999999999999999999999999999999999990000000000000000
00000000000000000000000099999999999999999999954444599999000000009999999999999999999999999999999999999999999999990000000000000000
00000000000000000000000099999999999999999999954444599999000000009999999999999999999999999999999999999999999999990000000000000000
00000000000000000000000033333333000000009999999988889888222822221111111188888888999989992222222200000050000000000000000000000000
00000000000000000000000033333333000000009999999988888898822222821111111188882888999999992222222200000000000000000000000000000000
00000000000000000000000033333333000000009999999998988888222228221111111182888888989999992222222205000000000000000000000000000000
00000000000000000000000033333333000000009999999988988998288282821111111188888888999989982222222200005000000000000000000000000000
00000000000000000000000033333333000000009999999999899889828828881112121188888828999999992222822200000005000000000000000000000000
00000000000000000000000033333333000000009999999998989999882888822121211282888888998999992222222200000000000000000000000000000000
00000000000000000000000033333333000000009999999999999989288888882212212188888888999999992822222200500000000000000000000000000000
00000000000000000000000033333333000000009999999999899999888828821221221288888888999999992222222800000000000000000000000000000000
000000000000000000000000aaaaaaaaaaaaaaaa999a999988888888222222221221212199999999888888885555555555050000000000000000000000000000
000000000000000000000000aaaaaaaaaaaaaaaaa9999a9988888888222222222212221299999999888888885555555055000000000000000000000000000000
000000000000000000000000aa0000aaaaaaaaaa99a999a9888888882222222222221222999999a9888888880500500550005000000000000000000000000000
000000000000000000000000aa7070aaaaaaaaaaaa9aa99a888888882222222221212221a9999999898888885050005500000000000000000000000000000000
000000000000000000000000aa0000aaaaaaaaaa99a9aaa9888888882222222222222122999a9999888889880005050005000000000000000000000000000000
000000000000000000000000a000000aaaaaaaaa9aa9a9aa88888888222222222222222299999999889888885000000000000000000000000000000000000000
000000000000000000000000aa0000aaaaaaaaaaaaaaaaaa88888888222222222212222299a99a99888888980050005000000500000000000000000000000000
000000000000000000000000aa0aa0aaaaaaaaaaaa9aaa9a888888882222222222222222a999999a988888880000000000500000000000000000000000000000
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
57777775577777755777777557777775577777755777777557777775577777755777777557777775577777755777777557777775577777755777777557777775
57777775577777755777777557777775577777755777777557777775577777755700007557777775577777755777777557777775577777755777777557777775
57744775588888255777777557b77775577777755777777557777775500000055077770557700075577000755770007557700075577000755770007557700075
57a47775588888255777777557737b3557777b7557777775500000055000000550577c0557088805570bbb05570aaa0557099905570eee05570ccc0557077705
5aa7777558278825577777755777b375577737755777777550000005500000055707707557000005570000055700000557000005570000055700000557000005
59a977755777882557cccc755788387557999975577777755000000557777775507557055080cc0550b0cc0550a0cc055090cc0550e0cc0550c0cc055070cc05
59aa7775577788255c7cccc55888882559aa9995500000055777777550000005570000755088000550bb000550aa00055099000550ee000550cc000550770005
599aa775577882755cccccc55888882559a9999550000005500000055000000550c0cc055088880550bbbb0550aaaa055099990550eeee0550cccc0550777705
5999a7755778827557cccc75528882255999994550000005500000055000000550c0cc055088880550bbbb0550aaaa055099990550eeee0550cccc0550777705
57999a7557888275577cc775522222255799447557777775500000055777777550c0cc0550088805500bbb05500aaa0550099905500eee05500ccc0550077705
57799945578827755777777557222275577777755777777557777775500000055000000557080805570b0b05570a0a0557090905570e0e05570c0c0557070705
57777775578827755777777557777775577777755777777557777775500000055700007557007005570070055700700557007005570070055700700557007005
57777775577777755777777557777775577777755777777557777775500000055700007557777775577777755777777557777775577777755777777557777775
57777775577777755777777557777775577777755777777557777775577777755667766557777775577777755777777557777775577777755777777557777775
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
55555555555555555555555555555555999999959999999959999999999999959999999999999544445999999999999999999999000000000000000000000000
57777775577777755777777557777775999999959999999999999999999999999999999999999544445999999999999999999999000000000000000000000000
57777775577777755777777557777775999999959999999999999999999999999999999999999544445999999999999999999999000000000000000000000000
57700075577000755770007557700075999999959999999999999999999999999999999999999504405999999999999999999999000000000000000000000000
57022205570444055701110557055505999999959999999999999999999999999999999999999540405999999999999999999999000000000000000000000000
57000005570000055700000557000005999999959999999999999999999999999999999999999504045999999999995555999999000000000000000000000000
5020cc055040cc055010cc055050cc05999999959999999999999999999999999999999999999500005999999999950000599999000000000000000000000000
50220005504400055011000550550005999999955555555599999999999999999999999999999504005999999999950000599999000000000000000000000000
50222205504444055011110550555505555555555999999999999999999999990000000099999500045999999999950000599999000000000000000000000000
50222205504444055011110550555505999999995999999999999999999999990000000099999500005999999944444444444499000000000000000000000000
50022205500444055001110550055505999999995999999999999999999999990000000099999500005999999944444444444499000000000000000000000000
57020205570404055701010557050505999999995999999999999999999999990000000099999955559999999944444444444499000000000000000000000000
57007005570070055700700557007005999999995999999999999999999999990000000099999999999999999900000000000099000000000000000000000000
57777775577777755777777557777775999999995999999999999999999999990000000099999999999999999999954444599999000000000000000000000000
57777775577777755777777557777775999999995999999999999999999999990000000099999999999999999999954444599999000000000000000000000000
55555555555555555555555555555555999999995999999959999999999999950000000099999999999999999999954444599999000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000010000000004040100000102020202080800000001040400040001020202020808
0000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4f6e6f6969696969696969696969694fe8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f7e7f7373737373737373737373734fe8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f63636363636363636363636363634fe8f7e5e5e5e5e5e5e5e5e5f6e8e8e8e8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f63636363636363636363636363634fe8e4c0c0c0c1c1c1c9c9c9f5e8ebece8a8a8a8a8a8a8a8a8a8a8a8a8a8a8a4a80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f636a6b6c6d6363646564656465634fe8e4d0d0d0d1d1d1d9d9d9f5e8fbfce8b8b8b8b8b8b8b8b8b8b8b8b8b8b8a4b80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f637a7b7c7d6363747574757475634fe8e4c0c0c0c1c1c1c9c9c9f5e8e9eae8abababababababababababababa4a4a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f63636363636363636363636363634fe8e4d0d0d0d1d1d1d9d9d9f5e8f9fae8a7a7a7a7a7a7a7a7a7a7a7a7a7a4a4a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f63636363636363636363636363634fe8e4c0c0c0c1c1c1c9c9c9f5e8e8e8e8a9a9a9a9a9a9a9a9a9a9a9a9a4a4a4a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f636a6b6c6d6363646564656465634fe8e4d0d0d0d1d1d1d9d9d9f5e8e8e8e8babababababababababababaa4a4a4a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f637a7b7c7d6363747574757475634fe8e7f4f4f4f4f4f4f4f4f4e6e8e8e8e8a6a6a6a6a6a6a6a6a6a6a6a6a4a4a4a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f63636363636363636363636363634fe8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8aaaaaaaaaaaaaaaaaaaaaaa4a4a4a4a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f63636363636363636363636363634fe8e888898a8b8a8b8a8b8de8e8e8e8e8b9b9b9b9b9b9b9b9b9b9b9a4a4a4a4a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f636a6b6c6d6363646564656465634fe8e898999a9b9a9b9a9b9de8e8e8e8e8b5b5b5b5b5b5b5b5b5b5b5a4a4a4a4a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f637a7b7c7d6363747574757475634fe8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8b4b4b4b4b4b3b4b4b4b4b4a4a4a4a4a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4f63636363636363636363636363634fe8e8e8e8e8e8e8e8e8e8e8e8e8e8e8e8bbbbbbbbbbbbbbbbbbbbbbbbbbbca4a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
79797979797979797979797979797979a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5a5acacacacacacacacacacacacaca4a4a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000a4a4a4a4a4a4a4a4a4a4a4a4a4a4a4a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00030000196500060018650006001865000600186500060018650006001865000600186500060018650006001865000600186500c600176500c60017650176000f65017600206501660008050006000855000600
000400000000024350283502b350303502135023350243502635000000293502a3502a3502c3502d3502e3502f350303500000000000323500000000000363500000000000000003a35000000000003e35000000
000800002645026400264501840032450034002d4502d4002d400004002c450134002b450134002945013400264501340029450004002b450004002445000400244500040026450004002d450004000040000400
000800002c450004002945000400264500040029450004002b450004002345000400234500040032450004002d450004002b4000040017450004002b450004002945000400264500040029450004002b45000400
00080000000002345000000234500000026450000002d4500000000000000002c450000002b450000002945000000264500000029450000002b45000000000000000000000000000000000000000000000000000
000800002345000000234500000026450000002d4500000000000000002c450000002b450000002945000000264500000029450000002b4500000000000000000000000000000000000000000000000000000000
010800001803300000000000000000000000000000000000180330000000000000000000000000000000000018033000000000000000000000000000000000001803300000000000000000000000000000000000
00040000273502a3502c3502d3502e3502e3502f350313502035021350233502435026350273502c3502c3502135024350253502835029350293502c3502d3501e35021350233502435026350273502c3502d350
000200003035030350303503335033350333503335033350333503335033350333503335033350333503335033350003000030000300003000030000300003000030000300003000030000300003000030000300
00060000180501b0501d0501e0501d0501b0501805000000000001705018050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002415027100271500010029150001002a15000100291500010027150001002415000100001002210022100221502615024150001000010000100271002415027100271500010029150001002a15000100
00100000291500010027150001002a150001000010000100001002a15029150271502a15029150271500010024150001000010000100001000010000100001000010000100001000010000100001000010000100
__music__
00 0a424344
00 0b424344
00 02424344
02 03424344
00 04424344
00 05424344


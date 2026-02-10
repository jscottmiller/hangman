class_name Main extends Node2D

const MAX_ROUNDS := 5
const MINIMUM_LETTERS := 5

@onready var animations := %Animations as AnimationPlayer
@onready var round_ui := %RoundUI as Control
@onready var results_ui := %ResultsUI as Control
@onready var round_label := %RoundLabel as Label
@onready var timer := %Timer as Label
@onready var round_timer := %RoundTimer as Timer
@onready var end_round_timer := %EndRoundTimer as Timer
@onready var word_container := %WordContainer as HBoxContainer
@onready var hangman_parts := %HangmanParts as Node2D
@onready var hangman_stand := %Stand as Sprite2D
@onready var hangman_head_alive := %HeadAlive as Sprite2D
@onready var hangman_head_dead := %HeadDead as Sprite2D
@onready var guesses_grid := %GuessesGrid as GridContainer
@onready var scores_grid := %ScoresGrid as GridContainer
@onready var results_grid := %ResultsGrid as GridContainer

var whitespace_re := RegEx.new()
var guess_re := RegEx.new()
var all_words: Array
var current_round = 1
var round_running = false
var player_scores = {}
var recent_guesses = []
var word: String
var guessed_letters := []
var revealed_letters := []
var incorrect_guesses := 0


func _ready() -> void:
	whitespace_re.compile("\\S+")
	guess_re.compile("[a-zA-Z]+")
	
	_read_word_list()
	_start_game()


func _process(delta: float) -> void:
	if round_timer.is_stopped():
		timer.text = "0:00"
		return
	
	var left := floori(round_timer.time_left)
	var sec := left % 60
	var min := left / 60
	
	timer.text = "{0}:{1}".format([min, "%02d" % sec])


func _read_word_list():
	all_words = []
	
	var file := FileAccess.open("res://Puzzles/common_words.txt", FileAccess.READ)
	while not file.eof_reached():
		var line := file.get_line()
		if line == "" or line.length() < MINIMUM_LETTERS:
			continue
		all_words.append(line.to_upper())
	file.close()


func _select_word() -> String:
	return all_words.pick_random()


func _start_game() -> void:
	animations.play("start game")
	
	_reset_game()
	_update_score_grid()
	_start_round()


func _end_game() -> void:
	animations.play("game over")	
	
	_update_results_grid()


func _start_round() -> void:
	_reset_round()
	_set_round_label()
	_layout_hangman()
	_layout_letters()
	_update_recent_guess_grid()


func _end_round() -> void:
	var win := _remaining_letter_count() == 0
	if win:
		animations.play("round win")
	else:
		animations.play("round loss")
	round_running = false
	round_timer.stop()
	end_round_timer.start()
	_reveal_letters(true)


func _next_round() -> void:
	current_round += 1
	_start_round()


func _reset_game() -> void:
	player_scores = {}
	current_round = 1


func _reset_round() -> void:
	word = _select_word()
	round_timer.start()
	recent_guesses = []
	guessed_letters = []
	revealed_letters = []
	incorrect_guesses = 0
	round_running = true


func _check_round_over() -> void:
	var over := _remaining_letter_count() == 0
	if over:
		_end_round()


func _set_round_label() -> void:
	round_label.text = "Round {0}".format([current_round])


func _layout_hangman() -> void:
	for c in hangman_parts.get_children():
		c.hide()
	hangman_head_dead.hide()


func _update_hangman(game_over: bool = false) -> void:
	if game_over:
		incorrect_guesses = hangman_parts.get_child_count()
	
	for i in incorrect_guesses:
		hangman_parts.get_child(i).show()
	
	if incorrect_guesses == hangman_parts.get_child_count():
		hangman_stand.hide()
		hangman_head_alive.hide()
		hangman_head_dead.show()
		_end_round()


func _layout_letters() -> void:
	for c in word_container.get_children():
		c.queue_free()
	
	for i in word.length():
		var letter_scene := preload("res://Scenes/Game/letter.tscn")
		var letter_ui = letter_scene.instantiate()
		word_container.add_child(letter_ui)


func _reveal_letters(game_over: bool) -> void:
	for i in word.length():
		var letter := word[i]
		var letter_ui := word_container.get_child(i) as Letter
		var revealed := letter in revealed_letters
		if revealed:
			letter_ui.reveal_letter(letter, true)
		elif game_over:
			letter_ui.reveal_letter(letter, false)


func _update_recent_guess_grid() -> void:
	for c in guesses_grid.get_children():
		c.queue_free()
	
	var rev_recent := recent_guesses.duplicate()
	rev_recent.reverse()
	
	for guess in rev_recent.slice(0, 10):
		var player_label := Label.new()
		player_label.text = guess.player
		player_label.custom_minimum_size.x = 300
		player_label.custom_minimum_size.y = 50
		
		var guess_label := Label.new()
		guess_label.text = guess.guess
		guess_label.custom_minimum_size.y = 50
		
		guesses_grid.add_child(player_label)
		guesses_grid.add_child(guess_label)


func _update_score_grid() -> void:
	for c in scores_grid.get_children():
		c.queue_free()
	
	var player_score_pairs := []
	for player in player_scores:
		player_score_pairs.append([player, player_scores[player]])
	
	player_score_pairs.sort_custom(func(a, b): return a[1] > b[1])
	for pair in player_score_pairs.slice(0, 10):
		var player_label := Label.new()
		player_label.text = pair[0]
		player_label.custom_minimum_size.x = 300
		player_label.custom_minimum_size.y = 50
		
		var score_label := Label.new()
		score_label.text = str(pair[1])
		score_label.custom_minimum_size.y = 50
		
		scores_grid.add_child(player_label)
		scores_grid.add_child(score_label)


func _update_results_grid() -> void:
	for c in results_grid.get_children():
		c.queue_free()
	
	var player_score_pairs := []
	for player in player_scores:
		player_score_pairs.append([player, player_scores[player]])
	
	player_score_pairs.sort_custom(func(a, b): return a[1] > b[1])
	for i in range(3):
		if i > player_score_pairs.size() - 1:
			continue
		
		var medal_label := Label.new()
		medal_label.text = {
			0: "🥇",
			1: "🥈",
			2: "🥉"
		}[i]
		medal_label.custom_minimum_size.x = 50
		medal_label.custom_minimum_size.y = 150
		medal_label.set("theme_override_font_sizes/font_size", 100)
		
		var player_label := Label.new()
		player_label.text = player_score_pairs[i][0]
		player_label.custom_minimum_size.y = 150
		player_label.set("theme_override_font_sizes/font_size", 100)
		
		results_grid.add_child(medal_label)
		results_grid.add_child(player_label)


func _on_round_timer_timeout() -> void:
	_update_hangman(true)
	_end_round()


func _on_end_round_timer_timeout() -> void:
	if current_round < MAX_ROUNDS:
		_next_round()
	else:
		_end_game()


func _on_twitch_chat_auth_failed() -> void:
	Auth.clear_token()
	get_tree().change_scene_to_file("res://Scenes/Game/menu.tscn")


func _on_twitch_chat_chat_message(sender: String, message: String) -> void:
	var parts := []
	for m in whitespace_re.search_all(message):
		parts.append(m.get_string())
	
	if parts.size() != 1:
		return
	
	if guess_re.search(parts[0]) == null:
		return
	
	var guess := parts[0].to_upper() as String
	if guess.length() == 1:
		_single_letter_guess(sender, guess)
	else:
		_word_guess(sender, guess)


func _single_letter_guess(player: String, letter: String) -> void:
	if not round_running or letter in revealed_letters or letter in guessed_letters:
		return
	
	recent_guesses.append({
		"player": player,
		"guess": letter
	})
	guessed_letters.append(letter)
	
	_update_recent_guess_grid()
	
	if player not in player_scores:
		player_scores[player] = 0
	
	if letter in word:
		revealed_letters.append(letter)
		player_scores[player] += 20 * _count_occurances(letter)
		animations.play("correct guess")
	else:
		incorrect_guesses += 1
		player_scores[player] -= 5
		animations.play("incorrect guess")

	_reveal_letters(false)
	_update_hangman()
	_update_score_grid()
	_check_round_over()


func _word_guess(player: String, word_guess: String) -> void:
	if not round_running:
		return
	
	recent_guesses.append({
		"player": player,
		"guess": word_guess
	})
	
	_update_recent_guess_grid()
	
	if player not in player_scores:
		player_scores[player] = 0

	var remaining_letters := _remaining_letter_count()
	
	if word_guess == word:
		_fill_remaining_letters()
		player_scores[player] += remaining_letters * 20 + 30
		animations.play("correct guess")
	else:
		incorrect_guesses += 1
		player_scores[player] -= remaining_letters * 5
		animations.play("incorrect guess")

	_reveal_letters(false)
	_update_hangman()
	_update_score_grid()
	_check_round_over()


func _remaining_letter_count() -> int:
	var unique_letters := {}
	for letter in word:
		unique_letters[letter] = true
	return unique_letters.size() - revealed_letters.size()


func _count_occurances(letter: String) -> int:
	var count := 0
	for l in word:
		if l == letter:
			count += 1
	return count


func _fill_remaining_letters() -> void:
	var unique_letters := {}
	for letter in word:
		unique_letters[letter] = true
	revealed_letters = unique_letters.keys()

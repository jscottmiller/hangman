class_name Letter extends Control

@onready var label := %Label as Label
@onready var animations := %Animations as AnimationPlayer

const CORRECT_COLOR := Color.GREEN
const INCORRECT_COLOR := Color.RED

var revealed := false


func _ready() -> void:
	label.hide()


func reveal_letter(letter: String, correct: bool) -> void:
	if revealed:
		return
	
	revealed = true
	label.text = letter.to_upper()
	var animation := "reveal_correct" if correct else "reveal_incorrect"
	animations.play(animation)

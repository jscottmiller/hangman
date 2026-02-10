class_name Menu extends Control

@onready var login_button := %LoginButton as Button
@onready var token_container := %TokenContainer as HBoxContainer
@onready var token_input := %TokenInput as TextEdit
@onready var logout_button := %LogoutButton as Button
@onready var channel_input := %ChannelInput as TextEdit
@onready var start_button := %StartButton as Button


func _ready() -> void:
	channel_input.text = Auth.channel_name
	_set_buttons()


func _set_buttons() -> void:
	var authed := Auth.is_authed()
	var channel_set := Auth.channel_name != ""
	
	token_container.hide()
	login_button.disabled = authed
	logout_button.disabled = !authed
	start_button.disabled = !authed or !channel_set


func _on_login_button_pressed() -> void:
	Auth.begin_grant_flow()
	token_container.show()


func _on_logout_button_pressed() -> void:
	Auth.clear_token()
	_set_buttons()


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Game/main.tscn")


func _on_save_token_button_pressed() -> void:
	Auth.access_token = token_input.text.strip_edges()
	_set_buttons()


func _on_channel_input_text_changed() -> void:
	Auth.channel_name = channel_input.text.strip_edges()
	_set_buttons()

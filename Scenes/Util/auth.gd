extends Node

const TWITCH_AUTH_URL := "https://id.twitch.tv/oauth2/authorize"
const AUTH_V1_FILE := "user://auth_v1.json"

var _access_token: String
var _channel_name: String


var access_token: String:
	get:
		if _access_token == "":
			_load()
		return _access_token
	set(value):
		_access_token = value
		_save()


var channel_name: String:
	get:
		if _channel_name == "":
			_load()
		return _channel_name
	set(value):
		_channel_name = value
		_save()


func is_authed() -> bool:
	return access_token != ""


func clear_token() -> void:
	access_token = ""


func begin_grant_flow() -> void:
	var params := _encode_params({
		"client_id": TwitchConfig.CLIENT_ID,
		"redirect_uri": TwitchConfig.REDIRECT_URL,
		"response_type": "token",
		"scope": "chat:read"
	})
	var redirect_url := TWITCH_AUTH_URL + params
	OS.shell_open(redirect_url)


func _encode_params(params: Dictionary) -> String:
	if params.size() == 0:
		return ""
		
	var encoded := "?"
	for key in params:
		var value := str(params[key])
		encoded += "{0}={1}&".format([key.uri_encode(), value.uri_encode()])
	return encoded.left(-1)


func _load() -> void:
	if !FileAccess.file_exists(AUTH_V1_FILE):
		return
	
	var f := FileAccess.open(AUTH_V1_FILE, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text()) as Dictionary
	
	if data == null:
		return
	
	var access_token = data.access_token as String
	if access_token:
		_access_token = access_token
	
	var channel_name = data.channel_name as String
	if channel_name:
		_channel_name = channel_name


func _save() -> void:
	var f := FileAccess.open(AUTH_V1_FILE, FileAccess.WRITE)
	f.store_string(JSON.stringify({
		"access_token": _access_token,
		"channel_name": _channel_name
	}))

class_name TwitchChat extends Node

signal auth_failed
signal chat_message

const TWITCH_AUTH_URL := "https://id.twitch.tv/oauth2/authorize"
const TWITCH_IRC_WS_URL := "wss://irc-ws.chat.twitch.tv:443"

@onready var ping_timer := %PingTimer as Timer
@onready var reconnect_timer := %ReconnectTimer as Timer

var username := ""
var access_token := ""
var twitch_client: WebSocketPeer
var initialized := false
var message_queue := []


func _ready() -> void:
	connect_to_twitch(Auth.channel_name, Auth.access_token)


func _process(delta: float) -> void:
	if twitch_client == null:
		return
	
	twitch_client.poll()
	
	var state = twitch_client.get_ready_state()
	match state:
		WebSocketPeer.STATE_OPEN:
			if not initialized:
				initialized = true
				ping_timer.start()
				_on_irc_connected()
			
			while message_queue.size():
				var message := message_queue.pop_front() as String
				twitch_client.send_text(message)
			
			while twitch_client.get_available_packet_count():
				var data := twitch_client.get_packet()
				var message := data.get_string_from_utf8()
				var parsed := _parse_message(message)
				if parsed.size() == 0:
					continue
				_on_irc_message(parsed)
		
		WebSocketPeer.STATE_CLOSED:
			var code := twitch_client.get_close_code()
			var reason := twitch_client.get_close_reason()
			print("socket closed with code: {0}, reason {1}. clean: {2}".format([code, reason, code != -1]))
			
			twitch_client.close()
			twitch_client = null
			if initialized:
				initialized = false
				ping_timer.stop()
				message_queue.clear()
			
			reconnect_timer.start()
			emit_signal("disconnected")


func connect_to_twitch(username: String, access_token: String) -> void:
	self.username = username	
	self.access_token = access_token
	
	twitch_client = WebSocketPeer.new()
	twitch_client.connect_to_url(TWITCH_IRC_WS_URL)


func _push_message(message: String, params: Array=[]) -> void:
	message_queue.append(message.format(params))


func _on_irc_connected() -> void:
	_push_message("CAP REQ :twitch.tv/membership twitch.tv/tags twitch.tv/commands")
	_push_message("PASS oauth:{0}", [access_token])
	_push_message("NICK {0}", [username])
	_push_message("JOIN #{0}", [username])


func _on_irc_message(message: Dictionary) -> void:
	match message.command.command:
		"NOTICE":
			if message.parameters == "Login authentication failed":
				emit_signal("auth_failed")
		"PRIVMSG":
			var sender := message.source.nick as String
			var text := message.parameters as String
			emit_signal("chat_message", sender, text)


func _parse_message(message: String) -> Dictionary:
	var raw_tags: String
	var raw_source: String
	var raw_command: String
	var raw_parameters: String
	
	var index := 0
	
	if message[index] == "@":
		var end := message.find(" ")
		raw_tags = message.substr(1, end - 1)
		index = end + 1
	
	if message[index] == ':':
		index += 1
		var end := message.find(" ", index)
		raw_source = message.substr(index, end - index)
		index = end + 1
	
	var end := message.find(":", index)
	if end == -1:
		end = message.length()
	
	raw_command = message.substr(index, end - index).strip_edges()
	
	if end != message.length():
		index = end + 1
		raw_parameters = message.substr(index).strip_edges()
		
	var parsed_command := _parse_command(raw_command)
	if parsed_command.size() == 0:
		return {}
	
	var parsed := {
		"command": parsed_command,
		"parameters": raw_parameters
	}
	
	if raw_source.find("!"):
		parsed.source = _parse_source(raw_source)
	
	if raw_parameters != "" and raw_parameters[0] == "!":
		parsed.command = _parse_parameters(raw_parameters, parsed.command)
	
	return parsed


func _parse_command(rawCommand: String) -> Dictionary:
	var parsed: Dictionary
	var parts := rawCommand.split(' ');

	match parts[0]:
		"JOIN", "PART", "NOTICE", "CLEARCHAT", "HOSTTARGET", "PRIVMSG":
			parsed = {
				"command": parts[0],
				"channel": parts[1]
			}
		"PING":
			parsed = {
				"command": parts[0]
			}
		"CAP":
			parsed = {
				"command": parts[0],
				"isCapRequestEnabled": (parts[2] == 'ACK')
			}
		"GLOBALUSERSTATE":
			parsed = {
				"command": parts[0]
			}             
		"USERSTATE", "ROOMSTATE":
			parsed = {
				"command": parts[0],
				"channel": parts[1]
			}
		"RECONNECT":
			parsed = {
				"command": parts[0]
			}
		"421":
			print("Unsupported IRC command: {2}".format(parts))
		"001":
			parsed = {
				"command": parts[0],
				"channel": parts[1]
			}
		"002", "003", "004", "353", "366", "372", "375", "376":
			print(parts)
			print("numeric message: {0}".format(parts))
		_:
			print("unexpected command: {0}".format([parts]))

	return parsed


func _parse_source(raw_source: String) -> Dictionary:
	var parts := raw_source.split('!');
	return {
		"nick": parts[0],
		"host": parts[1] if parts.size() == 2 else parts[0]
	}


func _parse_parameters(raw_params: String, command: Dictionary) -> Dictionary:
	var index := 0
	var commandParts := raw_params.substr(index+1).strip_edges()
	var params_idx = commandParts.find(' ')

	if -1 == params_idx:
		command.botCommand = commandParts.substr(0)
	else:
		command.botCommand = commandParts.substr(0, params_idx)
		command.botCommandParams = commandParts.substr(params_idx).strip_edges()

	return command


func _on_ping_timer_timeout() -> void:
	message_queue.append("PING :tmi.twitch.tv")

class_name LobbyManager
extends Node

signal all_peers_ready

var ready_peer_id: Array[int] = []
var is_lobby_closed: bool

#本来不用这个,但需要解决一种情况,例如3个人2个人按了R,第3个没按R,然后又掉线了,check_all_peer_ready()就会返回false就开始不了了
func _ready() -> void:
	if is_multiplayer_authority():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	if  multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		all_peers_ready.emit.call_deferred()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("lobby_ready"):
		#玩家按R键调用rpc
		request_peer_ready.rpc_id(MultiplayerPeer.TARGET_PEER_SERVER)
		get_viewport().set_input_as_handled()


func close_lobby():
	is_lobby_closed = true


@rpc("any_peer", "call_local", "reliable")
func request_peer_ready():
	if !is_multiplayer_authority() or is_lobby_closed:
		return
	
	var sender_id := multiplayer.get_remote_sender_id()
	if !ready_peer_id.has(sender_id):
		ready_peer_id.append(sender_id)
	
	try_all_peers_ready()


func try_all_peers_ready():
	if check_all_peer_ready():
		all_peers_ready.emit()


func check_all_peer_ready() -> bool:
	var all_peers := multiplayer.get_peers()
	all_peers.append(MultiplayerPeer.TARGET_PEER_SERVER)
	
	for peer_id in all_peers:
		if !ready_peer_id.has(peer_id):
			return false
	return true


func _on_peer_disconnected(peer_id: int):
	try_all_peers_ready()

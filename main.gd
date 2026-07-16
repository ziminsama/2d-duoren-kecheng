extends Node2D


func _ready() -> void:
	print("hello world peer_ready.rpc")
	peer_ready.rpc_id(1)


@rpc("any_peer","call_remote","reliable")
func peer_ready():
	print("peer %s ready" % multiplayer.get_remote_sender_id())
	

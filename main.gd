extends Node2D

var player_scene: PackedScene = preload("uid://c0k0voeng6qno")
var enemy_scene: PackedScene = preload("uid://ba8sru6tn6nvg")

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var player_spawn_position: Marker2D = $PlayerSpawnPosition


func _ready() -> void:
	#print("hello world peer_ready.rpc")
	multiplayer_spawner.spawn_function = func(data):
		var player = player_scene.instantiate() as Player
		player.name = str(data.peer_id)
		player.input_multiplayer_authority = data.peer_id
		player.global_position = player_spawn_position.global_position
		return player
	
	peer_ready.rpc_id(1)
	
	#if is_multiplayer_authority():
		#var enemy = enemy_scene.instantiate() as Node2D
		#enemy.global_position = Vector2.ONE * 200
		#add_child(enemy, true)
		#A20节加了enemy_manager后,在那里就加载敌人了,这里就不用这段脚本了


@rpc("any_peer","call_local","reliable")
func peer_ready():
	var sender_id = multiplayer.get_remote_sender_id()
	multiplayer_spawner.spawn({"peer_id": sender_id})

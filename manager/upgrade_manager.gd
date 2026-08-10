extends Node

@export var enemy_manager: EnemyManager #挂载会发出round_completed的EnemyManager
@export var spawn_position: Node2D
@export var spawn_root: Node
@export var available_upgrades: Array[UpgradeResource] #UpgradeResource就是新建的自定义资源

var upgrade_option_scene: PackedScene = preload("uid://c416xr6lgku2v")


func _ready() -> void:
	enemy_manager.round_completed.connect(_on_round_completed)


func generate_upgrade_option():
	var connected_peer_ids := multiplayer.get_peers()
	connected_peer_ids.append(MultiplayerPeer.TARGET_PEER_SERVER)
	for connected_peer_id in connected_peer_ids:
		var selected_upgrades := [
			available_upgrades[0].id, 
			available_upgrades[0].id, 
			available_upgrades[0].id
		]
		set_upgrade_options.rpc_id(connected_peer_id, selected_upgrades) #这个是服务端调用,服务端给每个客户端选


func show_upgrade_resources(upgrade_resources: Array[UpgradeResource]):
	var initial_x = -64
	var x_difference = 64
	
	for i in range(upgrade_resources.size()):
		var upgrade_option: UpgradeOption = upgrade_option_scene.instantiate()
		upgrade_option.global_position = spawn_position.global_position
		
		upgrade_option.global_position += Vector2.RIGHT * (initial_x + x_difference * i)
		
		spawn_root.add_child(upgrade_option)


@rpc("authority", "call_local", "reliable")
func set_upgrade_options(upgrades_ids: Array): #客户端接收的是升级资源的id,需要把id转化成资源,再调用show_upgrade_resources
	var upgrade_resources: Array[UpgradeResource] = []
	for upgrades_id in upgrades_ids:
		#这里是用了回调函数find_custom
		var resource_index: int = available_upgrades.find_custom(func (item: UpgradeResource):
			return item.id == upgrades_id
		)
		upgrade_resources.append(available_upgrades[resource_index])
	
	show_upgrade_resources(upgrade_resources)


func _on_round_completed():
	generate_upgrade_option()

class_name UpgradeManager
extends Node

signal upgrades_completed

@export var enemy_manager: EnemyManager #挂载会发出round_completed的EnemyManager
@export var spawn_position: Node2D
@export var spawn_root: Node
@export var available_upgrades: Array[UpgradeResource] #UpgradeResource就是新建的自定义资源

static var instance: UpgradeManager

var upgrade_option_scene: PackedScene = preload("uid://c416xr6lgku2v")
#godot暂时不支持字典存自定义数组,无法使用下面的方法
#var peer_id_upgrade_options: Dictionary[int, Array[UpgradeResource]]
var peer_id_to_upgrade_options: Dictionary[int, Array] = {}
var peer_id_to_upgrades_acquired: Dictionary[int, Dictionary] = {} #嵌套的字典无法加类型,不知道版本更新行不行
var outstanding_peers_to_upgrade: Array[int] = []


static func get_peer_upgrade_count(peer_id: int, upgrade_id: String) -> int:
	if !is_instance_valid(instance):
		return 0
	
	if !instance.peer_id_to_upgrades_acquired.has(peer_id):
		return 0
	
	if !instance.peer_id_to_upgrades_acquired[peer_id].has(upgrade_id):
		return 0
	
	return instance.peer_id_to_upgrades_acquired[peer_id][upgrade_id]


static func peer_has_upgrade(peer_id:int, upgrade_id: String) -> bool:
	return get_peer_upgrade_count(peer_id, upgrade_id) > 0


func _ready() -> void:
	instance = self #把instance指向self,就是指向节点本身
	enemy_manager.round_completed.connect(_on_round_completed)
	
	if is_multiplayer_authority():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

#做随机升级资源，简单粗暴方法，打乱数组取前三个，费不了多少资源；但更常见做法是用战利品表。这里不讲战利品表，只讲简单粗暴方法
func generate_upgrade_option():
	peer_id_to_upgrade_options.clear()
	var connected_peer_ids := multiplayer.get_peers()
	connected_peer_ids.append(MultiplayerPeer.TARGET_PEER_SERVER)
	for connected_peer_id in connected_peer_ids:
		outstanding_peers_to_upgrade.append(connected_peer_id)
		
		var available_upgrades_copy := Array(available_upgrades)
		available_upgrades_copy.shuffle()
		
		var chosen_upgrades := available_upgrades_copy.slice(0,3)
		peer_id_to_upgrade_options[connected_peer_id] = chosen_upgrades

		
		var upgrade_options := create_upgrade_option_nodes(chosen_upgrades)
		var selected_upgrades: Array = []
		for i in upgrade_options.size():
			var upgrade_option := upgrade_options[i]
			var upgrade_resource := chosen_upgrades[i] as UpgradeResource
			upgrade_option.set_peer_id_filter(connected_peer_id)
			var uid :=ResourceUID.create_id()
			upgrade_option.name = str(uid)
			
			selected_upgrades.append({
				"name": upgrade_option.name,
				"id": upgrade_resource.id
			})
			
			upgrade_option.visible = connected_peer_id == MultiplayerPeer.TARGET_PEER_SERVER
		
		if connected_peer_id != MultiplayerPeer.TARGET_PEER_SERVER:
			set_upgrade_options.rpc_id(connected_peer_id, selected_upgrades) 


func create_upgrade_option_nodes(upgrade_resources: Array[UpgradeResource])-> Array[UpgradeOption]:
	var result: Array[UpgradeOption] = []
	var initial_x = -64
	var x_difference = 64
	
	for i in range(upgrade_resources.size()):
		var upgrade_option: UpgradeOption = upgrade_option_scene.instantiate()
		upgrade_option.set_upgrade_index(i)
		upgrade_option.set_upgrade_resource(upgrade_resources[i])
		
		upgrade_option.global_position = spawn_position.global_position
		upgrade_option.global_position += Vector2.RIGHT * (initial_x + x_difference * i)
		spawn_root.add_child(upgrade_option)
		upgrade_option.play_in(i * .1)
		
		upgrade_option.selected.connect(_on_upgrade_option_selected)
		result.append(upgrade_option)
	
	return result


@rpc("authority", "call_local", "reliable")
func set_upgrade_options(selected_upgrades: Array): #客户端接收的是升级资源的id,需要把id转化成资源,再调用show_upgrade_resources
	var upgrade_resources: Array[UpgradeResource] = []
	for upgrade in selected_upgrades:
		var resource_index: int = available_upgrades.find_custom(func (item: UpgradeResource):
			return item.id == upgrade.id
		)
		upgrade_resources.append(available_upgrades[resource_index])
	
	var created_nodes := create_upgrade_option_nodes(upgrade_resources)
	for i in created_nodes.size():
		created_nodes[i].name = selected_upgrades[i].name


func handle_upgrade_selected(upgrade_index: int, for_peer_id: int):
	if !peer_id_to_upgrades_acquired.has(for_peer_id):
		peer_id_to_upgrades_acquired[for_peer_id] = {}
	
	var upgrade_dictionary: Dictionary = peer_id_to_upgrades_acquired[for_peer_id] #把键for_peer_id的值是一个数组,赋给了upgrade_dictionary
	var chosen_upgrade = peer_id_to_upgrade_options[for_peer_id][upgrade_index] #取字典中键for_peer_id的值,是数组,再取数组中键upgrade_index的值
	
	var upgrade_count: int = 0
	if upgrade_dictionary.has(chosen_upgrade.id):
		upgrade_count = upgrade_dictionary[chosen_upgrade.id]
	
	upgrade_dictionary[chosen_upgrade.id] = upgrade_count + 1
	
	outstanding_peers_to_upgrade.erase(for_peer_id)
	
	print("Peer %s has selected upgrade with id %s" %[
		for_peer_id, 
		peer_id_to_upgrade_options[for_peer_id][upgrade_index].id
	])
	
	check_upgrades_complete()


func check_upgrades_complete():
	if outstanding_peers_to_upgrade.size() > 0:
		return
	
	upgrades_completed.emit()


func _on_round_completed():
	generate_upgrade_option()


func _on_upgrade_option_selected(upgrade_index: int, for_peer_id: int):
	handle_upgrade_selected(upgrade_index, for_peer_id)


func _on_peer_disconnected(peer_id: int):
	if outstanding_peers_to_upgrade.has(peer_id):
		outstanding_peers_to_upgrade.erase(peer_id)
		check_upgrades_complete()

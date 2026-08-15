class_name Player
extends CharacterBody2D

signal died

const BASE_MOVEMENT_SPEED: float = 100
const BASE_FIRE_RATE: float = .25
const BASE_BULLET_DAMAGE: int = 1

@onready var player_input_synchronizer_component: PlayerInputSynchronizerComponent = $PlayerInputSynchronizerComponent
@onready var weapon_root: Node2D = $Visuals/WeaponRoot
@onready var fire_rate_timer: Timer = $FireRateTimer
@onready var health_component: HealthComponent = $HealthComponent
@onready var visuals: Node2D = $Visuals
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var barrel_position: Marker2D = %BarrelPosition
@onready var display_name_label: Label = $DisplayNameLabel

var bullet_scene: PackedScene = preload("uid://jlap4yf3gf0i")
var muzzle_flash_scene: PackedScene = preload("uid://cnxo8p5hrj6tv")
var input_multiplayer_authority: int
var is_dying: bool
var is_respawn: bool
var display_name: String


func _ready() -> void:
	player_input_synchronizer_component.set_multiplayer_authority(input_multiplayer_authority)
	
	var is_single_player = multiplayer.multiplayer_peer is OfflineMultiplayerPeer
	var is_client_authority = player_input_synchronizer_component.is_multiplayer_authority()
	
	if is_single_player or is_client_authority:
		display_name_label.visible = false
	
	display_name_label.text = display_name
	
	if is_multiplayer_authority():
		if is_respawn:
			health_component.current_health = 1
		health_component.died.connect(_on_died)
#func _input(event: InputEvent) -> void:
	#if event.is_action_pressed("attack"):
		#create_bullet()
#一开始测试用的,后面要同步到服务器,直接删掉无用


func _process(_delta: float) -> void:
	update_aim_position()
	if is_multiplayer_authority():
		if is_dying:
			global_position = Vector2.RIGHT * 1000
			return

		velocity = player_input_synchronizer_component.movement_vector * get_movement_speed()
		move_and_slide()
		if player_input_synchronizer_component.is_attack_pressed:
			try_fire()


func get_movement_speed() -> float:
	var movement_upgrade_count := UpgradeManager.get_peer_upgrade_count(
		player_input_synchronizer_component.get_multiplayer_authority(),
		"movement_speed"
	)
	
	var speed_modifier := 1 + (1 * movement_upgrade_count)
	
	return BASE_MOVEMENT_SPEED * speed_modifier


func get_fire_rate() -> float:
	var fire_rate_count := UpgradeManager.get_peer_upgrade_count(
		player_input_synchronizer_component.get_multiplayer_authority(),
		"fire_rate"
	)
	
	var fire_rate_modifier := 1 - (.5 * fire_rate_count)
	
	return BASE_FIRE_RATE * fire_rate_modifier


func get_bullet_damage() -> int:
	var damage_count := UpgradeManager.get_peer_upgrade_count(
		player_input_synchronizer_component.get_multiplayer_authority(),
		"damage"
	)
	
	return BASE_BULLET_DAMAGE + damage_count


func set_display_name(incoming_name: String):
	display_name = incoming_name


func update_aim_position():
	var aim_vector = player_input_synchronizer_component.aim_vector
	var aim_position = weapon_root.global_position + aim_vector
	
	visuals.scale = Vector2.ONE if aim_vector.x >=0 else Vector2(-1, 1)
	weapon_root.look_at(aim_position)


func try_fire():
	if !fire_rate_timer.is_stopped():
		return
	
	var bullet = bullet_scene.instantiate() as Bullet #这个变量其实是场景实例化的节点,还在内存中,下一步再加到main场景中变成节点
	bullet.damage = get_bullet_damage()
	bullet.global_position = barrel_position.global_position #老师总结的经验是建议在添加节点之前改位置,这样会在_ready函数之前设好,如果添加了再改位置,就会运行了_ready之后再赋值全局位置
	bullet.source_peer_id = player_input_synchronizer_component.get_multiplayer_authority()
	bullet.start(player_input_synchronizer_component.aim_vector) #alt+↑是把代码上移，旋转和方向等自定义属性，可在节点加入场景树前先修改，有些是不行的。
	
	get_parent().add_child(bullet, true)
	
	fire_rate_timer.wait_time = get_fire_rate()
	fire_rate_timer.start()
	
	play_fire_effect.rpc()


@rpc("authority", "call_local", "unreliable")
func play_fire_effect():
	if animation_player.is_playing():
		animation_player.stop()
	animation_player.play("fire")
	
	var muzzle_flash: Node2D = muzzle_flash_scene.instantiate()
	muzzle_flash.global_position = barrel_position.global_position
	muzzle_flash.rotation = barrel_position.global_rotation
	get_parent().add_child(muzzle_flash)
	
	if player_input_synchronizer_component.is_multiplayer_authority():
		GameCamera.shake(1)


func kill():
	if !is_multiplayer_authority():
		push_error("Cannot call kill on non-server client")
		return
	
	_kill.rpc()
	await get_tree().create_timer(.5).timeout
	
	died.emit()
	queue_free()


@rpc("authority", "call_local", "reliable")
func _kill():
	is_dying = true
	player_input_synchronizer_component.public_visibility = false


func _on_died():
	kill()
	

class_name Player
extends CharacterBody2D

signal died

@onready var player_input_synchronizer_component: PlayerInputSynchronizerComponent = $PlayerInputSynchronizerComponent
@onready var weapon_root: Node2D = $Visuals/WeaponRoot
@onready var fire_rate_timer: Timer = $FireRateTimer
@onready var health_component: HealthComponent = $HealthComponent
@onready var visuals: Node2D = $Visuals
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var barrel_position: Marker2D = %BarrelPosition

var bullet_scene: PackedScene = preload("uid://jlap4yf3gf0i")
var muzzle_flash_scene: PackedScene = preload("uid://cnxo8p5hrj6tv")
var input_multiplayer_authority: int
var is_dying: bool


func _ready() -> void:
	player_input_synchronizer_component.set_multiplayer_authority(input_multiplayer_authority)
	
	if is_multiplayer_authority():
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

		velocity = player_input_synchronizer_component.movement_vector * 300
		move_and_slide()
		if player_input_synchronizer_component.is_attack_pressed:
			try_fire()


func update_aim_position():
	var aim_vector = player_input_synchronizer_component.aim_vector
	var aim_position = weapon_root.global_position + aim_vector
	
	visuals.scale = Vector2.ONE if aim_vector.x >=0 else Vector2(-1, 1)
	weapon_root.look_at(aim_position)


func try_fire():
	if !fire_rate_timer.is_stopped():
		return
	
	var bullet = bullet_scene.instantiate() as Bullet
	#这个变量其实是场景实例化的节点,还在内存中,下一步再加到main场景中变成节点
	bullet.global_position = barrel_position.global_position
	#老师总结的经验是建议在添加节点之前改位置,这样会在_ready函数之前设好,如果添加了再改位置,就会运行了_ready之后再赋值全局位置
	bullet.start(player_input_synchronizer_component.aim_vector)
	#alt+↑是把代码上移，旋转和方向等自定义属性，可在节点加入场景树前先修改，有些是不行的。
	get_parent().add_child(bullet, true)
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
	

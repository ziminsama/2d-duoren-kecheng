extends CharacterBody2D


@onready var target_acquisition_timer: Timer = $TargetAcquisitionTimer
@onready var health_component: HealthComponent = $HealthComponent
@onready var visuals: Node2D = $Visuals
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var charge_attack_timer: Timer = $ChargeAttackTimer
@onready var hitbox_collision_shape: CollisionShape2D = %HitboxCollisionShape

var target_position: Vector2
var state_machine: CallableStateMachine = CallableStateMachine.new()
var default_collision_mask: int
var default_collision_layer: int


func _ready() -> void:
	state_machine.add_states(state_spawn, enter_state_spawn, Callable())
	state_machine.add_states(state_normal, enter_state_normal, Callable())
	state_machine.add_states(state_charge_attack, enter_state_charge_attack, Callable())
	state_machine.add_states(state_attack, enter_state_attack, leave_state_attack)
	state_machine.set_initial_state(state_spawn)
	
	default_collision_layer = collision_layer
	default_collision_mask = collision_mask
	hitbox_collision_shape.disabled = true
	
	if is_multiplayer_authority():
		health_component.died.connect(_on_died)


#这里的怪物追敌AI可以延伸类比至法术追踪目标了,只是法术速度更快
func _process(_delta: float) -> void:
	state_machine.update()
	if is_multiplayer_authority():
		move_and_slide()


func enter_state_spawn():
	var tween := create_tween()
	#easings.net里面可以看补间曲线
	tween.tween_property(visuals, "scale", Vector2.ONE, 0.4)\
		.from(Vector2.ZERO)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK)
	#这里connect用了新方法,匿名函数.之前是放一个回调函数，另外再定义这个回调函数
	tween.finished.connect(func ():
		state_machine.change_state(state_normal)
	)


func state_spawn():
	pass


func enter_state_normal():
	if is_multiplayer_authority():
		acquire_target()
		target_acquisition_timer.start()


func state_normal():
	if is_multiplayer_authority():
		velocity = global_position.direction_to(target_position) * 40
		
		if target_acquisition_timer.is_stopped():
			acquire_target()
			target_acquisition_timer.start()
		
		if attack_cooldown_timer.is_stopped() && global_position.distance_to(target_position) < 150:
			state_machine.change_state(state_charge_attack)
	
	flip()


func enter_state_charge_attack():
	acquire_target()
	charge_attack_timer.start()


func state_charge_attack():
	if is_multiplayer_authority():
		#这里直接用,不好解释
		velocity = velocity.lerp(Vector2.ZERO, 1.0 - exp(-15 * get_process_delta_time()))
		if charge_attack_timer.is_stopped():
			state_machine.change_state(state_attack)


func enter_state_attack():
	if is_multiplayer_authority():
		collision_mask = 1 << 0
		collision_layer = 0
		hitbox_collision_shape.disabled = false
		velocity = global_position.direction_to(target_position) * 400


func state_attack():
	if is_multiplayer_authority():
		velocity = velocity.lerp(Vector2.ZERO, 1.0 - exp(-3 * get_process_delta_time()))
		if velocity.length() < 25:
			state_machine.change_state(state_normal)


func leave_state_attack():
	if is_multiplayer_authority():
		collision_mask = default_collision_mask
		collision_layer = default_collision_layer
		hitbox_collision_shape.disabled = true
		attack_cooldown_timer.start()


func flip():
	visuals.scale = Vector2.ONE if global_position.x < target_position.x else Vector2(-1, 1)


func acquire_target():
	var players = get_tree().get_nodes_in_group("player")
	var nearest_player: Player = null
	var nearest_squared_distance: float
	
	for player in players:
		if nearest_player == null:
			nearest_player = player
			nearest_squared_distance = nearest_player.global_position.distance_squared_to(global_position)
			continue
	
		var player_squared_distance: float = player.global_position.distance_squared_to(global_position)
		if player_squared_distance <= nearest_squared_distance:
			nearest_squared_distance = player_squared_distance
			nearest_player = player
	
	if nearest_player != null:
		target_position = nearest_player.global_position


func _on_died():
	GameEvents.emit_enemy_died()
	queue_free()

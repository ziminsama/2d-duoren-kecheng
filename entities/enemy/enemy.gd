extends CharacterBody2D


@onready var target_acquisition_timer: Timer = $TargetAcquisitionTimer
@onready var health_component: HealthComponent = $HealthComponent
@onready var visuals: Node2D = $Visuals

var target_position: Vector2
var is_spawning: bool


func _ready() -> void:
	target_acquisition_timer.timeout.connect(_on_target_acquisition_timer_timeout)
	play_spawn_animation()
	
	if is_multiplayer_authority():
		health_component.died.connect(_on_died)
		#这段试了func _process里面效果一样但疯狂报错，感觉像每帧都在出信号，
		#放_ready里面是因为触发一次？但是ready明明开始，还是不明白.新理解,是新生成的enemy的health_com要连上enemy的_on_died信号?
		acquire_target()

#这里的怪物追敌AI可以延伸类比至法术追踪目标了,只是法术速度更快
func _process(_delta: float) -> void:
	if is_multiplayer_authority() && !is_spawning:
		velocity = global_position.direction_to(target_position) * 40
		move_and_slide()
	
	if !is_spawning:
		flip()


func flip():
	visuals.scale = Vector2.ONE if global_position.x < target_position.x else Vector2(-1, 1)


func play_spawn_animation():
	is_spawning = true
	var tween := create_tween()
	#easings.net里面可以看补间曲线
	tween.tween_property(visuals, "scale", Vector2.ONE, 0.4)\
		.from(Vector2.ZERO)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_BACK)
	#这里connect用了新方法,匿名函数.之前是放一个回调函数，另外再定义这个回调函数
	tween.finished.connect(func ():
		is_spawning = false
	)
	#另一种方法,异步操作
	#await tween.finished
	#is_spawning = false


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


func _on_target_acquisition_timer_timeout():
	if is_multiplayer_authority():
		acquire_target()
#这里应该是作者的习惯,每个信号有一个形象的触发函数,函数里面才是真正的函数,可以方便加入服务器权威判断
#另外一个ryan的教程是用navigation2d


func _on_died():
	GameEvents.emit_enemy_died()
	queue_free()

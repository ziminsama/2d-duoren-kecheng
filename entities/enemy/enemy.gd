extends CharacterBody2D


@onready var target_acquisition_timer: Timer = $TargetAcquisitionTimer
@onready var health_component: HealthComponent = $HealthComponent


var target_position: Vector2


func _ready() -> void:
	target_acquisition_timer.timeout.connect(_on_target_acquisition_timer_timeout)
	#每0.2秒拿一次
	if is_multiplayer_authority():
		health_component.died.connect(_on_died)
		#这段试了func _process里面效果一样但疯狂报错，感觉像每帧都在出信号，
		#放_ready里面是因为触发一次？但是ready明明开始，还是不明白
		acquire_target()

#这里的怪物追敌AI可以延伸类比至法术追踪目标了,只是法术速度更快
func _process(_delta: float) -> void:
	if is_multiplayer_authority():
		velocity = global_position.direction_to(target_position) * 40
		move_and_slide()


#func handel_hit():
	#health_component.damage(1)
	#用了组件原来的不用了
	#current_health -= 1
	#if current_health <= 0:
		#queue_free()


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


#func _on_area_entered(other_area: Area2D):
	#if !is_multiplayer_authority():
		#return
	#
	#if other_area.owner is Bullet:
		#var bullet = other_area.owner as Bullet
		#bullet.register_collision()
		#handel_hit()
		#print("collision")


func _on_target_acquisition_timer_timeout():
	if is_multiplayer_authority():
		acquire_target()
#这里应该是作者的习惯,每个信号有一个形象的触发函数,函数里面才是真正的函数,可以方便加入服务器权威判断
#另外一个ryan的教程是用navigation2d


func _on_died():
	GameEvents.emit_enemy_died()
	queue_free()

extends Node

const BASE_ROUND_TIME: int = 20
const ROUND_GROWTH: int = 5
const BASE_ENEMY_SPAWN_TIME: float = 2
const ENEMY_SPAWN_TIME_GROWTH: float = -0.15


@export var enemy_scene: PackedScene
@export var enemy_spawn_root: Node
@export var spawn_rect: ReferenceRect

@onready var spawn_interval_timer: Timer = $SpawnIntervalTimer
@onready var round_timer: Timer = $RoundTimer

var round_count: int = 0

func _ready() -> void:
	spawn_interval_timer.timeout.connect(_on_spawn_interval_timer_timeout)
	round_timer.timeout.connect(_on_round_timer_timeout)
	begin_round()


func begin_round():
	round_count += 1
	round_timer.wait_time = BASE_ROUND_TIME + ((round_count - 1) * ROUND_GROWTH)
	round_timer.start()
	
	spawn_interval_timer.wait_time = BASE_ENEMY_SPAWN_TIME + ((round_count - 1) * ENEMY_SPAWN_TIME_GROWTH)
	spawn_interval_timer.start()


func get_randon_spawn_position() -> Vector2:
	var x = randi_range(0, spawn_rect.size.x)
	var y = randi_range(0, spawn_rect.size.y)
	return spawn_rect.global_position + Vector2(x, y)


func spawn_enemy():
	var enemy = enemy_scene.instantiate() as Node2D
	enemy.global_position = get_randon_spawn_position()
	enemy_spawn_root.add_child(enemy, true)


func _on_spawn_interval_timer_timeout():
	if is_multiplayer_authority():
		spawn_enemy()
		spawn_interval_timer.start()


func _on_round_timer_timeout():
	if is_multiplayer_authority():
		spawn_interval_timer.stop()
		print("round over")

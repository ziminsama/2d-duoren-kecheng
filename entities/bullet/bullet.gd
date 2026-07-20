class_name Bullet
extends Node2D

const SPEED: int = 600

@onready var life_timer: Timer = $LifeTimer

var direction: Vector2

func _ready() -> void:
	life_timer.timeout.connect(_on_life_timer_timeout)
	#connect里面的是函数名，不加()


func _process(delta: float) -> void:
	global_position += direction * SPEED * delta


func  start(direction: Vector2):
	self.direction = direction
	rotation = direction.angle()
	#self.direction表示访问脚本自己定义的 direction 变量


func _on_life_timer_timeout():
	if is_multiplayer_authority():
		queue_free()

extends CharacterBody2D

func _process(delta: float) -> void:
	var movement_vector = Input.get_vector("move_left","move_right","move_up","move_down")
	velocity = movement_vector * 100
	move_and_slide()
	#pass

#测试 建议用_physics_process,我在测有什么不同,实际发现没啥不同
#func _physics_process(delta: float) -> void:
	#var movement_vector = Input.get_vector("move_left","move_right","move_up","move_down")
	#velocity = movement_vector * 300
	#move_and_slide()

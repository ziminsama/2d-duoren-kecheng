class_name Player
extends CharacterBody2D

@onready var player_input_synchronizer_component: PlayerInputSynchronizerComponent = $PlayerInputSynchronizerComponent

var input_multiplayer_authority: int


func _ready() -> void:
	player_input_synchronizer_component.set_multiplayer_authority(input_multiplayer_authority)
	set_process(is_multiplayer_authority())


func _process(delta: float) -> void:
	velocity = player_input_synchronizer_component.movement_vector * 300
	move_and_slide()


#测试 建议用_physics_process,我在测有什么不同,实际发现没啥不同
#func _physics_process(delta: float) -> void:
	#var movement_vector = Input.get_vector("move_left","move_right","move_up","move_down")
	#velocity = movement_vector * 300
	#move_and_slide()

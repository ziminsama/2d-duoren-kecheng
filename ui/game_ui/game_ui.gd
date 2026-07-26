extends CanvasLayer

@export var enemy_manager: EnemyManager
@onready var time_label: Label = %TimeLabel
@onready var round_label: Label = %RoundLabel


func _ready() -> void:
	enemy_manager.round_changed.connect(_on_round_begin)


func _process(_delta: float) -> void:
	time_label.text = str(ceili(enemy_manager.get_round_time_remaining()))


func _on_round_begin(round_count: int):
	#round_label.text = str("ROUND "+str(round_count))
	round_label.text = "ROUND %s" % round_count

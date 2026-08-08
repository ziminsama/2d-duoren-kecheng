class_name GameUI
extends CanvasLayer

@export var enemy_manager: EnemyManager
@onready var time_label: Label = %TimeLabel
@onready var round_label: Label = %RoundLabel
@onready var health_progress_bar: ProgressBar = %HealthProgressBar
@onready var display_name_label: Label = %DisplayNameLabel


func _ready() -> void:
	enemy_manager.round_changed.connect(_on_round_begin)

#时间是浮点一直在变,所有通过process获取,
func _process(_delta: float) -> void:
	time_label.text = str(ceili(enemy_manager.get_round_time_remaining()))


func connect_player(player: Player):
	(func():
		if multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
			display_name_label.text = "Player"
		else:
			display_name_label.text = player.display_name
		player.health_component.health_changed.connect(_on_health_changed)
		#一般不单独调用信号处理函数,但是因为第一次生命变更在_ready中,可能先于同步器,导致第一次变更没有触发信号;更严谨的方法是写一个更新什么值的方法
		_on_health_changed(player.health_component.current_health, player.health_component.max_health)
	).call_deferred()

#回合是int,特定情况才变,变的时候触发信号,获取就好
func _on_round_begin(round_count: int):
	#round_label.text = str("ROUND "+str(round_count))
	round_label.text = "ROUND %s" % round_count


func _on_health_changed(current_health: int, max_health: int):
	health_progress_bar. value = float(current_health) / float(max_health) if max_health !=0 else 0

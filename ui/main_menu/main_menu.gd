extends Control

var main_scene: PackedScene = preload("uid://dwmo7komf8w84")

@onready var single_player_button: Button = $VBoxContainer/SinglePlayerButton
@onready var multiplayer_button: Button = $VBoxContainer/MultiplayerButton
@onready var option_button: Button = $VBoxContainer/OptionButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

@onready var multiplayer_menu_scene: PackedScene = load("uid://blcl2gvj853fj")

var options_menu_scene: PackedScene = preload("uid://b2x7jtmwrt4kv")

func _ready() -> void:
	single_player_button.pressed.connect(_on_single_player_button_pressed)
	multiplayer_button.pressed.connect(_on_multiplayer_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	option_button.pressed.connect(_on_option_button_pressed)
	
	UIAudioManager.register_buttons([
		single_player_button,
		multiplayer_button,
		quit_button,
		option_button
	])


func _on_single_player_button_pressed():
	get_tree().change_scene_to_packed(main_scene)


func _on_multiplayer_button_pressed():
	get_tree().change_scene_to_packed(multiplayer_menu_scene)


func _on_quit_button_pressed():
	get_tree().quit()

func _on_option_button_pressed():
	var option_menu := options_menu_scene.instantiate()
	add_child(option_menu)

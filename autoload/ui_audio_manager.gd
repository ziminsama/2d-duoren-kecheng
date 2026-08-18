extends Node

@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer

static var instance: UIAudioManager


func _ready() -> void:
	instance = self


static func register_buttons(buttons: Array):
	for button in buttons:
		button.pressed.connect(instance._on_button_pressed) #静态函数不能直接调用动态函数,要有个实例来调用


func _on_button_pressed():
	instance.audio_stream_player.play()

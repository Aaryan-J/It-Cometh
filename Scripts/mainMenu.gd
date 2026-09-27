extends Control

@onready var playButton = $PlayButton

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if playButton:
		playButton.pressed.connect(_on_play_button_pressed)

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

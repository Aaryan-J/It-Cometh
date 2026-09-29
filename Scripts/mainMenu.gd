extends Control

@onready var playButton: Button = $PlayButton
@onready var tutorialButton: Button = $TutorialButton
@onready var tutorialPanel: Panel = $TutorialPanel
@onready var closeTutorialButton: Button = $TutorialPanel/CloseTutorialButton

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if tutorialPanel:
		tutorialPanel.hide()

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _on_tutorial_button_pressed() -> void:
	if tutorialPanel:
		tutorialPanel.show()

func _on_close_tutorial_button_pressed() -> void:
	if tutorialPanel:
		tutorialPanel.hide()

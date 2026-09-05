extends Control

@onready var timerLabel: Label = $"../TimerLabel"
@onready var crosshair: ColorRect = $"../Crosshair"

var currentActiveTask: Interactable = null

func openMinigame(taskNode: Interactable) -> void:
	currentActiveTask = taskNode
	show()
	
	get_parent().get_parent().get_node("Camera3D").set_process_input(false)
	get_parent().get_parent().set_physics_process(false)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if crosshair: crosshair.hide()
	
	print("Minigame opened for: ", currentActiveTask.taskName)
	
func closeMinigame(successfullyFixed: bool) -> void:
	hide()
	get_parent().get_parent().get_node("Camera3D").set_process_input(true)
	get_parent().get_parent().set_physics_process(true)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if crosshair: crosshair.show()
	
	if successfullyFixed and currentActiveTask:
		currentActiveTask.completeTask()
		
	currentActiveTask = null


func _on_fix_button_pressed() -> void:
	closeMinigame(true)

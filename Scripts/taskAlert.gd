extends Label

@onready var gameManager = get_tree().get_first_node_in_group("gameManagerGroup")

func _process(_delta: float) -> void:
	if not gameManager or not gameManager.isGameActive:
		text = ""
		return
	
	if gameManager.activeBrokenTasks.size() == 0:
		text = ""
		return
		
	var alertString: String = "CRITICAL FAILURES:\n"
	
	for task in gameManager.activeBrokenTasks:
		alertString += "- Fix: " + task.taskName + "\n"
		
	text = alertString
	
	add_theme_color_override("font_color", Color(1, 0.2, 0.2))

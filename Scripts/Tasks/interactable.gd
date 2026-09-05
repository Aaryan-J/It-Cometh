extends StaticBody3D
class_name Interactable

# signals
signal taskBroken(taskNode)
signal taskFixed(taskNode)

@export var taskName: String = "Bunker Component"
@export var isBroken: bool = false

func interact(playerNode: CharacterBody3D):
	if isBroken:
		startMinigame(playerNode)
	else:
		print(taskName, " is working perfectly right now.")

func startMinigame(playerNode: CharacterBody3D):  # player node for when imma add minigames
	var minigameWindow = playerNode.get_node_or_null("HUD/MinigameWindow")
	
	if minigameWindow:
		minigameWindow.openMinigame(self)
	else:
		print("HUD minigame window not found. Auto complete task")
		completeTask() #TODO: make sure to add minigame to this
	
func completeTask():
	isBroken = false
	taskFixed.emit(self)
	print(taskName, " has been repaired.")
	
func breakTask():
	isBroken = true
	taskBroken.emit(self)
	print("WARNING: ", taskName, " has broken down.")

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
	print("Starting minigame for ", taskName)
	completeTask() #TODO: make sure to add minigame to this
	
func completeTask():
	isBroken = false
	taskFixed.emit(self)
	print(taskName, " has been repaired.")
	
func breakTask():
	isBroken = true
	taskBroken.emit(self)
	print("WARNING: ", taskName, " has broken down.")

extends StaticBody3D
class_name Interactable

# signals
signal taskBroken(taskNode)
signal taskFixed(taskNode)

@export var taskName: String = "Bunker Component"
@export var isBroken: bool = false
@export_range(0,2) var noteIndex: int = 0

func interact(playerNode: CharacterBody3D):
	if taskName == "TerminalCodeNote":
		var manager = get_tree().get_first_node_in_group("gameManagerGroup")
		var displayLabel = get_node_or_null("CodeDisplay")

		if manager and manager.activeTerminalCode[noteIndex] != "":
			var activeCode = manager.activeTerminalCode[noteIndex]
			print("STICKY NOTE ", noteIndex + 1, ": Reading sequence line -> ", activeCode) # put UI print label thingy here
			if displayLabel:
				displayLabel.text = activeCode
				displayLabel.modulate = Color.DARK_RED
		else:
			print("STICKY NOTE BLANK")
			if displayLabel:
				displayLabel.text = "...."
		return

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
		completeTask()

func completeTask():
	isBroken = false
	taskFixed.emit(self)
	print(taskName, " has been repaired.")

func breakTask():
	isBroken = true
	taskBroken.emit(self)
	print("WARNING: ", taskName, " has broken down.")

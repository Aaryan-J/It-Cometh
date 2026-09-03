extends Node

# ------ editor vars ------
@export var totalApocalypseTime: float = 300.0 

# ------ internal vars ------
var timeLeft: float = 300.0
var currentMaxCap: float = 300.0

var isGameActive: bool = true
var totalTasksCompleted: int = 0
var activeBrokenTasks: Array[Interactable] = []

# timer var
var taskSpawnCooldown: float = 25.0
var taskSpawnTimer: float = 0.0

var allBunkerTasks: Array[Node] = []

# ---------------
func _ready() -> void:
	add_to_group("gameManagerGroup")
	
	currentMaxCap = totalApocalypseTime
	timeLeft = currentMaxCap
	
	allBunkerTasks = get_tree().get_nodes_in_group("bunkerTasks")
	
	for task in allBunkerTasks:
		if task is Interactable:
			task.taskFixed.connect(_on_taskRepaired)
	
	print("Bunker systems online. Initial timer full at: 5:00")

func _process(delta: float) -> void:
	if not isGameActive:
		return
		
	timeLeft -= delta
	if timeLeft <= 0:
		triggerCosmicEnding()
		return
		
	adjustDifficultyScaling()
	
	if activeBrokenTasks.size() < allBunkerTasks.size():
		taskSpawnTimer += delta
		if taskSpawnTimer >= taskSpawnCooldown:
			taskSpawnTimer = 0.0
			breakRandomBunkerTask()
			
# ------ task handling ------

func breakRandomBunkerTask() -> void:
	var workingTasks = allBunkerTasks.filter(func(t): return not t.isBroken)
	if workingTasks.size() > 0:
		var chosenTask = workingTasks.pick_random()
		chosenTask.breakTask()
		activeBrokenTasks.append(chosenTask)
		# tts "Warning: Component Failure Detected"

func _on_taskRepaired(task: Interactable) -> void:
	activeBrokenTasks.erase(task)
	totalTasksCompleted += 1
	
	currentMaxCap = max(currentMaxCap - 10.0, 15.0) # Floor at 15s so it never goes negative
	
	timeLeft = currentMaxCap
	
	print("Task Fixed! Ceiling shrunk to ", currentMaxCap, "s and timer was fully refilled.")
	
func adjustDifficultyScaling() -> void:
	if currentMaxCap > 200:
		taskSpawnCooldown = 25.0
	elif currentMaxCap > 100:
		taskSpawnCooldown = 12.0
	else:
		taskSpawnCooldown = 5.0 

# ------ ending ------

func triggerCosmicEnding() -> void:
	isGameActive = false
	print("IT IS HERE")

# ------ look back penalty ------
func applyLookbackPenalty() -> void:
	timeLeft = max(timeLeft - 30.0, 1.0)
	print("PENALTY: Looked back! 30 seconds drained from active clock.")

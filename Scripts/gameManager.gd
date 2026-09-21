extends Node

# ------ references ------
@onready var bgMusicPlayer: AudioStreamPlayer = $BGMusicPlayer
@onready var jumpscarePlayer: AudioStreamPlayer = $JumpscarePlayer
@onready var narratorPlayer: AudioStreamPlayer = $NarratorPlayer

# ------ editor vars ------
@export var totalApocalypseTime: float = 300.0

@export var jumpscareSounds: Array[AudioStream] = []

# ------ internal vars ------
var timeLeft: float = 300.0
var currentMaxCap: float = 300.0

var isGameActive: bool = true
var totalTasksCompleted: int = 0
var activeBrokenTasks: Array[Interactable] = []

# timer var
var taskSpawnCooldown: float = 15.0
var taskSpawnTimer: float = 0.0

var allBunkerTasks: Array[Node] = []

var activeTerminalCode: Array[String] = ["", "", ""]

# jumpscare vars
var jumpscareCooldown: float = 30.0
var lastJumpscareTime: float = 300.0

# ---------------
func _ready() -> void:
	add_to_group("gameManagerGroup")

	currentMaxCap = totalApocalypseTime
	timeLeft = currentMaxCap

	var scannedNodes = get_tree().get_nodes_in_group("bunkerTasks")

	for node in scannedNodes:
		if node is Interactable and node.taskName != "TerminalCodeNote":
			allBunkerTasks.append(node)
			node.taskFixed.connect(_on_taskRepaired)


	var testAudio = load("res://Assets/Audio/Music/Tense Ambience 3 Track .mp3")
	playBGMusic(testAudio)

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

	if isGameActive:
		if (lastJumpscareTime - timeLeft) >= jumpscareCooldown:
			var scareChance = 0.0005 * activeBrokenTasks.size()
			if randf() < scareChance and jumpscareSounds.size() > 0:
				lastJumpscareTime = timeLeft
				var chosenSound = jumpscareSounds.pick_random()
				triggerAudioJumpscare(chosenSound)

# ------ task handling ------

func breakRandomBunkerTask() -> void:
	var workingTasks = allBunkerTasks.filter(func(t): return not t.isBroken)
	if workingTasks.size() > 0:
		var chosenTask = workingTasks.pick_random()
		chosenTask.breakTask()
		activeBrokenTasks.append(chosenTask)

		if chosenTask.taskName == "FuseBox":
			get_tree().call_group("bunkerLightsGroup", "setLightPower", false)
		elif chosenTask.taskName == "MainframeTerminal":
			for i in range(3):
				var generatedSegment = ""
				for j in range(4):
					generatedSegment += str(randi() % 10)
				activeTerminalCode[i] = generatedSegment
		# tts "Warning: Component Failure Detected"

func _on_taskRepaired(task: Interactable) -> void:
	activeBrokenTasks.erase(task)
	totalTasksCompleted += 1

	if task.taskName == "FuseBox":
		get_tree().call_group("bunkerLightsGroup", "setLightPower", true)

	currentMaxCap = max(currentMaxCap - 10.0, 15.0) # doesnt go less than 15 sec

	timeLeft = currentMaxCap

	print("Task Fixed! Ceiling shrunk to ", currentMaxCap, "s and timer was fully refilled.")

func adjustDifficultyScaling() -> void:
	if currentMaxCap > 200:
		taskSpawnCooldown = 25.0
	elif currentMaxCap > 100:
		taskSpawnCooldown = 15.0
	else:
		taskSpawnCooldown = 5.0

# ------ ending ------

func triggerCosmicEnding() -> void:
	isGameActive = false
	print("IT IS HERE")

# ------ look back penalty ------
func applyLookBackPenalty() -> void:
	timeLeft = max(timeLeft - 30.0, 1.0)
	print("PENALTY: Looked back! 30 seconds drained from active clock.")

# ------ music and sfx ------
func playBGMusic(stream: AudioStream) -> void:
	if not bgMusicPlayer or not stream: return
	bgMusicPlayer.stream = stream
	bgMusicPlayer.play()
	print_debug("BG audio playing")

func triggerAudioJumpscare(stream: AudioStream) -> void:
	if not jumpscarePlayer or not stream: return
	jumpscarePlayer.stream = stream
	jumpscarePlayer.play()
	print_debug("Jumpscare audio playing")

func playNarratorVoice(stream: AudioStream) -> void:
	if not narratorPlayer or not stream: return
	narratorPlayer.stream = stream
	narratorPlayer.play()
	print_debug("Narrator audio playing")

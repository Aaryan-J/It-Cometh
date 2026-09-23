extends Node

# ------ references ------
@onready var bgMusicPlayer: AudioStreamPlayer = $BGMusicPlayer
@onready var jumpscarePlayer: AudioStreamPlayer = $JumpscarePlayer
@onready var narratorPlayer: AudioStreamPlayer = $NarratorPlayer

# ------ editor vars ------
@export var totalApocalypseTime: float = 300.0

@export_group("Jumpscare Sounds")
@export var jumpscareSounds: Array[AudioStream] = []

@export_group("Narrator")
@export var voiceIntro: AudioStream
@export var voiceFuseBlown: AudioStream
@export var voiceRadioBroken: AudioStream
@export var voiceMainframeLockout: AudioStream
@export var voiceOxygenBroken: AudioStream
@export var voiceTaskFixed: AudioStream
@export var voicePanic30s: AudioStream

var milestoneNarrated: Dictionary = {
	"intro": false,
	"panic": false
}

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
		if timeLeft <= (totalApocalypseTime - 5.0) and not milestoneNarrated["intro"]:
			milestoneNarrated["intro"] = true
			playNarratorVoice(voiceIntro)

		if timeLeft <= 30.0 and not milestoneNarrated["panic"]:
			milestoneNarrated["panic"] = true
			playNarratorVoice(voicePanic30s)

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
			playNarratorVoice(voiceFuseBlown)
		elif chosenTask.taskName == "MainframeTerminal":
			for i in range(3):
				var generatedSegment = ""
				for j in range(4):
					generatedSegment += str(randi() % 10)
				activeTerminalCode[i] = generatedSegment
			playNarratorVoice(voiceMainframeLockout)
		elif chosenTask.taskName == "Radio":
			playNarratorVoice(voiceRadioBroken)
		elif chosenTask.taskName == "OxygenFilter":
			playNarratorVoice(voiceOxygenBroken)
		# tts "Warning: Component Failure Detected"

func _on_taskRepaired(task: Interactable) -> void:
	activeBrokenTasks.erase(task)
	totalTasksCompleted += 1

	if task.taskName == "FuseBox":
		get_tree().call_group("bunkerLightsGroup", "setLightPower", true)

	currentMaxCap = max(currentMaxCap - 10.0, 15.0) # doesnt go less than 15 sec

	timeLeft = currentMaxCap

	playNarratorVoice(voiceTaskFixed)
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

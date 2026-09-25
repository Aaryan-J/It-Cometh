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
@export var voiceIntro: Array[AudioStream] = []
@export var voiceFuseBlown: Array[AudioStream] = []
@export var voiceRadioBroken: Array[AudioStream] = []
@export var voiceMainframeLockout: Array[AudioStream] = []
@export var voiceOxygenBroken: Array[AudioStream] = []
@export var voiceTaskFixed: Array[AudioStream] = []
@export var voicePanic30s: Array[AudioStream] = []

var introIndex: int = 0
var panicIndex: int = 0

@export_group("Don't Look Back")
@export var voiceDontLookBack: AudioStream
@export var lookBackJumpscare: AudioStream

var dontLookBackMilestones: Array[float] = [240.0, 160.0, 80.0]
var evaluatedMilestones: Array[bool] = [false, false, false]

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


	var bgAudio = load("res://Assets/Audio/Music/Tense Ambience 3 Track .mp3")
	playBGMusic(bgAudio)

func _process(delta: float) -> void:
	if not isGameActive:
		return # safety check

	timeLeft -= delta
	if timeLeft <= 0:
		triggerCosmicEnding() # trigger ending
		return

	adjustDifficultyScaling()

	if activeBrokenTasks.size() < allBunkerTasks.size():
		taskSpawnTimer += delta
		if taskSpawnTimer >= taskSpawnCooldown:
			taskSpawnTimer = 0.0
			breakRandomBunkerTask()

	if isGameActive:
		# play sounds according to events
		if timeLeft <= (totalApocalypseTime - 5.0) and introIndex < voiceIntro.size() and not narratorPlayer.is_playing():
			playNarratorVoice(voiceIntro[introIndex])
			introIndex += 1
			print_debug(introIndex)

		if timeLeft <= 30.0 and panicIndex < voicePanic30s.size() and not narratorPlayer.is_playing():
			playNarratorVoice(voicePanic30s[panicIndex])
			panicIndex += 1

		for i in range(dontLookBackMilestones.size()):
			if timeLeft <= dontLookBackMilestones[i] and not evaluatedMilestones[i]:
				evaluatedMilestones[i] = true
				forceLookBackEvent()

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
			if activeTerminalCode[0] == "" and activeTerminalCode[1] == "" and activeTerminalCode[2] == "":
				for i in range(3):
					var generatedSegment = ""
					for j in range(4):
						generatedSegment += str(randi() % 10)
					activeTerminalCode[i] = generatedSegment

		if timeLeft <= 30 or (narratorPlayer and narratorPlayer.is_playing()):
			return
		else:
			pass

		if chosenTask.taskName == "Radio" and voiceRadioBroken.size() > 0:
			playNarratorVoice(voiceRadioBroken.pick_random())
		elif chosenTask.taskName == "OxygenFilter" and voiceOxygenBroken.size() > 0:
			playNarratorVoice(voiceOxygenBroken.pick_random())
		elif chosenTask.taskName == "FuseBox" and voiceFuseBlown.size() > 0:
			playNarratorVoice(voiceFuseBlown.pick_random())
		elif chosenTask.taskName == "MainframeTerminal" and voiceMainframeLockout.size() > 0:
			playNarratorVoice(voiceMainframeLockout.pick_random())

func _on_taskRepaired(task: Interactable) -> void:
	activeBrokenTasks.erase(task)
	totalTasksCompleted += 1

	if task.taskName == "FuseBox":
		get_tree().call_group("bunkerLightsGroup", "setLightPower", true)

	currentMaxCap = max(currentMaxCap - 10.0, 15.0) # doesnt go less than 15 sec

	timeLeft = currentMaxCap


	if timeLeft <= 30 or (narratorPlayer and narratorPlayer.is_playing()):
		return

	if voiceTaskFixed.size() > 0:
		playNarratorVoice(voiceTaskFixed.pick_random())
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

	if lookBackJumpscare:
		triggerAudioJumpscare(lookBackJumpscare)


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

func forceLookBackEvent() -> void:
	if narratorPlayer:
		narratorPlayer.stop()

	if voiceDontLookBack:
		playNarratorVoice(voiceDontLookBack)

	var cameraNode = get_tree().get_first_node_in_group("cameraGroup")
	if cameraNode and cameraNode.has_method("startDontLookBackEvent"):
		if voiceDontLookBack:
			playNarratorVoice(voiceDontLookBack)
		cameraNode.startDontLookBackEvent()

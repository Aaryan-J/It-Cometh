extends Control

# ------ references ------
@onready var crosshair: ColorRect = $"../Crosshair"

@onready var player: CharacterBody3D = get_parent().get_parent()
@onready var camera: Node3D = $"../../Camera3D"

@onready var closeButton: Button = $BGPanel/CloseButton

#wire matching game
@onready var wireContainer: Control = $BGPanel/WireContainer
@onready var leftWires: VBoxContainer = $"BGPanel/WireContainer/LeftWires"
@onready var rightWires: VBoxContainer = $"BGPanel/WireContainer/RightWires"
@onready var wireDrawingLayer: Control = $"BGPanel/WireContainer/WireDrawingLayer"
@onready var currentLine: Line2D = $"BGPanel/WireContainer/WireDrawingLayer/CurrentLine"

# dial tuning minigame
@onready var radioContainer: Control = $BGPanel/RadioContainer
@onready var dialSlider: HSlider = $BGPanel/RadioContainer/DialHSlider
@onready var targetLabel: Label = $BGPanel/RadioContainer/TargetLabel
@onready var currentLabel: Label = $BGPanel/RadioContainer/CurrentLabel

# oxygen minigame
@onready var oxygenContainer: Control = $BGPanel/OxygenContainer
@onready var pressureBar: ProgressBar = $BGPanel/OxygenContainer/PressureBar
@onready var statusLabel: Label = $BGPanel/OxygenContainer/StatusLabel

# terminal minigame
@onready var terminalContainer: Control = $BGPanel/TerminalContainer
@onready var terminalDisplay: Label = $BGPanel/TerminalContainer/TerminalDisplay
@onready var codeInput: LineEdit = $BGPanel/TerminalContainer/CodeInput
@onready var progressLabel: Label = $BGPanel/TerminalContainer/ProgressLabel

# ------ variables ------
var currentActiveTask: Interactable = null

# wire matching gmae
var wireColors: Array[Color] = [Color.RED, Color.GREEN, Color.YELLOW, Color.BLUE]
var selectedLeftWire: Button = null
var completedConnections: int = 0
var requiredConnections: int = 4

# dial tuning minigame
var targetFrequency: float = 0
var frequencyTolerance: float = 0.3

var isStabilizing: bool = false
var stabilizerTime: float = 0
const STABILIZE_DURATION: float = 2.5

# oxygen minigame
var currentPressure: float = 50
var oxygenHoldTimer: float = 0
const OXYGEN_HOLD_DURATION: float = 3

const SAFE_ZONE_LOW: float = 40
const SAFE_ZONE_HIGH: float = 60

# terminal minigame
var targetCode: String = ""
var terminalProgress: int = 0
const REQUIRED_TERMINAL_STEPS: int = 3

func _ready() -> void:
	if closeButton:
		if closeButton.pressed.is_connected(_on_close_button_pressed):
			closeButton.pressed.disconnect(_on_close_button_pressed)
		closeButton.pressed.connect(_on_close_button_pressed)

func _process(delta: float) -> void:
	# wire game
	if is_visible_in_tree() and selectedLeftWire and currentLine:
		if currentLine.points.size() == 2:
			currentLine.set_point_position(1, currentLine.get_local_mouse_position())

	# radio game
	if is_visible_in_tree() and radioContainer and radioContainer.visible and isStabilizing:
		stabilizerTime += delta

		if currentLabel:
			var displayVal = snapped(dialSlider.value, 0.1)
			var progressPct = int((stabilizerTime / STABILIZE_DURATION) * 100)
			currentLabel.text = "STABILIZING: %d%% (%0.1f MHz)" % [progressPct, displayVal]

		if stabilizerTime >= STABILIZE_DURATION:
			isStabilizing = false
			closeMinigame(true)

	# oxygen game
	if is_visible_in_tree() and oxygenContainer and oxygenContainer.visible:
		currentPressure += delta * 12

		if currentPressure >= 100 or currentPressure <= 0:
			currentPressure = 50
			oxygenHoldTimer = 0
			if statusLabel: statusLabel.text = "CRITICAL FAILURE: Pressure reset"

		if pressureBar: pressureBar.value = currentPressure

		if currentPressure >= SAFE_ZONE_LOW and currentPressure <= SAFE_ZONE_HIGH:
			oxygenHoldTimer += delta
			var progress_pct = int((oxygenHoldTimer / OXYGEN_HOLD_DURATION) * 100)
			if statusLabel: statusLabel.text = "STABILIZING O2: %d%%" % progress_pct

			if oxygenHoldTimer >= OXYGEN_HOLD_DURATION:
				closeMinigame(true)

		else:
			oxygenHoldTimer = 0
			if statusLabel: statusLabel.text = "WARNING: Stabilize pressure between 40% to 60%!"

# helper functions
func openMinigame(taskNode: Interactable) -> void:
	currentActiveTask = taskNode
	show()

	if camera: camera.set_process_input(false)
	if player: player.set_physics_process(false)


	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if crosshair: crosshair.hide()

	print("Minigame opened for: ", currentActiveTask.taskName)
	_setup_minigame(currentActiveTask.taskName)

func closeMinigame(successfullyFixed: bool) -> void:
	hide()
	if camera: camera.set_process_input(true)
	if player: player.set_physics_process(true)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if crosshair: crosshair.show()

	if successfullyFixed and currentActiveTask:
		currentActiveTask.completeTask()

	currentActiveTask = null

func _setup_minigame(taskname: String) -> void:
	if closeButton: closeButton.show()
	if wireContainer: wireContainer.hide()
	if radioContainer: radioContainer.hide()
	if oxygenContainer: oxygenContainer.hide()
	if terminalContainer: terminalContainer.hide()
	$BGPanel/FixButton.show()

	match taskname:
		"FuseBox":
			if $BGPanel/FixButton: $BGPanel/FixButton.hide()
			_start_wire_minigame()

		"Radio":
			if $BGPanel/FixButton: $BGPanel/FixButton.hide()
			_start_radio_minigame()

		"OxygenFilter":
			if $BGPanel/FixButton: $BGPanel/FixButton.hide()
			_start_oxygen_minigame()

		"MainframeTerminal":
			if $BGPanel/FixButton: $BGPanel/FixButton.hide()
			_start_terminal_minigame()
		_:
			pass

# wire game
func _start_wire_minigame() -> void:
	if not wireContainer: return
	wireContainer.show()

	completedConnections = 0
	selectedLeftWire = null

	for oldLine in wireDrawingLayer.get_children():
		if oldLine != currentLine:
			oldLine.queue_free()
	if currentLine:
		currentLine.clear_points()


	for child in leftWires.get_children():
		child.queue_free()
	for child in rightWires.get_children():
		child.queue_free()

	var leftColors = wireColors.duplicate()
	leftColors.shuffle()

	var rightColors = wireColors.duplicate()
	rightColors.shuffle()

	for i in range(leftColors.size()):
		var btn = Button.new()
		btn.text = "● W" + str(i+1)
		btn.modulate = leftColors[i]
		btn.set_meta("color", leftColors[i])
		btn.pressed.connect(_on_left_wire_pressed.bind(btn))
		leftWires.add_child(btn)

	for j in range(rightColors.size()):
		var btn = Button.new()
		btn.text = "W" + str(j+1) + " ●"
		btn.modulate = rightColors[j]
		btn.set_meta("color", rightColors[j])
		btn.pressed.connect(_on_right_wire_pressed.bind(btn))
		rightWires.add_child(btn)

func _on_left_wire_pressed(clickedBtn: Button) -> void:
	selectedLeftWire = clickedBtn

	currentLine.clear_points()
	var buttonCenter = clickedBtn.global_position + (clickedBtn.size / 2)
	currentLine.add_point(currentLine.to_local(buttonCenter))
	currentLine.add_point(currentLine.get_local_mouse_position())
	currentLine.default_color = clickedBtn.get_meta("color")

	print("selected left wire color: ", clickedBtn.get_meta("color"))

func _on_right_wire_pressed(clickedBtn: Button) -> void:
	if not selectedLeftWire:
		print ("Select a left wire first")
		return

	var leftColor = selectedLeftWire.get_meta("color")
	var rightColor = clickedBtn.get_meta("color")

	if leftColor == rightColor:
		var finalLine = Line2D.new()
		wireDrawingLayer.add_child(finalLine)

		finalLine.default_color = leftColor
		finalLine.width = currentLine.width

		var startPos: Vector2 = wireDrawingLayer.make_canvas_position_local(selectedLeftWire.global_position + (selectedLeftWire.size / 2))
		var endPos: Vector2 = wireDrawingLayer.make_canvas_position_local(clickedBtn.global_position + (clickedBtn.size / 2))

		finalLine.add_point(finalLine.to_local(selectedLeftWire.global_position + (selectedLeftWire.size / 2)))
		finalLine.add_point(finalLine.to_local(clickedBtn.global_position + (clickedBtn.size / 2)))

		selectedLeftWire.disabled = true
		clickedBtn.disabled = true
		selectedLeftWire = null
		currentLine.clear_points()
		completedConnections += 1

		if completedConnections >= requiredConnections:
			closeMinigame(true)
	else:
		print("Wrong color combination. Try again")
		selectedLeftWire = null
		currentLine.clear_points()

# radio game
func _start_radio_minigame() -> void:
	if not radioContainer: return
	radioContainer.show()

	targetFrequency = snapped(randf_range(88.0, 108.0), 0.1)
	if targetLabel: targetLabel.text = "Tune to: " + str(targetFrequency) + " Mhz"

	if dialSlider:
		dialSlider.value = 88.0
		_on_dial_value_changed(dialSlider.value)

		if dialSlider.value_changed.is_connected(_on_dial_value_changed):
			dialSlider.value_changed.disconnect(_on_dial_value_changed)
		dialSlider.value_changed.connect(_on_dial_value_changed)

func _on_dial_value_changed(value: float) -> void:
	var displayVal = snapped(value, 0.1)
	if currentLabel: currentLabel.text = "Current: " + str(displayVal) + " MHz"

	if abs(displayVal - targetFrequency) <= frequencyTolerance:
		if not isStabilizing:
			isStabilizing = true
			stabilizerTime = 0.0
		else:
			if isStabilizing:
				isStabilizing = false
				if currentLabel:
					currentLabel.text = "Current: " + str(displayVal) + " MHz"

# oxygen game
func _start_oxygen_minigame() -> void:
	if not oxygenContainer: return
	oxygenContainer.show()

	currentPressure = 50
	oxygenHoldTimer = 0
	if pressureBar: pressureBar.value = currentPressure
	if statusLabel: statusLabel.text = "Stabilize pressure between 40% to 60%!"

	var ventBtn = $BGPanel/OxygenContainer/VentButton
	if ventBtn:
		if ventBtn.pressed.is_connected(_on_vent_button_pressed):
			ventBtn.pressed.disconnect(_on_vent_button_pressed)
		ventBtn.pressed.connect(_on_vent_button_pressed)

func _on_vent_button_pressed() -> void:
	currentPressure -= 15
	print("Valve vented. Current pressure score: ", currentPressure)

# terminal game
func _start_terminal_minigame() -> void:
	if not terminalContainer: return
	terminalContainer.show()

	var manager = get_tree().get_first_node_in_group("gameManagerGroup")
	if not manager: return
	terminalProgress = 0
	if manager:
		for code in manager.activeTerminalCode:
			if code == "":
				terminalProgress += 1

	_update_terminal_display()

	if codeInput:
		codeInput.text = ""
		codeInput.grab_focus()
		if codeInput.text_submitted.is_connected(_on_code_submitted):
			codeInput.text_submitted.disconnect(_on_code_submitted)
		codeInput.text_submitted.connect(_on_code_submitted)

func _update_terminal_display() -> void:
	if terminalDisplay:
		terminalDisplay.text = "INPUT OVERRIDE KEY"
	if progressLabel:
		progressLabel.text = "AUTHENTICATED BLOCKS: %d/3" % [terminalProgress]

func _on_code_submitted(submitted_text: String) -> void:
	var manager = get_tree().get_first_node_in_group("gameManagerGroup")
	if not manager: return

	var cleanInput = submitted_text.strip_edges()

	if manager.activeTerminalCode.has(cleanInput) and cleanInput != "":
		var codeIndex = manager.activeTerminalCode.find(cleanInput)
		manager.activeTerminalCode[codeIndex] = ""

		terminalProgress += 1
		print("Total authenticated: ", terminalProgress)

		if codeInput: codeInput.text = ""

		if terminalProgress >= 3:
			print("Mainframe fully functional.")
			closeMinigame(true)
		else:
			_update_terminal_display()
			if codeInput: codeInput.grab_focus()
	else:
		print("COMBINATION REJECTED. Invalid key sequence.")
		if codeInput:
			codeInput.text = ""
			codeInput.grab_focus()

# fix button
func _on_fix_button_pressed() -> void:
	closeMinigame(true)

func _on_close_button_pressed() -> void:
	closeMinigame(false)

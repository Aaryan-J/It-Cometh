extends Control

# ------ references ------
@onready var crosshair: ColorRect = $"../Crosshair"

@onready var player: CharacterBody3D = get_parent().get_parent()
@onready var camera: Node3D = $"../../Camera3D"

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

func _process(delta: float) -> void:
	if is_visible_in_tree() and selectedLeftWire and currentLine:
		if currentLine.points.size() == 2:
			currentLine.set_point_position(1, currentLine.get_local_mouse_position())
			
	if is_visible_in_tree() and radioContainer and radioContainer.visible and isStabilizing:
		stabilizerTime += delta
		
		if currentLabel:
			var displayVal = snapped(dialSlider.value, 0.1)
			var progressPct = int((stabilizerTime / STABILIZE_DURATION) * 100)
			currentLabel.text = "STABILIZING: %d%% (%0.1f MHz)" % [progressPct, displayVal]
			
		if stabilizerTime >= STABILIZE_DURATION:
			isStabilizing = false
			closeMinigame(true)

# helped functions
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
	if wireContainer: wireContainer.hide()
	if radioContainer: radioContainer.hide()
	$BGPanel/FixButton.show()
	
	match taskname:
		"FuseBox":
			$BGPanel/FixButton.hide()
			_start_wire_minigame()
		"Radio":
			$BGPanel/FixButton.hide()
			_start_radio_minigame()
		_:
			pass

# wire game
func _start_wire_minigame() -> void:
	if not wireContainer: return
	wireContainer.show()
	completedConnections = 0
	for oldLine in wireDrawingLayer.get_children():
		if oldLine != currentLine: oldLine.queue_free()
	currentLine.clear_points()
	selectedLeftWire = null
	
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
	
func _on_fix_button_pressed() -> void:
	closeMinigame(true)

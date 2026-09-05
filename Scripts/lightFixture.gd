extends Node3D

@onready var lightSource: OmniLight3D = $Light
@onready var meshInstance: MeshInstance3D = $MeshInstance3D

var gameManager = null

var isPowerOn: bool = true
var flickerTimer: float = 0
var targetFlickerDelay: float = 0.5

func _ready() -> void:
	add_to_group("bunkerLightsGroup")
	gameManager = get_tree().get_first_node_in_group("gameManagerGroup")
	
	if meshInstance and meshInstance.get_surface_override_material(0):
		var uniqueMat = meshInstance.get_surface_override_material(0).duplicate()
		meshInstance.set_surface_override_material(0, uniqueMat)

func _process(delta: float) -> void:
	if not isPowerOn:
		return
	
	if gameManager and gameManager.isGameActive:
		var timeRemaining = gameManager.timeLeft
		
		if timeRemaining <= 45:
			_execute_flicker_loop(delta, 0.05)
		elif timeRemaining <= 120:
			_execute_flicker_loop(delta, 0.2)
		else:
			if randf() < 0.002:
				_apply_visual_state(false)
			else:
				_apply_visual_state(true)

func setLightPower(state: bool) -> void:
	isPowerOn = state
	_apply_visual_state(state)
	
func _execute_flicker_loop(delta: float, delaySpeed: float) -> void:
	flickerTimer += delta
	if flickerTimer >= delaySpeed:
		flickerTimer = 0
		
		if lightSource:
			var nextState = !lightSource.visible
			_apply_visual_state(nextState)
			
func _apply_visual_state(state: bool) -> void:
	if lightSource:
		lightSource.visible = state
		
		if meshInstance:
			var material = meshInstance.get_surface_override_material(0)
			if material:
				material.emission_enabled = state

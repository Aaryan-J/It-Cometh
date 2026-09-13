extends Node3D

var sensitivity = 0.2

@onready var interactionRay: RayCast3D = $interactionRay
@onready var interactionPrompt: Label = $"../HUD/InteractionPrompt"
@onready var gameManager = get_tree().get_first_node_in_group("gameManagerGroup")
@onready var crosshair: ColorRect = $"../HUD/Crosshair"
@onready var flashlight: SpotLight3D = $Flashlight

var isDontLookBackActive: bool = false
var startingYRotation: float = 0.0

const ROTATION_THRESHOLD: float = 1.2

# cursor lock 
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
# input handling
func _input(event: InputEvent) -> void:
	# unlock cursor when escape is pressed
	if Input.is_action_just_pressed("escape"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# lock cursor when clicked on screen
	if event is InputEventMouseButton and event.pressed:
			if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# rotation
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		get_parent().rotate_y(deg_to_rad(-event.relative.x * sensitivity))
		rotate_x(deg_to_rad(-event.relative.y * sensitivity))
		rotation.x = clamp(rotation.x, deg_to_rad(-70), deg_to_rad(70))
		
	#interaction
	if Input.is_action_just_pressed("interact"):
		if interactionRay and interactionRay.is_colliding():
			var target = interactionRay.get_collider()
			if target is Interactable:
				print("raycast hit object: ", target.taskName)
				target.interact(get_parent())
				
	# TEMPORARY REMOVE LATER
	if Input.is_key_pressed(KEY_T) and not isDontLookBackActive:
		startDontLookBackEvent()
		
	# flashlight
	if Input.is_action_just_pressed("flashlight"):
		if flashlight:
			flashlight.visible = !flashlight.visible

func _process(delta: float) -> void:
	handleHUDPrompts()
	
	if isDontLookBackActive:
		var currentYRotation = get_parent().global_transform.basis.get_euler().y
		
		var angleDiff = abs(angle_difference(startingYRotation, currentYRotation))
		
		if angleDiff > ROTATION_THRESHOLD:
			triggerLookBackPenalty()
	
func startDontLookBackEvent() -> void:
	isDontLookBackActive = true
	
	startingYRotation = get_parent().global_transform.basis.get_euler().y
	print("NARRATOR: DO NOT LOOK BEHIND YOU.") # tts narrator
	
func triggerLookBackPenalty() -> void:
	isDontLookBackActive = false
	
	if gameManager:
		gameManager.applyLookBackPenalty()
	
func handleHUDPrompts() -> void:
	if interactionRay and interactionRay.is_colliding():
		var target = interactionRay.get_collider()
		if target is Interactable:
			if target.isBroken:
				interactionPrompt.text = "[E] Repair " + target.taskName
				return
			elif target.taskName == "TerminalCodeNote":
				interactionPrompt.text = "[E] Read Sticky Note"
				return
			
	if interactionPrompt: interactionPrompt.text = ""
	if crosshair: crosshair.color = Color.WHITE

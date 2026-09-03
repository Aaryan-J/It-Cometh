extends Node3D

var sensitivity = 0.2
@onready var interactionRay: RayCast3D = $Camera3D/interactionRay

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
				target.interact(get_parent())
				

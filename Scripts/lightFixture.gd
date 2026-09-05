extends Node3D

@onready var lightSource: OmniLight3D = $Light
@onready var meshInstance: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	add_to_group("bunkerLightsGroup")
	
func setLightPower(state: bool) -> void:
	if lightSource:
		lightSource.visible = state
		
		var material = meshInstance.get_surface_override_material(0)
		if material:
			material.emission_enabled = state
		

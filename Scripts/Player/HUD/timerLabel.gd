extends Label

@onready var gameManager = get_tree().get_first_node_in_group("gameManagerGroup")

var pulseTime: float = 0.0

func _process(delta: float) -> void:
	if not gameManager or not gameManager.isGameActive:
		text = "--:--"
		return
	
	var totalSeconds: float = gameManager.timeLeft
	
	var minutes: int = int(totalSeconds) / 60
	var seconds: int = int(totalSeconds) % 60
	text = "%02d:%02d" % [minutes, seconds]
	
	if totalSeconds <= 30.0:
		pulseTime += delta * 8.0
		var pulseWave = (sin(pulseTime) + 1.0)/2.0
		add_theme_color_override("font_color", Color(1, 0, 0).lerp(Color(1, 0.4, 0.4), pulseWave))
		scale = Vector2.ONE * (1 + (0.05 * pulseWave))
	else:
		add_theme_color_override("font_color", Color.WHITE)
		scale = Vector2.ONE

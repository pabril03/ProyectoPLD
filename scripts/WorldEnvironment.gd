extends CanvasModulate

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalSettings.brightness_updated.connect(_on_brightness_updated)

func _on_brightness_updated(value):
	var clamped_value = clamp(value, 0.2, 1.0)
	self.color = Color(clamped_value, clamped_value, clamped_value, 1.0)

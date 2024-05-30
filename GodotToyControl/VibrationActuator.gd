extends Node

@export var endpoint: VibrationEndpoint
@export var value: float:
	set(v):
		v = clamp(v, 0.0, 1.0)
		if is_equal_approx(value, v):
			return
		value = v
		GodotToyControl.vibrate_endpoint(endpoint, value)
		

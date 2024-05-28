extends "res://buttplug/ButtplugSubDevice.gd"

func vibrate(value: float):
	_parent.vibrate(value, _index)

func get_identifyer_string() -> String:
	return "%s - Vibe(%d)" % [_parent.device_display_name, _index]

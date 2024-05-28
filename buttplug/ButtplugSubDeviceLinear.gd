extends "res://buttplug/ButtplugSubDevice.gd"

func linear(value: float, time: float):
	_parent.linear(value, time, _index)

func get_identifyer_string() -> String:
	return "%s - Linear(%d)" % [_parent.device_display_name, _index]

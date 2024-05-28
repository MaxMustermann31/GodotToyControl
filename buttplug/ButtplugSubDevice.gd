extends RefCounted

const ButtplugDevice = preload("res://buttplug/ButtplugDevice.gd")

var _parent: ButtplugDevice
var _index: int

func _init(parent: ButtplugDevice, index: int):
	_parent = parent
	_index = index

func get_parent() -> ButtplugDevice:
	return _parent

func vibrate(_value):
	pass

func get_identifyer_string() -> String:
	return "%s - %d" % [_parent.device_display_name, _index]

extends Resource
class_name Endpoint

const ButtplugSubDeviceVibration = preload("res://buttplug/ButtplugSubDeviceVibration.gd")
const ButtplugSubDeviceLinear = preload("res://buttplug/ButtplugSubDeviceLinear.gd")

enum EndpointType {
	Vibrate,
	Linear
}

@export var name: String = ""

func accepts_device(device):
	match get_type():
		EndpointType.Vibrate:
			return device is ButtplugSubDeviceVibration
		EndpointType.Linear:
			return device is ButtplugSubDeviceLinear
	return false

func get_type() -> EndpointType:
	return EndpointType.Vibrate

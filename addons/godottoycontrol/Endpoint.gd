extends Resource
class_name Endpoint

enum EndpointType {
	Vibrate,
	Linear
}

@export var name: String = ""

func accepts_feature(feature: GSFeature):
	match get_type():
		EndpointType.Vibrate:
			return feature.actuator_type == "Vibrate"
		EndpointType.Linear:
			return feature.actuator_type == "Position"
	return false

func get_type() -> EndpointType:
	return EndpointType.Vibrate

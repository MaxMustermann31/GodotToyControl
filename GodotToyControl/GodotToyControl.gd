extends Node

signal endpoint_connected(endpoint, feature)
signal endpoint_disconnected(endpoint, feature)


func connect_feature_to_endpoint(endpoint: Endpoint, feature: GSFeature):
	if not endpoint in _endpoint_connections:
		_endpoint_connections[endpoint] = {}
	if feature in _endpoint_connections[endpoint]:
		return
	if not endpoint.accepts_feature(feature):
		return
	disconnect_feature_from_all_endpoints(feature)
	_endpoint_connections[endpoint][feature] = true
	endpoint_connected.emit(endpoint, feature)

func disconnect_feature_from_all_endpoints(feature: GSFeature):
	for endpoint in _endpoint_connections:
		if feature in _endpoint_connections[endpoint]:
			disconnect_feature_from_endpoint(endpoint, feature)
	
func disconnect_feature_from_endpoint(endpoint: Endpoint, feature: GSFeature):
	if not endpoint in _endpoint_connections:
		return
	if not feature in _endpoint_connections[endpoint]:
		return
	_endpoint_connections[endpoint].erase(feature)
	GSClient.stop_feature(feature)
	endpoint_disconnected.emit(endpoint, feature)

func get_endpoint_features(endpoint: Endpoint) -> Array:
	if not endpoint in _endpoint_connections:
		return []
	return _endpoint_connections[endpoint].keys()
	

func vibrate_endpoint(endpoint: Endpoint, value: float):
	if not endpoint in _endpoint_connections:
		return
	var features = _endpoint_connections[endpoint]
	for feature in features:
		GSClient.send_feature(feature, value)


func linear_endpoint(endpoint: Endpoint, value: float, duration: float):
	if not endpoint in _endpoint_connections:
		return
	var features = _endpoint_connections[endpoint]
	for feature in features:
		GSClient.send_feature(feature, value, int(duration * 1000))

# private

var _endpoint_connections := {}

func _ready():
	GSClient.client_connection_changed.connect(_gsclient_connection_changed)
	GSClient.client_device_removed.connect(_gsclient_device_removed)

func _gsclient_connection_changed(_connected):
	for endpoint in _endpoint_connections.keys():
		var features = _endpoint_connections[endpoint]
		for feature in features:
			endpoint_disconnected.emit(endpoint, feature)
	_endpoint_connections = {}

func _gsclient_device_removed(device: GSDevice):
	var device_features = {}
	for feature in device.features:
		device_features[feature] = true
	for endpoint in _endpoint_connections.keys():
		var features = _endpoint_connections[endpoint]
		for feature in features:
			if not feature in device_features:
				continue
			endpoint_disconnected.emit(endpoint, feature)
			_endpoint_connections[endpoint].erase(feature)

extends Tree


func _get_drag_data(at_position):
	var tree_item = get_item_at_position(at_position)
	if not tree_item:
		return null
	var device = tree_item.get_metadata(0)
	if not device is GSClient and not device is GSFeature:
		return null
	return device

func _can_drop_data(_at_position, data):
	if data is GSFeature:
		return true
	return false

func _drop_data(_at_position, data):
	if not data is GSFeature:
		return
	GodotToyControl.disconnect_feature_from_all_endpoints(data)

func _ready():
	create_item()
	GSClient.client_device_list_received.connect(device_list_received)
	GSClient.client_connection_changed.connect(client_connection_changed)
	GSClient.client_device_added.connect(device_added)
	GSClient.client_device_removed.connect(device_removed)
	device_list_received(GSClient.get_devices())

func device_list_received(list: Array):
	var known_devices := {}
	var root = get_root()
	for child in root.get_children():
		var device = child.get_metadata(0)
		if device is GSDevice:
			known_devices[device] = true
	
	for device in list:
		if not device in known_devices:
			device_added(device)

func device_added(device: GSDevice):
	var root = get_root()
	var device_item = root.create_child()
	device_item.set_text(0, device.device_name)
	device_item.set_metadata(0, device)
	for feature in device.features:
		if not ((feature.feature_command == GSMessage.MESSAGE_TYPE_SCALAR_CMD and  feature.actuator_type == "Vibrate") or \
			(feature.feature_command == GSMessage.MESSAGE_TYPE_LINEAR_CMD and feature.actuator_type == "Position")):
			continue
		var feature_item = device_item.create_child()
		feature_item.set_text(0, "%s: %s(%d)" % [feature.device.device_name, feature.actuator_type, feature.feature_index])
		feature_item.set_metadata(0, feature)

func device_removed(device: GSDevice):
	var root = get_root()
	for device_item in root.get_children():
		if device_item.get_metadata(0) == device:
			device_item.free()

func client_connection_changed(connected: bool):
	if not connected:
		clear()
		create_item()

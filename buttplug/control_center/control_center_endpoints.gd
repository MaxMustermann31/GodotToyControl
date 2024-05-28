extends Tree

const ButtplugDevice = preload("res://buttplug/ButtplugDevice.gd")
const ButtplugSubDevice = preload("res://buttplug/ButtplugSubDevice.gd")

func _ready():
	#Buttplug.device_removed.connect(self.on_device_removed)
	Buttplug.endpoint_connected.connect(self.on_endpoint_connected)
	Buttplug.endpoint_disconnected.connect(self.on_endpoint_disconnected)

func _get_drag_data(at_position):
	var tree_item = get_item_at_position(at_position)
	if not tree_item:
		return
	var device = tree_item.get_metadata(0)
	if not device or not device is ButtplugSubDevice:
		return
	return device

func _can_drop_data(at_position, data):
	if not data is ButtplugDevice and not data is ButtplugSubDevice:
		return false
	var tree_item = get_item_at_position(at_position)
	if not tree_item:
		return false
	if tree_item.get_parent() != get_root():
		return false
	var endpoint = tree_item.get_metadata(0)
	if data is ButtplugDevice:
		for sub_device in data.get_sub_devices():
			if endpoint.accepts_device(sub_device):
				return true
		return false
	elif data is ButtplugSubDevice:
		return endpoint.accepts_device(data)
	return false

func _drop_data(at_position, device):
	var tree_item = get_item_at_position(at_position)
	var endpoint = tree_item.get_metadata(0)
	if not endpoint is Endpoint:
		return
	if device is ButtplugDevice:
		for sub_device in device.get_sub_devices():
			Buttplug.connect_endpoint(endpoint, sub_device)
	elif device is ButtplugSubDevice:
		Buttplug.connect_endpoint(endpoint, device)

func update_list(endpoints):
	clear()
	var root = create_item()
	for endpoint in endpoints:
		var endpoint_name = endpoint.name
		var endpoint_item =  root.create_child()
		endpoint_item.set_text(0, endpoint_name)
		endpoint_item.set_metadata(0, endpoint)
		var devices = Buttplug.get_endpoint_devices(endpoint)
		for device in devices:
			add_device_to_endpoint(endpoint_item, device)

func on_endpoint_connected(endpoint: Endpoint, device: ButtplugSubDevice):
	var root = get_root()
	for child in root.get_children():
		if child.get_metadata(0) == endpoint:
			add_device_to_endpoint(child, device)
			break

func on_endpoint_disconnected(endpoint: Endpoint, device: ButtplugSubDevice):
	var root = get_root()
	for child in root.get_children():
		if child.get_metadata(0) == endpoint:
			remove_device_from_endpoint(child, device)
			break


func add_device_to_endpoint(endpoint_item: TreeItem, device: ButtplugSubDevice):
	var item = endpoint_item.create_child()
	item.set_text(0, device.get_identifyer_string())
	item.set_metadata(0, device)


func remove_device_from_endpoint(endpoint_item: TreeItem, device: ButtplugSubDevice):
	for child in endpoint_item.get_children():
		if child.get_metadata(0) == device:
			child.free()

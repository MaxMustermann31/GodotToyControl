extends Tree

const ButtplugDevice = preload("res://buttplug/ButtplugDevice.gd")
const ButtplugSubDevice = preload("res://buttplug/ButtplugSubDevice.gd")


func _get_drag_data(at_position):
	var tree_item = get_item_at_position(at_position)
	if not tree_item:
		return null
	var device = tree_item.get_metadata(0)
	if not device is ButtplugDevice and not device is ButtplugSubDevice:
		return null
	return device

func _can_drop_data(_at_position, data):
	if data is ButtplugSubDevice:
		return true
	return false

func _drop_data(_at_position, data):
	if not data is ButtplugSubDevice:
		return
	Buttplug.disconnect_device_from_all_endpoint(data)

func _ready():
	create_item()
	Buttplug.device_added.connect(device_added)
	Buttplug.device_removed.connect(device_removed)
	for device in Buttplug.get_devices():
		device_added(device)

func device_added(device: ButtplugDevice):
	var root = get_root()
	var device_item = root.create_child()
	device_item.set_text(0, device.device_name)
	device_item.set_metadata(0, device)
	for sub_device in device.get_sub_devices():
		var sub_device_item = device_item.create_child()
		sub_device_item.set_text(0, sub_device.get_identifyer_string())
		sub_device_item.set_metadata(0, sub_device)

func device_removed(device: ButtplugDevice):
	var root = get_root()
	for device_item in root.get_children():
		if device_item.get_metadata(0) == device:
			device_item.free()


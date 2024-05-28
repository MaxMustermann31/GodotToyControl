extends RefCounted

const ButtplugSubDevice = preload("res://buttplug/ButtplugSubDevice.gd")
const ButtplugSubDeviceVibration = preload("res://buttplug/ButtplugSubDeviceVibration.gd")
const ButtplugSubDeviceLinear = preload("res://buttplug/ButtplugSubDeviceLinear.gd")

var device_name
var device_index
var device_display_name
var valid
var should_stop := false
var dirty := false

var sub_devices := []
var scalar_list := []
var linear_list := []

func stop():
	if not valid:
		return
	should_stop = true
	_mark_dirty()

func vibrate(value: float, index: int):
	if not valid:
		return
	var found = false
	for vibration in scalar_list:
		if vibration["Index"] == index and vibration["ActuatorType"] == "Vibrate":
			vibration["Scalar"] = value
			found = true
			break
	if not found:
		scalar_list.push_back({
			"Index": index,
			"Scalar": value,
			"ActuatorType": "Vibrate",
		})
		_mark_dirty()

func linear(value: float, time: float, index: int):
	if not valid:
		return
	var found = false
	for linear_move in linear_list:
		if linear_move["Index"] == index:
			linear_move["Position"] = value
			linear_move["Duration"] = int(time * 1000)
			found = true
			break
	if not found:
		linear_list.push_back({
			"Index": index,
			"Position": value,
			"Duration": int(time * 1000),
		})
		_mark_dirty()

func get_sub_devices():
	return sub_devices

# private

func _mark_dirty():
	if not dirty:
		dirty = true
		_actuate_deferred.call_deferred()


func _actuate_deferred():
	if should_stop:
		_send_stop_device()
	else:
		if not scalar_list.is_empty():
			_scalarCmd(scalar_list)
		if not linear_list.is_empty():
			_linearCmd(linear_list)
	
	should_stop = false
	scalar_list = []
	linear_list = []
	dirty = false

func _init(_device_name: String, _device_index: int, _device_display_name: String, device_messages: Dictionary):
	device_name = _device_name
	device_display_name = _device_display_name
	device_index = _device_index
	valid = true
	var scalar_cmd = device_messages["ScalarCmd"] if "ScalarCmd" in device_messages else []
	for i in scalar_cmd.size():
		var feature = scalar_cmd[i]
		if not "ActuatorType" in feature:
			continue
		if feature["ActuatorType"] == "Vibrate":
			sub_devices.push_back(ButtplugSubDeviceVibration.new(self, i))
	var linear_cmd = device_messages["LinearCmd"] if "LinearCmd" in device_messages else []
	for i in linear_cmd.size():
		var feature = linear_cmd[i]
		if not "ActuatorType" in feature:
			continue
		if feature["ActuatorType"] == "Position":
			sub_devices.push_back(ButtplugSubDeviceLinear.new(self, i))

func _remove():
	valid = false

func _send_stop_device():
	var packet = {
		"Id": Buttplug._next_id(),
		"DeviceIndex": device_index,
	}
	return Buttplug._send_packet("StopDeviceCmd", packet)

func _scalarCmd(scalars: Array):
	var packet = {
		"Id": Buttplug._next_id(),
		"DeviceIndex": device_index,
		"Scalars": scalars,
	}
	return Buttplug._send_packet("ScalarCmd", packet)

func _linearCmd(scalars: Array):
	var packet = {
		"Id": Buttplug._next_id(),
		"DeviceIndex": device_index,
		"Vectors": scalars,
	}
	return Buttplug._send_packet("LinearCmd", packet)

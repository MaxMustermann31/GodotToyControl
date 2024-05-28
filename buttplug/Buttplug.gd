extends Node

signal connected()
signal disconnected(code)
signal device_added(device)
signal device_removed(device)
signal endpoint_connected(endpoint, device)
signal endpoint_disconnected(endpoint, device)
signal buttplug_log(message)

# public API

## Try to connect to a buttplug server listening on [param url] with the client
## name [param client_name].
func client(url: String, client_name: String):
	_cleanup()
	_client_name = client_name
	if url.is_empty():
		url = "ws://localhost:12345"
	_socket = WebSocketPeer.new()
	var err = _socket.connect_to_url(url)
	if err != OK:
		_log_message("Unable to connect to buttplug: %s" % error_string(err))
		return err
	set_process(true)
	state = State.WEBSOCKET_CONNECTING
	buttplug_log.emit("Connecting %s to buttplug" % client_name)
	return OK

## Diconnect from the buttplug server.
func disconnect_client():
	_cleanup()
	_log_message("Disconnecting %s from %s" % [_client_name, _server_name])
	if _socket:
		_socket.close()
	else:
		set_process(false)

func is_client_connected():
	return state == State.CONNECTED

func is_client_connecting():
	return state == State.WEBSOCKET_CONNECTING || state == State.BUTTPLUG_CONNECTING

func get_server_name():
	return _server_name

func start_scanning():
	if state != State.CONNECTED:
		return ERR_CONNECTION_ERROR
	var request = _send_start_scanning()
	await request.finished
	if request.response_type == request.ResponseType.Ok:
		_log_message("Starting scanning")
		return OK
	else:
		return request.response_value

func stop_scanning():
	if state != State.CONNECTED:
		return ERR_CONNECTION_ERROR
	var request = _send_stop_scanning()
	await request.finished
	if request.response_type == request.ResponseType.Ok:
		return OK
	else:
		return request.response_value
		
func request_device_list():
	if state != State.CONNECTED:
		return ERR_CONNECTION_ERROR
	var request = _send_request_device_list()
	await request.finished
	if request.response_type == request.ResponseType.Ok:
		return OK
	else:
		return request.response_value

func stop_all_devices():
	if state != State.CONNECTED:
		return ERR_CONNECTION_ERROR
	var request = _send_stop_all_devices()
	await request.finished
	if request.response_type == request.ResponseType.Ok:
		return OK
	else:
		return request.response_value

func get_devices():
	return _device_list.values()

func connect_endpoint(endpoint: Endpoint, device: ButtplugSubDevice):
	if not endpoint in _endpoint_connections:
		_endpoint_connections[endpoint] = {}
	if device in _endpoint_connections[endpoint]:
		return
	if not endpoint.accepts_device(device):
		return
	disconnect_device_from_all_endpoint(device)
	_endpoint_connections[endpoint][device] = true
	endpoint_connected.emit(endpoint, device)

func disconnect_device_from_all_endpoint(device: ButtplugSubDevice):
	for endpoint in _endpoint_connections:
		if device in _endpoint_connections[endpoint]:
			disconnect_endpoint(endpoint, device)
	
func disconnect_endpoint(endpoint: Endpoint, device: ButtplugSubDevice):
	if not endpoint in _endpoint_connections:
		return
	if not device in _endpoint_connections[endpoint]:
		return
	_endpoint_connections[endpoint].erase(device)
	device.get_parent().stop()
	endpoint_disconnected.emit(endpoint, device)

func get_endpoint_devices(endpoint: Endpoint) -> Array:
	if not endpoint in _endpoint_connections:
		return []
	return _endpoint_connections[endpoint].keys()
	

func vibrate_endpoint(endpoint: Endpoint, value: float):
	if not endpoint in _endpoint_connections:
		return
	var devices = _endpoint_connections[endpoint]
	for device in devices:
		device.vibrate(value)


func linear_endpoint(endpoint: Endpoint, value: float, duration: float):
	if not endpoint in _endpoint_connections:
		return
	var devices = _endpoint_connections[endpoint]
	for device in devices:
		device.linear(value, duration)

# private

const Request := preload("res://buttplug/Request.gd")
const ButtplugDevice := preload("res://buttplug/ButtplugDevice.gd")
const ButtplugSubDevice = preload("res://buttplug/ButtplugSubDevice.gd")

enum State {
	DISCONNECTED,
	WEBSOCKET_CONNECTING,
	BUTTPLUG_CONNECTING,
	CONNECTED,
}
var state: State = State.DISCONNECTED

var _socket: WebSocketPeer
var _current_id = 1
var _pending_requests := {}
var _client_name: String
var _server_name: String
var _device_list := {}
var _endpoint_connections := {}


func _ready():
	set_process(false)


func _process(_delta):
	_socket.poll()
	var ws_state = _socket.get_ready_state()
	match ws_state:
		WebSocketPeer.STATE_OPEN:
			if state == State.WEBSOCKET_CONNECTING:
				state = State.BUTTPLUG_CONNECTING
				_send_request_server_info()
			while _socket.get_available_packet_count():
				_handle_packet(_socket.get_packet())
		WebSocketPeer.STATE_CLOSING:
			# Keep polling to achieve proper close.
			pass
		WebSocketPeer.STATE_CLOSED:
			var code = _socket.get_close_code()
			var reason = _socket.get_close_reason()
			_log_message("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
			disconnected.emit(code)
			_socket = null
			state = State.DISCONNECTED
			_cleanup()
			set_process(false)

func _handle_packet(packet: PackedByteArray):
	var packet_unpacked = JSON.parse_string(packet.get_string_from_utf8())
	for obj in packet_unpacked:
		for packet_name in obj.keys():
			if not packet_name in on_receive:
				continue
			var packet_value = obj[packet_name]
			var request
			if "Id" in packet_value:
				request = _get_pending_request(packet_value["Id"])
			on_receive[packet_name].call(packet_value, request)

func _log_message(message: String):
	buttplug_log.emit(message)

func _cleanup():
	_current_id = 1
	_client_name = ""
	_server_name = ""
	for device_id in _device_list.keys():
		_remove_device(device_id)
	_device_list = {}
	_endpoint_connections = {}
	_pending_requests = {}

func _next_id() -> int:
	var result = _current_id
	_current_id += 1
	return result

func _send_packet(packet_name: String, packet: Dictionary):
	var message = JSON.stringify([{
		packet_name: packet
	}])
	_socket.send_text(message)
	if not "Id" in packet:
		return
	var id = packet["Id"]
	var request = Request.new()
	_pending_requests[id] = request
	return request

func _send_request_server_info():
	var packet = {
		Id = _next_id(),
		ClientName = _client_name,
		MessageVersion = 3,
	}
	return _send_packet("RequestServerInfo", packet)

func _send_start_scanning():
	var packet = {
		Id = _next_id(),
	}
	return _send_packet("StartScanning", packet)

func _send_stop_scanning():
	var packet = {
		Id = _next_id(),
	}
	return _send_packet("StopScanning", packet)

func _send_request_device_list():
	var packet = {
		Id = _next_id(),
	}
	return _send_packet("RequestDeviceList", packet)

func _send_stop_all_devices():
	var packet = {
		Id = _next_id(),
	}
	return _send_packet("StopAllDevices", packet)


func _get_pending_request(id: int):
	if not id in _pending_requests:
		return null
	var result = _pending_requests[id]
	_pending_requests.erase(id)
	return result

var on_receive = {
	"Ok": func(_packet: Dictionary, request):
		if not request:
			return
		request.ok(),
	"Error": func(packet: Dictionary, request):
		_log_message("Error: %s" % packet["ErrorMessage"])
		request.error(packet["ErrorMessage"]),
	"ServerInfo": func(packet: Dictionary, _request):
		_server_name = packet["ServerName"]
		state = State.CONNECTED
		_log_message("Connected to %s" % _server_name)
		connected.emit(),
	"DeviceList": func(packet: Dictionary, request):
		if not request:
			return
		var devices = packet["Devices"]
		for device in devices:
			_add_device(device)
		request.ok(),
	"DeviceAdded": func(packet: Dictionary, _request):
		_add_device(packet),
	"DeviceRemoved": func(packet: Dictionary, _request):
		var device_index = packet["DeviceIndex"]
		_remove_device(device_index),
}

func _add_device(device_definition: Dictionary):
	var device_index = device_definition["DeviceIndex"] as int
	if device_index in _device_list:
		return
	var device_name = device_definition["DeviceName"]
	var device_display_name = device_definition["DeviceDisplayName"] if "DeviceDisplayName" in device_definition else device_name
	var device_messages = device_definition["DeviceMessages"]
	var device = ButtplugDevice.new(device_name, device_index, device_display_name, device_messages)
	_device_list[device_index] = device
	_log_message("Device %s connected." % device_display_name)
	device_added.emit(device)

func _remove_device(device_index: int):
	if not device_index in _device_list:
		return
	var device = _device_list[device_index]
	device._remove()
	for endpoint in _endpoint_connections:
		for sub_device in device.get_sub_devices():
			disconnect_endpoint(endpoint, sub_device)
	_device_list.erase(device_index)
	_log_message("Device %s disconnected." % device.device_display_name)
	device_removed.emit(device)

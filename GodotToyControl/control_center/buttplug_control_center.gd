extends Control

@export var endpoints: Array[Endpoint] = []
@export var show_send_message: bool = false

@onready var host = %host
@onready var port = %port
@onready var connect_button = $%connect
@onready var log_textfield = %log_textfield
@onready var endpoints_node = %endpoints

func print_log(value: String):
	if value.begins_with("Sending message") and not show_send_message:
		return
	log_textfield.append_text(value + "\n")

func set_url_editable(value: bool):
	host.editable = value
	port.editable = value

func _on_connect_pressed():
	if connect_button.text == "Disconnect":
		set_url_editable(false)
		set_connect_text(false)
		GSClient.stop()
		return
		
	var host_value = GSClient.DEFAULT_HOST if host.text.is_empty() else host.text
	var port_value = GSClient.DEFAULT_PORT if port.text.is_empty() else int(port.text)
	var resp = GSClient.start(host_value, port_value)
	print(resp)
	if resp != OK:
		return
	set_connect_button_enabled_state()
	set_url_editable(false)
	

func _ready():
	GSClient.client_connection_changed.connect(self.gsclient_connection_changed)
	GSClient.client_message.connect(self.print_log)
	set_connect_text(GSClient.get_client_state() == GSClient.ClientState.CONNECTED)
	set_connect_button_enabled_state()
	set_url_editable(GSClient.get_client_state() == GSClient.ClientState.DISCONNECTED)
	endpoints_node.update_list(endpoints)

func _on_stop_pressed():
	GSClient.stop_all_devices()

func gsclient_connection_changed(connected: bool):
	set_connect_text(connected)
	set_url_editable(not connected)
	set_connect_button_enabled_state()
	if connected:
		GSClient.request_device_list()

func set_connect_text(disconnect_text: bool):
	connect_button.text = "Disconnect" if disconnect_text else "Connect"


func set_connect_button_enabled_state():
	connect_button.disabled = GSClient.get_client_state() != GSClient.ClientState.CONNECTED and GSClient.get_client_state() != GSClient.ClientState.DISCONNECTED


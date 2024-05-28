extends Control

@export var endpoints: Array[Endpoint] = []

const ButtplugDevice = preload("res://buttplug/ButtplugDevice.gd")

@onready var url = $%url
@onready var connect_button = $%connect
@onready var log_textfield = %log_textfield
@onready var endpoints_node = %endpoints

func print_log(value: String):
	log_textfield.append_text(value + "\n")


func _on_connect_pressed():
	url.editable = false
	if connect_button.text == "Disconnect":
		set_connect_text(false)
		Buttplug.disconnect_client()
		return
		
	connect_button.disabled = true
	Buttplug.client(url.text, "GodotButtplug")

func on_buttplug_connected():
	set_connect_text(true)
	await Buttplug.request_device_list()

func _ready():
	Buttplug.connected.connect(self.on_buttplug_connected)
	Buttplug.disconnected.connect(self.on_disconnected)
	Buttplug.buttplug_log.connect(self.print_log)
	if Buttplug.is_client_connected():
		set_connect_text(true)
	elif Buttplug.is_client_connecting():
		connect_button.disabled = true
	url.editable = not Buttplug.is_client_connected() and not Buttplug.is_client_connecting()
	endpoints_node.update_list(endpoints)

func _on_stop_pressed():
	Buttplug.stop_all_devices()

func on_disconnected(_code):
	url.editable = true
	set_connect_text(false)
	connect_button.disabled = false

func set_connect_text(disconnect_text: bool):
	connect_button.disabled = false
	if disconnect_text:
		connect_button.text = "Disconnect"
	else:
		connect_button.text = "Connect"


func _input(event):
	if not event.is_action("ui_accept"):
		return
	$EndpointActuator2.value = 1.0 if event.is_pressed() else 0.0

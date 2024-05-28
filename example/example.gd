extends Control

@onready var panel_container = %PanelContainer
@onready var vibrator_animation_player = %vibrator_AnimationPlayer
@onready var vibration_actuator = %VibrationActuator
@onready var vibrator_slider = %vibrator_slider
@onready var linear_animation_player = $VBoxContainer/Control/HBoxContainer/VBoxContainer2/linear_AnimationPlayer
@onready var linear_actuator = $VBoxContainer/Control/HBoxContainer/VBoxContainer2/LinearActuator
@onready var linear_slider = %linear_slider

func _ready():
	panel_container.hide()

func _on_show_config_pressed():
	panel_container.visible = not panel_container.visible


func _on_vibrator_pattern_pressed():
	if not vibrator_animation_player.is_playing():
		vibrator_animation_player.play("vibrate")
		vibrator_slider.editable = false
	else:
		vibrator_animation_player.stop()
		vibrator_slider.editable = true


func _on_vibrator_slider_value_changed(value):
	if not vibrator_slider.editable:
		return
	vibration_actuator.value = value



func _on_linear_pattern_pressed():
	if not linear_animation_player.is_playing():
		linear_animation_player.play("linear")
		linear_slider.editable = false
	else:
		linear_animation_player.stop()
		linear_slider.editable = true

func _on_linear_slider_value_changed(value):
	if not linear_slider.editable:
		return
	linear_actuator.actuate(value, 0.1)

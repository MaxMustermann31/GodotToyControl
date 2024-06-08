@tool
extends EditorPlugin


func _enter_tree():
	add_autoload_singleton("GodotToyControl", "GodotToyControl.gd")


func _exit_tree():
	remove_autoload_singleton("GodotToyControl")

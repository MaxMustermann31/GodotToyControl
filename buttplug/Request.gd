extends RefCounted

enum ResponseType {
	Ok,
	Error,
}

signal finished()

var response_type
var response_value

func ok():
	response_type = ResponseType.Ok
	finished.emit()

func error(value: String):
	response_type = ResponseType.Error
	response_value = value
	finished.emit()

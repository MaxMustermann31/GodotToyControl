extends Node

@export var endpoint: LinearEndpoint
@export_range(0.0, 1.0) var position: float = 0.0

@export var animation_player: AnimationPlayer

func actuate(value: float, time: float):
	GodotToyControl.linear_endpoint(endpoint, value, time)

# private

var _current_animation: Animation
var _current_track: int = -1
var _current_keyframe: int = 0
var _keyframe_count: int = 0
var _current_keyframe_time: float
var _next_keyframe_time: float

func _ready():
	if animation_player:
		animation_player.animation_started.connect(self._animation_started)

	set_process(animation_player and _current_animation and _current_track != -1)

func _process(_delta):
	if not animation_player.is_playing():
		set_process(false)
		return
	
	var current_animation_position = animation_player.current_animation_position
	var new_keyframe = false
	if current_animation_position < _current_keyframe_time:
		_init_track()
	while current_animation_position >= _next_keyframe_time and _current_keyframe + 2 < _keyframe_count:
		_current_keyframe += 1
		_current_keyframe_time = _next_keyframe_time
		_next_keyframe_time = _current_animation.track_get_key_time(_current_track, _current_keyframe + 1)
		new_keyframe = true
	if new_keyframe:
		var delta_time = _next_keyframe_time - current_animation_position
		delta_time /= animation_player.get_playing_speed()
		var target_position = _current_animation.track_get_key_value(_current_track, _current_keyframe + 1)
		actuate(target_position, delta_time)

func _animation_started(animation: String):
	var root_node = animation_player.get_node(animation_player.root_node)
	var node_path = root_node.get_path_to(self)
	_current_animation = animation_player.get_animation(animation)
	_current_track = _current_animation.find_track(node_path.get_concatenated_names() + ":position", Animation.TYPE_VALUE)
	if _current_track != -1 and animation_player:
		_init_track()
		set_process(true)

func _init_track():
	_current_keyframe = -1
	_current_keyframe_time = 0.0
	_next_keyframe_time = _current_animation.track_get_key_time(_current_track, _current_keyframe + 1)
	_keyframe_count = _current_animation.track_get_key_count(_current_track)

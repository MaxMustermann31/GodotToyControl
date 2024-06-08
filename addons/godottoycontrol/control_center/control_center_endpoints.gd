extends Tree

func _ready():
	GodotToyControl.endpoint_connected.connect(self.on_endpoint_connected)
	GodotToyControl.endpoint_disconnected.connect(self.on_endpoint_disconnected)

func _get_drag_data(at_position):
	var tree_item = get_item_at_position(at_position)
	if not tree_item:
		return
	var feature = tree_item.get_metadata(0)
	if not feature or not feature is GSFeature:
		return
	return feature

func _can_drop_data(at_position, data):
	if not data is GSDevice and not data is GSFeature:
		return false
	var tree_item = get_item_at_position(at_position)
	if not tree_item:
		return false
	if tree_item.get_parent() != get_root():
		return false
	var endpoint = tree_item.get_metadata(0)
	if data is GSDevice:
		for feature in data.features:
			if endpoint.accepts_feature(feature):
				return true
		return false
	elif data is GSFeature:
		return endpoint.accepts_feature(data)
	return false

func _drop_data(at_position, data):
	var tree_item = get_item_at_position(at_position)
	var endpoint = tree_item.get_metadata(0)
	if not endpoint is Endpoint:
		return
	if data is GSDevice:
		for feature in data.features:
			GodotToyControl.connect_feature_to_endpoint(endpoint, feature)
	elif data is GSFeature:
		GodotToyControl.connect_feature_to_endpoint(endpoint, data)

func update_list(endpoints):
	clear()
	var root = create_item()
	for endpoint in endpoints:
		var endpoint_name = endpoint.name
		var endpoint_item =  root.create_child()
		endpoint_item.set_text(0, endpoint_name)
		endpoint_item.set_metadata(0, endpoint)
		var features = GodotToyControl.get_endpoint_features(endpoint)
		for feature in features:
			add_feature_to_endpoint(endpoint_item, features)

func on_endpoint_connected(endpoint: Endpoint, device: GSFeature):
	var root = get_root()
	for child in root.get_children():
		if child.get_metadata(0) == endpoint:
			add_feature_to_endpoint(child, device)
			break

func on_endpoint_disconnected(endpoint: Endpoint, device: GSFeature):
	var root = get_root()
	for child in root.get_children():
		if child.get_metadata(0) == endpoint:
			remove_feature_from_endpoint(child, device)
			break


func add_feature_to_endpoint(endpoint_item: TreeItem, feature: GSFeature):
	var item = endpoint_item.create_child()
	item.set_text(0, "%s: %s(%d)" % [feature.device.device_name, feature.actuator_type, feature.feature_index])
	item.set_metadata(0, feature)


func remove_feature_from_endpoint(endpoint_item: TreeItem, feature: GSFeature):
	for child in endpoint_item.get_children():
		if child.get_metadata(0) == feature:
			child.free()

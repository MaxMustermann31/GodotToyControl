# GodotToyControl

GodotToyControl is a collection of scripts for godot that help interact with buttplug.io to control sex toys from the game engine.

It currently supports vibrating toys and somewhat supports one axis linear toys. It abstracts the individual toys away so developers can interact with custom defined virtual toys (`VibrationActuator` and `LinearActuator`, see below).

A basic configuarion panel is provided in buttplug/control_center/ which allows to connect real world toys to virtual toys/endpoints. How it is used is presented in a small example application in example/.

## Buttplug.gd

This is the main class of this project. It has to be added as a singleton called `Buttplug` in order to be accessible from the other scripts.

### methods

```
Buttplug.client(url, client_name)
```

Connect to a buttplug instance at `url` using the client name `client_name`. Has to be called before any other function.
Once a connection is esatblished, `connected` is emitted.

```
Buttplug.disconnect()
```

Close an existing connection.
On success `disconnected(code)` is emitted where `code` is the status code of the underlying websocket connection.

```
Buttplug.is_client_connected()
Buttplug.is_client_connecting()
```

These functions give more information about the current connection status.

```
Buttplug.get_server_name()
```

Returns the name of the connected server.

```
Buttplug.start_scanning()
Buttplug.stop_scanning()
```

Tell the server to start/stop scanning for new devices.

```
Buttplug.request_device_list()
```

Requests a list of all currently connected devices from the server. This has to be called once after the connection is established to initialize the device list known by godot.

```
Buttplug.stop_all_devices()
```

Stop every device. Useful as a panik button.

```
Buttplug.get_devices()
```

Returns an Array of all currently known devices. Every device is an instance of `ButtplugDevice.gd`

```
Buttplug.connect_endpoint(endpoint, device)
```

Connects the `Endpoint.gd` endpoint with the `ButtplugSubDevice.gd` device.


```
Buttplug.disconnect_device_from_all_endpoints(device)
```

Disconnects the `ButtplugSubDevice.gd` device from every endpoint it is currently connected with.

```
Buttplug.disconnect_device_from_endpoint(endpoint, device)
```

Disconnects the `ButtplugSubDevice.gd` device from the `Endpoint.gd` endpoint.

```
Buttplug.get_endpoint_devices(endpoint)
```

Returns an Array of all `ButtplugSubDevice.gd` devices currently connected to the endpoint `endpoint`.

```
Buttplug.vibrate_endpoint(endpoint, value)
```

Tell every device connected to the `Endpoint.gd` endpoint to vibrate with a strength of `value`. `value` has to be in the range from `0.0` to `1.0`.

```
Buttplug.linear_endpoint(endpoint, value, duration)
```

Tell every device connected to the `Endpoint.gd` endpoint to move to position `value` within `duration` seconds. `value` has to be in the range from `0.0` to `1.0`.

### signals

```
signal connected()
```

Emitted after a connection with the buttplug server has been established.

```
signal disconnected(code)
```

Emitted after a connection with the buttplug server has been terminated. `code` is the status code of the underlying websocket connection.

```
signal device_added(device)
```

Emitted when a new device has been connected to the server or after a device list with previously unknown devices was received. `device` is of type `ButtplugDevice.gd`.

```
signal device_removed(device)
```

Emitted when a device has been disconnected to the server or the connection with the server was terminated. `device` is of type `ButtplugDevice.gd`.

```
signal endpoint_connected(endpoint, device)
```

Emitted when a `ButtplugSubDevice.gd` `device` has been connected to an `Endpoint.gd` `endpoint`.

```
signal endpoint_disconnected(endpoint, device)
```

Emitted when a `ButtplugSubDevice.gd` `device` has been disconnected from an `Endpoint.gd` `endpoint`.

```
signal buttplug_log(message)
```

Emitted when an event happened that might be useful for debugging. `message` contains a String, for example the error string send from the buttplug.io server in case of a malformed package.

## ButtplugDevice.gd

### methods

```
stop()
```

Stops the current action performed by the device.

```
get_sub_devices()
```

Returns an Array of `ButtplugSubDevice.gd` objects, one for each vibrator/linear actuator of the device.

## ButtplugSubDeviceVibration.gd

This represents a single vibration motor of a `ButtplugDevice.gd` device. It should be treated as an opaque object and passed along to `Buttplug.connect_endpoint`.

## ButtplugSubDeviceLinear.gd

This represents a single linear motor of a `ButtplugDevice.gd` device. It should be treated as an opaque object and passed along to `Buttplug.connect_endpoint`.

## VibrationActuator.tscn

This node represents the main interaction point to vibrating toys. It abstracts away the individual toys and allows developers to craft user experiences that can be mapped to toys by the user.

### members

```
endpoint
```

A `VibrationEndpoint.gd` object. Pass this to `Buttplug.connect_endpoint` in order to connect it to devices.

```
value
```

The vibration strength of connected toys. Every time this value changes a message is send to all connected toys.


## LinearActuator.tscn

This node represents the main interaction point to linear toys. It abstracts away the individual toys and allows developers to craft user experiences that can be mapped to toys by the user.
Unfortunately, linear toys are not as easy to control as vibrating toys since we need to know the time duration of each stroke. So, linear toys can only interacted with programmatically using `actuate(value, time)`.
A workaround for controlling motion using AnimationPlayer is provided. This implementation doesn't work for AnimationPlayers that are controlled by an AnimationTree or are playing backwards.

### methods

```
actuate(value, time)
```

Moves all connected toys to position `value` withing `time` seconds.

### members

```
endpoint
```

A `LinearEndpoint.gd` object. Pass this to `Buttplug.connect_endpoint` in order to connect it to devices.

```
position
```

The target position of connected toys. This member is completely ignored and is only used as an aid for animating toys using an AnimationPlayer.

```
animation_player
```

In order for animations to work, we need to calculate the time offset to the next keyframe. So, we need access to the AnimationPlayer which is controlling this actuator.

## Endpoint.gd

An endpoint to connect toys to via `Buttplug.connect_endpoint`. Comes in two variants: `VibrationEndpoint.gd` and `LinearEndpoint.gd`.

### members

```
name
```

A string with the name of the endpoint to be displayed in e.g. configuration menus.

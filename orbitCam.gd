extends Camera3D

@export var target: Node3D           # Set this to the Node3D you wish to orbit around (e.g. your globe)
@export var distance: float = 3.0      # Starting distance from the target
@export var rotation_speed: float = 0.01  # Sensitivity of rotation (adjust as needed)
@export var zoom_speed: float = 0.2       # Sensitivity of zooming

var yaw: float = 0.0
var pitch: float = 0.0
var dragging: bool = false
var last_mouse_pos: Vector2

func _input(event):
	# Right mouse button dragging to orbit.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				dragging = true
				last_mouse_pos = event.position
			else:
				dragging = false
		# Zoom in/out with the mouse wheel.
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			distance = max(1.0, distance - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			distance += zoom_speed
	elif event is InputEventMouseMotion and dragging:
		# Update yaw and pitch based on mouse movement.
		var delta: Vector2 = event.relative
		yaw -= delta.x * rotation_speed
		pitch = clamp(pitch - delta.y * rotation_speed, -PI/2 + 0.1, PI/2 - 0.1)
		
func _process(delta):
	if target == null:
		return
	
	# Calculate the new camera offset using spherical coordinates.
	var offset = Vector3(
		distance * cos(pitch) * sin(yaw),
		distance * sin(pitch),
		distance * cos(pitch) * cos(yaw)
	)
	
	# Set camera position relative to the target.
	var target_pos = target.global_transform.origin
	global_transform.origin = target_pos + offset
	
	# Ensure the camera looks at the target.
	look_at(target_pos, Vector3.UP)

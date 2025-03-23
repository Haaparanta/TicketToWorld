extends Camera3D

@export var target: Node3D         # The node the camera orbits around.
@export var distance: float = 10.0   # Default distance from the target.
@export var rotation_speed: float = 1.0
@export var zoom_speed: float = 0.5

var yaw: float = 0.0
var pitch: float = 0.0

func _ready():
	if target == null:
		target = self
		push_warning("No target set for the orbit camera!")
	# (No need to create and add a Tween node manually in Godot 4.)

func _process(delta):
	_handle_input(delta)
	_update_camera()

func _handle_input(delta):
	# Rotate using arrow keys.
	if Input.is_action_pressed("ui_left"):
		yaw -= rotation_speed * delta
	if Input.is_action_pressed("ui_right"):
		yaw += rotation_speed * delta
	if Input.is_action_pressed("ui_up"):
		pitch = clamp(pitch - rotation_speed * delta, deg2rad(-80), deg2rad(80))
	if Input.is_action_pressed("ui_down"):
		pitch = clamp(pitch + rotation_speed * delta, deg2rad(-80), deg2rad(80))

func _input(event):
	# Zoom with the mouse wheel.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			distance = max(2.0, distance - zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			distance += zoom_speed

func _update_camera():
	# Calculate the offset using spherical coordinates.
	var offset = Vector3(
		distance * cos(pitch) * sin(yaw),
		distance * sin(pitch),
		distance * cos(pitch) * cos(yaw)
	)
	global_transform.origin = target.global_transform.origin + offset
	look_at(target.global_transform.origin, Vector3.UP)

# Smoothly transitions the camera to focus on the given airport.
# new_distance is the desired distance from the airport.
func focus_on_airport(airport: Node3D, new_distance: float, duration: float = 1.0) -> void:
	# Get the current camera position.
	var current_pos: Vector3 = global_transform.origin
	# Get the airport (target) position.
	var target_pos: Vector3 = airport.global_transform.origin
	# Determine the direction from the airport to the current camera position.
	var ray_dir: Vector3 = (current_pos - target_pos).normalized()
	# Calculate the new desired camera position.
	var new_camera_pos: Vector3 = target_pos + ray_dir * new_distance
	
	# Create a tween via the scene tree.
	var t = get_tree().create_tween()
	t.tween_property(self, "global_transform.origin", current_pos, new_camera_pos, duration).
		set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	# Optionally update the target immediately (or tween rotation as well).
	target = airport

func deg2rad(deg: float) -> float:
	return deg * PI / 180.0

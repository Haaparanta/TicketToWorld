extends Node3D

@export var camera: Camera3D         # Assign your Camera3D node here (or leave null to auto-find)
@export var selection_ray_length: float = 1000.0
@export var info_label: Label        # Assign a Label node (in your UI) to display airport info

func _ready():
	# Ensure a valid Camera3D.
	if camera == null:
		camera = get_viewport().get_camera_3d()
		if camera == null:
			print("No Camera3D is assigned or found in the scene!")
	
	# Ensure a valid UI Label.
	if info_label == null:
		print("No info_label (Label node) assigned for displaying airport info!")
	else:
		# Allow clicks to pass through the UI label.
		info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_select_airport(event.position)

func _select_airport(screen_pos: Vector2):
	# Ensure the camera is valid.
	if camera == null:
		print("Camera is not set! Cannot project ray.")
		return
	
	# Compute ray parameters.
	var ray_origin: Vector3 = camera.project_ray_origin(screen_pos)
	var ray_dir: Vector3 = camera.project_ray_normal(screen_pos)
	var ray_end: Vector3 = ray_origin + ray_dir * selection_ray_length
	print("Ray origin: ", ray_origin, " | Ray end: ", ray_end)
	
	# Set up the ray query.
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	query.from = ray_origin
	query.to = ray_end
	query.collision_mask = 1             # Ensure this matches your airport collision layer.
	query.collide_with_areas = true        # Detect Area3D nodes.
	query.collide_with_bodies = true       # Detect physics bodies if needed.
	
	var space_state = get_world_3d().direct_space_state
	if space_state == null:
		print("No direct space state found!")
		return
	
	var result = space_state.intersect_ray(query)
	if result:
		print("Raycast result: ", result)
		var collider = result.collider
		# If the collider is a CollisionShape3D, try using its parent.
		if collider.get_parent() != null:
			collider = collider.get_parent()
		if collider == null:
			print("Collider is null!")
			return
		# Check if this collider belongs to the "airport" group.
		if collider.is_in_group("airport"):
			if collider.has_method("get_airport_info"):
				var info = collider.get_airport_info()
				print("Retrieved airport info: ", info)
				if info_label:
					info_label.text = info
				else:
					print("info_label is null!")
			else:
				print("Collider in 'airport' group does not have get_airport_info() method!")
		else:
			print("Hit object is not an airport: ", collider.name)
			if info_label:
				info_label.text = "Hit object: " + collider.name
	else:
		print("No collision result")
		if info_label:
			info_label.text = "No object selected."

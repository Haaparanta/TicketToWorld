extends Node3D

@export var camera: Camera3D         # Assign your Camera3D node here (or leave null to auto-find)
@export var selection_ray_length: float = 1000.0
@export var info_label: Label        # Assign a Label node (in your UI) to display airport info

func _ready():
	# Check for a valid Camera3D.
	if camera == null:
		camera = get_viewport().get_camera_3d()
		if camera == null:
			push_error("No Camera3D is assigned or found in the scene!")
	# Check for a valid UI Label.
	if info_label == null:
		push_error("No info_label (Label node) assigned for displaying airport info!")
	else:
		# Ensure the UI label does not block mouse input.
		info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_select_airport(event.position)

func _select_airport(screen_pos: Vector2):
	if camera == null:
		push_error("Camera is not set! Cannot project ray.")
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
	query.collision_mask = 1  # This should match the collision layers used by your airports.
	query.collide_with_areas = true   # IMPORTANT: ensure Areas (your airports) are detected.
	query.collide_with_bodies = true    # Also detect bodies if needed.
	
	var space_state = get_world_3d().direct_space_state
	if space_state == null:
		push_error("No direct space state found!")
		return
	
	var result = space_state.intersect_ray(query)
	if result:
		print("Raycast hit: ", result)
		var collider = result.collider
		# If the collider is a CollisionShape3D, assume its parent is the airport.
		if collider is CollisionShape3D:
			collider = collider.get_parent()
		if collider == null:
			push_error("Collider is null!")
			return
		# Check if the collider is in the "airport" group.
		if collider.is_in_group("airport"):
			if collider.has_method("get_airport_info"):
				var info = collider.get_airport_info()
				info_label.text = info
				print("Selected airport: ", info)
			else:
				push_error("Collider in 'airport' group does not have get_airport_info()!")
		else:
			info_label.text = "Hit object: " + collider.name
			print("Hit object: ", collider.name)
	else:
		info_label.text = "No object selected."
		print("No object selected.")

# Helper: Recursively count valid CollisionShape3D nodes in the scene.
func count_valid_collision_shapes(node: Node) -> int:
	var count: int = 0
	if node is CollisionShape3D:
		var cs: CollisionShape3D = node
		if cs.shape != null and cs.disabled == false:
			count += 1
	for child in node.get_children():
		if child is Node:
			count += count_valid_collision_shapes(child)
	return count

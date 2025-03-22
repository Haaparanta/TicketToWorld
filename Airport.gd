extends Area3D

@export var icao_code: String = "UNKNOWN"
@export var iata_code: String = "UNKNOWN"
@export var airport_name: String = "UNKNOWN"
@export var city_name: String = "UNKNOWN"
@export var country_name: String = "UNKNOWN"
@export var latitude_deg: float = 0.0
@export var longitude_deg: float = 0.0

func _ready():
	var has_errors = false
	
	# Validate exported text fields.
	if icao_code == "UNKNOWN":
		print("Error: ICAO code is not set for airport!")
		has_errors = true
	if iata_code == "UNKNOWN":
		print("Error: IATA code is not set for airport!")
		has_errors = true
	if airport_name == "UNKNOWN":
		print("Error: Airport name is not set!")
		has_errors = true
	if city_name == "UNKNOWN":
		print("Error: City name is not set!")
		has_errors = true
	if country_name == "UNKNOWN":
		print("Error: Country name is not set!")
		has_errors = true
	
	# Check coordinates (adjust these checks as needed because (0,0) can be valid).
	if latitude_deg == 0.0:
		print("Warning: Latitude is 0.0 for airport: %s" % airport_name)
	if longitude_deg == 0.0:
		print("Warning: Longitude is 0.0 for airport: %s" % airport_name)
	
	# Ensure the Area3D is monitoring so that signals and raycasts work.
	monitoring = true
	
	# Check for a CollisionShape3D child.
	var collision_shape: CollisionShape3D = null
	if has_node("CollisionShape3D"):
		collision_shape = $CollisionShape3D
	else:
		print("Error: No CollisionShape3D found under airport '%s'. Creating one automatically." % airport_name)
		collision_shape = CollisionShape3D.new()
		var sphere = SphereShape3D.new()
		sphere.radius = 0.1  # Adjust the size as needed.
		collision_shape.shape = sphere
		add_child(collision_shape)
	
	# Validate the collision shape.
	if collision_shape.shape == null:
		print("Error: CollisionShape3D under airport '%s' has no shape assigned!" % airport_name)
		has_errors = true
	if collision_shape.disabled:
		print("Error: CollisionShape3D under airport '%s' is disabled!" % airport_name)
		has_errors = true
	
	# Check collision layer and mask (assuming you want them both to be 1).
	if collision_layer != 1:
		print("Warning: Collision layer for airport '%s' is not 1 (found %d)." % [airport_name, collision_layer])
	if collision_mask != 1:
		print("Warning: Collision mask for airport '%s' is not 1 (found %d)." % [airport_name, collision_mask])
	
	# If everything is valid, no errors will be printed.
	# Finally, add this airport node to the "airport" group.
	if not is_in_group("airport"):
		add_to_group("airport")

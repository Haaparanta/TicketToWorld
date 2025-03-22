extends Node3D

# Preload your Airport marker scene.
@export var airport_scene: PackedScene = preload("res://airport.tscn")
# Preload your debug (red) marker scene (should be a simple red marker).
@export var debug_marker_scene: PackedScene = preload("res://red_marker.tscn")

# Set your globe's radius (should match your sphere's radius).
@export var globe_radius: float = 1.0

# Rotation offset (in degrees) to adjust for model/texture alignment.
# With the swapped conversion below, setting rotation_offset to 90° 
# makes lat=0, lon=0 yield (1,0,0).
@export var rotation_offset: float = 90.0

# Path to the airports data file.
@export var data_file_path: String = "res://GlobalAirportDatabase.txt"

# Class to hold airport data.
class AirportData:
	var icao_code: String
	var iata_code: String
	var airport_name: String
	var city_name: String
	var country_name: String
	var latitude_deg: float
	var longitude_deg: float

func _ready():
	var airports = parse_airport_data(data_file_path)
	print("Parsed %d airports" % airports.size())
	
	# Dictionary to track countries that already have an airport.
	var added_countries = {}
	
	for airport in airports:
		# Only add the airport if its country hasn't been added yet.
		if not added_countries.has(airport.country_name):
			add_airport(airport)
			added_countries[airport.country_name] = true
	# Optionally, add a debug (red) marker at lat=0, lon=0 to verify alignment.
	# add_debug_marker(0, 0)

func parse_airport_data(file_path: String) -> Array:
	var airports = []
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			if line == "":
				continue
			var parts = line.split(":")
			# Ensure there are at least 16 parts (adjust if your file format changes)
			if parts.size() >= 16:
				# Skip lines that have "N/A" in any of the first five fields.
				if parts[0] == "N/A" or parts[1] == "N/A" or parts[2] == "N/A" or parts[3] == "N/A" or parts[4] == "N/A":
					continue
				var airport = AirportData.new()
				airport.icao_code = parts[0]
				airport.iata_code = parts[1]
				airport.airport_name = parts[2]
				airport.city_name = parts[3]
				airport.country_name = parts[4]
				# For your data, latitude is at parts[14] and longitude at parts[15].
				airport.latitude_deg = parts[14].to_float()
				airport.longitude_deg = parts[15].to_float()
				airports.append(airport)
			else:
				print("Line format is incorrect: ", line)
		file.close()
	else:
		print("Failed to open file: ", file_path)
	return airports

func add_airport(airport_data: AirportData):
	# Instantiate the airport marker.
	var airport_instance = airport_scene.instantiate()
	
	# Set properties (ensure your marker scene exposes these via exported variables).
	airport_instance.icao_code = airport_data.icao_code
	airport_instance.iata_code = airport_data.iata_code
	airport_instance.airport_name = airport_data.airport_name
	airport_instance.city_name = airport_data.city_name
	airport_instance.country_name = airport_data.country_name
	airport_instance.latitude_deg = airport_data.latitude_deg
	airport_instance.longitude_deg = airport_data.longitude_deg
	
	# Add the instance to the scene tree first.
	add_child(airport_instance)
	
	# Compute 3D position on the globe using our swapped conversion.
	var pos: Vector3 = get_position_on_sphere(airport_data.latitude_deg, airport_data.longitude_deg, globe_radius)
	# (Optional) Add a slight offset along the surface normal if needed.
	var marker_offset: float = globe_radius * 0.0
	pos += pos.normalized() * marker_offset
	
	# Now that the node is inside the tree, update its global position.
	airport_instance.global_transform.origin = pos
	
	# Orient the marker so that its “up” faces away from the globe’s center.
	airport_instance.look_at_from_position(
		pos,      # current position
		pos * 2,  # target point (directly away from the center)
		Vector3.UP
	)

func add_debug_marker(latitude: float, longitude: float):
	# Instantiate the debug (red) marker.
	var debug_marker = debug_marker_scene.instantiate()
	var pos: Vector3 = get_position_on_sphere(latitude, longitude, globe_radius)
	debug_marker.global_transform.origin = pos
	debug_marker.look_at_from_position(pos, pos * 2, Vector3.UP)
	add_child(debug_marker)
	print("Added debug marker at lat: %f, lon: %f, pos: %s" % [latitude, longitude, pos])

# Helper: Convert degrees to radians.
func deg2rad(deg: float) -> float:
	return deg * PI / 180.0

# Helper: Convert latitude/longitude to a position on a sphere.
#
# Using the swapped conversion:
#   x = r * cos(lat) * sin(lon)
#   y = r * sin(lat)
#   z = r * cos(lat) * cos(lon)
#
# For lat=0, lon=0, we get (0, 0, r). Then applying a rotation offset of 90° around Y
# rotates (0,0,r) to (r,0,0) – as desired.
func get_position_on_sphere(latitude: float, longitude: float, radius: float) -> Vector3:
	# Normalize longitude to [0, 360).
	longitude = fposmod(longitude, 360)
	var lat_rad = deg2rad(latitude)
	var lon_rad = deg2rad(longitude)
	
	# Swapped conversion: note x and z are swapped relative to the standard formula.
	var x = radius * cos(lat_rad) * sin(lon_rad)
	var y = radius * sin(lat_rad)
	var z = radius * cos(lat_rad) * cos(lon_rad)
	var pos = Vector3(x, y, z)
	
	# Apply the rotation offset around the Y-axis.
	if rotation_offset != 0.0:
		var offset_basis = Basis(Vector3.UP, deg2rad(rotation_offset))
		pos = offset_basis * pos  # Multiply the basis with the vector.
	
	return pos

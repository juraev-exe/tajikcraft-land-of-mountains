class_name DayNightCycle
extends Node3D

@onready var sun_light: DirectionalLight3D = DirectionalLight3D.new()
@onready var moon_light: DirectionalLight3D = DirectionalLight3D.new()
@onready var world_env: WorldEnvironment = WorldEnvironment.new()
@onready var weather_particles: CPUParticles3D = CPUParticles3D.new()

var env_resource: Environment = Environment.new()

func _ready() -> void:
	_setup_lights()
	_setup_environment()
	_setup_weather_particles()
	GameManager.time_changed.connect(_on_time_changed)
	GameManager.weather_changed.connect(_on_weather_changed)

func _exit_tree() -> void:
	if weather_particles:
		weather_particles.mesh = null

func _process(_delta: float) -> void:
	if GameManager.player_node and GameManager.player_node is Node3D and weather_particles.emitting:
		weather_particles.global_position = GameManager.player_node.global_position + Vector3(0, 12, 0)

func _setup_weather_particles() -> void:
	weather_particles.name = "WeatherParticles"
	weather_particles.emitting = false
	weather_particles.amount = 320
	weather_particles.lifetime = 2.2
	weather_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	weather_particles.emission_box_extents = Vector3(16.0, 2.0, 16.0)
	weather_particles.direction = Vector3(-0.15, -1.0, 0.05)
	weather_particles.spread = 8.0
	weather_particles.gravity = Vector3(0, -9.8, 0)
	weather_particles.initial_velocity_min = 6.0
	weather_particles.initial_velocity_max = 10.0
	var flake := BoxMesh.new()
	flake.size = Vector3(0.08, 0.18, 0.08)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.90, 0.95, 1.0, 0.85)
	flake.material = mat
	weather_particles.mesh = flake
	add_child(weather_particles)

func _setup_lights() -> void:
	# Sun
	sun_light.name = "SunLight"
	sun_light.shadow_enabled = true
	sun_light.light_energy = 1.0
	add_child(sun_light)

	# Moon
	moon_light.name = "MoonLight"
	moon_light.shadow_enabled = false
	moon_light.light_energy = 0.15
	moon_light.light_color = Color(0.65, 0.75, 0.95)
	add_child(moon_light)

func _setup_environment() -> void:
	env_resource.background_mode = Environment.BG_COLOR
	env_resource.background_color = Color(0.45, 0.65, 0.95)
	env_resource.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_resource.ambient_light_color = Color(0.5, 0.6, 0.7)
	env_resource.ambient_light_energy = 0.5

	# Mountain Fog
	env_resource.fog_enabled = true
	env_resource.fog_light_color = Color(0.65, 0.78, 0.9)
	env_resource.fog_density = 0.008
	env_resource.fog_sky_affect = 0.5

	world_env.environment = env_resource
	add_child(world_env)

func _on_time_changed(hours: float) -> void:
	# 0..24 hours maps to 0..360 degrees
	var sun_angle_deg: float = (hours / 24.0) * 360.0 - 90.0
	sun_light.rotation_degrees = Vector3(sun_angle_deg, -30.0, 0)
	moon_light.rotation_degrees = Vector3(sun_angle_deg + 180.0, -30.0, 0)

	# Light colors and ambient shading throughout the day
	if hours >= 5.0 and hours < 8.0:
		# Sunrise over the Pamir Mountains (Amber / Pinkish gold)
		var t: float = (hours - 5.0) / 3.0
		sun_light.light_color = Color(1.0, 0.68, 0.45).lerp(Color(1.0, 0.95, 0.88), t)
		sun_light.light_energy = lerp(0.1, 1.1, t)
		moon_light.light_energy = lerp(0.15, 0.0, t)
		env_resource.background_color = Color(0.2, 0.15, 0.35).lerp(Color(0.55, 0.72, 0.95), t)
		env_resource.ambient_light_energy = lerp(0.15, 0.55, t)
	elif hours >= 8.0 and hours < 17.5:
		# Full Day
		sun_light.light_color = Color(1.0, 0.98, 0.92)
		sun_light.light_energy = 1.15
		moon_light.light_energy = 0.0
		env_resource.background_color = Color(0.48, 0.72, 0.96)
		env_resource.ambient_light_energy = 0.6
	elif hours >= 17.5 and hours < 20.0:
		# Sunset (Deep Crimson & Golden Orange)
		var t: float = (hours - 17.5) / 2.5
		sun_light.light_color = Color(1.0, 0.95, 0.88).lerp(Color(0.95, 0.38, 0.22), t)
		sun_light.light_energy = lerp(1.1, 0.05, t)
		moon_light.light_energy = lerp(0.0, 0.18, t)
		env_resource.background_color = Color(0.48, 0.72, 0.96).lerp(Color(0.12, 0.10, 0.25), t)
		env_resource.ambient_light_energy = lerp(0.6, 0.15, t)
	else:
		# Pamir Night (Deep indigo sky with crystal starlight)
		sun_light.light_energy = 0.0
		moon_light.light_energy = 0.22
		env_resource.background_color = Color(0.04, 0.05, 0.12)
		env_resource.ambient_light_color = Color(0.15, 0.18, 0.32)
		env_resource.ambient_light_energy = 0.18

func _on_weather_changed(weather_name: String) -> void:
	match weather_name:
		"clear":
			env_resource.fog_density = 0.006
			env_resource.fog_light_color = Color(0.65, 0.78, 0.9)
			weather_particles.emitting = false
		"rain":
			env_resource.fog_density = 0.025
			env_resource.fog_light_color = Color(0.45, 0.50, 0.55)
			weather_particles.gravity = Vector3(0, -16.0, 0)
			weather_particles.emitting = true
		"snowstorm":
			env_resource.fog_density = 0.05
			env_resource.fog_light_color = Color(0.85, 0.88, 0.92)
			weather_particles.gravity = Vector3(-2.5, -4.2, 1.0)
			weather_particles.emitting = true
		"fog":
			env_resource.fog_density = 0.04
			env_resource.fog_light_color = Color(0.75, 0.75, 0.78)
			weather_particles.emitting = false
		"mountain_wind":
			env_resource.fog_density = 0.018
			env_resource.fog_light_color = Color(0.75, 0.65, 0.55)
			weather_particles.emitting = false


extends Node2D

@onready var bg_day: TextureRect = $BackgroundDay
@onready var bg_night: TextureRect = $BackgroundNight
@onready var axolotl: Node2D = $Axolotl
@onready var day_night_btn: TextureButton = $Ui/DayNightBtn
@onready var paw_btn: TextureButton = $Ui/PawBtn
@onready var cursors: Node2D = $cursors
@onready var particles: Node2D = $particles
@onready var outline_poly: Polygon2D = $Axolotl/OutlinePoly

var is_night: bool = false
var is_paw_mode: bool = false
var transition_duration: float = 0.8
var sprite_delay: float = 0.2

var pet_count: int = 0
var last_pet_speech_time: float = 0.0

# ====== СИСТЕМА ИНТЕНСИВНОСТИ ГЛАЖКИ ======
var last_mouse_pos: Vector2 = Vector2.ZERO
var mouse_velocity: Vector2 = Vector2.ZERO
var pet_intensity: float = 0.0  # 0.0 - 1.0+, накапливается при быстром движении
var intensity_decay: float = 2.0  # Насколько быстро падает интенсивность
var intensity_buildup: float = 0.15  # Насколько быстро растёт при движении

func _ready():
	bg_day.texture = load("res://assets/png/bg.png")
	bg_night.texture = load("res://assets/png/bg_night.png")
	bg_day.modulate.a = 1.0
	bg_night.modulate.a = 0.0
	
	if day_night_btn:
		day_night_btn.pressed.connect(_on_day_night_pressed)
	if paw_btn:
		paw_btn.pressed.connect(_on_paw_pressed)
	
	last_mouse_pos = get_global_mouse_position()

func _process(delta):
	if is_paw_mode:
		cursors.follow_mouse("paw")
	
	# Отслеживаем скорость движения мыши
	var current_mouse = get_global_mouse_position()
	mouse_velocity = (current_mouse - last_mouse_pos) / delta
	last_mouse_pos = current_mouse
	
	# Интенсивность падает со временем
	pet_intensity = maxf(0.0, pet_intensity - intensity_decay * delta)
	
	# Если гладим (зажата ЛКМ и мышь над аксолотлем) — накапливаем интенсивность
	if is_paw_mode and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var axolotl_rect = axolotl.get_global_rect()
		if axolotl_rect.has_point(current_mouse):
			# Чем резче движение, тем быстрее растёт интенсивность
			var speed = mouse_velocity.length()
			var boost = clampf(speed / 500.0, 0.0, 1.0) * intensity_buildup
			pet_intensity = clampf(pet_intensity + boost, 0.0, 2.0)

func _input(event):
	if not is_paw_mode:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_check_petting()
			else:
				axolotl.set_sprite("normal")
				axolotl.stop_wobble()
				pet_intensity = 0.0  # Сброс при отпускании
	
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_check_petting()

func _on_day_night_pressed():
	is_night = not is_night
	
	if is_night:
		day_night_btn.texture_normal = load("res://assets/png/night.png")
	else:
		day_night_btn.texture_normal = load("res://assets/png/day.png")
	
	var bg_tween = create_tween()
	if is_night:
		bg_tween.tween_property(bg_night, "modulate:a", 1.0, transition_duration)
	else:
		bg_tween.tween_property(bg_night, "modulate:a", 0.0, transition_duration)
	
	await get_tree().create_timer(sprite_delay).timeout
	
	var sprite_tween = create_tween()
	if is_night:
		sprite_tween.tween_property(axolotl.get_node("SpriteNight"), "modulate:a", 1.0, transition_duration - sprite_delay)
	else:
		sprite_tween.tween_property(axolotl.get_node("SpriteNight"), "modulate:a", 0.0, transition_duration - sprite_delay)
	
	axolotl.set_night(is_night)

func _on_paw_pressed():
	is_paw_mode = not is_paw_mode
	
	if is_paw_mode:
		paw_btn.self_modulate = Color(1.3, 0.6, 0.6, 1.0)
		cursors.show_cursor("paw")
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	else:
		paw_btn.self_modulate = Color.WHITE
		cursors.hide_all()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		axolotl.set_sprite("normal")
		axolotl.stop_wobble()

func _check_petting():
	var axolotl_rect = axolotl.get_global_rect()
	var mouse_pos = get_global_mouse_position()
	
	if axolotl_rect.has_point(mouse_pos):
		_handle_petting()
	else:
		axolotl.set_sprite("normal")
		axolotl.stop_wobble()

func _handle_petting():
	axolotl.set_sprite("happy")
	axolotl.wobble()
	pet_count += 1
	
	if particles and outline_poly:
		particles.spawn_hearts_inside(outline_poly, pet_intensity)

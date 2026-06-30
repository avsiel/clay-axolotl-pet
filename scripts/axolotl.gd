extends Node2D

@onready var sprite_day: Sprite2D = $SpriteDay
@onready var sprite_night: Sprite2D = $SpriteNight

var blink_timer: float = 0.0
var blink_interval: float = 3.0
var is_blinking: bool = false
var is_night: bool = false
var wobble_tween: Tween

# === НОВОЕ: запоминаем исходный масштаб ===
var original_scale: Vector2 = Vector2(1, 1)

# Текстуры
var day_normal: Texture2D
var day_blink: Texture2D
var night_normal: Texture2D
var night_blink: Texture2D

func _ready():
	# Загружаем текстуры один раз
	day_normal = load("res://assets/png/sprite.png")
	day_blink = load("res://assets/png/spriteclosedboth.png")
	night_normal = load("res://assets/png/night_sprite.png")
	night_blink = load("res://assets/png/night_spriteclosedboth.png")
	
	# Инициализация
	sprite_day.texture = day_normal
	sprite_night.texture = night_normal
	sprite_day.modulate.a = 1.0
	sprite_night.modulate.a = 0.0
	
	# === НОВОЕ: запоминаем исходный масштаб ===
	original_scale = scale

func _process(delta):
	blink_timer += delta
	if blink_timer >= blink_interval and not is_blinking:
		blink()
		blink_timer = 0.0
		blink_interval = 2.0 + randf() * 4.0

func blink():
	is_blinking = true
	
	# Моргаем активным спрайтом
	if is_night:
		sprite_night.texture = night_blink
	else:
		sprite_day.texture = day_blink
	
	await get_tree().create_timer(0.15).timeout
	
	# Возвращаем нормальную текстуру
	if is_night:
		sprite_night.texture = night_normal
	else:
		sprite_day.texture = day_normal
	
	is_blinking = false

func set_night(night: bool):
	is_night = night
	if not is_blinking:
		if is_night:
			sprite_night.texture = night_normal
		else:
			sprite_day.texture = day_normal

func set_sprite(state: String):
	"""Меняет спрайт: 'normal' или 'happy'"""
	if is_blinking:
		return
	
	match state:
		"happy":
			sprite_day.texture = day_blink
			sprite_night.texture = night_blink
		"normal":
			sprite_day.texture = day_normal
			sprite_night.texture = night_normal

func wobble():
	"""Анимация покачивания с учётом исходного масштаба"""
	if wobble_tween and wobble_tween.is_running():
		return
	
	# === ИСПРАВЛЕНО: используем original_scale ===
	var wobble_scale = original_scale * 1.02
	
	wobble_tween = create_tween().set_loops()
	wobble_tween.tween_property(self, "scale", wobble_scale, 0.175)
	wobble_tween.parallel().tween_property(self, "rotation", deg_to_rad(1), 0.175)
	wobble_tween.tween_property(self, "scale", wobble_scale, 0.175)
	wobble_tween.parallel().tween_property(self, "rotation", deg_to_rad(-1), 0.175)
	wobble_tween.tween_property(self, "scale", original_scale, 0.175)  # Возвращаем к original_scale
	wobble_tween.parallel().tween_property(self, "rotation", 0, 0.175)

func stop_wobble():
	"""Останавливает покачивание и возвращаем исходный масштаб"""
	if wobble_tween and wobble_tween.is_running():
		wobble_tween.stop()
	scale = original_scale  # === ИСПРАВЛЕНО: возвращаем original_scale ===
	rotation = 0

func get_global_rect() -> Rect2:
	"""Возвращает прямоугольник аксолотля для проверки попадания мыши"""
	var active_sprite = sprite_night if is_night else sprite_day
	var tex = active_sprite.texture
	if not tex:
		return Rect2()
	
	var size = tex.get_size() * active_sprite.scale * scale
	var pos = global_position - size / 2.0
	return Rect2(pos, size)

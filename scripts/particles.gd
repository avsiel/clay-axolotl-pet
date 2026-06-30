extends Node2D

@onready var hearts_template: Sprite2D = $HeartsTemplate

func _ready():
	if hearts_template:
		hearts_template.visible = false

func spawn_hearts_inside(poly: Polygon2D, intensity: float):
	"""
	Спавн ВНУТРИ полигона (коллизии), но с анимацией как в веб-версии.
	"""
	if not hearts_template or not poly:
		return
	
	var polygon = poly.polygon
	if polygon.size() < 3:
		return
	
	var poly_transform = poly.global_transform
	var bounds = _get_polygon_bounds(polygon)
	
	# Шанс как в вебе — очень редкий
	var spawn_chance = clampf(intensity * 0.005, 0.001, 0.2)
	if randf() > spawn_chance:
		return
	
	# Ищем случайную точку ВНУТРИ полигона
	var spawn_pos: Vector2
	var found = false
	for attempt in range(30):
		var local_pos = Vector2(
			randf_range(bounds.position.x, bounds.end.x),
			randf_range(bounds.position.y, bounds.end.y)
		)
		if _point_in_polygon(local_pos, polygon):
			spawn_pos = poly_transform * local_pos
			found = true
			break
	
	if not found:
		spawn_pos = poly_transform * _get_polygon_center(polygon)
	
	# Создаём сердечко
	var particle = hearts_template.duplicate()
	get_parent().add_child(particle)
	
	# Разброс как в веб-версии (±50px по X, ±25px по Y)
	var offset = Vector2(randf_range(-50, 50), randf_range(-25, 25))
	particle.global_position = spawn_pos + offset
	
	particle.visible = true
	particle.modulate.a = 1.0
	particle.scale = Vector2.ONE * randf_range(0.12, 0.22)
	
	# ====== АНИМАЦИЯ КАК В ВЕБ-ВЕРСИИ ======
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Всплываем вверх на ~150px (как translateY(-150px))
	tween.tween_property(particle, "global_position:y", particle.global_position.y - randf_range(120, 180), 1.5).set_ease(Tween.EASE_OUT)
	
	# Поворот (как rotate(random * 180 - 90))
	tween.tween_property(particle, "rotation", deg_to_rad(randf_range(-90, 90)), 1.5)
	
	# Scale 1.2x (как в CSS)
	tween.tween_property(particle, "scale", particle.scale * 1.2, 1.5)
	
	# Fade out
	tween.tween_property(particle, "modulate:a", 0.0, 1.2).set_delay(0.3)
	
	# Удаляем через ~2 сек
	tween.finished.connect(func(): particle.queue_free())

func _get_polygon_bounds(polygon: PackedVector2Array) -> Rect2:
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	for p in polygon:
		min_x = minf(min_x, p.x)
		min_y = minf(min_y, p.y)
		max_x = maxf(max_x, p.x)
		max_y = maxf(max_y, p.y)
	return Rect2(min_x, min_y, max_x - min_x, max_y - min_y)

func _point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	var inside = false
	var j = polygon.size() - 1
	for i in range(polygon.size()):
		var pi = polygon[i]
		var pj = polygon[j]
		if ((pi.y > point.y) != (pj.y > point.y)) and \
		   (point.x < (pj.x - pi.x) * (point.y - pi.y) / (pj.y - pi.y) + pi.x):
			inside = not inside
		j = i
	return inside

func _get_polygon_center(polygon: PackedVector2Array) -> Vector2:
	var center = Vector2.ZERO
	for p in polygon:
		center += p
	return center / polygon.size()

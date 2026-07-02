extends Node2D

@onready var bg_day: TextureRect = $BackgroundDay
@onready var bg_night: TextureRect = $BackgroundNight
@onready var axolotl: Node2D = $Axolotl
@onready var day_night_btn: TextureButton = $Ui/DayNightBtn
@onready var paw_btn: TextureButton = $Ui/PawBtn
@onready var chat_btn: TextureButton = $Ui/ChatBtn
@onready var cursors: Control = $CursorLayer/cursors
@onready var particles: Node2D = $particles
@onready var outline_poly: Polygon2D = $Axolotl/OutlinePoly
@onready var bubble: Control = $bubble
@onready var zvuk_btn: TextureButton = $Ui/ZvukBtn
@onready var music_day: AudioStreamPlayer = $MusicDay
@onready var music_night: AudioStreamPlayer = $MusicNight
@onready var sponge_btn: TextureButton = $Ui/SpongeBtn
@onready var net_btn: TextureButton = $Ui/NetBtn

var is_night: bool = false
var transition_duration: float = 0.8
var sprite_delay: float = 0.2
var music_enabled := true
var active_tool: String = ""
var pet_count: int = 0
var last_pet_speech_time: float = 0.0

# ====== СИСТЕМА ИНТЕНСИВНОСТИ ГЛАЖКИ ======
var last_mouse_pos: Vector2 = Vector2.ZERO
var mouse_velocity: Vector2 = Vector2.ZERO
var pet_intensity: float = 0.0
var intensity_decay: float = 2.0
var intensity_buildup: float = 0.15

# ====== PETTING PHRASES (non-repeating) ======
var available_phrase_indices: Array[int] = []
var all_phrases: Array[String] = [
	"Mmm, that feels nice!",
	"Pet me more, please!",
	"Your paw is so warm!",
	"I'm melting with tenderness!",
	"This is the best massage!",
	"Purring... bubbling...",
	"Don't stop!",
	"I'm a happy little blob of clay!",
	"You're spoiling me!",
	"I love being petted!"
]

# ====== SPECIAL PHRASES (non-repeating) ======
var available_special_indices: Array[int] = []
var special_phrases: Array[String] = [
	"Hi, owner! I missed you!",
	"The water feels so cozy today...",
	"Want to know a secret? Gills are antennas for cuteness!",
	"I found a shiny pebble! Here, take it!",
	"Blub blub! That means 'I love you'!",
	"Owner, can I have some more shrimp?",
	"I was just thinking... you're the best!",
	"Did you see that fish? It winked at me!",
	"My gills are wiggling with happiness!",
	"Sending you clay-soft hugs!",
	"I drew a heart out of bubbles!",
	"You're here! I'm so happy!",
	"The water's warm, just like your smile!",
	"I hid a treasure under a rock!",
	"Bubbling out a little tune for you!",
	"Owner, give me a paw-hug!",
	"I'm an axolotl, wet and happy!",
	"Today's a great day for swimming!",
	"Did you notice how nicely I swam?",
	"Bubbles, bubbles, bubbles everywhere!"
]

var axolotl_original_scale: Vector2 = Vector2.ONE

func _ready():
	bg_day.texture = load("res://assets/png/bg.png")
	bg_night.texture = load("res://assets/png/bg_night.png")
	bg_day.modulate.a = 1.0
	bg_night.modulate.a = 0.0
	
	if day_night_btn:
		day_night_btn.pressed.connect(_on_day_night_pressed)
	if paw_btn:
		paw_btn.pressed.connect(_on_paw_pressed)
	if chat_btn:
		chat_btn.pressed.connect(_on_chat_pressed)
	if zvuk_btn:
		zvuk_btn.pressed.connect(_on_zvuk_pressed)
	if sponge_btn:
		sponge_btn.pressed.connect(_on_sponge_pressed)
	if net_btn:
		net_btn.pressed.connect(_on_net_pressed)
	
	last_mouse_pos = get_global_mouse_position()
	
	_refill_phrase_indices()
	_refill_special_indices()
	
	axolotl_original_scale = axolotl.scale
	music_day.play()
	music_night.play()

	music_day.volume_db = -10.0
	music_night.volume_db = -42.0

	zvuk_btn.texture_normal = load("res://assets/png/zvuk_on.png")

func _process(delta):
	if active_tool != "":
		cursors.follow_mouse(active_tool)
	
	var current_mouse = get_global_mouse_position()
	mouse_velocity = (current_mouse - last_mouse_pos) / delta
	last_mouse_pos = current_mouse
	
	pet_intensity = maxf(0.0, pet_intensity - intensity_decay * delta)
	
	if active_tool == "paw" and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var axolotl_rect = axolotl.get_global_rect()
		if axolotl_rect.has_point(current_mouse):
			var speed = mouse_velocity.length()
			var boost = clampf(speed / 500.0, 0.0, 1.0) * intensity_buildup
			pet_intensity = clampf(pet_intensity + boost, 0.0, 2.0)

func _input(event):
	if active_tool == "":
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if active_tool == "paw":
					_check_petting()
				elif active_tool == "sponge":
					_check_sponge()
				elif active_tool == "net":
					_check_net()
			else:
				if active_tool == "paw":
					axolotl.set_sprite("normal")
					axolotl.stop_wobble()
					pet_intensity = 0.0
	
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if active_tool == "paw":
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
	_update_music()

func _on_paw_pressed():
	if active_tool == "paw":
		_disable_tool()
		return
	
	_disable_tool()
	active_tool = "paw"
	paw_btn.self_modulate = Color(1.3, 0.6, 0.6, 1.0)
	cursors.show_cursor("paw")
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_chat_pressed():
	_play_speech_animation()
	_say_special_phrase()

func _play_speech_animation():
	if axolotl.has_meta("speech_tween"):
		var old_tween = axolotl.get_meta("speech_tween")
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	axolotl.scale = axolotl_original_scale
	
	var tween = create_tween()
	axolotl.set_meta("speech_tween", tween)
	
	tween.tween_property(axolotl, "scale", axolotl_original_scale * Vector2(1.0, 1.05), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(axolotl, "scale", axolotl_original_scale, 0.1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	
	await tween.finished

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
	
	var now_ms = Time.get_unix_time_from_system() * 1000
	if now_ms - last_pet_speech_time > 8000 and randf() < 0.03:
		last_pet_speech_time = now_ms
		_say_pet_phrase()
	
	if particles and outline_poly:
		particles.spawn_hearts_inside(outline_poly, pet_intensity)

func _refill_phrase_indices():
	available_phrase_indices.clear()
	for i in range(all_phrases.size()):
		available_phrase_indices.append(i)
	available_phrase_indices.shuffle()

func _say_pet_phrase():
	if available_phrase_indices.is_empty():
		_refill_phrase_indices()
	
	var phrase_index = available_phrase_indices.pop_back()
	var phrase = all_phrases[phrase_index]
	bubble.show_text(phrase)

func _refill_special_indices():
	available_special_indices.clear()
	for i in range(special_phrases.size()):
		available_special_indices.append(i)
	available_special_indices.shuffle()

func _say_special_phrase():
	if available_special_indices.is_empty():
		_refill_special_indices()
	
	var phrase_index = available_special_indices.pop_back()
	var phrase = special_phrases[phrase_index]
	bubble.show_text(phrase)

func _update_music():
	if not music_enabled:
		return

	if not music_day.playing:
		music_day.play()

	if not music_night.playing:
		music_night.play()

	var tween := create_tween()

	if is_night:
		tween.parallel().tween_property(music_day, "volume_db", -80.0, 0.8)
		tween.parallel().tween_property(music_night, "volume_db", -12.0, 0.8)
	else:
		tween.parallel().tween_property(music_day, "volume_db", -12.0, 0.8)
		tween.parallel().tween_property(music_night, "volume_db", -80.0, 0.8)

func _on_zvuk_pressed():
	music_enabled = !music_enabled

	if music_enabled:
		zvuk_btn.texture_normal = load("res://assets/png/zvuk_on.png")

		if not music_day.playing:
			music_day.play()

		if not music_night.playing:
			music_night.play()

		_update_music()

	else:
		zvuk_btn.texture_normal = load("res://assets/png/zvuk_off.png")

		var tween := create_tween()
		tween.parallel().tween_property(music_day, "volume_db", -80.0, 0.5)
		tween.parallel().tween_property(music_night, "volume_db", -80.0, 0.5)

func _on_sponge_pressed():
	if active_tool == "sponge":
		_disable_tool()
		return

	_disable_tool()
	active_tool = "sponge"
	sponge_btn.self_modulate = Color(1.3, 0.6, 0.6, 1.0)
	cursors.show_cursor("sponge")
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _on_net_pressed():
	if active_tool == "net":
		_disable_tool()
		return

	_disable_tool()
	active_tool = "net"
	net_btn.self_modulate = Color(1.3, 0.6, 0.6, 1.0)
	cursors.show_cursor("net")
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _disable_tool():
	var prev_tool = active_tool
	active_tool = ""
	
	cursors.hide_all()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	paw_btn.self_modulate = Color.WHITE
	sponge_btn.self_modulate = Color.WHITE
	net_btn.self_modulate = Color.WHITE
	
	if prev_tool == "paw":
		axolotl.set_sprite("normal")
		axolotl.stop_wobble()
		pet_intensity = 0.0

func _check_sponge():
	print("Sponge used at ", get_global_mouse_position())

func _check_net():
	print("Net used at ", get_global_mouse_position())

extends Control

@onready var text_label: Label = $TextLabel
@onready var typing_sound: AudioStreamPlayer = $TypingSound

var typing_timer: Timer
var line_timer: Timer
var current_tween: Tween

var current_text := ""
var current_index := 0


func _ready():
	visible = false
	modulate.a = 0.0
	text_label.text = ""

	# Шрифт
	var font = load("res://assets/font/pinlock.otf")
	if font:
		text_label.add_theme_font_override("font", font)

	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_label.clip_text = false

	typing_timer = Timer.new()
	typing_timer.wait_time = 0.075
	typing_timer.one_shot = false
	add_child(typing_timer)
	typing_timer.timeout.connect(_type_next_character)

	line_timer = Timer.new()
	line_timer.one_shot = true
	add_child(line_timer)
	line_timer.timeout.connect(_hide_bubble)

	if typing_sound:
		typing_sound.stream = load("res://assets/ost/boop.wav")
		typing_sound.volume_db = linear_to_db(0.25)
		typing_sound.max_polyphony = 16


func show_text(text: String):
	typing_timer.stop()
	line_timer.stop()

	if current_tween and current_tween.is_valid():
		current_tween.kill()

	current_text = text
	current_index = 0

	text_label.text = ""
	modulate.a = 1.0
	visible = true

	typing_timer.start()


func _type_next_character():
	if current_index >= current_text.length():
		typing_timer.stop()

		var reading_time = maxf(2.0, current_text.length() * 0.060)
		line_timer.start(reading_time)
		return

	var c := current_text[current_index]
	text_label.text += c
	current_index += 1

	if c != " " and c != "\n":
		_play_typing_sound()


func _play_typing_sound():
	if typing_sound == null or typing_sound.stream == null:
		return

	typing_sound.pitch_scale = 1.03
	typing_sound.play()


func _hide_bubble():
	if current_tween and current_tween.is_valid():
		current_tween.kill()

	current_tween = create_tween()
	current_tween.tween_property(self, "modulate:a", 0.0, 0.5)

	await current_tween.finished

	visible = false
	text_label.text = ""
	modulate.a = 1.0

extends Control

@onready var text_label: Label = $TextLabel

var typing_timer: Timer
var line_timer: Timer
var current_tween: Tween

# Класс для хранения состояния печати
class TypingState:
	var text: String
	var index: int = 0
	var length: int = 0
	
	func _init(t: String):
		text = t
		length = t.length()

func _ready():
	visible = false
	modulate.a = 0.0
	text_label.text = ""
	
	typing_timer = Timer.new()
	typing_timer.wait_time = 0.042
	typing_timer.one_shot = false
	add_child(typing_timer)
	
	line_timer = Timer.new()
	line_timer.one_shot = true
	add_child(line_timer)

func show_text(text: String):
	typing_timer.stop()
	line_timer.stop()
	
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	
	visible = true
	modulate.a = 1.0
	text_label.text = ""
	
	_type_text(text)

func _type_text(text: String):
	var state = TypingState.new(text)
	
	# Очищаем старые подключения
	if typing_timer.timeout.get_connections().size() > 0:
		typing_timer.timeout.disconnect(_on_typing_timeout)
	
	typing_timer.timeout.connect(_on_typing_timeout.bind(state))
	typing_timer.start()

func _on_typing_timeout(state: TypingState):
	if state.index >= state.length:
		typing_timer.stop()
		var reading_time = maxf(2.0, state.length * 0.065)
		
		# Правильное отключение сигнала
		if line_timer.is_connected("timeout", _hide_bubble):
			line_timer.disconnect("timeout", _hide_bubble)
		line_timer.timeout.connect(_hide_bubble)
		
		line_timer.start(reading_time)
		return
	
	text_label.text += state.text[state.index]
	state.index += 1

func _hide_bubble():
	line_timer.stop()
	
	current_tween = create_tween()
	current_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await current_tween.finished
	
	visible = false
	text_label.text = ""
	modulate.a = 1.0
	current_tween = null

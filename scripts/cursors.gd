extends Control  # ← БЫЛО Node2D, СТАЛО Control

@onready var paw_cursor: Sprite2D = $PawCursor
@onready var net_cursor: Sprite2D = $NetCursor
@onready var sponge_cursor: Sprite2D = $SpongeCursor
@onready var hvat_cursor: Sprite2D = $HvatCursor

func _ready():
	hide_all()
	# Для Control z_index работает иначе
	z_index = 100
	z_as_relative = false

func hide_all():
	if paw_cursor: paw_cursor.visible = false
	if net_cursor: net_cursor.visible = false
	if sponge_cursor: sponge_cursor.visible = false
	if hvat_cursor: hvat_cursor.visible = false

func show_cursor(cursor_name: String):
	hide_all()
	match cursor_name:
		"paw":
			if paw_cursor: paw_cursor.visible = true
		"net":
			if net_cursor: net_cursor.visible = true
		"sponge":
			if sponge_cursor: sponge_cursor.visible = true
		"hvat":
			if hvat_cursor: hvat_cursor.visible = true

func follow_mouse(cursor_name: String):
	var cursor: Sprite2D = null
	match cursor_name:
		"paw":
			cursor = paw_cursor
		"net":
			cursor = net_cursor
		"sponge":
			cursor = sponge_cursor
		"hvat":
			cursor = hvat_cursor
	
	if cursor:
		# Для Control используем position вместо global_position
		cursor.position = get_local_mouse_position()

extends Node2D

@onready var paw_cursor: Sprite2D = $PawCursor
@onready var net_cursor: Sprite2D = $NetCursor
@onready var sponge_cursor: Sprite2D = $SpongeCursor
@onready var hvat_cursor: Sprite2D = $HvatCursor

func _ready():
	# Все курсоры скрыты при старте
	hide_all()

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
		cursor.global_position = get_global_mouse_position()

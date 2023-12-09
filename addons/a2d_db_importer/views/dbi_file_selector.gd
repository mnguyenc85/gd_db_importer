@tool
class_name DBImFileSelector
extends Control

@onready var lblTitle: Label = $lblTitle
@onready var txtPath: LineEdit = $txtFilePath
@onready var btLoad: Button = $btLoad

signal openFileDialogSignal
signal loadFileSignal
signal clearSignal

var _title: String
@export var title: String:
	get: return _title
	set(value): 
		_title = value
		if lblTitle: lblTitle.text = value
var _showLoad: bool
@export var ShowButton: bool:
	get: return _showLoad
	set(value):
		_showLoad = value
		if btLoad: btLoad.visible = _showLoad

var UserId: int = 0

var _filepath: String
@export var filepath: String:
	get: return _filepath
	set(value): 
		_filepath = value
		if txtPath: txtPath.text = value

func _ready():
	add_theme_constant_override("margin_left", 6)
	add_theme_constant_override("margin_right", 6)
	lblTitle.text = _title
	btLoad.visible = _showLoad
	txtPath.text = _filepath

func _on_btClear_pressed():
	txtPath.text = ""
	emit_signal("clearSignal", UserId)

func _on_btBrowse_pressed():
	emit_signal("openFileDialogSignal", UserId)

func _on_btLoad_pressed():
	emit_signal("loadFileSignal", UserId)

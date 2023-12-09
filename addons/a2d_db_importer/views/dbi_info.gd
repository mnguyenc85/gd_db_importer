@tool
extends Control

@onready var pnl: GridContainer = $MarginContainer/GridContainer
var _addedChildren: Array[Label] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func add_info(name: String, value: String):
	var lblName = Label.new()
	lblName.text = name
	lblName.self_modulate = Color(0.8, 0.8, 0.8)
	var lblValue = Label.new()
	lblValue.text = value
	lblValue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lblValue.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lblValue.clip_text = true
	pnl.add_child(lblName)
	pnl.add_child(lblValue)
	_addedChildren.append(lblName)
	_addedChildren.append(lblValue)
	
func clear():
	for c in _addedChildren:
		c.queue_free()
	_addedChildren.clear()

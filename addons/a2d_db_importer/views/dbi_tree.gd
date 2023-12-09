@tool
class_name DBIContentTree
extends Control

@onready var tree = $Tree

signal itemSelectedSignal(parent, id)

var _txIcons = load("res://addons/a2d_db_importer/images/icons.png")
var ti_root: TreeItem
var ti_atlas: TreeItem
var ti_skel: TreeItem
var ti_arm: TreeItem

func _ready():
	ti_root = tree.create_item()
	tree.hide_root = true
	ti_atlas = _create_tree_item("Atlas", 1, 0)
	ti_skel = _create_tree_item("Skel Info",4, 0)
	ti_arm = _create_tree_item("Armature", 2, 0)

func _create_tree_item(title: String, icx: int, icy: int) -> TreeItem:
	var node: TreeItem = tree.create_item(ti_root)
	node.set_text(0, title)
	var icon = AtlasTexture.new()
	icon.atlas = _txIcons
	icon.region = Rect2(icx * 16, icy * 16, 16, 16)
	node.set_icon(0, icon)
	return node

func _on_tree_item_selected():
	var item: TreeItem = tree.get_selected()
	if item == ti_atlas:
		itemSelectedSignal.emit(0, -1)
		return
	elif item == ti_skel:
		itemSelectedSignal.emit(1, -1)
		return
	elif item == ti_arm:
		itemSelectedSignal.emit(2, -1)
		return
	
	var parent = item.get_parent()
	if parent == ti_arm:
		itemSelectedSignal.emit(2, item.get_instance_id())
	pass

func _clear_branch(node: TreeItem):
	for c in node.get_children():
		_clear_branch(c)
		node.remove_child(c)
		c.free()

func clear_tree_branch(p: int):
	match p:
		0: _clear_branch(ti_atlas)
		2: _clear_branch(ti_arm)

# temporary
func add_tree_item(p: int, tiParent: TreeItem = null, text0: String = "", text1: String = "") -> TreeItem:	
	var tip: TreeItem = null
	match p:
		0: tip = ti_atlas
		2: tip = ti_arm
		-1: tip = tiParent
	if tip:
		var ti: TreeItem = tree.create_item(tip)
		ti.set_text(0, text0)
		ti.set_text(1, text1)
		return ti
		
	return null

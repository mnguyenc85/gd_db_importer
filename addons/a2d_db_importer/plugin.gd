@tool
extends EditorPlugin

const UTILS = preload("res://addons/a2d_db_importer/utils/dbi_utils.gd")
const MainPanelTemp: PackedScene = preload("res://addons/a2d_db_importer/views/dbi_main.tscn")
const SKEL = preload("res://addons/a2d_db_importer/utils/dbi_skel_file.gd")
const ATLAS = preload("res://addons/a2d_db_importer/utils/dbi_atlas_file.gd")
const CREATER = preload("res://addons/a2d_db_importer/utils/dbi_creator.gd")

var pnlMain: DBIMainPanel
var _cFileDropped: Callable

func _enter_tree():
	add_custom_type("Bone2D_Alter", "Bone2D", 
		preload("res://addons/a2d_db_importer/utils/bond2d_alter.gd"), 
		preload("res://addons/a2d_db_importer/images/Bone2D.svg"))

	pnlMain = MainPanelTemp.instantiate()
	pnlMain.importSignal.connect(_import_armature)
	get_editor_interface().get_editor_main_screen().add_child(pnlMain)
	scene_changed.connect(_on_scene_changed)
	_set_status()
	_make_visible(false)
	
	# TODO: how to stop EditorNode::_dropped_files when dropped files to this pluggin?
	var filesdroppedSignal: Signal = get_tree().get_root().files_dropped
	_cFileDropped = Callable(pnlMain, "on_files_dropped")
	filesdroppedSignal.connect(_cFileDropped)

func _exit_tree():
	remove_custom_type("Bone2D_Atler")
	if pnlMain:
		if _cFileDropped:
			get_tree().get_root().files_dropped.disconnect(_cFileDropped)
		pnlMain.queue_free()

func _has_main_screen():
	return true
	
func _make_visible(visible):
	if pnlMain:
		pnlMain.visible = visible

func _get_plugin_name():
	return "A2D DB Importer"
	
func _get_plugin_icon():
	return get_editor_interface().get_base_control().get_theme_icon("Node", "EditorIcons")

# --------- my private methods ---------
func _on_scene_changed(scene):
	_set_status(scene.name)

func _set_status(sceneName: String = ""):
	if Engine.is_editor_hint(): pnlMain.set_status(0, "Editor")
	else: pnlMain.set_status(0, "Game")
	pnlMain.set_status(1, sceneName)

# (call from signal importSignal)
func _import_armature(af: ATLAS.DBIAtlasFile, sf: SKEL.DBISkelFile, arm: SKEL.DBISkelArmature):
	var root = get_tree().edited_scene_root
	if !root: return
	var creator = CREATER.DBICreator.new()
	creator.create(root, af, sf, arm)

## Utility function
## Clear all children of node[name] which is child of root node
func _clear_2nd_node(name: String):
	var root = get_tree().edited_scene_root
	if !root: return
	var node = root.find_child(name)
	if !node: return
	for c in node.get_children():
		c.queue_free()



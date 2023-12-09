@tool
class_name DBIMainPanel
extends VBoxContainer

const SKEL = preload("res://addons/a2d_db_importer/utils/dbi_skel_file.gd")
const ATLAS = preload("res://addons/a2d_db_importer/utils/dbi_atlas_file.gd")

signal importSignal(af: ATLAS.DBIAtlasFile, sf: SKEL.DBISkelFile, arm: SKEL.DBISkelArmature)

@onready var atlasSelector: DBImFileSelector = $Margin1/Vbox1/fsAtlas
@onready var skelSelector: DBImFileSelector = $Margin1/Vbox1/fsSkel
@onready var resDirSelector: DBImFileSelector = $Margin1/Vbox1/fsTexture
@onready var tree: DBIContentTree = $Margin1/Vbox1/Hbox1/ContentTree
@onready var pnlInfo = $Margin1/Vbox1/Hbox1/DBIInfo
@onready var btImport = $Margin1/Vbox1/Hbox2/btImport
@onready var fdlg: FileDialog = $FileDialog
@onready var imgAtlas: TextureRect = $Margin1/Vbox1/Hbox1/ScrollContainer/imgAtlas

var _fdlg_id: int
var skelFile := SKEL.DBISkelFile.new()
var atlasFile := ATLAS.DBIAtlasFile.new()
var _import_arm: SKEL.DBISkelArmature = null

func _ready():
	atlasSelector.UserId = 1
	atlasSelector.openFileDialogSignal.connect(_open_fileDialog)
	atlasSelector.loadFileSignal.connect(_load_atlas)
	atlasSelector.clearSignal.connect(_clear_load_file)
	skelSelector.UserId = 2
	skelSelector.openFileDialogSignal.connect(_open_fileDialog)
	skelSelector.loadFileSignal.connect(_load_skel)
	skelSelector.clearSignal.connect(_clear_load_file)
	resDirSelector.UserId = 3
	resDirSelector.openFileDialogSignal.connect(_open_fileDialog)
	
	tree.itemSelectedSignal.connect(_on_treeitem_selected)
	$PnlStatus/HBoxContainer/lblMode.text = "Game"
	if !Engine.is_editor_hint(): 
		btImport.disabled = true
		get_tree().get_root().files_dropped.connect(on_files_dropped)

func set_status(id: int, value: String):
	if id == 0: $PnlStatus/HBoxContainer/lblMode.text = value
	elif id == 1: $PnlStatus/HBoxContainer/lblRootNode.text = value

func on_files_dropped(files: PackedStringArray):
	for f in files:
		if f.length() > 8:
			var ext = f.substr(f.length() - 8)
			print("Process dropped files %s" % f)
			if ext == "ske.json":
				skelSelector.filepath = f
				var atlasFile = f.substr(0, f.length() - 8) + "tex.json"
				if FileAccess.file_exists(atlasFile): atlasSelector.filepath = atlasFile
				break
			elif ext == "tex.json":
				atlasSelector.filepath = f
				var skeFile = f.substr(0, f.length() - 8) + "ske.json"
				if FileAccess.file_exists(skeFile): skelSelector.filepath = skeFile
				break
#		else:
#			var ext = f.get_extension()
#			if ext == "png" or ext == "jpg":
#			txPage.texture = _load_image(f)
#			break
	
func _open_fileDialog(id):
	if id == 3:
		fdlg.access = FileDialog.ACCESS_RESOURCES
		fdlg.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	elif id == 2:
		fdlg.access = FileDialog.ACCESS_FILESYSTEM
		fdlg.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		fdlg.filters = PackedStringArray(["*.json"])
	elif id == 1:
		fdlg.access = FileDialog.ACCESS_FILESYSTEM
		fdlg.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		fdlg.filters = PackedStringArray(["*.json"])
	_fdlg_id = id
	fdlg.visible = true

func _on_fdlg_file_selected(path):
	if _fdlg_id == 1: atlasSelector.filepath = path
	elif _fdlg_id == 2: skelSelector.filepath = path
	elif _fdlg_id == 3:
		resDirSelector.filepath = path

func _load_skel(id):
	if !skelFile.load_file(skelSelector.filepath):
		print("Error load skel file: %s" % skelSelector.filepath)
		return
	# add armature to tree
	for a in skelFile.d_armature.values():
		var tiArm: TreeItem = tree.add_tree_item(2, null, a.name)
		a.treeId = tiArm.get_instance_id()
		for b in a.bones.values():
			var tiBone: TreeItem = tree.add_tree_item(-1, tiArm, b.name, str(b.index))
			b.treeId = tiBone.get_instance_id()

func _load_atlas(id):
	if !atlasFile.load_file(atlasSelector.filepath):
		print("Error load atlas file: %s" % atlasSelector.filepath)
		return
		
	# add atlas regions to tree
	for r in atlasFile.d_region.values():
		var tiReg: TreeItem = tree.add_tree_item(0, null, r.name)
		r.treeId = tiReg.get_instance_id()
		
	# TODO: copy image to resDirSelector.filepath
	imgAtlas.texture = _load_image(atlasFile.baseDir + "\\" + atlasFile.imgPath)
	imgAtlas.draw_regions(atlasFile.d_region.values())

	atlasFile.importPath = resDirSelector.filepath + "\\" + atlasFile.filename

func _clear_load_file(id):
	pnlInfo.clear()
	if id == 2:
		_import_arm = null
		btImport.disabled = true
		btImport.text = "Import"
		tree.clear_tree_branch(2)
		skelFile.clear()
	elif id == 1:
		tree.clear_tree_branch(0)
		atlasFile.clear()
		imgAtlas.clear()

func _on_treeitem_selected(parent, id):
	#print("TreeItem selected %d.%d" % [parent, id])
	pnlInfo.clear()
	var infos: Array[String] = []
	if parent == 0 and id == - 1:
		infos = atlasFile.getInfo()
	elif parent == 1 and id == -1:
		infos = skelFile.getInfo()
	elif parent == 2:
		var a = skelFile.get_armature(id)
		if a: 
			infos = a.getInfo()
			_import_arm = a
			btImport.text = "Import: %s" % a.name
			btImport.disabled = false
	
	# Show informations
	if infos.size() > 0:
		var n = int(infos.size() / 2)
		for i in range(n):
			pnlInfo.add_info(infos[i * 2], infos[i * 2 + 1])

func _on_btImport_pressed():
	importSignal.emit(atlasFile, skelFile, _import_arm)

func _on_btDebug_pressed():
	print("List signals connect to `filesdropped`:")
	for c in get_tree().get_root().files_dropped.get_connections():
		print("   ", c)
		
	if !resDirSelector.filepath.is_empty() and !atlasFile.imgPath.is_empty():
		var texFile = resDirSelector.filepath + "\\" + atlasFile.imgPath.get_file()
		print("Texture file: ", texFile)
		if !FileAccess.file_exists(texFile):
			DirAccess.copy_absolute(atlasFile.imgPath, texFile)

# Utility functions
# Doesn't access class variables -> move to utils\dbi_utils.gd
func _load_image(path: String):
	var img = Image.load_from_file(path)
	var tex = ImageTexture.create_from_image(img)
	return tex










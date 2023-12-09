# DBISkelFile
#	version: String
#	name: String
#	d_armature: Dictionay[String, DBISkelArmature]
#		name: String
#		bones: Dictionary[name, DBISkelBone]
#			name: String
#			pname: String
#			length: float
#			index: int
#			transform: Transform2D
#		bone_names: Array[String] 						# ordered
#		animations: Array[DBIAnimation]
#	d_slot: Dictionary[String, DBISkelSlot]
#		name: String
#		bone: String
#		arm_name: String
#		displays: Array[DBISkelDisplay]
#			name: String
#			path: String								# -> region in Atlas file
#			slotName: String
#			type: DBIDisplayType
#			transform := Transform2D
#			meshData: DBIMeshDisplayData
#				vertices: PackedFloat32Array
#				uvs: PackedFloat32Array
#				triangles: PackedInt32Array
#				edges: PackedInt32Array
#				userEdges: PackedInt32Array
#				vert_min_x: float
#				vert_max_x: float
#				vert_min_y: float
#				vert_max_y: float
#				size: Vector2i
#				in_vert_count: int
#				boneData: Dictionary[int, DBIWeights]
#					boneIdx: int
#					boneName: String					# -> d_armature -> bone_names
#					transform: Transform2D
#					weights: PackedFloat32Array

const UTILS = preload("res://addons/a2d_db_importer/utils/dbi_utils.gd")
const DBANI = preload("res://addons/a2d_db_importer/utils/dbi_skel_animation.gd")

enum DBIDisplayType { DTUnknown = 0, DTImage = 1, DTMesh = 2 }

class DBIWeights:
	var boneIdx: int
	var boneName: String
	var transform: Transform2D
	var weights: PackedFloat32Array
	
	func _init(nVertices: int, idx: int = 0):
		weights = UTILS.init_pf32a(nVertices)
	
	func parse_transform(json: Array, i: int):
		boneIdx = int(json[i])
		var x0 = float(json[i + 1])
		var x1 = float(json[i + 2])
		var y0 = float(json[i + 3])
		var y1 = float(json[i + 4])
		var o0 = float(json[i + 5])
		var o1 = float(json[i + 6])
		transform = Transform2D(Vector2(x0, x1), Vector2(y0, y1), Vector2(o0, o1))

# path: armature/skin/slot/display
class DBIMeshDisplayData:
	var vertices: PackedFloat32Array
	var uvs: PackedFloat32Array
	var triangles: PackedInt32Array
	var edges: PackedInt32Array
	var userEdges: PackedInt32Array
	
	var boneData := {}						# [boneIdx: int, data: DBIWeights]
	var slotPose: Transform2D
	
#	var vert_min_x: float = INF
#	var vert_max_x: float = -INF
#	var vert_min_y: float = INF
#	var vert_max_y: float = -INF
	
	var size: Vector2i
	var vert_count: int
	var in_vert_count: int

	func from_json(json: Dictionary):
		var w = int(json["width"]) if json.has("width") else 0
		var h = int(json["height"]) if json.has("height") else 0
		size = Vector2i(w, h)
		
		var max_edge_index = 0
		for v in json["vertices"]: vertices.append(v)
		for uv in json["uvs"]: uvs.append(uv)
		for t in json["triangles"]: triangles.append(int(t))
		for e in json["edges"]: 
			edges.append(int(e))
			max_edge_index = max(max_edge_index, e)
		for ue in json["userEdges"]: userEdges.append(int(ue))
		
		if json["slotPose"]: _parse_slotPose(json["slotPose"])
		
		vert_count = int(vertices.size() / 2)
		in_vert_count = vert_count - max_edge_index
		_parse_weights(json["bonePose"], json["weights"], vert_count)

#		for i in range(0, vertices.size(), 2):
#			vert_min_x = minf(vert_min_x, vertices[i])
#			vert_max_x = maxf(vert_max_x, vertices[i])
#			vert_min_y = minf(vert_min_y, vertices[i + 1])
#			vert_max_y = maxf(vert_max_y, vertices[i + 1])

	func _parse_weights(jBonePoses: Array, jWeights: Array, nVertices: int):
		for i in range(0, jBonePoses.size(), 7):
			var bd = DBIWeights.new(nVertices)
			bd.parse_transform(jBonePoses, i)
			boneData[bd.boneIdx] = bd

		var i = 0
		var n = jWeights.size()
		var v_i = 0
		while  i < n:
			var nw = int(jWeights[i])
			for j in range(nw):
				var jj = i + 1 + j * 2
				var b_i = int(jWeights[jj])
				if !boneData.has(b_i): boneData[b_i] = DBIWeights.new(nVertices, b_i)
				var bd = boneData[b_i]
				bd.weights[v_i] = float(jWeights[jj + 1])
			i += 1 + nw * 2
			v_i += 1

	func _parse_slotPose(j: Array):
		var x0 = float(j[0])
		var x1 = float(j[1])
		var y0 = float(j[2])
		var y1 = float(j[3])
		var o0 = float(j[4])
		var o1 = float(j[5])
		slotPose = Transform2D(Vector2(x0, x1), Vector2(y0, y1), Vector2(o0, o1))

# path: skin/slot/display
# aka attachment in spine2d
class DBISkelDisplay:
	var name: String
	var path: String			# link to region in Atlas file?
	var type: DBIDisplayType
	var transform: Transform2D
	
	var meshData: DBIMeshDisplayData = null

	var slot: DBISkelSlot
	
	func from_json(j: Dictionary):
		name = j["name"]
		path = j["path"] if j.has("path") else name
		if j.has("transform"): transform = UTILS.parse_transform(j["transform"])
		if !j.has("type"):
			type = DBIDisplayType.DTImage
		else:
			match j["type"]:
				"image": 
					type = DBIDisplayType.DTImage
				"mesh": 
					type = DBIDisplayType.DTMesh
					meshData = DBIMeshDisplayData.new()
					meshData.from_json(j)
				_: type = DBIDisplayType.DTUnknown

# path: armature/bone
class DBISkelBone:
	var name: String
	var pname: String
	var length: float
	var index: int
	var transform: Transform2D
	
	var treeId: int
		
	func from_json(b: Dictionary):
		name = b["name"]
		if b.has("parent"): pname = b["parent"]
		if b.has("length"): length = b["length"]
		if b.has("transform"): transform = UTILS.parse_transform(b["transform"])

# path: armature/skin/slot
class DBISkelSlot:
	var name: String
	var boneName: String
	var displays: Array[DBISkelDisplay] = []
	var idx: int
	var z: int
	#var color: Color
	var arm_name: String

	var bone: DBISkelBone

	func from_json(j: Dictionary):
		name = j["name"]
		boneName = j["parent"]
		if j.has("z"): z = int(j["z"])
		# TODO: color, z?

# path: armature
class DBISkelArmature:
	var name: String
	# path: armature/bone
	var bones: Dictionary = {}
	var bone_names: Array[String] = []
	# path: armature/slot
	var d_slot: Dictionary = { }			# [slot_name: String, slot: DBISkelSlot]
	var maxZ: int
	
	var animations: Array[DBANI.DBIAnimation]
	
	var treeId: int
	
	func from_json(json: Dictionary):
		name = json["name"]
		var idx = 0
		for jB in json["bone"]:
			var bone = DBISkelBone.new()
			bone.from_json(jB)
			bone.index = idx
			bones[bone.name] = bone
			bone_names.append(bone.name)
			idx += 1

		idx = 0
		maxZ = -INF
		for jS in json["slot"]:
			var slot = DBISkelSlot.new()
			slot.from_json(jS)
			slot.idx = idx
			maxZ = max(maxZ, slot.z)
			d_slot[slot.name] = slot
			slot.bone = bones[slot.boneName]
			idx += 1
		
		for jSkin in json["skin"]:
			for jSlot in jSkin["slot"]:
				var sname: String = jSlot["name"]
				var slot: DBISkelSlot = d_slot[sname] if d_slot.has(sname) else null
				for jDisplay in jSlot["display"]:
					var d := DBISkelDisplay.new()
					d.from_json(jDisplay)
					if slot: 
						d.slot = slot
						slot.displays.append(d)
		
		_set_boneData_name()

		for jAni in json["animation"]:
			var ani := DBANI.DBIAnimation.new()
			ani.from_json(jAni)
			animations.append(ani)

	func _set_boneData_name():
		for s in d_slot.values():
			for d in s.displays:
				if d.meshData:
					for bw in d.meshData.boneData.values():
						bw.boneName = bone_names[bw.boneIdx]

	var _info: Array[String] = []
	func getInfo() -> Array[String]:
		if _info.size() <= 0:
			_info.append("Bones:")
			_info.append(str(bones.size()))
			_info.append("Slots:")
			_info.append(str(d_slot.size()))
		return _info

class DBISkelFile:
	var version: String
	var name: String
	
	var d_armature: Dictionary = { }		# [arm_name: String, arm: DBISkelArmature]
	
	func load_file(filepath: String) -> bool:
		if !FileAccess.file_exists(filepath): return false
		var jstr = FileAccess.get_file_as_string(filepath)
		var json = JSON.parse_string(jstr)
		
		if !(json.has("version") or json.has("name") or json.has("armature")): return false
		
		clear()
		
		version = json["version"]
		name = json["name"]
		
		for jA in json["armature"]:
			var arm := DBISkelArmature.new()
			arm.from_json(jA)
			d_armature[arm.name] = arm
		return true

	func get_armature(treeId: int) -> DBISkelArmature:
		for a in d_armature.values():
			if a.treeId == treeId: return a
		return null
	
	var _info: Array[String] = []
	func getInfo() -> Array[String]:
		if _info.size() <= 0 and !name.is_empty():
			_info.append("Name:")
			_info.append(name)
			_info.append("Version:")
			_info.append(version)
			_info.append("No.Arm:")
			_info.append(str(d_armature.size()))
		return _info

	func clear():
		_info.clear()
		name = ""
		d_armature.clear()




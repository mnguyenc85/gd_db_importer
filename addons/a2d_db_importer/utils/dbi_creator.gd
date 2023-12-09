const UTILS = preload("res://addons/a2d_db_importer/utils/dbi_utils.gd")
const SKEL = preload("res://addons/a2d_db_importer/utils/dbi_skel_file.gd")
const ATLAS = preload("res://addons/a2d_db_importer/utils/dbi_atlas_file.gd")

class DBICreator:
	
	var _root: Node
	var _skinNode: Node2D
	var _skelNode: Skeleton2D
	
	func create(root: Node, af: ATLAS.DBIAtlasFile, sf: SKEL.DBISkelFile, arm: SKEL.DBISkelArmature):
		_root = root
		_skelNode = _find_or_create_skeleton2d("DBSkel", root, root)
		if !_skelNode: 
			print("Can't create or find Skeleton2D node")
			return
		_skinNode = _find_or_create_node("DBSkin", root, root)
		if !_skinNode:
			print("Can't create or find `DBSkin` node")
			return
		
		var d_existed := {}		# Already added bones or skins
		_children_to_dictionary(_root, d_existed)
		_add_armature_to_scene(d_existed, arm)
		_add_skin_to_scene(d_existed, arm, af)
		_create_animations(d_existed, arm)

	## (call from create)
	func _add_armature_to_scene(d_existed, arm: SKEL.DBISkelArmature):
		for bdata in arm.bones.values():
			var bname = "B_" + UTILS.gen_name(bdata.name)
			
			if d_existed.has(bname): continue
			
			var b: Bone2D
			if bdata.length <= 0:
				b = Bone2D_Alter.new()
				b.display_mode = Bone2D_Alter.BoneDisplayType.Dot
				b.set_length(1)
			else:
				b = Bone2D.new()
				b.set_length(bdata.length)

			b.name = bname
			b.set_autocalculate_length_and_angle(false)
			b.scale = Vector2(1, 1)
			b.transform = bdata.transform
					
			if bdata.pname.is_empty():
				_skelNode.add_child(b)
				b.set_owner(_root)
			else:
				var pname = "B_" + UTILS.gen_name(bdata.pname)
				if d_existed.has(pname):
					var pb = d_existed[pname]
					pb.add_child(b)
					b.set_owner(_root)
				else:
					print("Can't find parent [%s] of bone [%s]" % [pname, b.name])
			d_existed[b.name] = b

	# (call from import_armature)
	func _add_skin_to_scene(d_existed, arm: SKEL.DBISkelArmature, af: ATLAS.DBIAtlasFile):
		var texture: Texture2D = null
		if FileAccess.file_exists(af.importPath):
			texture = load(af.importPath)
		
		# add slot + all displays
		for slot in arm.d_slot.values():
			var bone_name = "B_" + UTILS.gen_name(slot.boneName)
			if d_existed.has(bone_name):
				var bone = d_existed[bone_name]
				for d in slot.displays:
					# check if polygon already existed
					var display_name = "P_" + UTILS.gen_name(d.name)
					if d_existed.has(display_name): continue
					
					var polygon = null
					if af.d_region.has(d.path):
						if d.type == 1:
							polygon = _create_image_display(d, af.d_region[d.path], _skelNode)
						elif d.type == 2:
							polygon = _create_mesh_display(d, af.d_region[d.path], _skelNode)
					else:
						print_debug("Missing atlas %s" % d.path)
					
					if polygon:
						if texture: polygon.texture = texture
						
#						bone.add_child(polygon)
						_skinNode.add_child(polygon)
						polygon.set_owner(_root)
						
						polygon.z_index = d.slot.z - arm.maxZ - 1
						polygon.skeleton = polygon.get_path_to(_skelNode)
						if d.type == 2: _assign_weights(polygon, d,  _skelNode)
						
						d_existed[polygon.name] = polygon
			else:
				print("Missing bone %s of slot %s" % [slot.boneName, slot.name])

	func _create_image_display(d: SKEL.DBISkelDisplay, a: ATLAS.DBIAtlasRegion, skel: Skeleton2D):
		var polygon: Polygon2D = Polygon2D.new()
		polygon.name = "P_" + UTILS.gen_name(d.name)
		# set origin to center of atlas region: default origin is (0.5, 0.5)
		var ox = a.x + a.w * 0.5
		var oy = a.y + a.h * 0.5
		var arr := PackedFloat32Array([ 
			a.x, a.y, a.x + a.w, a.y,
			a.x + a.w, a.y + a.h, a.x, a.y + a.h])
		polygon.polygon = _floats_to_pv2a(arr, Vector2(1, 1), Vector2(-ox, -oy))
		polygon.uv = _floats_to_pv2a(arr)
		
		var boneName = "B_" + UTILS.gen_name(d.slot.boneName)
		var boneNode: Bone2D = skel.find_child(boneName)
		if boneNode:
			polygon.transform = boneNode.get_global_transform() * d.transform
		else:
			print_debug("Can't fine bone name: %s" % boneName)
			polygon.transform = d.transform
		return polygon

	## d: Mesh display
	## a: Atlas region
	func _create_mesh_display(d: SKEL.DBISkelDisplay, a: ATLAS.DBIAtlasRegion, skel: Skeleton2D):
		var plg: Polygon2D = Polygon2D.new()
		plg.name = "P_" + UTILS.gen_name(d.name)
		var m: SKEL.DBIMeshDisplayData = d.meshData
		# set origin to center of atlas region
		# pivot = 0.5, 0.5
		var ox = (a.x + a.w) / 2
		var oy = (a.y + a.h) / 2
		
		# WORKING:
		#var vertices0 = _floats_to_pv2a(m.vertices, Vector2(1, 1), Vector2(-ox, -oy))
		var vert0 = _floats_to_pv2a(m.vertices)
		var vert1 = _apply_bone_pose(vert0, d, skel)
		plg.polygon = vert1
		plg.uv = _floats_to_pv2a(m.uvs, Vector2(a.w, a.h), Vector2(a.x, a.y))
		plg.internal_vertex_count = m.in_vert_count	
		plg.polygons = _triangles_to_polygons(m.triangles)
		
		# calculate parent bone' transform
		plg.transform = d.meshData.slotPose
		## d.transform?
		return plg

	func _assign_weights(p: Polygon2D, d: SKEL.DBISkelDisplay, skel: Skeleton2D):
		var nv = p.polygon.size()
		p.clear_bones()
		#print("Assign weights to %s" % p.name)
		for i in range(skel.get_bone_count()):
			var bone: Bone2D = skel.get_bone(i)
			var path = skel.get_path_to(bone)
			
			var w: PackedFloat32Array
			for bw in d.meshData.boneData.values():
				if "B_" + UTILS.gen_name(bw.boneName) == bone.name:
					w = bw.weights
					#print("--> Bone `%s` has %d weights" % [bone.name, w.size()])
					break
			if !w: w = UTILS.init_pf32a(nv)
			p.add_bone(path, w)

	func _apply_bone_pose(vertices, display: SKEL.DBISkelDisplay, skel: Skeleton2D):
		var ownerBone = display.slot.boneName
		var m = display.meshData
		var boneData = m.boneData
		
		var verts := UTILS.init_pv2a(m.vert_count)
		for bp in boneData.values():
			bp = bp as SKEL.DBIWeights
			var boneName = "B_" + UTILS.gen_name(bp.boneName)
			var bone: Bone2D = skel.find_child(boneName)
			if bone:
				var btr = bone.get_global_transform()
				var t = btr * bp.transform.inverse()
				for i in range(m.vert_count):
					verts[i] += t * vertices[i] * bp.weights[i]
			else:
				print_debug("Can't find bone %s" % boneName)
		return verts

	func _create_animations(d_existed: Dictionary, arm: SKEL.DBISkelArmature):
		var players = _root.find_children("AnimationPlayer")
		if players.size() <= 0: 
			print_debug("You need to add a 'AnimationPlayer' first")
			return
		
		# TODO: Add default AnimationLibrary if has none
		var lib: AnimationLibrary = players[0].libraries[""]
		for dbAni in arm.animations:
			if lib.has_animation(dbAni.name): continue
			
			var ani = Animation.new()
			ani.length = dbAni.duration / 10
			for b in dbAni.bones:
				var bname = "B_" + UTILS.gen_name(b.name)
				if not d_existed.has(bname): continue
				var bone: Bone2D = d_existed[bname] as Bone2D

				var pos0 = bone.position
				var rot0 = bone.rotation
				var scale0 = bone.scale
				var path = str(_root.get_path_to(d_existed[bname]))
				#print(path, pos0, rot0)

				if b.translates.size() > 0:
					var track_index = ani.add_track(Animation.TYPE_VALUE)
					ani.track_set_path(track_index, path + ":position")
					for btr in b.translates:
						ani.track_insert_key(track_index, btr.t / 10, pos0 + btr.translate)
				if b.rotations.size() > 0:
					var track_index = ani.add_track(Animation.TYPE_VALUE)
					ani.track_set_path(track_index, path + ":rotation")
					for btr in b.rotations:
						ani.track_insert_key(track_index, btr.t / 10, rot0 + deg_to_rad(btr.rotation))
				if b.scales.size() > 0:
					var track_index = ani.add_track(Animation.TYPE_VALUE)
					ani.track_set_path(track_index, path + ":scale")
					for btr in b.scales:
						ani.track_insert_key(track_index, btr.t / 10, scale0 + btr.scale)
			
			lib.add_animation(dbAni.name, ani)
			print("Create animation: ", dbAni.name)


#region ----- Utility functions -----
# Doesn't access to class variables -> move to utils\dbi_utils.gd
	func _floats_to_pv2a(vertices: PackedFloat32Array, scale := Vector2(1, 1), offset := Vector2()) -> PackedVector2Array:
		var arr: Array[Vector2] = []
		var n = vertices.size()
		for i in range(0, n, 2):
			arr.append(Vector2(vertices[i] * scale.x + offset.x, vertices[i + 1] * scale.y + offset.y))
		return PackedVector2Array(arr)

	func _triangles_to_polygons(indices: PackedInt32Array) -> Array:
		var triangles = []
		var n = indices.size()
		for i in range(0, n, 3):
			triangles.append(PackedInt32Array([indices[i], indices[i + 1], indices[i + 2]]))
		return triangles

	## Utility function
	## TODO: filter by name?
	func _children_to_dictionary(node: Node, d: Dictionary):
		var waiting := node.get_children()
		while not waiting.is_empty():
			var c = waiting.pop_back() as Node
			waiting.append_array(c.get_children())
			d[c.name] = c

	## find child node of parent node using name
	## if not existed, create new Node2D
	func _find_or_create_node(name: String, parent: Node, owner: Node):
		var node = parent.find_child(name)
		if !node:
			node = Node2D.new()
			node.name = name
			parent.add_child(node)
			node.set_owner(owner)
		return node

	func _find_or_create_skeleton2d(name: String, parent: Node, owner: Node):
		var node = parent.find_child(name)
		if !node:
			node = Skeleton2D.new()
			node.name = name
			parent.add_child(node)
			node.set_owner(owner)
		return node
#endregion



class DBIAtlasRegion:
	var x: int
	var y: int
	var w: int
	var h: int
	var name: String
	
	var treeId: int
	
	func from_json(j):
		x = int(j["x"])
		y = int(j["y"])
		w = int(j["width"])
		h = int(j["height"])
		name = j["name"]

class DBIAtlasFile:
	# dir of atlas file
	var baseDir: String
	# image path in atlas file
	var imgPath: String
	# filename of image file
	var filename: String
	# imported texture's path
	var importPath: String
	var name: String
	var width: int
	var height: int
	
	var d_region: Dictionary = { }		# [r_name: String, r: DBIAtlasRegion]
	
	func load_file(filepath: String) -> bool:
		baseDir = filepath.get_base_dir()
#		print("Atlas's basedir: ", baseDir)
		if !FileAccess.file_exists(filepath): return false
		var jstr = FileAccess.get_file_as_string(filepath)
		var json = JSON.parse_string(jstr)
		
		if !(json.has("name") or json.has("SubTexture") or json.has("imagePath")): return false
		
		name = json["name"]
		imgPath = json["imagePath"]
		filename = imgPath.get_file()

		if json.has("width"): width = int(json["width"])
		if json.has("height"): height = int(json["height"])
		
		for jr in json["SubTexture"]:
			var r = DBIAtlasRegion.new()
			r.from_json(jr)
			d_region[r.name] = r
		
		return true

	var _info: Array[String] = []
	func getInfo() -> Array[String]:
		if _info.size() <= 0 and !name.is_empty():
			_info.append("Name:")
			_info.append(name)
			_info.append("Image:")
			_info.append(imgPath)
			_info.append("Size:")
			_info.append("%d x %d" % [width, height])
			
		return _info

	func clear():
		_info.clear()
		name = ""
		d_region.clear()

## Parse DragonBone's transform (x, y, skX, skY) to Transform2D
static func parse_transform(j: Dictionary) -> Transform2D:
	var x = j["x"] if j.has("x") else 0
	var y = j["y"] if j.has("y") else 0
	var skX = j["skX"] if j.has("skX") else 0
	var skY = j["skY"] if j.has("skY") else 0
	var rotation = deg_to_rad(skX)
	return Transform2D(rotation, Vector2(x, y))

static func to_array_int(a: Array):
	var out: Array[int]
	for i in a:
		out.append(int(i))
	return out

static func to_array_float(a: Array):
	var out: Array[float]
	for i in a:
		out.append(float(i))
	return out

static func gen_name(s: String) -> String:
	var ss = s
	for i in range(ss.length()):
		if ss[i] in "~!@#$%^&*()-+=[]{}|\\<>,./? ":
			ss[i] = '_'
	return ss

## Find max in PackedInt32Array
static func max_pi32a(arr: PackedInt32Array) -> int:
	var max_val = arr[0]
	for i in range(1, arr.size()):
		max_val = max(max_val, arr[i])
	return max_val

## Create a PackedFloat32Array with size of n
static func init_pf32a(n: int) -> PackedFloat32Array:
	var arr: Array[float] = []
	for i in range(n): arr.append(0)
	return PackedFloat32Array(arr)

## Create a PackedVertor2Array with size of n
static func init_pv2a(n: int) -> PackedVector2Array:
	var arr: Array[Vector2] = []
	for i in range(n): arr.append(Vector2())
	return PackedVector2Array(arr)

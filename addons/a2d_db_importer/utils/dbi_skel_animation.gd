class DBIAnimation:
	var name: String
	var duration: float
	var bones: Array[DBIAniBone]
	# slots, iks, ffds, frames
	# playTimes
	
	func from_json(j: Dictionary):
		name = j["name"]
		duration = float(j["duration"])
		for jBone in j["bone"]:
			var b := DBIAniBone.new()
			b.from_json(jBone)
			bones.append(b)
	
class DBIAniBone:
	var name: String
	var translates: Array[DBIAniFrameTranslate]
	var rotations: Array[DBIAniFrameRotate]
	var scales: Array[DBIAniFrameScale]
	
	func from_json(j: Dictionary):
		name = j["name"]
		
		var t = 0
		var isTranslate = false
		var isRotation = false
		var isScale = false
		
		# TODO: curve
		for jFrame in j["frame"]:
			var duration = float(jFrame["duration"])
			var tweenEasing = float(jFrame["tweenEasing"]) if jFrame.has("tweenEasing") else 0
#region Dragon Bone V5
			if jFrame.has("transform"):
				var tf: Dictionary = jFrame["transform"]
				if tf.has("x") or tf.has("y"):
					var x: float = float(tf["x"]) if tf.has("x") else 0
					var y: float = float(tf["y"]) if tf.has("y") else 0
					_add_translate(t, duration, tweenEasing, x, y)
					isTranslate = true
				if tf.has("skX"):
					var r = float(tf["skX"])
					_add_rotation(t, duration, tweenEasing, r)
					isRotation = true
				if tf.has("scX") or tf.has("scY"):
					var scX = float(tf["scX"]) if tf.has("scX") else 1
					var scY = float(tf["scY"]) if tf.has("scY") else 1
					_add_scale(t, duration, tweenEasing, scX - 1, scY - 1)
					isScale = true
				if tf.size() == 0:
					_add_translate(t, duration, tweenEasing)
					_add_rotation(t, duration, tweenEasing)
					_add_scale(t, duration, tweenEasing)
#endregion
#region Dragon Bone V5.5
			if jFrame.has("translateFrame"):
				var tf: Dictionary = jFrame["translateFrame"]
				var x: float = float(tf["x"]) if tf.has("x") else 0
				var y: float = float(tf["y"]) if tf.has("y") else 0
				_add_translate(t, duration, tweenEasing, x, y)
				isTranslate = true
			if jFrame.has("rotateFrame"):
				var tf: Dictionary = jFrame["rotateFrame"]
				var r = float(tf["rotate"]) if tf.has("rotate") else 0
				_add_rotation(t, duration, tweenEasing, r)
				isRotation = true
			if jFrame.has("scaleFrame"):
				var tf: Dictionary = jFrame["scaleFrame"]
				var scX = float(tf["x"]) if tf.has("x") else 0
				var scY = float(tf["y"]) if tf.has("y") else 0
				_add_scale(t, duration, tweenEasing, scX, scY)
				isScale = true
#endregion
			t += duration
		
		if not isTranslate: translates.clear()
		if not isRotation: rotations.clear()
		if not isScale: scales.clear()

	func _add_translate(t, d, te, x = 0, y = 0):
		var frame := DBIAniFrameTranslate.new()
		frame.duration = d
		frame.tweenEasing = te
		frame.t = t
		frame.translate = Vector2(x, y)
		translates.append(frame)

	func _add_rotation(t, d, te, r = 0):
		var frame := DBIAniFrameRotate.new()
		frame.duration = d
		frame.tweenEasing = te
		frame.t = t
		frame.rotation = r
		rotations.append(frame)

	func _add_scale(t, d, te, sx = 0, sy = 0):
		var frame := DBIAniFrameScale.new()
		frame.duration = d
		frame.tweenEasing = te
		frame.t = t
		frame.scale = Vector2(sx, sy)
		scales.append(frame)


class DBIAniFrame:
	var tweenEasing: float
	var duration: float
	var t: float

class DBIAniFrameTranslate:
	extends DBIAniFrame
	var translate: Vector2

class DBIAniFrameRotate:
	extends DBIAniFrame
	var rotation: float

class DBIAniFrameScale:
	extends  DBIAniFrame
	var scale: Vector2
	
# Skew?

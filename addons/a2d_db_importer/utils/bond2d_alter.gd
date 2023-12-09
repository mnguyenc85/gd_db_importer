# This script for editor mode 
# Remove this script from Bone2D node when ready for game mode

@tool
class_name Bone2D_Alter
extends Bone2D

enum BoneDisplayType { Normal, FirstChild, BoneSelf, Line, Dot }
var _display_mode: BoneDisplayType = BoneDisplayType.Normal
@export var display_mode: BoneDisplayType:
	get: return _display_mode
	set(value): 
		_display_mode = value
		if display_mode != BoneDisplayType.Normal:
			set("editor_settings/show_bone_gizmo", false)
		else: queue_redraw()

var _showDebug: bool = false
@export var show_debug: bool:
	get: return _showDebug
	set(v):
		if _showDebug != v:
			_showDebug = v
			_print_debug()

func _draw():
	if not Engine.is_editor_hint(): return
	match _display_mode:
		BoneDisplayType.FirstChild: 
			if !_draw_bone_1stChild(): _draw_bone_self()
		BoneDisplayType.BoneSelf: _draw_bone_self()
		BoneDisplayType.Line: _draw_bone_line()
		BoneDisplayType.Dot: _draw_bone_dot()
	
	_draw_link()
	# force children redraw?
	for c in get_children():
		if c is Bone2D: 
			c.queue_redraw()
	pass
	
func _draw_bone_1stChild() -> bool:
	for c in get_children():
		if c is Bone2D: 
			_draw_bone(c.position, 0)
			return true
	return false

func _draw_bone_self():
	var l = get_length()
	if l > 0:
		var end = Vector2(l, 0).rotated(get_bone_angle())
		_draw_bone(end, l)

func _draw_bone(end: Vector2, l: float):
	if l <= 0: l = end.length()
	var end_n = end.normalized()
	var w_l = min(10, l * 0.1)						# TODO: change?
	var w = Vector2(end_n.y, -end_n.x)
	var c = Color(0.8, 0.8, 0.8)
	
	var points = PackedVector2Array([
		Vector2(), (end_n + w) * w_l, end, (end_n - w) * w_l
	])
	var colors = PackedColorArray([c, c, c, c])
	
	draw_polygon(points, colors, points, null)
	
func _draw_bone_line():
	for c in get_children():
		if c is Bone2D:
			draw_line(Vector2(), c.position, Color(1, 1, 1), 0.5)

func _draw_bone_dot():
	if Engine.is_editor_hint():
		draw_arc(Vector2(), 5, 0, TAU, 32, Color(0.8, 0.8, 0.8))

# draw a link: a line from parent's end to me
func _draw_link():
	var p = get_parent()
	var p_gt = p.get_global_transform()
	var p_1stChild: Bone2D
	for c in p.get_children():
		if c is Bone2D:
			p_1stChild = c
			break

	var me_gt = get_global_transform()
	
	if p is Bone2D_Alter:
		if p.display_mode == BoneDisplayType.BoneSelf:
			_draw_line_to_parent_end(p, p_gt, me_gt)
		elif p.display_mode == BoneDisplayType.FirstChild:
			if get_index() > 0: _draw_line_to_parent_1stChild(p, p_1stChild, p_gt, me_gt)
		elif p.display_mode == BoneDisplayType.Dot:
			_draw_line_to_parent(p, p_gt, me_gt)

func _draw_line_to_parent(p: Bone2D, p_gt: Transform2D, me_gt: Transform2D):
	var rel = p_gt.get_origin() - me_gt.get_origin()
	draw_dashed_line(Vector2(), rel.rotated((-me_gt.get_rotation())), Color(0.8, 0.6, 0.6), 0.5, 5)

func _draw_line_to_parent_end(p: Bone2D, p_gt: Transform2D, me_gt: Transform2D):
	var rel = p_gt.get_origin() - me_gt.get_origin()
	var p_l = p.get_length()
	var p_end = (rel + Vector2(p_l, 0).rotated(p_gt.get_rotation() + p.get_bone_angle())).rotated(-me_gt.get_rotation())
	draw_dashed_line(Vector2(), p_end, Color(0.6, 0.8, 0.6), 0.5, 5)

func _draw_line_to_parent_1stChild(p: Bone2D, p_1stChild: Bone2D, p_gt: Transform2D, me_gt: Transform2D):
	var rel = p_1stChild.get_global_transform().get_origin() - me_gt.get_origin()
	var cpos = rel.rotated(-me_gt.get_rotation())
	draw_dashed_line(Vector2(), cpos, Color(0.6, 0.6, 0.8), 0.5, 5)
	
func _print_debug():
	print("Bone %s global transform:" % name)
	print(get_global_transform())
	var p = get_parent()
	if p:
		print("  Parent's global transform")
		print(p.get_global_transform())
	pass




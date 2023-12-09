@tool
extends TextureRect

var _regions: Array						# Array[ATLAS.DBIAtlasRegion]
var _font: Font
var _fHeight: float

func _ready():
	_font = ThemeDB.fallback_font
	_fHeight = _font.get_height(16) * 4 / 5

func _draw():
	for r in _regions:
		draw_rect(Rect2(r.x, r.y, r.w, r.h), Color.RED, false, 1)
		draw_string(_font, Vector2(r.x, r.y + _fHeight), r.name, HORIZONTAL_ALIGNMENT_LEFT)

func draw_regions(regions: Array):
	self._regions.append_array(regions)
	queue_redraw()

func clear():
	texture = null
	self._regions.clear()
	queue_redraw()




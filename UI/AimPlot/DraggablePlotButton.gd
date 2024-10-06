extends Button

var parent

var follow = false
var offset
# Called when the node enters the scene tree for the first time.
func _ready():
	pressed.connect(StartMoving)


func _process(_delta):
	if not Input.is_action_pressed("Click"):
		follow = false
	
	if follow:
		position = MousePos() - offset
		clampPos()
		modulate = Color.DIM_GRAY
		parent.UpdateLinePos()
	else:
		modulate = Color.WHITE


func StartMoving():
	follow = true
	offset = MousePos() - position

func StopMoving():
	pass

func MousePos():
	return get_viewport().get_mouse_position()

func clampPos():
	var relativePos = position + size/2.0 - (parent.size * (parent.center * 2)) / 2.0
	var newRelativePos = relativePos
	var angleToCenter = atan2(relativePos.y, relativePos.x)
	var dist = relativePos.length()
	
	var psize = parent.size.y
	if dist > parent.radius * psize:
		newRelativePos = Vector2(cos(angleToCenter), sin(angleToCenter))* psize * parent.radius
	
	if dist < parent.radiusMin * psize:
		newRelativePos = Vector2(cos(angleToCenter), sin(angleToCenter))* psize * parent.radiusMin
	
	var startAngle = parent.start + parent.rotationOffset
	var endAngle = parent.end + parent.rotationOffset
	
	if parent.flipped:
		startAngle = PI - startAngle
		endAngle = PI - endAngle
		
		var switch = endAngle
		endAngle = startAngle
		startAngle = switch
	startAngle *= -1
	endAngle *= -1
	var pass1 = angleToCenter > startAngle && angleToCenter < endAngle + PI * 2
	var pass2 = angleToCenter < endAngle && angleToCenter > startAngle - PI * 2
	if pass1 || pass2:
		var v1a = Vector2(cos(startAngle), sin(startAngle))
		var v2a = v1a
		v1a *= parent.radiusMin * psize
		v2a *= parent.radius * psize 
		
		var nearest1 = Geometry2D.get_closest_point_to_segment(relativePos, v1a, v2a)
		
		var v1b = Vector2(cos(endAngle), sin(endAngle))
		var v2b = v1b
		v1b *= parent.radiusMin * psize
		v2b *= parent.radius * psize 
		
		var nearest2 = Geometry2D.get_closest_point_to_segment(relativePos, v1b, v2b)
		
		var use1 = (nearest1 - relativePos).length() < (nearest2 - relativePos).length()
		
		newRelativePos = nearest1 if use1 else nearest2
	
	position = newRelativePos - size/2.0 + (parent.size * (parent.center * 2))/2.0

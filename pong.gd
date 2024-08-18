extends Node2D


var screen_size
var pad_size
var direction = Vector2(1.0, 0.0)

# Constant for ball speed (in pixels/second)
const INITIAL_BALL_SPEED = 280
# Speed of the ball (also in pixels/second)
var ball_speed = INITIAL_BALL_SPEED
# Constant for pads speed
const PAD_SPEED = 400

var score_p1 = 0
var score_p2 = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size
	pad_size = $p1.get_texture().get_size()
	set_process(true)
	

func paddle_contact(left, right, ball_pos):
	if ((left.has_point(ball_pos) and direction.x < 0) or (right.has_point(ball_pos) and direction.x > 0)):
		direction.x = -direction.x
		direction.y = randf()*2.0 - 1
		direction = direction.normalized()
		ball_speed *= 1.02
		
func move_pad(pad, delta, xn):
	var pad_position = pad.position
	if (pad_position.y > 0 and Input.is_action_pressed("p" + str(xn) + "_up")):
		pad_position.y += -PAD_SPEED * delta
	if (pad_position.y < screen_size.y and Input.is_action_pressed("p" + str(xn) + "_down")):
		pad_position.y -= -PAD_SPEED * delta
	return pad_position
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var ball_pos = $ball.position
	var p1 = Rect2( $p1.position - pad_size*0.5, pad_size )
	var p2 = Rect2( $p2.position- pad_size*0.5, pad_size )
	
	# Integrate new ball position
	ball_pos += direction * ball_speed * delta
	
	# check for paddle contact
	paddle_contact(p1, p2, ball_pos)
	
	# flip when touching roof or floor
	if ((ball_pos.y < 0 and direction.y < 0) or (ball_pos.y > screen_size.y and direction.y > 0)):
		direction.y = -direction.y
		
	# move left pad
	$p1.position = move_pad($p1, delta, 1)
	$p2.position = move_pad($p2, delta, 2)
	
	# keep track of score
	if (ball_pos.x < 0 or ball_pos.x > screen_size.x):
		if ball_pos.x < 0:
			score_p2 += 1
		else:
			score_p1 += 1
		update_score_display()
		ball_pos = screen_size*0.5
		ball_speed = INITIAL_BALL_SPEED
		direction = Vector2(-1, 0)
	
	$ball.position = ball_pos
	
func update_score_display():
	$score_label_p1.text = str(score_p1)
	$score_label_p2.text = str(score_p2)
	print(score_p1, score_p2)

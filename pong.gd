extends Node2D


var screen_size
var pad_size
var direction = Vector2(1.0, 0.0)

# Constant for ball speed (in pixels/second)
const INITIAL_BALL_SPEED = 380
# Speed of the ball (also in pixels/second)
var ball_speed = INITIAL_BALL_SPEED
# Constant for pads speed
const MAX_PADDLE_SPEED = 500
const PADDLE_ACCELERATION = 5000
const PADDLE_DECELERATION = 3000
const AI_SPEED = 200

var score_p1 = 0
var score_p2 = 0

var use_ai = true

var paddle_hit_sound: AudioStreamPlayer
var score_pause_timer: Timer

var p1_velocity = 0
var p2_velocity = 0

# Called when the node enters the scene tree for the first time.
func _ready():
    screen_size = get_viewport_rect().size
    pad_size = $p1.get_texture().get_size()
    $score_label_p1.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    $score_label_p2.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    update_score_display()
    set_process(true)
    
    # set up sound effect
    paddle_hit_sound = AudioStreamPlayer.new()
    add_child(paddle_hit_sound)
    paddle_hit_sound.stream = load("res://assets/sounds/paddle.wav")
    
    # set up the score pause timer
    score_pause_timer = Timer.new()
    add_child(score_pause_timer)
    score_pause_timer.one_shot = true
    score_pause_timer.wait_time = 1.0

func paddle_contact(left, right, ball_pos):
    if ((left.has_point(ball_pos) and direction.x < 0) or (right.has_point(ball_pos) and direction.x > 0)):
        direction.x = -direction.x
        direction.y = randf()*2.0 - 1
        direction = direction.normalized()
        ball_speed *= 1.06
        paddle_hit_sound.play()
        
func move_pad(pad, delta, xn):
    var input_direction = 0
    if Input.is_action_pressed("p" + str(xn) + "_up"):
        input_direction -= 1
    if Input.is_action_pressed("p" + str(xn) + "_down"):
        input_direction += 1
    
    var velocity = p1_velocity if xn == 1 else p2_velocity
    
    if input_direction != 0:
        velocity += input_direction * PADDLE_ACCELERATION * delta
    else:
        velocity = move_toward(velocity, 0, PADDLE_DECELERATION * delta)
    
    velocity = clamp(velocity, -MAX_PADDLE_SPEED, MAX_PADDLE_SPEED)
    
    pad.position.y += velocity * delta
    pad.position.y = clamp(pad.position.y, pad_size.y / 2, screen_size.y - pad_size.y / 2)
    
    if xn == 1:
        p1_velocity = velocity
    else:
        p2_velocity = velocity
    
func move_ai_pad(pad, ball, delta):
    var target_y = predict_ball_y(ball)
    var direction = 1 if target_y > pad.position.y else -1
    pad.position.y += direction * AI_SPEED * delta
    print(pad.position.y)
    pad.position.y = clamp(pad.position.y, 0, screen_size.y)

func predict_ball_y(ball):
    var ball_position = ball.position
    var ball_velocity = direction * ball_speed
    
    # calculate time for ball to reach AI paddle's x position
    var time_to_reach = ($p2.position.x - ball_position.x) / ball_velocity.x
    
    # predict y position
    var predicted_y = ball_position.y + (ball_velocity.y * time_to_reach)
    
    # bounces
    var bounces = int(abs(predicted_y) / screen_size.y)
    predicted_y = fmod(abs(predicted_y), screen_size.y)
    
    if bounces % 2 != 0:
        predicted_y = screen_size.y - predicted_y
    
    return predicted_y
        
func _process(delta):
    if score_pause_timer.is_stopped():
        process_game(delta)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func process_game(delta):
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
    move_pad($p1, delta, 1)
    
    # move right pad
    if not use_ai:
        move_pad($p2, delta, 2)
    else:
        move_ai_pad($p2, $ball, delta)
    
    # keep track of score
    if (ball_pos.x < 0 or ball_pos.x > screen_size.x):
        if ball_pos.x < 0:
            score_p2 += 1
            direction = Vector2(-1, 0)
        else:
            score_p1 += 1
            direction = Vector2(1, 0)
        update_score_display()
        
        # reset
        ball_pos = screen_size*0.5
        ball_speed = INITIAL_BALL_SPEED
        $p1.position.y = screen_size.y * 0.5
        $p2.position.y = screen_size.y * 0.5
        p1_velocity = 0
        p2_velocity = 0
        
        score_pause_timer.start()
    
    $ball.position = ball_pos
    
func update_score_display():
    $score_label_p1.text = str(score_p1)
    $score_label_p2.text = str(score_p2)

extends CharacterBody2D
class_name EnemyHSM

#FIXME: This also contributes to crashes
#FIXME: Enemy doesn't update if patrol point is placed on top of them


@onready var stay_still_timer = Timer.new()


#@onready var flashlight_vision_cone: Polygon2D = $Rig/Left/FlashLightVision/VisionCone

@onready var nav: NavigationAgent2D = $NavigationAgent2D

@export_category("Base")
@export var hsm : LimboHSM #This stays as export var

#Maybe give each point an export var for how much time the enemy idles
@export var patrol_points : Array[PatrolPoints]= []
@export var backtrack := false
var next_point : PatrolPoints
var counter : int = 0
var starting_global_pos : Vector2

@export_category("Stats")
@export var patrol_speed := 100


var rotation_speed := 5.0
var direction : Vector2
var state_list = []
#HACK: This global variable can be replaced by the nav's target
var target_pos : Vector2 = global_position

var current_speed : int


func _ready() -> void:
	intialize_nodes()
	state_machine()
	
	
	current_speed = patrol_speed
	#vision_color = flashlight_vision_cone.color
	await NavigationServer2D.map_changed
	
	nav.target_reached.connect(patrol_point_reached)
	
	
	next_point = patrol_points[0]
	

func intialize_nodes():
	for child in get_children():
		if child is PatrolPoints:
			patrol_points.append(child)
		
	
	#combat_hsm.enemy = self
	#add_child(combat_hsm)
	
	stay_still_timer.one_shot = true
	add_child(stay_still_timer)


#region Bug Should Occur here

#Idle State
func _idle_ready() -> void:
	#print("idle")
	current_speed = patrol_speed

func move_towards_point():
	if next_point:
		move(next_point.return_pos())

func _idle_physics_process(_delta: float) -> void:
	move_towards_point()

# Connected through nav target_reached signal
func patrol_point_reached():
	#await next_point.time_idle
	if not next_point or patrol_points.size() == 0:
		push_error("next_point is invalid or patrol_points is empty.")
		return
	
	if hsm and hsm.get_active_state().name == "Idle":
		stay_still_timer.wait_time = next_point.time_idle
		if stay_still_timer.is_stopped():
			stay_still_timer.start()
		await stay_still_timer.timeout
		
		counter += 1
		if patrol_points.size() == 1:
			return
		if counter >= patrol_points.size():
			counter = 0
			if backtrack:
				patrol_points.reverse()
		next_point = patrol_points[counter]
	else:
		push_error("hsm or active state is invalid.")
		
#endregion
	
	
#General
func _physics_process(delta: float) -> void:
	if !stay_still_timer.is_stopped() and next_point.match_rotation:
		rotate_to_target(next_point.return_rotation(), delta * 1.25)
	
	
	move_and_slide()

func state_machine() -> void:
	#States
	var idle_state : LimboState = add_state("Idle", _idle_ready, _idle_physics_process)
	print(idle_state)
	for state in state_list:
		hsm.add_child(state)
	
	#Transitions
	hsm.add_transition(hsm.ANYSTATE, idle_state, &"state_ended")
	
	
	#HSM
	hsm.initial_state = idle_state
	hsm.initialize(self)
	hsm.set_active(true)
	
func add_state(state_name : String, enter : Callable, update : Callable) -> LimboState:
	var state : LimboState = LimboState.new().named(state_name).call_on_enter(enter).call_on_update(update)
	state_list.append(state)
	return state
	
	
#Navigation
func move(target : Vector2):
	target_pos = target
	nav.set_target_position(target)
	direction = (nav.get_next_path_position() - global_position).normalized()
	rotate_to_target(nav.get_next_path_position(), 0.01)
	
	
	
	velocity.x = lerp(velocity.x, current_speed * direction.x, .2)
	velocity.y = lerp(velocity.y, current_speed * direction.y, .2)

#Start a navigation timer instead for optimization
func navigation():
	nav.set_target_position(target_pos)

# Callable Methods
func rotate_to_target(target : Vector2, delta) -> void:
	var direction : Vector2 = (target - global_position)
	var angleTo = transform.x.angle_to(direction) 
	rotate(sign(angleTo) * min(delta * rotation_speed, abs(angleTo)))

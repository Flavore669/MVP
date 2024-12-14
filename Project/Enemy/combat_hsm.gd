extends LimboHSM
class_name CombatLogic

@onready var to_action_timer : Timer = Timer.new()
@onready var follow_up_buffer : Timer = Timer.new()
@onready var block_timer : Timer = Timer.new()

#TODO: Add data to determine if enemy becomes more offensive/defensive
@onready var to_action_wait_time : float
@onready var follow_up_points : int 
@onready var chill_speed : int 
@onready var angle : int 
@onready var radius : int 
@onready var orbit_speed : int 

var idle_behavoirs : Array[Callable] = []
var state_list : Array = []
var idle_transitions : Array[StringName] = []
var action_transitions : Array[StringName] = []
var enemy : EnemyHSM


func _ready() -> void:
	enemy = get_parent()
	randomize_action_timer()
	instatiate_variables()
	randomize()
	state_machine()
	intialize_nodes()
	

func instatiate_variables():
	to_action_wait_time = enemy.to_action_wait_time
	follow_up_points = enemy.follow_up_points
	chill_speed = enemy.chill_speed
	angle = enemy.angle
	radius = enemy.radius
	orbit_speed = enemy.orbit_speed
	
	idle_behavoirs.append(orbit_player)
	idle_behavoirs.append(move_towards_player)

func intialize_nodes():
	to_action_timer.one_shot = true
	to_action_timer.wait_time = to_action_wait_time
	to_action_timer.timeout.connect(to_combat)
	add_child(to_action_timer)
	
	follow_up_buffer.one_shot = true
	follow_up_buffer.wait_time = 0.1
	add_child(follow_up_buffer)
	

# Orbit State (orbit the player menacingly)
func _orbit_ready():
	enemy.current_speed = chill_speed
	angle *= coinflip()

func _orbit_physics_process(_delta : float):
	enemy.move(enemy.player.global_position + Vector2.RIGHT.rotated(angle) * radius)
	enemy.look_at(enemy.player.global_position)

func orbit_player():
	enemy.move(enemy.player.global_position + Vector2.RIGHT.rotated(angle) * radius)
	enemy.look_at(enemy.player.global_position)

# Chill state (wander towards the player)
func _chill_ready():
	enemy.current_speed = chill_speed

func _chill_physics_process(_delta : float):
	move_towards_player()

func move_towards_player():
		var dir := (enemy.global_position - enemy.player.global_position).normalized()
		enemy.move(enemy.player.global_position + dir * 120)
		
# Attack State
func _attack_ready():
	to_action_timer.stop()
	enemy.attack()
	enemy.pick_attack()

func _attack_physics_process(_delta : float):
	move_towards_player()
	

func _attack_exit():
	#TODO: Improve followup(Put limit on consecutive follups?)
	if !to_action_timer:
		find_combat_timer()
	to_action_timer.start()
	enemy.pick_attack()
	followup_action()

# Block State
func _block_ready():
	to_action_timer.stop()
	enemy.block()

func _block_physics_process(_delta : float):
	move_towards_player()

#FIXME: It's not adding the timer error periodically? See if find_combat_timer fixes this
func _block_exit():
	if !to_action_timer:
		find_combat_timer()
	to_action_timer.start()
	followup_action()

# State Machine
func state_machine():
	#States
	var orbit_idle_state : LimboState = add_state("Orbit", _orbit_ready, _orbit_physics_process)
	
	var chill_idle_state : LimboState = add_state("Chill", _chill_ready, _chill_physics_process)
	
	var attack_state : LimboState = followup_state("Attack", _attack_ready, _attack_physics_process,_attack_exit)
	
	var block_state : LimboState = followup_state("Block", _block_ready, _block_physics_process,_block_exit)
	
	for state in state_list:
		add_child(state)
	
	# Action Transitions
	add_transition(ANYSTATE, attack_state, &"attack_started")
	action_transitions.append(&"attack_started")
	add_transition(ANYSTATE, block_state, &"block_started")
	action_transitions.append(&"block_started")
	
	#Idle Transitions
	add_transition(ANYSTATE, chill_idle_state, &"chill_started")
	idle_transitions.append(&"chill_started")
	add_transition(ANYSTATE, orbit_idle_state, &"orbit_started")
	idle_transitions.append(&"orbit_started")
	
	#HSM
	initial_state = chill_idle_state
	
	initialize(self)
	set_active(false)

# Add State helper functions
func add_state(state_name : String, enter : Callable, process : Callable) -> LimboState:
	var state : LimboState = LimboState.new().named(state_name).call_on_enter(enter).call_on_update(process)
	state_list.append(state)
	return state

func followup_state(state_name : String, enter : Callable, process : Callable, exit : Callable) -> LimboState:
	var state : LimboState = LimboState.new().named(state_name).call_on_enter(enter).call_on_update(process).call_on_exit(exit)
	state_list.append(state)
	return state

# HSM Dispatches

# to_action_timer timout signal
func to_combat():
	print("attack started")
	randomize_action_timer()
	dispatch(random_action())
	

# completed_recovery signal
func leave_combat():
	print("attack ended")
	enemy.in_action = false
	dispatch(random_idle())

# Miscallaneous
func coinflip() -> int:
	var coin_flip = [-1,1].pick_random()
	return coin_flip

func followup_action():
	var coin := coinflip()
	if coin == 1 and follow_up_points > 0:
		follow_up_buffer.start()
		follow_up_points -= 1
		await follow_up_buffer.timeout
		to_combat()

func randomize_action_timer():
	to_action_timer.wait_time = randf_range(1.0,3.5)

func random_action() -> StringName:
	return action_transitions.pick_random()
	
func random_idle() -> StringName:
	return idle_transitions.pick_random()
	
func find_combat_timer():
	for child in get_children():
		if child is Timer:
			to_action_timer = child
			return

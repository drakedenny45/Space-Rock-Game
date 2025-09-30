extends Node

@export var rock_scene: PackedScene
@export var player_scene: PackedScene

var screensize: Vector2
var player: Node = null
var score: int = 0
var playing: bool = false
var initial_rocks: int = 5

func _ready() -> void:
    randomize()
    screensize = get_viewport().get_visible_rect().size

    if rock_scene == null:
        push_error("Main.gd: 'rock_scene' is not assigned. Drag rock.tscn into the Main node's 'rock_scene' export in the Inspector.")
    if player_scene == null:
        push_error("Main.gd: 'player_scene' is not assigned. Drag player.tscn into the Main node's 'player_scene' export in the Inspector.")

    new_game()

func new_game() -> void:
    score = 0
    playing = true

    # Remove any old rocks
    for child in get_children():
        if child.is_in_group("rocks"):
            child.queue_free()

    # Handle player
    if player == null:
        if player_scene == null:
            push_error("Cannot spawn player: player_scene is null.")
        else:
            player = player_scene.instantiate()
            add_child(player)
    # Reset existing player position and state
    player.position = screensize / 2
    if "reset" in player:
        player.reset()  # Call the player’s reset function if it exists

    # Spawn initial rocks
    for i in range(initial_rocks):
        spawn_rock(3)

func spawn_rock(size: int = 3, pos: Variant = null, vel: Variant = null) -> void:
    if rock_scene == null:
        push_error("Cannot spawn rock: rock_scene is null.")
        return

    var rock = rock_scene.instantiate()
    add_child(rock)
    rock.add_to_group("rocks")
    rock.screensize = screensize

    var p: Vector2 = pos if pos != null else Vector2(randf() * screensize.x, randf() * screensize.y)
    var v: Vector2 = vel if vel != null else Vector2(randf_range(-100, 100), randf_range(-100, 100))

    rock.start(p, v, size)
    rock.exploded.connect(Callable(self, "_on_rock_exploded"))

func _on_rock_exploded(size: int, _radius: int, pos: Vector2, vel: Vector2) -> void:
    score += 10
    if size > 1:
        for i in range(2):
            var new_vel = vel.rotated(randf_range(-0.5, 0.5)) * 1.2
            spawn_rock(size - 1, pos, new_vel)

func _process(delta: float) -> void:
    if not playing:
        return

    var input_vector = Vector2.ZERO
    if Input.is_action_pressed("ui_right"):
        input_vector.x += 1
    if Input.is_action_pressed("ui_left"):
        input_vector.x -= 1
    if Input.is_action_pressed("ui_down"):
        input_vector.y += 1
    if Input.is_action_pressed("ui_up"):
        input_vector.y -= 1

    if player and input_vector != Vector2.ZERO:
        player.position += input_vector.normalized() * 200 * delta
        player.position.x = wrapf(player.position.x, 0, screensize.x)
        player.position.y = wrapf(player.position.y, 0, screensize.y)

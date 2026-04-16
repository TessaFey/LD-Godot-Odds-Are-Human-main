extends Node

# --- Configuration ---
const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1" # Localhost for testing
const MAX_CLIENTS = 4

var players = []

var peer = ENetMultiplayerPeer.new()

func _ready():
	# Connect standard multiplayer signals
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# --- Hosting and Joining ---

func host_game():
	var error = peer.create_server(PORT, MAX_CLIENTS)
	if error != OK:
		print("Error: Cannot host server. Code: ", error)
		return
	
	multiplayer.multiplayer_peer = peer
	print("Server hosted successfully!")
	
	players.append(1)

func join_game(address: String = DEFAULT_SERVER_IP):
	var error = peer.create_client(address, PORT)
	if error != OK:
		print("Error: Cannot join game. Code: ", error)
		return
		
	multiplayer.multiplayer_peer = peer
	print("Attempting to join server at ", address, "...")

# --- Signal Callbacks ---

func _on_player_connected(id):
	print("Player connected with ID: ", id)
	if not players.has(id):
		players.append(id)

func _on_player_disconnected(id):
	print("Player disconnected with ID: ", id)
	players.erase(id)

func _on_connected_ok():
	print("Successfully connected to the server!")

func _on_connected_fail():
	print("Failed to connect to the server.")

func _on_server_disconnected():
	print("The server has disconnected.")

# --- Game Logic ---

@rpc("call_local", "authority", "reliable")
func change_scene(scene_path: String):
	get_tree().change_scene_to_file(scene_path)

func server_change_scene(scene_path: String):
	if multiplayer.is_server():
		rpc("change_scene", scene_path)

# --- RPC Communication Example ---

# The @rpc annotation dictates how and where this function runs.
# "any_peer" means anyone can call it. "call_local" means it also runs on the machine that called it.
@rpc("any_peer", "call_local")
func send_chat_message(message: String):
	var sender_id = multiplayer.get_remote_sender_id()
	print("Message from %s: %s" % [sender_id, message])

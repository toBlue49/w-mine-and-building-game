extends Node

var requested_value = []

##NOTE: How to use get request system:
#Call get_var() with the arguments get_peer (peer id of the get request peer),
#get_node (NodePath of the get request), args (arguments used in send(),
#timeout_sec (default 3sec). Returns the get request value or -32676 if the timeout triggers.

@rpc("any_peer", "call_remote")
func return_value(goal_peer: int, value, index: int, do_log = false):
	if multiplayer.get_unique_id() != goal_peer: return
	if do_log: print_rich("[INFO] Request Returned[%s] -> %s" % [index, value])

	self.requested_value[index] = value


@rpc("any_peer", "call_remote")
func send(get_peer:int, goal_peer: int, call_node: NodePath, args: Array, index: int):
	print("%s / %s" % [get_peer, multiplayer.get_unique_id()])
	if multiplayer.get_unique_id() != get_peer: return
	if args[0] == "get_block_slice": #[1] = slice_count
		await get_tree().process_frame
		var result: Array = get_node(call_node).level_to_array(args[1])
		return_value.rpc(goal_peer, result, index)
	if args[0] == "compare_protocol":#[1] = client protocol version
		var result: int = args[1] - global.PROTOCOL_VERSION
		return_value.rpc(goal_peer, result, index, true)

func get_var(get_peer: int, get_nodepath: NodePath, args: Array, timeout_sec: float = 5.0) -> Variant:
	print(get_peer)
	print(get_nodepath)
	print(args)
	
	var index = requested_value.size()
	requested_value.append(null)
	
	send.rpc(get_peer, multiplayer.get_unique_id(), get_nodepath, args, index)
	while requested_value[index] == null and timeout_sec > 0:
		await get_tree().process_frame
		timeout_sec -= get_process_delta_time()
	
	if timeout_sec < 0: #timeout
		return -32676
	else:
		var value = requested_value[index]
		requested_value[index] = null #don't keep it in memory
		return value

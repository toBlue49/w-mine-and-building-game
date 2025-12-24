extends Node

@rpc("any_peer", "call_remote")
func return_value(goal_peer: int, goal_node: NodePath, var_name: StringName, value, do_log = false, special: String = "none"):
	if multiplayer.get_unique_id() != goal_peer: return
	var node: Node = get_node(goal_node)
	if do_log: print_rich("[INFO] Request Returned: %s.%s -> %s" % [goal_node, var_name, value])
	if special == "append_array":
		var array = node.get(var_name)
		for i in value:
			array.append(i)
	else:
		node.set(var_name, value)

##NOTE: How to use request system:
#Make an call to the send function from your node and peer; give this information
#to the send function. Also give the goal node and variable, to know what to
#change. Then code some case, which gets an value, then call return_value.

@rpc("any_peer", "call_remote")
func send(get_peer:int, goal_peer: int, call_node: NodePath, goal_node: NodePath, var_name: StringName, args: Array):
	if multiplayer.get_unique_id() != get_peer: return
	if args[0] == "testing_2":
		return_value(goal_peer, goal_node, var_name, 2)
	if args[0] == "get_chunk": #[1] = slice
		await get_tree().process_frame
		var result: Array = get_node(call_node).level_to_array(args[1])
		return_value.rpc(goal_peer, goal_node, var_name, result, false, "append_array")
		return_value.rpc(goal_peer, goal_node, "get_level_array_slice", args[1], true)
	if args[0] == "compare_protocol":#[1] = client protocol version
		var result: int = args[1] - global.PROTOCOL_VERSION
		return_value.rpc(goal_peer, goal_node, var_name, result, true)

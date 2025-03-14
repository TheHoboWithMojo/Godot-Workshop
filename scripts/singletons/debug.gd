extends Node

# Holds advanced printing functions
		
func throw_error(self_node: Node, reason: String, input: Variant = null):
		
	var file_name: String = self_node.get_script().resource_path.get_file()
	var function_name: String = get_stack()[-1].function  # Get the last function in the call stack
	if input == null:
		print("Error: in %s, %s(). %s." % [file_name, function_name, reason])
		return
	
	print("Error: in %s, %s(). %s. Input: %s" % [file_name, function_name, reason, input])

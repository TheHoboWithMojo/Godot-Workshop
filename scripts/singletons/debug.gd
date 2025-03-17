extends Node

# Holds advanced printing functions
func throw_error(self_node: Node, reason: String, input: Variant = null):
		
	var file_name: String = self_node.get_script().resource_path.get_file()
	var function_name: String = get_stack()[-1].function  # Get the last function in the call stack
	if input == null:
		print("Error: in %s, %s(). %s." % [file_name, function_name, reason])
		return
	
	print("Error: in %s, %s(). %s. Input: %s" % [file_name, function_name, reason, input])
	
func print_pretty_rows(rows: Array, title: String) -> void: # Prints an array beautifully
	for row: Array in rows:
		print("\n%s:" % title)
		for field: Array in row:
			print("  %s: %s" % [field[0], field[1]])
		print("\n---------------")

extends Node

var factions_dict = {
	"New California Republic": {
		"rep": 50,
		"decisions": []
	},
	"Caesar's Legion": {
		"rep": 50,
		"decisions": []
	},
	"Brotherhood of Steel": {
		"rep": 50,
		"decisions": []
	},
	"Followers of the Apocalypse": {
		"rep": 50,
		"decisions": []
	},
	"Great Khans": {
		"rep": 50,
		"decisions": []
	},
	"Gun Runners": {
		"rep": 50,
		"decisions": []
	},
	"Boomers": {
		"rep": 50,
		"decisions": []
	},
	"Enclave Remnants": {
		"rep": 50,
		"decisions": []
	},
	"White Glove Society": {
		"rep": 50,
		"decisions": []
	},
	"Omertas": {
		"rep": 50,
		"decisions": []
	},
	"Chairmen": {
		"rep": 50,
		"decisions": []
	},
	"Kings": {
		"rep": 50,
		"decisions": []
	},
	"Powder Gangers": {
		"rep": 50,
		"decisions": []
	},
	"Fiends": {
		"rep": 50,
		"decisions": []
	},
	"Van Graffs": {
		"rep": 50,
		"decisions": []
	},
	"Crimson Caravan": {
		"rep": 50,
		"decisions": []
	},
	"Jacobstown": {
		"rep": 50,
		"decisions": []
	},
	"Westside Cooperative": {
		"rep": 50,
		"decisions": []
	},
	"Brotherhood Outcasts": {
		"rep": 50,
		"decisions": []
	}
}

func change_rep(faction: String, rep_change: int) -> void:
	if factions_dict.has(faction):
		factions_dict[faction]["rep"] += rep_change
	else:
		Data.throw_error(self, "Faction " + faction + " not found!")

func log_decision(faction: String, decision: String, rep_change: int) -> void:
	if factions_dict.has(faction):
		# Update reputation
		change_rep(faction, rep_change)
		
		# Check if decision already exists
		var found = false
		for entry in factions_dict[faction]["decisions"]:
			if entry[0] == decision:
				entry[1] += rep_change  # Update reputation impact
				entry[2] += 1  # Increment count
				found = true
				break
		
		# If decision not found, add a new entry
		if not found:
			factions_dict[faction]["decisions"].append([decision, rep_change, 1])
	else:
		Data.throw_error(self, "Faction " + faction + " not found!")
		
func get_rep_status(faction: String) -> String:
	if factions_dict.has(faction):
		var rep = factions_dict[faction]["rep"]
		if rep < 0:
			return "Hostile"
		elif rep < 25:
			return "Unfriendly"
		elif rep < 50:
			return "Neutral"
		elif rep < 75:
			return "Friendly"
		else:
			return "Allied"
	else:
		Data.throw_error(self, "Faction " + faction + " not found!")
		return "Faction not found!"

func reset_faction(faction: String) -> void:
	if factions_dict.has(faction):
		factions_dict[faction]["rep"] = 50
		factions_dict[faction]["decisions"] = []
	else:
		Data.throw_error(self, "Faction " + faction + " not found!")
		
func print_faction_status(faction: String) -> void:
	if factions_dict.has(faction):
		var rep = factions_dict[faction]["rep"]
		var status = get_rep_status(faction)
		var header = "| %-25s | %-10s (%3d) |" % [faction, status, rep]
		var divider = "-" .repeat(header.length())

		print(divider)
		print(header)
		print(divider)

		for entry in factions_dict[faction]["decisions"]:
			print("x" + str(entry[2]) + " " + entry[0] + " (" + str(entry[1]) + ")")

		print(divider)
	else:
		Data.throw_error(self, "Faction " + faction + " not found!")

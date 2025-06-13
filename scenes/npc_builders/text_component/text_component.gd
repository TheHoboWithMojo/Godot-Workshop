extends Control
@export var message: String
@export var repeatable: bool = true
@export var character: Node2D
@onready var completed: bool = false
@onready var text_box: RichTextLabel = $Text
@onready var words_in_message: int = message.split(" ").size()

func _ready() -> void:
	Dialogic.timeline_started.connect(_on_dialogue_start)
	Dialogic.timeline_ended.connect(_on_dialogue_end)

@onready var displaying: bool = false

func display() -> void:
	if not displaying:
		displaying = true
		if (completed and not repeatable) or text_box.text == message:
			text_box.set_visible(false)
			displaying = false
			return
		else:
			completed = true
			text_box.set_visible(true)
			text_box.set_text(message)
			await Global.delay(self, max(3.0, words_in_message*1))
			text_box.set_text("")
			text_box.set_visible(false)
			displaying = false
			
func _on_dialogue_start() -> void:
	self.set_visible(false)
	
func _on_dialogue_end() -> void:
	text_box.set_text("")
	self.set_visible(true)

func _process(_delta: float) -> void:
	if Global.get_vector_to_player(character).length() <= 100:
		display()

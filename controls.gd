extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass


func _on_back_pressed():
    get_tree().root.get_node("Menu").visible = true
    self.queue_free()

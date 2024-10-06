@tool
extends EditorPlugin
class_name NodeSelection
static var SelectedNodes = []

func _enter_tree():
	pass

func _process(delta):
	SelectedNodes = get_editor_interface().get_selection().get_selected_nodes()

func _exit_tree():
	# Clean-up of the plugin goes here.
	pass

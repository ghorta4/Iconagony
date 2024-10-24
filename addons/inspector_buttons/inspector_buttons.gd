@tool
extends EditorPlugin

var inspector_plugin

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		# Add our custom Go button!
		inspector_plugin = preload("inspector_buttons_plugin.gd").new()
		add_inspector_plugin(inspector_plugin)

func _exit_tree() -> void:
	remove_inspector_plugin(inspector_plugin)

func _get_plugin_name() -> String:
	return "Inspector Buttons"

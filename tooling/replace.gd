@tool
extends EditorScript

const NEW_SCENE = preload("res://valvecontrol.tscn")   # your valve switch scene

func _run():
	var root = get_scene()
	for old in get_editor_interface().get_selection().get_selected_nodes():
		var parent = old.get_parent()
		var idx = old.get_index()
		var nm = old.name
		var xf = old.transform
		var n = NEW_SCENE.instantiate()
		for p in old.get_property_list():
			if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and p.name in n:
				n.set(p.name, old.get(p.name))
		parent.remove_child(old)
		old.queue_free()
		parent.add_child(n)
		parent.move_child(n, idx)
		n.owner = root
		n.name = nm
		n.transform = xf

extends BaseManager

enum Member { METHOD, SIGNAL }

var _trait_definitions: Dictionary[String, Set] = {}
var _cached_definitions: Dictionary[String, Set] = {}
var _cached_matches: Dictionary[String, Dictionary] = {}

func initialize() -> Error:
	for global_class in ProjectSettings.get_global_class_list():
		var script: GDScript = ResourceLoader.load(global_class["path"])
		if _is_trait(script):
			_register_trait(script)
	return OK


func implements(trait_script: GDScript, object: Object) -> bool:
	var trait_script_id: String = _get_script_id(trait_script)
	
	if trait_script_id not in _trait_definitions:
		return false
		
	var object_script_variant: Variant = object.get_script()
	
	if object_script_variant == null:
		return false
		
	var object_script: GDScript = object_script_variant
	var object_script_id: String = _get_script_id(object_script)
	
	if object_script_id not in _cached_matches:
		_cached_matches[object_script_id] = {}
	elif _cached_matches[object_script_id].has(trait_script_id):
		return _cached_matches[object_script_id][trait_script_id]

	if object_script_id not in _cached_definitions:
		_cached_definitions[object_script_id] = _extract_definition(object_script)

	var matched: bool = _match_definitions(
		_trait_definitions[trait_script_id], 
		_cached_definitions[object_script_id])
	
	_cached_matches[object_script_id][trait_script_id] = matched
	return matched


func _register_trait(script: GDScript) -> void:
	var script_id: String = _get_script_id(script)
	if script_id not in _trait_definitions:
		_trait_definitions[script_id] = _extract_definition(script)
		_cached_definitions[script_id] = _trait_definitions[script_id]


static func _extract_definition(script: GDScript) -> Set:
	var definition: Set = Set.new()
	for method_proto in script.get_script_method_list():
		definition.add(_build_signature(Member.METHOD, method_proto))
	for signal_proto in script.get_script_signal_list():
		definition.add(_build_signature(Member.SIGNAL, signal_proto))
	return definition


static func _build_signature(member_type: Member, proto: Dictionary) -> String:
	return "%s%s(%s)%s" % [
		member_type,
		proto["name"],
		",".join(proto["args"].map(func(arg: Dictionary): return _build_signature_arg(arg))),
		_build_signature_arg(proto["return"])
	]


static func _build_signature_arg(arg: Dictionary) -> String:
	return "%s%s" % [arg["type"], arg["class_name"]]


static func _match_definitions(trait_def: Set, obj_def: Set) -> bool:
	return trait_def.intersect(obj_def).size() == trait_def.size()


static func _get_script_id(script: GDScript) -> String:
	return ResourceUID.path_to_uid(script.resource_path)


static func _is_trait(script: GDScript) -> bool:
	var parent: GDScript = script.get_base_script()
	while parent and parent != Trait:
		parent = parent.get_base_script()
	return parent == Trait

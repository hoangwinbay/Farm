extends Node
# Khởi tạo sớm: tạo phím điều khiển và font hỗ trợ tiếng Việt.

const ACTIONS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"interact": [KEY_E, KEY_SPACE],
	"inventory": [KEY_I, KEY_TAB],
	"cycle_seed": [KEY_R],
	"pause": [KEY_ESCAPE],
}


func _init() -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)

	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Segoe UI", "Arial", "Tahoma"])
	ThemeDB.fallback_font = f
	ThemeDB.fallback_font_size = 16

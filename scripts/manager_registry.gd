extends RefCounted
# Đăng Ký & Khởi Tạo Tất Cả Các Module Quản Lý (Manager Registry)

const FarmingControllerScript := preload("res://scripts/farming_controller.gd")
const PenManagerScript := preload("res://scripts/pen_manager.gd")
const FishingManagerScript := preload("res://scripts/fishing_manager.gd")
const StallManagerScript := preload("res://scripts/stall_manager.gd")
const WorldBuilderScript := preload("res://scripts/world_builder.gd")
const InteractionManagerScript := preload("res://scripts/interaction_manager.gd")
const DayNightCycleScript := preload("res://scripts/day_night_cycle.gd")
const SaveLoadManagerScript := preload("res://scripts/save_load_manager.gd")
const MineTransitionManagerScript := preload("res://scripts/mine_transition_manager.gd")
const UICoordinatorScript := preload("res://scripts/ui_coordinator.gd")
const GameLoopManagerScript := preload("res://scripts/game_loop_manager.gd")
const InputControllerScript := preload("res://scripts/input_controller.gd")
const DebugRunnerScript := preload("res://scripts/debug_runner.gd")
const ClicktestRunnerScript := preload("res://scripts/clicktest_runner.gd")


func init_managers(main: Node2D) -> void:
	main.world_builder = WorldBuilderScript.new()
	main.world_builder.setup(main)

	main.pen_manager = PenManagerScript.new()
	main.pen_manager.setup(main)

	main.farming_controller = FarmingControllerScript.new()
	main.fishing_manager = FishingManagerScript.new()
	main.stall_manager = StallManagerScript.new()

	main.interaction_manager = InteractionManagerScript.new()
	main.interaction_manager.setup(main)

	main.day_night_cycle = DayNightCycleScript.new()
	main.day_night_cycle.setup(main)

	main.save_load_manager = SaveLoadManagerScript.new()
	main.save_load_manager.setup(main)

	main.mine_transition_manager = MineTransitionManagerScript.new()
	main.mine_transition_manager.setup(main)

	main.ui_coordinator = UICoordinatorScript.new()
	main.ui_coordinator.setup(main)

	main.game_loop_manager = GameLoopManagerScript.new()
	main.game_loop_manager.setup(main)

	main.input_controller = InputControllerScript.new()
	main.input_controller.setup(main)

	main.debug_runner = DebugRunnerScript.new()
	main.debug_runner.setup(main)

	main.clicktest_runner = ClicktestRunnerScript.new()
	main.clicktest_runner.setup(main)

local Constants = {
	-- Dev / debug flags
	TEST_MAP_ENABLED           = true,
	STRICT_MAP_VALIDATION      = false,
	DEBUG_COMMANDS_ENABLED     = false,
	RUNTIME_AUDIT_ENABLED      = false,
	RUNTIME_AUDIT_INTERVAL     = 5,

	-- Safety
	FALL_RESET_Y               = -100,

	-- Lobby / round lifecycle
	MIN_PLAYERS_TO_START       = 2,
	LOBBY_COUNTDOWN_SECONDS    = 15,
	INTERMISSION_SECONDS       = 10,
	RESULTS_DISPLAY_SECONDS    = 8,
	ROUND_DURATION_SECONDS     = 8 * 60,

	-- Movement
	DEFAULT_WALK_SPEED         = 16,
	THIEF_CROUCH_SPEED         = 8,

	-- Objective
	OBJECTIVE_INTERACT_DISTANCE = 12,
	OBJECTIVE_SOLO_SECONDS     = 18,

	-- Idol / extraction
	THIEF_EXTRACT_HOLD_SECONDS         = 5,
	THIEF_EXTRACT_MOVE_CANCEL_DISTANCE = 1,
	IDOL_INTERACT_DISTANCE             = 10,
	EXTRACT_INTERACT_DISTANCE          = 14,
	EXTRACT_HOLD_DISTANCE              = 10,
	IDOL_CARRIER_SPEED_MULTIPLIER      = 0.75,
	IDOL_CARRIER_REVEAL_INTERVAL       = 1.25,
	IDOL_CARRIER_REVEAL_DURATION       = 1.5,

	-- Cage / rescue
	CAGE_RESCUE_DISTANCE       = 12,
	CAGE_RESCUE_SECONDS        = 4,

	-- Guardian abilities
	GUARDIAN_CATCH_DISTANCE    = 5,
	GUARDIAN_RUSH_DURATION     = 2,
	GUARDIAN_RUSH_COOLDOWN     = 10,
	GUARDIAN_RUSH_SPEED_MULTIPLIER = 1.45,
	GUARDIAN_REVEAL_DURATION   = 4,
	GUARDIAN_REVEAL_COOLDOWN   = 30,
	GUARDIAN_ROAR_RADIUS       = 22,
	GUARDIAN_ROAR_SLOW_DURATION   = 2.5,
	GUARDIAN_ROAR_SLOW_MULTIPLIER = 0.55,
	GUARDIAN_ROAR_COOLDOWN     = 18,

	-- Skill check
	SKILL_CHECK_ENABLED          = true,
	SKILL_CHECK_MIN_INTERVAL     = 4,
	SKILL_CHECK_MAX_INTERVAL     = 8,
	SKILL_CHECK_WINDOW_SECONDS   = 0.75,
	SKILL_CHECK_SUCCESS_BONUS    = 0.035,

	-- Ping / callout
	PING_COOLDOWN_SECONDS      = 3,
	PING_LIFETIME_SECONDS      = 5,
	PING_MAX_DISTANCE          = 120,

	-- AFK
	AFK_ENABLED                = true,
	AFK_LOBBY_SECONDS          = 60,
	AFK_ACTIVE_WARNING_SECONDS = 90,

	-- Sound / feedback
	THIEF_FOOTSTEP_VOLUME_SCALE_CROUCH = 0.25,

	-- Spawn positions (test map / fallback)
	GUARDIAN_SPAWN_POSITION = Vector3.new(0, 1, 0),
	CAGE_SPAWN_POSITION     = Vector3.new(-70, 2, 60),
	THIEF_SPAWN_POSITIONS = {
		Vector3.new(-20, 1, -60),
		Vector3.new(-7, 1, -60),
		Vector3.new(7, 1, -60),
		Vector3.new(20, 1, -60),
	},
	TEST_THIEF_SPAWN_POSITIONS = {
		Vector3.new(-24, 1.5, -75),
		Vector3.new(-8, 1.5, -75),
		Vector3.new(8, 1.5, -75),
		Vector3.new(24, 1.5, -75),
	},
	TEST_GUARDIAN_SPAWN_POSITION = Vector3.new(0, 1.5, 18),
}

return Constants

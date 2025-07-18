/mob
	density = 1
	layer = MOB_LAYER
	animate_movement = 2
	movable_flags = MOVABLE_FLAG_PROXMOVE
	sight = DEFAULT_SIGHT
	blocks_emissive = EMISSIVE_BLOCK_GENERIC
	pass_flags_self = PASSMOB
	var/datum/mind/mind
	var/static/next_mob_id = 0

	/// List of movement speed modifiers applying to this mob
	var/list/movespeed_modification //Lazy list, see mob_movespeed.dm
	/// List of movement speed modifiers ignored by this mob. List -> List (id) -> List (sources)
	var/list/movespeed_mod_immunities //Lazy list, see mob_movespeed.dm
	/// The calculated mob speed slowdown based on the modifiers list
	var/cached_multiplicative_slowdown

	// we never want to hide a turf because it's not lit
	// We can rely on the lighting plane to handle that for us
	see_in_dark = 1e6

	var/stat = 0 //Whether a mob is alive or dead. TODO: Move this to living - Nodrak
	can_be_buckled = TRUE

	var/atom/movable/screen/cells = null
	var/atom/movable/screen/flash = null
	var/atom/movable/screen/blind = null
	var/atom/movable/screen/hands = null
	var/atom/movable/screen/pullin = null
	var/atom/movable/screen/purged = null
	var/atom/movable/screen/internals/internals = null
	var/atom/movable/screen/oxygen = null
	var/atom/movable/screen/paralysis_indicator = null
	var/atom/movable/screen/i_select = null
	var/atom/movable/screen/m_select = null
	var/atom/movable/screen/toxin = null
	var/atom/movable/screen/fire = null
	var/atom/movable/screen/bodytemp = null
	var/atom/movable/screen/healths = null
	var/atom/movable/screen/throw_icon = null
	var/atom/movable/screen/nutrition_icon = null
	var/atom/movable/screen/hydration_icon = null
	var/atom/movable/screen/pressure = null
	var/atom/movable/screen/damageoverlay = null
	var/atom/movable/screen/pain = null
	var/atom/movable/screen/gun/item/item_use_icon = null
	var/atom/movable/screen/gun/radio/radio_use_icon = null
	var/atom/movable/screen/gun/move/gun_move_icon = null
	var/atom/movable/screen/gun/mode/gun_setting_icon = null
	var/atom/movable/screen/gun/unique_action_icon = null
	var/atom/movable/screen/gun/toggle_firing_mode = null
	var/atom/movable/screen/energy/energy_display = null
	var/atom/movable/screen/instability/instability_display = null
	var/atom/movable/screen/up_hint = null

	//spells hud icons - this interacts with add_spell and remove_spell
	var/list/atom/movable/screen/movable/spell_master/spell_masters = null
	var/atom/movable/screen/movable/ability_master/ability_master = null

	/*A bunch of this stuff really needs to go under their own defines instead of being globally attached to mob.
	A variable should only be globally attached to turfs/objects/whatever, when it is in fact needed as such.
	The current method unnecessarily clusters up the variable list, especially for humans (although rearranging won't really clean it up a lot but the difference will be noticable for other mobs).
	I'll make some notes on where certain variable defines should probably go.
	Changing this around would probably require a good look-over the pre-existing code.
	*/
	var/atom/movable/screen/zone_sel/zone_sel = null

	var/use_me = 1 //Allows all mobs to use the me verb by default, will have to manually specify they cannot
	var/damageoverlaytemp = 0
	var/computer_id = null
	var/character_id = 0
	var/obj/machinery/machine = null
	var/height = HEIGHT_NOT_USED
	var/sdisabilities = 0				//Carbon
	var/disabilities = 0				//Carbon
	var/atom/movable/pulling = null
	var/next_move = null
	var/transforming = null				//Carbon
	var/other = 0.0
	var/hand = null
	var/eye_blind = null				//Carbon
	var/eye_blurry = null				//Carbon
	var/ear_deaf = null					//Carbon
	var/ear_damage = null				//Carbon
	var/stuttering = null
	var/slurring = null
	var/brokejaw = null
	var/real_name = null
	var/flavor_text = ""
	var/med_record = ""
	var/sec_record = ""
	var/list/incidents = list()
	var/list/additional_vision_handlers = list()
	var/gen_record = ""
	var/ccia_record = ""
	var/list/ccia_actions = list()
	var/exploit_record = ""
	var/blinded = null
	var/bhunger = 0						//Carbon
	var/ajourn = 0
	var/druggy = 0						//Carbon
	var/confused = 0					//Carbon
	var/antitoxs = null
	var/phoron = null
	var/sleeping = 0					//Carbon
	var/sleeping_msg_debounce = FALSE	//Carbon - Used to show a message once every time someone falls asleep.
	var/recently_slept = 0				//Carbon - Used to avoid falling over after waking up
	var/sleeping_indefinitely = FALSE
	var/sleep_buffer = 0				//Used for indefinite sleeping
	var/resting = 0						//Carbon
	var/lying = 0	// Is the mob lying down?
	var/lying_prev = 0	// Was the mob lying down before?
	var/lying_is_intentional = FALSE	// Is the mob lying down intentionally? (eg. a manouver)
	var/canmove = 1
	//Allows mobs to move through dense areas without restriction. For instance, in space or out of holder objects.
	var/incorporeal_move = INCORPOREAL_DISABLE
	var/lastpuke = 0
	var/unacidable = 0
	var/list/pinned = list()            // List of things pinning this creature to walls (see living_defense.dm)
	var/list/embedded = list()          // Embedded items, since simple mobs don't have organs.
	var/list/languages = list()         // For speaking/listening.
	var/list/speak_emote = list("says") // Verbs used when speaking. Defaults to 'say' if speak_emote is null.
	var/emote_type = 1		// Define emote default type, 1 for seen emotes, 2 for heard emotes
	var/facing_dir = null   // Used for the ancient art of moonwalking.

	var/obj/machinery/hologram/holopad/holo = null

	var/name_archive //For admin things like possession

	var/timeofdeath = 0.0//Living
	var/cpr = FALSE //Whether the mob is performing cpr or not

	var/bodytemperature = 310.055	//98.7 F
	var/old_x = 0
	var/old_y = 0
	var/drowsiness = 0.0//Carbon
	var/charges = 0.0
	var/nutrition = BASE_MAX_NUTRITION * CREW_NUTRITION_SLIGHTLYHUNGRY  //carbon
	var/nutrition_loss = HUNGER_FACTOR //How much hunger is lost per tick. This is modified by species
	var/nutrition_attrition_rate = 1   // A multiplier for how much nutrition this specific mob loses per tick.
	var/max_nutrition = BASE_MAX_NUTRITION

	var/hydration = BASE_MAX_HYDRATION * CREW_HYDRATION_SLIGHTLYTHIRSTY //carbon
	var/hydration_loss = THIRST_FACTOR //How much hunger is lost per tick. This is modified by species
	var/hydration_attrition_rate = 1   // A multiplier for how much hydration this specific mob loses per tick.
	var/max_hydration = BASE_MAX_NUTRITION

	var/overeatduration = 0		// How long this guy is overeating //Carbon
	var/overdrinkduration = 0	// How long this guy is overdrinking //Carbon

	var/paralysis = 0
	var/stunned = 0
	var/weakened = 0
	var/losebreath = 0 //Carbon
	var/shakecamera = 0
	var/a_intent = I_HELP//Living
	var/m_intent = M_WALK //Living
	var/lastKnownIP = null
	var/obj/item/l_hand = null//Living
	var/obj/item/r_hand = null//Living
	var/obj/item/back = null//Human/Monkey
	var/obj/item/tank/internal = null//Human/Monkey
	var/obj/item/storage/s_active = null//Carbon
	var/obj/item/clothing/mask/wear_mask = null//Carbon

	var/list/screens = list()

	var/seer = 0 //for cult//Carbon, probably Human

	var/datum/hud/hud_used = null

	var/list/grabbed_by = list(  )
	var/list/requests = list(  )

	var/list/mapobjs = list()

	var/in_throw_mode = 0

	var/inertia_dir = 0

	var/job = null//Living

	var/const/blindness = 1//Carbon
	var/const/deafness = 2//Carbon
	var/const/muteness = 4//Carbon

	var/can_pull_size = 10              // Maximum w_class the mob can pull.
	var/can_pull_mobs = MOB_PULL_LARGER // Whether or not the mob can pull other mobs.

	var/datum/dna/dna = null//Carbon

	var/mutations = 0 //Carbon -- Doohl
	//see: setup.dm for list of mutations

	var/voice_name = "unidentifiable voice"
	var/accent

	var/faction = "neutral" //Used for checking whether hostile simple animals will attack you, possibly more stuff later
	var/captured = 0 //Functionally, should give the same effect as being buckled_to into a chair when true.

//Generic list for proc holders. Only way I can see to enable certain verbs/procs. Should be modified if needed.
	//var/proc_holder_list[] = list()//Right now unused.
	//Also unlike the spell list, this would only store the object in contents, not an object in itself.

	/* Add this line to whatever stat module you need in order to use the proc holder list.
	Unlike the object spell system, it's also possible to attach verb procs from these objects to right-click menus.
	This requires creating a verb for the object proc holder.

	if (proc_holder_list.len)//Generic list for proc_holder objects.
		for(var/obj/effect/proc_holder/P in proc_holder_list)
			statpanel("[P.panel]","",P)
	*/

//The last mob/living/carbon to push/drag/grab this mob (mostly used by slimes friend recognition)
// This is stored as a weakref because BYOND's harddeleter sucks ass.
	var/datum/weakref/LAssailant

//Wizard mode, but can be used in other modes thanks to the brand new "Give Spell" badmin button
	var/list/spell/spell_list

//List of active diseases

	var/list/viruses = list() // replaces var/datum/disease/virus

//Monkey/infected mode
	var/list/resistances = list()

	mouse_drag_pointer = MOUSE_ACTIVE_POINTER

	var/update_icon = 1 //Set to 1 to trigger update_icon() at the next life() call

	var/status_flags = CANSTUN|CANWEAKEN|CANPARALYSE|CANPUSH	//bitflags defining which status effects can be inflicted (replaces canweaken, canstun, etc)

	var/area/lastarea = null

	var/digitalcamo = 0 // Can they be tracked by the AI?

	var/obj/control_object //Used by admins to possess objects. All mobs should have this var

	//Whether or not mobs can understand other mobtypes. These stay in /mob so that ghosts can hear everything.
	var/universal_speak = 0 // Set to 1 to enable the mob to speak to everyone -- TLE
	var/universal_understand = 0 // Set to 1 to enable the mob to understand everyone, not necessarily speak

	//If set, indicates that the client "belonging" to this (clientless) mob is currently controlling some other mob
	//so don't treat them as being SSD even though their client var is null.
	var/mob/teleop = null

	var/turf/listed_turf = null  	//the current turf being examined in the stat panel
	var/list/item_verbs = list()
	var/list/shouldnt_see = list()	//typecache of objects that this mob shouldn't see in the stat panel. this silliness is needed because of AI alt+click and cult blood runes

	var/list/active_genes=list()
	var/mob_size = MOB_MEDIUM
	/// The icon size width of the mob. Used for langchat resizing.
	var/icon_size = 32

	var/list/progressbars

	var/frozen = FALSE //related to wizard statues, if set to true, life won't process

	gfi_layer_rotation = GFI_ROTATION_DEFDIR
	var/disconnect_time = null//Time of client loss, set by Logout(), for timekeeping

	var/mob_thinks = TRUE

	var/authed = TRUE
	var/player_age = "Requires database"

	///Override for sound_environmentironments. If this is set the user will always hear a specific type of reverb (Instead of the area defined reverb)
	var/sound_environment_override = SOUND_ENVIRONMENT_NONE

	///the icon currently used for the typing indicator's bubble
	var/atom/movable/typing_indicator/typing_indicator
	/// User is thinking in character. Used to revert to thinking state after stop_typing
	var/thinking_IC = FALSE

	/// A assoc lazylist of to_chat notifications, key = string message, value = world time integer
	var/list/message_notifications

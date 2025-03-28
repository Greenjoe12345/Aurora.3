/*############################################
		THIS FILE IS DEPRECATED,
	USE code\game\atom\_atom.dm INSTEAD
############################################*/

/atom/proc/reveal_blood()
	return

/atom/proc/assume_air(datum/gas_mixture/giver)
	return null

/atom/proc/remove_air(amount)
	return null

/atom/proc/return_air()
	if(loc)
		return loc.return_air()

// Returns src and all recursive contents in a list.
/atom/proc/GetAllContents()
	. = list(src)
	var/i = 0
	while(i < length(.))
		var/atom/A = .[++i]
		. += A.contents

// identical to GetAllContents but returns a list of atoms of the type passed in the argument
/atom/proc/get_all_contents_of_type(type)
	var/list/processing_list = list(src)
	. = list()
	while(length(processing_list))
		var/atom/A = processing_list[1]
		processing_list.Cut(1, 2)
		processing_list += A.contents
		if(istype(A, type))
			. += A

// Returns a list of all locations (except the area) the movable is within
/proc/get_nested_locs(atom/movable/atom_on_location, include_turf = FALSE)
	. = list()
	var/atom/location = atom_on_location.loc
	var/turf/our_turf = get_turf(atom_on_location)
	while (location && location != our_turf)
		. += location
		location = location.loc

	if(our_turf && include_turf)
		. += our_turf

// Return flags that should be added to the viewer's sight variable.
// Otherwise return a negative number to indicate that the view should be cancelled.
/atom/proc/check_eye(user as mob)
	if (istype(user, /mob/living/silicon/ai))
		return 0
	return -1

/// Primarily used on machinery, when this returns TRUE, equipment that helps with vision, such as prescription glasses for nearsighted characters, have an effect despite the client eye not being on the mob
/atom/proc/grants_equipment_vision(var/mob/user)
	return

/atom/proc/additional_sight_flags()
	SHOULD_BE_PURE(TRUE)
	return 0

/atom/proc/additional_see_invisible()
	return 0

/atom/proc/on_reagent_change()
	return

/**
 * Called when an `/atom` collides with this atom
 *
 * It's roughly equivalent to `Bumped()` in TG, but it's not sleepable and you have to call parent
 *
 * * bumped_atom - The `/atom` that collided with this atom
 */
/atom/proc/CollidedWith(atom/bumped_atom)
	SHOULD_NOT_SLEEP(TRUE)
	SHOULD_CALL_PARENT(TRUE)

	SEND_SIGNAL(src, COMSIG_ATOM_BUMPED, bumped_atom)

// Convenience proc to see if a container is open for chemistry handling.
// Returns true if open, false if closed.
/atom/proc/is_open_container()
	return atom_flags & ATOM_FLAG_OPEN_CONTAINER

/atom/proc/is_pour_container()
	return atom_flags & ATOM_FLAG_POUR_CONTAINER

/atom/proc/CheckExit()
	return 1

// If you want to use this, the atom must have the MOVABLE_FLAG_PROXMOVE flag and the moving atom must also have the MOVABLE_FLAG_PROXMOVE flag currently to help with lag. -ComicIronic
/atom/proc/HasProximity(atom/movable/AM as mob|obj)
	return

/**
 * React to an EMP of the given severity
 *
 * Default behaviour is to send the [COMSIG_ATOM_PRE_EMP_ACT] and [COMSIG_ATOM_EMP_ACT] signal
 *
 * * severity - The severity of the EMP pulse (how strong it is), defines in `code\__DEFINES\empulse.dm`
 *
 * Returns the protection value
 */
/atom/proc/emp_act(var/severity)
	SHOULD_CALL_PARENT(TRUE)
	SHOULD_NOT_SLEEP(TRUE)

	var/protection = SEND_SIGNAL(src, COMSIG_ATOM_PRE_EMP_ACT, severity)

	SEND_SIGNAL(src, COMSIG_ATOM_EMP_ACT, severity, protection)
	return protection // Pass the protection value collected here upwards

/atom/proc/flash_act(intensity = FLASH_PROTECTION_MODERATE, override_blindness_check = FALSE, affect_silicon = FALSE, ignore_inherent = FALSE, type = /atom/movable/screen/fullscreen/flash, length = 2.5 SECONDS)
	return

/atom/proc/in_contents_of(container) // Can take class or object instance as argument.
	if(ispath(container))
		if(istype(src.loc, container))
			return 1
	else if(src in container)
		return 1
	return


/**
 * Checks if user can use this object. Set use_flags to customize what checks are done
 * Returns 0 (FALSE) if they can use it, a value representing why they can't if not
 * See `code\__DEFINES\misc.dm` for the list of flags and return codes
 *
 * * user - The `mob` to check against, if it can perform said use
 * * use_flags - The flags to modify the check behavior, eg. `USE_ALLOW_NON_ADJACENT`, see `code\__DEFINES\misc.dm` for the list of flags
 * * show_messages - A boolean, to indicate if a feedback message should be shown, about the reason why someone can't use the atom
 */
/atom/proc/use_check(mob/user, use_flags = 0, show_messages = FALSE)
	. = USE_SUCCESS
	if(!(use_flags & USE_ALLOW_NONLIVING) && !isliving(user)) // No message for ghosts.
		return USE_FAIL_NONLIVING

	if(!(use_flags & USE_ALLOW_NON_ADJACENT) && !Adjacent(user))
		if (show_messages)
			to_chat(user, SPAN_NOTICE("You're too far away from [src] to do that."))
		return USE_FAIL_NON_ADJACENT

	if(!(use_flags & USE_ALLOW_DEAD) && user.stat == DEAD)
		if (show_messages)
			to_chat(user, SPAN_NOTICE("How do you expect to do that when you're dead?"))
		return USE_FAIL_DEAD

	if(!(use_flags & USE_ALLOW_INCAPACITATED) && (user.incapacitated()))
		if (show_messages)
			to_chat(user, SPAN_NOTICE("You cannot do that in your current state."))
		return USE_FAIL_INCAPACITATED

	if(!(use_flags & USE_ALLOW_NON_ADV_TOOL_USR) && !user.IsAdvancedToolUser())
		if (show_messages)
			to_chat(user, SPAN_NOTICE("You don't know how to operate [src]."))
		return USE_FAIL_NON_ADV_TOOL_USR

	if((use_flags & USE_DISALLOW_SILICONS) && issilicon(user))
		if (show_messages)
			to_chat(user, SPAN_NOTICE("How do you propose doing that without hands?"))
		return USE_FAIL_IS_SILICON

	if((use_flags & USE_DISALLOW_SPECIALS) && is_mob_special(user))
		if (show_messages)
			to_chat(user, SPAN_NOTICE("Your current mob type prevents you from doing this."))
		return USE_FAIL_IS_MOB_SPECIAL

	if((use_flags & USE_FORCE_SRC_IN_USER) && !(src in user))
		if (show_messages)
			to_chat(user, SPAN_NOTICE("You need to be holding [src] to do that."))
		return USE_FAIL_NOT_IN_USER

/**
 * Checks if a mob can use an atom, message the user if not with an appropriate reason
 *
 * Returns 0 (FALSE) if they can use it, a value representing why they can't if not
 *
 * See `code\__DEFINES\misc.dm` for the list of flags and return codes
 *
 * * user - The `mob` to check against, if it can perform said use
 * * use_flags - The flags to modify the check behavior, eg. `USE_ALLOW_NON_ADJACENT`, see `code\__DEFINES\misc.dm` for the list of flags
 */
/atom/proc/use_check_and_message(mob/user, use_flags = 0)
	. = use_check(user, use_flags, TRUE)

/atom/proc/get_light_and_color(var/atom/origin)
	if(origin)
		color = origin.color
		set_light(origin.light_range, origin.light_power, origin.light_color)

// This function will recurse up the hierarchy containing src, in search of the target. It will stop when it reaches an area, as areas have no loc.
/atom/proc/find_up_hierarchy(var/atom/target)
	var/x = 0 // As a safety, we'll crawl up a maximum of ten layers.
	var/atom/a = src
	while (x < 10)
		x++
		if (isnull(a))
			return 0

		if (a == target) // We found it!
			return 1

		if (istype(a, /area))
			return 0 // Can't recurse any higher than this.

		a = a.loc

	return 0 // If we get here, we must be buried many layers deep in nested containers, which shouldn't happen.

// Recursively searches all atom contents (including the contents' contents and so on).
//
// ARGS:	path - Search atom contents for atoms of this type.
// 			filter_path - If set, contents of atoms not of types in this list are excluded from search.
//
// RETURNS: list of found atoms
/atom/proc/search_contents_for(path,list/filter_path=null)
	var/list/found = list()
	for(var/atom/A in src)
		if(istype(A, path))
			found += A
		if(filter_path)
			var/pass = 0
			for(var/type in filter_path)
				pass |= istype(A, type)
			if(!pass)
				continue
		if(A.contents.len)
			found += A.search_contents_for(path,filter_path)
	return found

// Called to set the atom's dir and used to add behaviour to dir-changes.
/atom/proc/set_dir(new_dir)
	. = new_dir != dir
	var/old_dir = dir
	dir = new_dir

	// Lighting.
	if (.)
		var/datum/light_source/L
		for (var/thing in light_sources)
			L = thing
			if (L.light_angle)
				L.source_atom.update_light()
		GLOB.dir_set_event.raise_event(src, old_dir, dir)

/atom/proc/melt()
	return

/atom/proc/add_hiddenprint(mob/living/M)
	if(isnull(M)) return
	if(!istype(M, /mob)) return
	if(isnull(M.key)) return
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if (!istype(H.dna, /datum/dna))
			return 0
		if (H.gloves)
			if(src.fingerprintslast != H.key)
				src.fingerprintshidden += "\[[time_stamp()]\] (Wearing gloves). Real name: [H.real_name], Key: [H.key]"
				src.fingerprintslast = H.key
			return 0
		if (!( src.fingerprints ))
			if(src.fingerprintslast != H.key)
				src.fingerprintshidden += "\[[time_stamp()]\] Real name: [H.real_name], Key: [H.key]"
				src.fingerprintslast = H.key
			return 1
	else
		if(src.fingerprintslast != M.key)
			src.fingerprintshidden += "\[[time_stamp()]\] Real name: [M.real_name], Key: [M.key]"
			src.fingerprintslast = M.key
	return

/atom/proc/add_fingerprint(mob/living/M, ignoregloves = 0)
	if(isnull(M)) return
	if(!istype(M, /mob)) return
	if(issilicon(M)) return
	if(isnull(M.key)) return
	if (ishuman(M))
		// Add the list if it does not exist.
		if(!fingerprintshidden)
			fingerprintshidden = list()

		// Fibers.
		add_fibers(M)

		// They have no prints.
		if ((M.mutations & mFingerprints))
			if(fingerprintslast != M.key)
				fingerprintshidden += "(Has no fingerprints) Real name: [M.real_name], Key: [M.key]"
				fingerprintslast = M.key
			return 0 //Now, lets get to the dirty work.
		// First, make sure their DNA makes sense.
		var/mob/living/carbon/human/H = M
		if (!istype(H.dna, /datum/dna) || !H.dna.uni_identity || (length(H.dna.uni_identity) != 32))
			if(!istype(H.dna, /datum/dna))
				H.dna = new /datum/dna(null)
				H.dna.real_name = H.real_name
		H.check_dna()

		// Now, deal with gloves.
		if (H.gloves && H.gloves != src)
			if(fingerprintslast != H.key)
				fingerprintshidden += "\[[time_stamp()]\](Wearing gloves). Real name: [H.real_name], Key: [H.key]"
				fingerprintslast = H.key
			H.gloves.add_fingerprint(M)

		// Deal with gloves that pass finger/palm prints.
		if(!ignoregloves)
			if(istype(H.gloves, /obj/item/clothing/gloves) && H.gloves != src)
				var/obj/item/clothing/gloves/G = H.gloves
				if(!prob(G.fingerprint_chance))
					return 0

		// Admin related.
		if(fingerprintslast != H.key)
			fingerprintshidden += "\[[time_stamp()]\]Real name: [H.real_name], Key: [H.key]"
			fingerprintslast = H.key

		// Make the list if it does not exist.
		if(!fingerprints)
			fingerprints = list()

		// Hash it.
		var/full_print = H.get_full_print()

		// Add the fingerprints.
		if(fingerprints[full_print])
			switch(charcount(fingerprints[full_print]))	// Tells us how many stars are in the current prints.

				if(28 to 32)
					if(prob(1))
						fingerprints[full_print] = full_print // You rolled a one buddy.
					else
						fingerprints[full_print] = stars(full_print, rand(0,40)) // 24 to 32.

				if(24 to 27)
					if(prob(3))
						fingerprints[full_print] = full_print // Sucks to be you.
					else
						fingerprints[full_print] = stars(full_print, rand(15, 55)) // 20 to 29.

				if(20 to 23)
					if(prob(5))
						fingerprints[full_print] = full_print // Had a good run didn't ya.
					else
						fingerprints[full_print] = stars(full_print, rand(30, 70)) // 15 to 25.

				if(16 to 19)
					if(prob(5))
						fingerprints[full_print] = full_print // Welp.
					else
						fingerprints[full_print]  = stars(full_print, rand(40, 100)) // 0 to 21.

				if(0 to 15)
					if(prob(5))
						fingerprints[full_print] = stars(full_print, rand(0,50)) // Small chance you can smudge.
					else
						fingerprints[full_print] = full_print

		else
			fingerprints[full_print] = stars(full_print, rand(0, 20)) // Initial touch, not leaving much evidence the first time.


		return 1
	else
		// Smudge up the prints a bit.
		if(fingerprintslast != M.key)
			fingerprintshidden += "\[[time_stamp()]\]Real name: [M.real_name], Key: [M.key]"
			fingerprintslast = M.key

	// Cleaning up.
	if(fingerprints && !fingerprints.len)
		qdel(fingerprints)
	return


/atom/proc/transfer_fingerprints_to(var/atom/A)
	if(!istype(A.fingerprints,/list))
		A.fingerprints = list()

	if(!istype(A.fingerprintshidden,/list))
		A.fingerprintshidden = list()

	if(!istype(fingerprintshidden, /list))
		fingerprintshidden = list()

	if(A.fingerprints && fingerprints)
		A.fingerprints |= fingerprints.Copy() // Detective.

	if(A.fingerprintshidden && fingerprintshidden)
		A.fingerprintshidden |= fingerprintshidden.Copy() // Admin. (A.fingerprintslast = fingerprintslast)


// Returns 1 if made bloody, returns 0 otherwise.
/atom/proc/add_blood(mob/living/carbon/human/M)

	if(atom_flags & ATOM_FLAG_NO_BLOOD)
		return 0

	if(!blood_DNA || !istype(blood_DNA, /list))	// If our list of DNA doesn't exist yet (or isn't a list), initialise it.
		blood_DNA = list()

	was_bloodied = 1
	blood_color = COLOR_HUMAN_BLOOD
	if(istype(M))
		if (!istype(M.dna, /datum/dna))
			M.dna = new /datum/dna(null)
			M.dna.real_name = M.real_name
		M.check_dna()
		if (M.species)
			blood_color = M.get_blood_color()
	. = 1
	return 1

// For any objects that may require additional handling when swabbed, e.g. a beaker may need to provide information about its contents, not just itself.
// Children must return additional_evidence list.
/atom/proc/get_additional_forensics_swab_info()
	SHOULD_CALL_PARENT(TRUE)
	var/list/additional_evidence = list(
		"type" = "",
		"dna" = list(),
		"gsr" = "",
		"sample_type" = "",
		"sample_message" = ""
	)

	return additional_evidence

/atom/proc/add_vomit_floor(var/mob/living/carbon/M, var/toxvomit = 0, var/datum/reagents/inject_reagents)
	if(istype(src, /turf/simulated))
		var/obj/effect/decal/cleanable/vomit/this = new /obj/effect/decal/cleanable/vomit(src)
		if(istype(inject_reagents) && inject_reagents.total_volume)
			inject_reagents.trans_to_obj(this, min(15, inject_reagents.total_volume))
			this.reagents.add_reagent(/singleton/reagent/acid/stomach, 5)

		// Make toxins related vomit look different.
		if(toxvomit)
			this.icon_state = "vomittox_[pick(1,4)]"

/mob/living/proc/handle_additional_vomit_reagents(obj/effect/decal/cleanable/vomit/vomit)
	SHOULD_NOT_SLEEP(TRUE)
	SHOULD_CALL_PARENT(TRUE)

	if(!istype(vomit))
		return

	vomit.reagents.add_reagent(/singleton/reagent/acid/stomach, 5)

/atom/proc/clean_blood()
	SHOULD_CALL_PARENT(TRUE)
	SHOULD_NOT_SLEEP(TRUE)

	if(!simulated)
		return
	fluorescent = 0
	src.germ_level = 0
	if(istype(blood_DNA, /list))
		blood_DNA = null
		return TRUE

/atom/proc/on_rag_wipe(var/obj/item/reagent_containers/glass/rag/R)
	clean_blood()
	R.reagents.splash(src, 1)

/atom/proc/get_global_map_pos()
	if(!islist(GLOB.global_map) || isemptylist(GLOB.global_map)) return
	var/cur_x = null
	var/cur_y = null
	var/list/y_arr = null
	for(cur_x=1,cur_x<=GLOB.global_map.len,cur_x++)
		y_arr = GLOB.global_map[cur_x]
		cur_y = y_arr.Find(src.z)
		if(cur_y)
			break

	if(cur_x && cur_y)
		return list("x"=cur_x,"y"=cur_y)
	else
		return 0

/atom/proc/isinspace()
	if(istype(get_turf(src), /turf/space))
		return 1
	else
		return 0


/**
 * Show a message to all mobs and objects in sight of this one, usually used for visible actions by the `src` mob
 *
 * _Implementations differs, basically this is a shitshow, check the params without assuming the order from this description_
 *
 * * message - The message output to anyone who can see, a string
 * * self_message - A message to show to the `src` mob
 * * blind_message - A message to show to mobs or movable atoms that are in view range but blind
 * * range - The range that is considered for the view evaluation, defaults to `world.view`
 * * show_observers - Boolean, if observers sees the message
 * * intent_message - A message sent via `intent_message()`
 * * intent_range - The range considered for the evaluation of the `intent_message`
 */
/atom/proc/visible_message(message, blind_message, range = world.view, intent_message = null, intent_range = 7)
	SHOULD_NOT_SLEEP(TRUE)

	var/list/hearers = get_hearers_in_view(range, src)

	for(var/atom/movable/AM as anything in hearers)
		if(ismob(AM))
			var/mob/M = AM
			if(M.see_invisible < invisibility)
				M.show_message(blind_message, 2)
				continue
		AM.show_message(message, 1, blind_message, 2)

	if(intent_message)
		intent_message(intent_message, intent_range, hearers) // pass our hearers list through to intent_message so it doesn't have to call get_hearers again

// Show a message to all mobs and objects in earshot of this atom.
// Use for objects performing audible actions.
// "message" is the message output to anyone who can hear.
// "deaf_message" (optional) is what deaf people will see.
// "hearing_distance" (optional) is the range, how many tiles away the message can be heard.
/atom/proc/audible_message(var/message, var/deaf_message, var/hearing_distance, var/intent_message = null, var/intent_range = 7)
	SHOULD_NOT_SLEEP(TRUE)

	if(!hearing_distance)
		hearing_distance = world.view

	var/list/hearers = get_hearers_in_view(hearing_distance, src)

	for(var/atom/movable/AM as anything in hearers)
		AM.show_message(message, 2, deaf_message, 1)

	if(intent_message)
		intent_message(intent_message, intent_range, hearers) // pass our hearers list through to intent_message so it doesn't have to call get_hearers again

/atom/proc/intent_message(var/message, var/range = 7, var/list/hearers = list())
	SHOULD_NOT_SLEEP(TRUE)
	if(air_sound(src))
		if(!hearers.len)
			hearers = get_hearers_in_view(range, src)
		for(var/mob/living/carbon/human/H as anything in GLOB.intent_listener)
			if(!(H in hearers))
				if(src.z == H.z && get_dist(src, H) <= range)
					H.intent_listen(src, message)

/atom/movable/proc/dropInto(var/atom/destination)
	while(istype(destination))
		var/atom/drop_destination = destination.onDropInto(src)
		if(!istype(drop_destination) || drop_destination == destination)
			return forceMove(destination)
		destination = drop_destination
	return forceMove(null)

/atom/proc/onDropInto(var/atom/movable/AM)
	return // If onDropInto returns null, then dropInto will forceMove AM into us.

/atom/movable/onDropInto(var/atom/movable/AM)
	return loc // If onDropInto returns something, then dropInto will attempt to drop AM there.

/**
 * This proc is used by ghost spawners to assign a player to a specific atom
 *
 * It receives the current mob of the player's argument and MUST return the mob the player has been assigned
 *
 * Returns the `/mob` the player was assigned to
 */
/atom/proc/assign_player(mob/user)
	RETURN_TYPE(/mob)
	return

/atom/proc/get_contained_external_atoms()
	. = contents

/atom/proc/dump_contents()
	for(var/thing in get_contained_external_atoms())
		var/atom/movable/AM = thing
		AM.dropInto(loc)
		if(ismob(AM))
			var/mob/M = AM
			if(M.client)
				M.client.eye = M.client.mob
				M.client.perspective = MOB_PERSPECTIVE

/atom/proc/check_add_to_late_firers()
	if(SSticker.current_state == GAME_STATE_PLAYING)
		do_late_fire()
		return
	LAZYADD(SSmisc_late.late_misc_firers, src)

/atom/proc/do_late_fire()
	return

/atom/proc/set_angle(degrees)
	var/matrix/M = matrix()
	M.Turn(degrees)
	// If we aren't 0, make it NN transform.
	if(degrees)
		appearance_flags |= PIXEL_SCALE
	transform = M

/atom/proc/handle_middle_mouse_click(var/mob/user)
	return FALSE

/atom/proc/get_standard_pixel_x()
	return initial(pixel_x)

/atom/proc/get_standard_pixel_y()
	return initial(pixel_y)

/atom/proc/handle_pointed_at(var/mob/pointer)
	return

/atom/proc/create_bullethole(obj/projectile/Proj)
	var/p_x = Proj.p_x + rand(-6, 6)
	var/p_y = Proj.p_y + rand(-6, 6)

	var/bullet_mark_icon_state = "dent"
	var/bullet_mark_dir = SOUTH
	if(Proj.damage_flags & DAMAGE_FLAG_LASER)
		if(Proj.damage >= 20)
			bullet_mark_icon_state = "scorch"
			bullet_mark_dir = pick(GLOB.cardinals) // Pick random scorch design
		else
			bullet_mark_icon_state = "light_scorch"

	var/obj/effect/overlay/bmark/bullet_mark = locate() in src
	if(!bullet_mark)
		bullet_mark = new(src)
		bullet_mark.icon_state = bullet_mark_icon_state
		bullet_mark.set_dir(bullet_mark_dir)
		bullet_mark.pixel_x = p_x
		bullet_mark.pixel_y = p_y
	// we limit to to 2 overlays, so 3 holes, to prevent decals from lagging the game
	else if(length(bullet_mark.overlays) < 2)
		var/image/bullet_overlay = image(bullet_mark.icon, icon_state = bullet_mark_icon_state, dir = bullet_mark_dir, pixel_x = p_x - bullet_mark.pixel_x, pixel_y = p_y - bullet_mark.pixel_y)
		bullet_mark.AddOverlays(bullet_overlay)

/atom/proc/clear_bulletholes()
	for(var/obj/effect/overlay/bmark/bullet_mark in src)
		qdel(bullet_mark)

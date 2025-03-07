/atom/movable/proc/get_mob()
	return

/obj/vehicle/train/get_mob()
	return buckled

/mob/get_mob()
	return src

/proc/mobs_in_view(var/range, var/source)
	. = list()
	for(var/atom/movable/AM in view(range, source))
		if (ismob(AM))
			. += AM
			continue

		if (!AM.can_hold_mob)
			continue

		. += AM.get_mob()

/// Species must be a datum.
/proc/random_hair_style(gender, species = /datum/species/human)
	var/h_style = "Bald"

	var/list/valid_hairstyles = list()
	for(var/hairstyle in GLOB.hair_styles_list)
		var/datum/sprite_accessory/S = GLOB.hair_styles_list[hairstyle]
		if(gender == MALE && S.gender == FEMALE)
			continue
		if(gender == FEMALE && S.gender == MALE)
			continue
		if(!(species in S.species_allowed))
			continue

		valid_hairstyles[hairstyle] = GLOB.hair_styles_list[hairstyle]

	if(valid_hairstyles.len)
		h_style = pick(valid_hairstyles)

	return h_style

/// Species must be a datum type.
/proc/random_facial_hair_style(gender, species = /datum/species/human, organ_status, robolimb_manufacturer)
	var/f_style = "Shaved"

	var/list/valid_facialhairstyles = list()
	for(var/facialhairstyle in GLOB.facial_hair_styles_list)
		var/datum/sprite_accessory/S = GLOB.facial_hair_styles_list[facialhairstyle]
		if(gender == MALE && S.gender == FEMALE)
			continue
		if(gender == FEMALE && S.gender == MALE)
			continue
		if(!(species in S.species_allowed))
			continue
		if(!check_robolimb_appropriate(S, organ_status, robolimb_manufacturer))
			continue

		valid_facialhairstyles[facialhairstyle] = GLOB.facial_hair_styles_list[facialhairstyle]

	if(valid_facialhairstyles.len)
		f_style = pick(valid_facialhairstyles)

		return f_style

/**
 * This proc checks if a sprite_accessory appropriate for a given organ and robolimb. The second argument must be an ORGAN_PREF define.
 * This can easily be made into a more general helper if needed by just turning organ_status into a boolean and feeding an instance into robolimb_manufacturer, maybe.
*/
/proc/check_robolimb_appropriate(datum/sprite_accessory/S, organ_status, robolimb_manufacturer)
	if(S.robotize_type_required)
		if(S.required_organ)
			// Null robotize_type_required means it doesn't matter what prosthetic type we use.
			if(isnull(S.robotize_type_required))
				return TRUE
			if(organ_status == ORGAN_PREF_CYBORG)
				if(length(S.robotize_type_required))
					var/datum/robolimb/R
					if(GLOB.all_robolimbs[robolimb_manufacturer])
						R = GLOB.all_robolimbs[robolimb_manufacturer]
					else
						R = GLOB.basic_robolimb
					if(!(R.company in S.robotize_type_required))
						return FALSE
				else
					// Empty list means we can't have a prosthetic type to use this marking.
					return FALSE
			else if(length(S.robotize_type_required))
				// There's a robotize type required and our limb is not a prosthetic.
				return FALSE
	return TRUE

/proc/sanitize_name(name, species = SPECIES_HUMAN)
	var/datum/species/current_species
	if(species)
		current_species = GLOB.all_species[species]

	return current_species ? current_species.sanitize_name(name) : sanitizeName(name)

/proc/random_name(gender, species = SPECIES_HUMAN)
	SHOULD_NOT_SLEEP(TRUE)

	var/datum/species/current_species
	if(species)
		current_species = GLOB.all_species[species]

	if(!current_species || current_species.name_language == null)
		if(gender==FEMALE)
			return capitalize(pick(GLOB.first_names_female)) + " " + capitalize(pick(GLOB.last_names))
		else
			return capitalize(pick(GLOB.first_names_male)) + " " + capitalize(pick(GLOB.last_names))
	else
		return current_species.get_random_name(gender)

/proc/random_skin_tone()
	switch(pick(60;"caucasian", 15;"afroamerican", 10;"african", 10;"latino", 5;"albino"))
		if("caucasian")		. = -10
		if("afroamerican")	. = -115
		if("african")		. = -165
		if("latino")		. = -55
		if("albino")		. = 34
		else				. = rand(-185,34)
	return min(max( .+rand(-25, 25), -185),34)

/proc/skintone2racedescription(tone)
	switch (tone)
		if(30 to INFINITY)		return "albino"
		if(20 to 30)			return "pale"
		if(5 to 15)				return "light skinned"
		if(-10 to 5)			return "white"
		if(-25 to -10)			return "tan"
		if(-45 to -25)			return "darker skinned"
		if(-65 to -45)			return "brown"
		if(-INFINITY to -65)	return "black"
		else					return "unknown"

/proc/age2agedescription(age)
	switch(age)
		if(0 to 1)			return "infant"
		if(1 to 3)			return "toddler"
		if(3 to 13)			return "child"
		if(13 to 19)		return "teenager"
		if(19 to 30)		return "young adult"
		if(30 to 45)		return "adult"
		if(45 to 60)		return "middle-aged"
		if(60 to 70)		return "aging"
		if(70 to INFINITY)	return "elderly"
		else				return "unknown"

/proc/RoundHealth(health)
	switch(health)
		if(100 to INFINITY)
			return "health100"
		if(90 to 100)
			return "health95"
		if(70 to 90)
			return "health80"
		if(50 to 70)
			return "health60"
		if(30 to 50)
			return "health40"
		if(18 to 30)
			return "health25"
		if(5 to 18)
			return "health10"
		if(1 to 5)
			return "health1"
		if(-99 to 0)
			return "health0"
		else
			return "health-100"

/*
Proc for attack log creation, because really why not
1 argument is the actor
2 argument is the target of action
3 is the description of action(like punched, throwed, or any other verb)
4 should it make adminlog note or not
5 is the tool with which the action was made(usually item)					5 and 6 are very similar(5 have "by " before it, that it) and are separated just to keep things in a bit more in order
6 is additional information, anything that needs to be added
*/

/proc/add_logs(mob/user, mob/target, what_done, var/admin=1, var/object=null, var/addition=null)
	if(user && ismob(user))
		user.attack_log += "\[[time_stamp()]\] <span class='warning'>Has [what_done] [target ? "[target.name][(ismob(target) && target.ckey) ? "([target.ckey])" : ""]" : "NON-EXISTANT SUBJECT"][object ? " with [object]" : " "][addition]</span>"
	if(target && ismob(target))
		target.attack_log += "\[[time_stamp()]\] <font color='orange'>Has been [what_done] by [user ? "[user.name][(ismob(user) && user.ckey) ? "([user.ckey])" : ""]" : "NON-EXISTANT SUBJECT"][object ? " with [object]" : " "][addition]</font>"
	if(admin)
		log_attack(SPAN_WARNING("[user ? "[user.name][(ismob(user) && user.ckey) ? "([user.ckey])" : ""]" : "NON-EXISTANT SUBJECT"] [what_done] [target ? "[target.name][(ismob(target) && target.ckey)? "([target.ckey])" : ""]" : "NON-EXISTANT SUBJECT"][object ? " with [object]" : " "][addition]"))

//checks whether this item is a module of the robot or exosuit it is located in. This is mainly to ensure that things do not get embedded or fed into autolathes if attached to a bot or exosuit
/proc/is_robot_module(var/obj/item/thing)
	if(!thing)
		return FALSE
	if(istype(thing.loc, /mob/living/heavy_vehicle))
		return TRUE
	if(istype(thing.loc, /mob/living/silicon/robot))
		var/mob/living/silicon/robot/R = thing.loc
		return (thing in R.module.modules)

/proc/get_exposed_defense_zone(var/atom/movable/target)
	var/obj/item/grab/G = locate() in target
	if(G && G.state >= GRAB_NECK) //works because mobs are currently not allowed to upgrade to NECK if they are grabbing two people.
		return pick(BP_HEAD, BP_L_HAND, BP_R_HAND, BP_L_FOOT, BP_R_FOOT, BP_L_ARM, BP_R_ARM, BP_L_LEG, BP_R_LEG)
	else
		return pick(BP_CHEST, BP_GROIN)


// Returns true if M was not already in the dead mob list
/mob/proc/switch_from_living_to_dead_mob_list()
	remove_from_living_mob_list()
	. = add_to_dead_mob_list()

// Returns true if M was not already in the living mob list
/mob/proc/switch_from_dead_to_living_mob_list()
	remove_from_dead_mob_list()
	. = add_to_living_mob_list()

// Returns true if the mob was in neither the dead or living list
/mob/proc/add_to_living_mob_list()
	return FALSE
/mob/living/add_to_living_mob_list()
	if((src in GLOB.living_mob_list) || (src in GLOB.dead_mob_list))
		return FALSE
	GLOB.living_mob_list += src
	return TRUE

// Returns true if the mob was removed from the living list
/mob/proc/remove_from_living_mob_list()
	return GLOB.living_mob_list.Remove(src)

// Returns true if the mob was in neither the dead or living list
/mob/proc/add_to_dead_mob_list()
	return FALSE

/mob/living/add_to_dead_mob_list()
	if((src in GLOB.living_mob_list) || (src in GLOB.dead_mob_list))
		return FALSE
	GLOB.dead_mob_list += src
	GLOB.death_event.raise_event(src)
	return TRUE

// Returns true if the mob was removed form the dead list
/mob/proc/remove_from_dead_mob_list()
	return GLOB.dead_mob_list.Remove(src)

// This will update a mob's name, real_name, mind.name, SSrecords records, pda and id
// Calling this proc without an oldname will only update the mob and skip updating the pda, id and records
/mob/proc/fully_replace_character_name(var/oldname,var/newname)
	if(!newname)	return 0
	real_name = newname
	name = newname
	if(mind)
		mind.name = newname
	if(dna)
		dna.real_name = real_name

	if(oldname)
		//update the datacore records! This is goig to be a bit costly.
		for(var/datum/record/general/R in list(SSrecords.records, SSrecords.records_locked))
			if(R.name == oldname)
				R.name = newname
				break

		//update our pda and id if we have them on our person
		var/list/searching = GetAllContents()
		var/search_id = TRUE
		var/search_pda = TRUE

		for(var/A in searching)
			if(search_id && istype(A, /obj/item/card/id) )
				var/obj/item/card/id/ID = A
				if(ID.registered_name == oldname)
					ID.registered_name = newname
					ID.name = "[newname]'s ID Card ([ID.assignment])"
					search_id = FALSE

					if(!search_pda)
						break

			else if(search_pda && istype(A, /obj/item/modular_computer))
				var/obj/item/modular_computer/PDA = A
				if(!PDA.registered_id)
					continue

				if(PDA.registered_id.registered_name == oldname)
					PDA.name = "PDA-[newname] ([PDA.registered_id.assignment])"
					search_pda = FALSE

					if(!search_id)
						break

	return TRUE

// Generalised helper proc for letting mobs rename themselves
/mob/proc/rename_self(var/role, var/allow_numbers=0)
	set waitfor = FALSE
	var/oldname = real_name

	var/time_passed = world.time
	var/newname

	for(var/i=1,i<=3,i++)	//we get 3 attempts to pick a suitable name.
		newname = input(src,"You are \a [role]. Would you like to change your name to something else?", "Name change",oldname) as text
		if((world.time-time_passed)>3000)
			return	//took too long
		newname = sanitizeName(newname, ,allow_numbers)	//returns null if the name doesn't meet some basic requirements. Tidies up a few other things like bad-characters.

		for(var/mob/living/M in GLOB.player_list)
			if(M == src)
				continue
			if(!newname || M.real_name == newname)
				newname = null
				break
		if(newname)
			break	//That's a suitable name!
		to_chat(src, "Sorry, that [role]-name wasn't appropriate, please try another. It's possibly too long/short, has bad characters or is already taken.")

	if(!newname)	//we'll stick with the oldname then
		return

	if(cmptext("ai",role))
		if(isAI(src))
			var/mob/living/silicon/ai/A = src
			oldname = null//don't bother with the records update crap
			// Set eyeobj name
			A.SetName(newname)

	fully_replace_character_name(oldname,newname)

///Makes a call in the context of a different usr. Use sparingly
/world/proc/push_usr(mob/user_mob, datum/callback/invoked_callback, ...)
	var/temp = usr
	usr = user_mob
	if (length(args) > 2)
		. = invoked_callback.Invoke(arglist(args.Copy(3)))
	else
		. = invoked_callback.Invoke()
	usr = temp

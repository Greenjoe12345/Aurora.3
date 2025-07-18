
/*
 *
 *  Mob Unit Tests.
 *
 *  Human suffocation in Space.
 *  Mob damage Template
 *
 */

#define SUCCESS 1
#define FAILURE 0

//
// Tests Life() and mob breathing in space.
//

/mob/living/test
	var/heard = FALSE

/mob/living/test/on_hear_say(var/message)
	. = ..(message)
	if(message)
		heard = TRUE
	return .

/datum/unit_test/mob_hear
	name = "MOB: Living mobs test for mob's speech"
	groups = list("mob")

	var/mob_type = /mob/living/test


/datum/unit_test/mob_hear/start_test()
	var/mobloc = pick(GLOB.tdome1)
	if(!mobloc)
		TEST_FAIL("Unable to find a location to create test mob")
		return 0
	for(var/mob/M in get_turf(mobloc))
		QDEL_NULL(M)
	var/list/test_speaker = create_test_mob_with_mind(mobloc, mob_type, TRUE)
	var/list/test_listener = create_test_mob_with_mind(mobloc, mob_type, TRUE)

	if(isnull(test_speaker) || isnull(test_listener))
		TEST_FAIL("Check Runtimed in Mob creation")
		return 0

	if(test_speaker["result"] == FAILURE )
		TEST_FAIL(test_speaker["msg"])
		return 0
	else if(test_listener ["result"] == FAILURE)
		TEST_FAIL(test_listener["msg"])
		return 0

	var/mob/living/test/test_speaker_mob = locate(test_speaker["mobref"])
	var/mob/living/test/test_listener_mob = locate(test_listener["mobref"])

	if(isnull(test_speaker_mob) || isnull(test_listener_mob))
		TEST_FAIL("Test unable to set test mob from reference")
		return 0

	if(test_speaker_mob.stat)
		TEST_FAIL("Test needs to be re-written, mob has a stat = [test_speaker_mob.stat]")
		return 0
	else if(test_listener_mob.stat)
		TEST_FAIL("Test needs to be re-written, mob has a stat = [test_speaker_mob.stat]")
		return 0

	if(test_speaker_mob.sleeping || test_listener_mob.sleeping)
		TEST_FAIL("Test needs to be re-written, mob is sleeping for some unknown reason")
		return 0

	var/message = "Test, can you hear me?"
	var/said = test_speaker_mob.say(message)

	if(said && test_listener_mob.heard)
		TEST_PASS("speech test complete, speaker said \"[message]\" and listener received it.")
		return 1
	else if(said)
		TEST_FAIL("speaker said the words, but listener did not hear it. The message was \"[message]\", the difference were X: [test_listener_mob.loc.x - test_speaker_mob.loc.x], Y: [test_listener_mob.loc.y - test_speaker_mob.loc.y]")
		return 0
	else
		TEST_FAIL("speaker did not say the words \"[message]\"")
		return 0

/datum/unit_test/human_breath
	name = "MOB: Human Suffocates in Space"
	groups = list("mob")

	var/starting_oxyloss = null
	var/ending_oxyloss = null
	var/mob/living/carbon/human/H
	async = 1


/datum/unit_test/human_breath/start_test()
	var/turf/T = locate(20,20,1) //TODO:  Find better way.

	if(!istype(T, /turf/space))	//If the above isn't a space turf then we force it to find one will most likely pick 1,1,1
		T = locate(/turf/space)

	H = new(T)

	starting_oxyloss = damage_check(H, DAMAGE_OXY)

	return 1

/datum/unit_test/human_breath/check_result()

	if(H.life_tick < 10) 	// Finish Condition
		return 0	// Return 0 to try again later.

	ending_oxyloss = damage_check(H, DAMAGE_OXY)

	if(starting_oxyloss < ending_oxyloss)
		TEST_PASS("Oxyloss = [ending_oxyloss]")
	else
		TEST_FAIL("Mob is not taking oxygen damage.  Damange is [ending_oxyloss]")

	return 1	// return 1 to show we're done and don't want to recheck the result.

// ============================================================================

/proc/create_test_mob_with_mind(var/turf/mobloc = null, var/mobtype = /mob/living/carbon/human, var/add_to_playerlist = FALSE)
	var/list/test_result = list("result" = FAILURE, "msg"    = "", "mobref" = null)

	if(isnull(mobloc))
		mobloc = pick(GLOB.tdome1)
	if(!mobloc)
		test_result["msg"] = "Unable to find a location to create test mob"
		return test_result

	var/mob/living/L = new mobtype(mobloc)

	L.mind_initialize("TestKey[rand(0,10000)]")

	test_result["result"] = SUCCESS
	test_result["msg"] = "Mob created"
	test_result["mobref"] = "[REF(L)]"

	if(add_to_playerlist)
		GLOB.player_list |= L
		testing("Adding test subject to the player list")
		world << "Adding test subject to the player list"

	return test_result

//Generic Check
// TODO: Need to make sure I didn't just recreate the wheel here.

/proc/damage_check(var/mob/living/M, var/damage_type)
	var/loss = null

	switch(damage_type)
		if(DAMAGE_BRUTE)
			loss = M.getBruteLoss()
		if(DAMAGE_BURN)
			loss = M.getFireLoss()
		if(DAMAGE_TOXIN)
			loss = M.getToxLoss()
		if(DAMAGE_OXY)
			loss = M.getOxyLoss()
			if(istype(M,/mob/living/carbon/human))
				var/mob/living/carbon/human/H = M
				var/obj/item/organ/internal/lungs/L = H.internal_organs_by_name["lungs"]
				if(L)
					loss = L.oxygen_deprivation
		if(DAMAGE_CLONE)
			loss = M.getCloneLoss()
		if(DAMAGE_PAIN)
			loss = M.getHalLoss()

	if(!loss && istype(M, /mob/living/carbon/human))          // Revert IPC's when?
		var/mob/living/carbon/human/H = M                 // IPC's have robot limbs which don't report damage to getXXXLoss()
		if(istype(H.species, /datum/species/machine))     // So we have ot hard code this check or create a different one for them.
			return H.species.total_health - H.health                     // TODO: Find better way to do this then hardcoding this formula

	return loss

// ==============================================================================================================

//
//DAMAGE EXPECTATIONS
// used with expectected_vunerability

#define STANDARD 0            // Will take standard damage (damage_ratio of 1)
#define ARMORED 1             // Will take less damage than applied
#define EXTRA_VULNERABLE 2    // Will take more dmage than applied
#define IMMUNE 3              // Will take no damage

//==============================================================================================================


/datum/unit_test/mob_damage
	name = "MOB: Template for mob damage"
	groups = list("mob")

	var/mob/living/carbon/human/testmob = null
	var/damagetype = DAMAGE_BRUTE
	var/mob_type = /mob/living/carbon/human
	var/expected_vulnerability = STANDARD
	var/check_health = 0
	var/damage_location = BP_CHEST

/datum/unit_test/mob_damage/start_test()
	var/list/test = create_test_mob_with_mind(null, mob_type)
	var/damage_amount = 5	// Do not raise, if damage >= 10 there is a % chance to reduce damage by half in /obj/item/organ/external/take_damage(), which makes checks impossible.

	if(isnull(test))
		TEST_FAIL("Check Runtimed in Mob creation")
		return 0

	if(test["result"] == FAILURE)
		TEST_FAIL(test["msg"])
		return 0

	var/mob/living/carbon/human/H = locate(test["mobref"])

	if(isnull(H))
		TEST_FAIL("Test unable to set test mob from reference")
		return 0

	if(H.stat)

		TEST_FAIL("Test needs to be re-written, mob has a stat = [H.stat]")
		return 0

	if(H.sleeping)
		TEST_FAIL("Test needs to be re-written, mob is sleeping for some unknown reason")
		return 0

	// Damage the mob

	var/initial_health = H.health

	H.apply_damage(damage_amount, damagetype, damage_location)

	H.updatehealth() // Just in case, though at this time apply_damage does this for us. We operate with the assumption that someone might mess with that proc one day.

	var/ending_damage = damage_check(H, damagetype)

	var/ending_health = H.health

	// Now test this stuff.

	var/failure = 0

	var/damage_ratio = STANDARD

	if (ending_damage == 0)
		damage_ratio = IMMUNE

	else if (ending_damage < damage_amount)
		damage_ratio = ARMORED

	else if (ending_damage > damage_amount)
		damage_ratio = EXTRA_VULNERABLE

	if(damage_ratio != expected_vulnerability)
		failure = 1

	// Now generate the message for this test.

	var/expected_msg = null

	switch(expected_vulnerability)
		if(STANDARD)
			expected_msg = "to take standard damage"
		if(ARMORED)
			expected_msg = "To take less damage"
		if(EXTRA_VULNERABLE)
			expected_msg = "To take extra damage"
		if(IMMUNE)
			expected_msg = "To take no damage"


	var/msg = "Damage taken: [ending_damage] out of [damage_amount] || expected: [expected_msg] \[Overall Health:[ending_health] (Initial: [initial_health])\]"

	if(failure)
		TEST_FAIL(msg)
	else
		TEST_PASS(msg)

	return 1

// =================================================================
// Human damage check.
// =================================================================

/datum/unit_test/mob_damage/brute
	name = "MOB: Human Brute damage check"
	damagetype = DAMAGE_BRUTE

/datum/unit_test/mob_damage/fire
	name = "MOB: Human Fire damage check"
	damagetype = DAMAGE_BURN

/datum/unit_test/mob_damage/tox
	name = "MOB: Human Toxin damage check"
	damagetype = DAMAGE_TOXIN

/datum/unit_test/mob_damage/oxy
	name = "MOB: Human Oxygen damage check"
	damagetype = DAMAGE_OXY

/datum/unit_test/mob_damage/clone
	name = "MOB: Human Clone damage check"
	damagetype = DAMAGE_CLONE

/datum/unit_test/mob_damage/halloss
	name = "MOB: Human Halloss damage check"
	damagetype = DAMAGE_PAIN

// =================================================================
// Unathi
// =================================================================

/datum/unit_test/mob_damage/unathi
	name = "MOB: Unathi damage check template"
	mob_type = /mob/living/carbon/human/unathi

/datum/unit_test/mob_damage/unathi/brute
	name = "MOB: Unathi Brute Damage Check"
	damagetype = DAMAGE_BRUTE
	expected_vulnerability = ARMORED

/datum/unit_test/mob_damage/unathi/fire
	name = "MOB: Unathi Fire Damage Check"
	damagetype = DAMAGE_BURN

/datum/unit_test/mob_damage/unathi/tox
	name = "MOB: Unathi Toxins Damage Check"
	damagetype = DAMAGE_TOXIN

/datum/unit_test/mob_damage/unathi/oxy
	name = "MOB: Unathi Oxygen Damage Check"
	damagetype = DAMAGE_OXY

/datum/unit_test/mob_damage/unathi/clone
	name = "MOB: Unathi Clone Damage Check"
	damagetype = DAMAGE_CLONE

/datum/unit_test/mob_damage/unathi/halloss
	name = "MOB: Unathi Halloss Damage Check"
	damagetype = DAMAGE_PAIN

// =================================================================
// SpessKahjit aka Tajaran
// =================================================================

/datum/unit_test/mob_damage/tajaran
	name = "MOB: Tajaran damage check template"
	mob_type = /mob/living/carbon/human/tajaran

/datum/unit_test/mob_damage/tajaran/brute
	name = "MOB: Tajaran Brute Damage Check"
	damagetype = DAMAGE_BRUTE
	expected_vulnerability = EXTRA_VULNERABLE

/datum/unit_test/mob_damage/tajaran/fire
	name = "MOB: Tajaran Fire Damage Check"
	damagetype = DAMAGE_BURN

/datum/unit_test/mob_damage/tajaran/tox
	name = "MOB: Tajaran Toxins Damage Check"
	damagetype = DAMAGE_TOXIN

/datum/unit_test/mob_damage/tajaran/oxy
	name = "MOB: Tajaran Oxygen Damage Check"
	damagetype = DAMAGE_OXY

/datum/unit_test/mob_damage/tajaran/clone
	name = "MOB: Tajaran Clone Damage Check"
	damagetype = DAMAGE_CLONE

/datum/unit_test/mob_damage/tajaran/halloss
	name = "MOB: Tajaran Halloss Damage Check"
	damagetype = DAMAGE_PAIN

// =================================================================
// Skrell
// =================================================================

/datum/unit_test/mob_damage/skrell
	name = "MOB: Skrell damage check template"
	mob_type = /mob/living/carbon/human/skrell

/datum/unit_test/mob_damage/skrell/brute
	name = "MOB: Skrell Brute Damage Check"
	damagetype = DAMAGE_BRUTE

/datum/unit_test/mob_damage/skrell/fire
	name = "MOB: Skrell Fire Damage Check"
	damagetype = DAMAGE_BURN

/datum/unit_test/mob_damage/skrell/tox
	name = "MOB: Skrell Toxins Damage Check"
	damagetype = DAMAGE_TOXIN

/datum/unit_test/mob_damage/skrell/oxy
	name = "MOB: Skrell Oxygen Damage Check"
	damagetype = DAMAGE_OXY

/datum/unit_test/mob_damage/skrell/clone
	name = "MOB: Skrell Clone Damage Check"
	damagetype = DAMAGE_CLONE

/datum/unit_test/mob_damage/skrell/halloss
	name = "MOB: Skrell Halloss Damage Check"
	damagetype = DAMAGE_PAIN

// =================================================================
// Diona
// =================================================================

/datum/unit_test/mob_damage/diona
	name = "MOB: Diona damage check template"
	mob_type = /mob/living/carbon/human/diona

/datum/unit_test/mob_damage/diona/brute
	name = "MOB: Diona Brute Damage Check"
	damagetype = DAMAGE_BRUTE
	expected_vulnerability = ARMORED

/datum/unit_test/mob_damage/diona/fire
	name = "MOB: Diona Fire Damage Check"
	damagetype = DAMAGE_BURN

/datum/unit_test/mob_damage/diona/tox
	name = "MOB: Diona Toxins Damage Check"
	damagetype = DAMAGE_TOXIN

/datum/unit_test/mob_damage/diona/oxy
	name = "MOB: Diona Oxygen Damage Check"
	damagetype = DAMAGE_OXY
	expected_vulnerability = IMMUNE

/datum/unit_test/mob_damage/diona/clone
	name = "MOB: Diona Clone Damage Check"
	damagetype = DAMAGE_CLONE
	expected_vulnerability = IMMUNE

/datum/unit_test/mob_damage/diona/halloss
	name = "MOB: Diona Halloss Damage Check"
	damagetype = DAMAGE_PAIN
	expected_vulnerability = ARMORED

// =================================================================
// SPECIAL WHITTLE SNOWFLAKES aka IPC
// =================================================================

/datum/unit_test/mob_damage/machine
	name = "MOB: IPC damage check template"
	mob_type = /mob/living/carbon/human/machine

/datum/unit_test/mob_damage/machine/brute
	name = "MOB: IPC Brute Damage Check"
	damagetype = DAMAGE_BRUTE
	expected_vulnerability = ARMORED

/datum/unit_test/mob_damage/machine/fire
	name = "MOB: IPC Fire Damage Check"
	damagetype = DAMAGE_BURN
	expected_vulnerability = EXTRA_VULNERABLE

/datum/unit_test/mob_damage/machine/tox
	name = "MOB: IPC Toxins Damage Check"
	damagetype = DAMAGE_TOXIN
	expected_vulnerability = IMMUNE

/datum/unit_test/mob_damage/machine/oxy
	name = "MOB: IPC Oxygen Damage Check"
	damagetype = DAMAGE_OXY
	expected_vulnerability = IMMUNE

/datum/unit_test/mob_damage/machine/clone
	name = "MOB: IPC Clone Damage Check"
	damagetype = DAMAGE_CLONE
	expected_vulnerability = IMMUNE

/datum/unit_test/mob_damage/machine/halloss
	name = "MOB: IPC Halloss Damage Check"
	damagetype = DAMAGE_PAIN
	expected_vulnerability = IMMUNE

// =================================================================
// Vaurca Worker
// =================================================================

/datum/unit_test/mob_damage/vaurca
	name = "MOB: Vaurca damage check template"
	mob_type = /mob/living/carbon/human/type_a

/datum/unit_test/mob_damage/vaurca/brute
	name = "MOB: Vaurca Brute Damage Check"
	damagetype = DAMAGE_BRUTE
	expected_vulnerability = ARMORED

/datum/unit_test/mob_damage/vaurca/fire
	name = "MOB: Vaurca Fire Damage Check"
	damagetype = DAMAGE_BURN
	expected_vulnerability = EXTRA_VULNERABLE

/datum/unit_test/mob_damage/vaurca/tox
	name = "MOB: Vaurca Toxins Damage Check"
	damagetype = DAMAGE_TOXIN
	expected_vulnerability = EXTRA_VULNERABLE

/datum/unit_test/mob_damage/vaurca/oxy
	name = "MOB: Vaurca Oxygen Damage Check"
	damagetype = DAMAGE_OXY
	expected_vulnerability = ARMORED

/datum/unit_test/mob_damage/vaurca/clone
	name = "MOB: Vaurca Clone Damage Check"
	damagetype = DAMAGE_CLONE

/datum/unit_test/mob_damage/vaurca/halloss
	name = "MOB: Vaurca Halloss Damage Check"
	damagetype = DAMAGE_PAIN

// ==============================================================================


/datum/unit_test/robot_module_icons
	name = "MOB: Robot module icon check"
	groups = list("mob")

	var/icon_file = 'icons/mob/screen/robot.dmi'

/datum/unit_test/robot_module_icons/start_test()
	var/failed = 0
	if(!isicon(icon_file))
		TEST_FAIL("[icon_file] is not a valid icon file.")
		return 1

	var/list/valid_states = icon_states(icon_file)

	if(!valid_states.len)
		return 1

	for(var/i=1, i<=GLOB.robot_modules.len, i++)
		var/bad_msg = "--------------- [GLOB.robot_modules[i]]"
		if(!(lowertext(GLOB.robot_modules[i]) in valid_states))
			TEST_FAIL(TEST_OUTPUT_RED(("[bad_msg] does not contain a valid icon state in [icon_file]")))
			failed=1

	if(failed)
		TEST_FAIL("Some icon states did not exist")
	else
		TEST_PASS("All modules had valid icon states")

	return 1

#undef IMMUNE
#undef SUCCESS
#undef FAILURE

// Originally a debug verb, made it a proper adminverb for ~fun~
/client/proc/makePAI()
	set name = "Make pAI"
	set category = "Admin"

	if(!check_rights(R_ADMIN))
		return

	if (!mob)
		return

	var/turf/t = get_turf(mob)
	var/pai_key
	var/name = input(mob, "", "What will the pAI's name be?") as text|null
	if (!name)
		return

	if(!pai_key)
		var/client/C = input("Select client") as null|anything in GLOB.clients
		if(!C) return
		pai_key = C.key

	log_and_message_admins("made a pAI with key=[pai_key] at ([t.x],[t.y],[t.z])")
	var/obj/item/device/paicard/card = new(t)
	var/mob/living/silicon/pai/pai = new(card)
	pai.key = pai_key
	card.setPersonality(pai)
	if(pai.mind)
		pai.mind.current.client.init_verbs()

	if(name)
		pai.SetName(name)

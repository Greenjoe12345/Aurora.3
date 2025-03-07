/mob/var/mob/lastattacker = null
/mob/var/mob/lastattacked = null
/mob/var/attack_log = list()

/proc/log_and_message_admins(var/message as text, var/mob/user = usr, var/turf/location)
	var/turf/T = location ? location : (user ? get_turf(user) : null)
	if(T)
		message = message + " (<a href='byond://?_src_=holder;adminplayerobservecoodjump=1;X=[T.x];Y=[T.y];Z=[T.z]'>JMP</a>)"

	log_admin(user ? "[key_name(user)] [message]" : "EVENT [message]")
	message_admins(user ? "[key_name_admin(user)] [message]" : "EVENT [message]")

/proc/log_and_message_admins_many(var/list/mob/users, var/message)
	if(!users || !users.len)
		return

	var/list/user_keys = list()
	for(var/mob/user in users)
		user_keys += key_name(user)

	log_admin("[english_list(user_keys)] [message]")
	message_admins("[english_list(user_keys)] [message]")

/proc/admin_attack_log(var/mob/attacker, var/mob/victim, var/attacker_message, var/victim_message, var/admin_message)
	var/jmp_link = ""
	if(victim)
		victim.attack_log +="\[[time_stamp()]\] <font color='orange'>[key_name(attacker)] - [victim_message]</font>"
		jmp_link = " (<A href='byond://?_src_=holder;adminplayerobservecoodjump=1;X=[victim.x];Y=[victim.y];Z=[victim.z]'>JMP</a>)"
	if(attacker)
		attacker.attack_log += "\[[time_stamp()]\] <span class='warning'>[key_name(victim)] - [attacker_message]</span>"
		jmp_link = " (<A href='byond://?_src_=holder;adminplayerobservecoodjump=1;X=[attacker.x];Y=[attacker.y];Z=[attacker.z]'>JMP</a>)"

	msg_admin_attack("[attacker ? key_name_admin(attacker) : ""] [admin_message] [victim ? key_name_admin(victim) : ""] (INTENT: [attacker? uppertext(attacker.a_intent) : "N/A"])[jmp_link]",ckey=key_name(attacker),ckey_target=key_name(victim))

/proc/admin_attacker_log_many_victims(var/mob/attacker, var/list/mob/victims, var/attacker_message, var/victim_message, var/admin_message)
	if(!victims || !victims.len)
		return

	for(var/mob/victim in victims)
		admin_attack_log(attacker, victim, attacker_message, victim_message, admin_message)

/proc/admin_inject_log(mob/attacker, mob/victim, obj/item/I, reagents, temperature, amount_transferred, violent=0)
	if(violent)
		violent = "violently "
	else
		violent = ""

	var/temperature_text = "([temperature - (T0C + 20)]C)"
	admin_attack_log(
						attacker,
						victim,
						"used \the [I] to [violent]inject - [reagents] [temperature_text] - [amount_transferred]u transferred",
						"was [violent]injected with \the [I] - [reagents] [temperature_text] - [amount_transferred]u transferred",
						"used \the [I] to [violent]inject [reagents] [temperature_text] ([amount_transferred]u transferred) into"
					)

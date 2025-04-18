/*
	Monitoring computer for the messaging server.
	Lets you read request console messages.
*/

// The monitor itself.
/obj/machinery/computer/message_monitor
	name = "messaging monitor console"
	desc = "Used to access and maintain data on messaging servers. Allows you to view requests console messages."
	icon_screen = "comm_logs"
	icon_keyboard = "green_key"
	icon_keyboard_emis = "green_key_mask"
	light_color = LIGHT_COLOR_GREEN
	var/hack_icon = "error"
	circuit = /obj/item/circuitboard/message_monitor
	//Server linked to.
	var/obj/machinery/telecomms/message_server/linkedServer = null
	//Sparks effect - For emag
	var/datum/effect_system/sparks/spark_system
	//Messages - Saves me time if I want to change something.
	var/noserver = SPAN_ALERT("ALERT: No server detected.")
	var/incorrectkey = SPAN_WARNING("ALERT: Incorrect decryption key!")
	var/defaultmsg = SPAN_NOTICE("Welcome. Please select an option.")
	var/rebootmsg = SPAN_WARNING("%$&(£: Critical %$$@ Error // !RestArting! <lOadiNg backUp iNput ouTput> - ?pLeaSe wAit!")
	//Computer properties
	var/screen = 0 		// 0 = Main menu, 1 = Message Logs, 2 = Hacked screen, 3 = Custom Message
	var/hacking = 0		// Is it being hacked into by the AI/Cyborg
	var/emag = 0		// When it is emagged.
	var/message = SPAN_NOTICE("System bootup complete. Please select an option.")	// The message that shows on the main menu.
	var/auth = 0 // Are they authenticated?
	var/optioncount = 8
	// Custom Message Properties
	var/customsender = "System Administrator"
	var/customjob		= "Admin"
	var/custommessage 	= "This is a test, please ignore."

/obj/machinery/computer/message_monitor/Initialize()
	..()
	spark_system = bind_spark(src, 5)

	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/message_monitor/LateInitialize()
	//If the server isn't linked to a server, and there's a server available, default it to the first one in the list.
	if(!linkedServer)
		for(var/obj/machinery/telecomms/message_server/S in SSmachinery.all_telecomms)
			linkedServer = S
			break

/obj/machinery/computer/message_monitor/Destroy()
	QDEL_NULL(spark_system)
	linkedServer = null
	return ..()

/obj/machinery/computer/message_monitor/attackby(obj/item/attacking_item, mob/user, params)
	if(stat & (NOPOWER|BROKEN))
		return ..()
	if(!istype(user))
		return TRUE
	if(attacking_item.isscrewdriver() && emag)
		//Stops people from just unscrewing the monitor and putting it back to get the console working again.
		to_chat(user, SPAN_WARNING("It is too hot to mess with!"))
		return TRUE

	return ..()

/obj/machinery/computer/message_monitor/emag_act(var/remaining_charges, var/mob/user)
	// Will create sparks and print out the console's password. You will then have to wait a while for the console to be back online.
	// It'll take more time if there's more characters in the password..
	if(!emag && operable())
		if(!isnull(linkedServer))
			emag = TRUE
			screen = 2
			spark_system.queue()
			var/obj/item/paper/monitorkey/MK = new/obj/item/paper/monitorkey
			MK.forceMove(loc)
			// Will help make emagging the console not so easy to get away with.
			MK.info += "<br><br><span class='warning'>£%@%(*$%&(£&?*(%&£/{}</span>"
			addtimer(CALLBACK(src, PROC_REF(UnmagConsole)), 100 * length(linkedServer.decryptkey))
			message = rebootmsg
			update_icon()
			return TRUE
		else
			to_chat(user, SPAN_NOTICE("A no server error appears on the screen."))

/obj/machinery/computer/message_monitor/update_icon()
	if(emag || hacking)
		icon_screen = hack_icon
	else
		icon_screen = initial(icon_screen)
	..()

/obj/machinery/computer/message_monitor/attack_hand(var/mob/living/user as mob)
	if(stat & (NOPOWER|BROKEN))
		return
	if(!istype(user))
		return
	//If the computer is being hacked or is emagged, display the reboot message.
	if(hacking || emag)
		message = rebootmsg
	var/dat = "<body>"
	dat += "<center><h2>Message Monitor Console</h2></center><hr>"
	dat += "<center><h4><font color='blue'[message]</h5></center>"

	if(auth)
		dat += "<h4><dd><A href='byond://?src=[REF(src)];auth=1'>&#09;<font color='green'>\[Authenticated\]</font></a>&#09;/"
		dat += " Server Power: <A href='byond://?src=[REF(src)];active=1'>[src.linkedServer && src.linkedServer.use_power ? "<font color='green'>\[On\]</font>":SPAN_WARNING("\[Off\]")]</a></h4>"
	else
		dat += "<h4><dd><A href='byond://?src=[REF(src)];auth=1'>&#09;<span class='warning'>\[Unauthenticated\]</span></a>&#09;/"
		dat += " Server Power: <u>[src.linkedServer && src.linkedServer.use_power ? "<font color='green'>\[On\]</font>":SPAN_WARNING("\[Off\]")]</u></h4>"

	if(hacking || emag)
		screen = 2
	else if(!auth || !linkedServer || (linkedServer.stat & (NOPOWER|BROKEN)))
		if(!linkedServer || (linkedServer.stat & (NOPOWER|BROKEN))) message = noserver
		screen = 0

	switch(screen)
		//Main menu
		if(0)
			//&#09; = TAB
			var/i = 0
			dat += "<dd><A href='byond://?src=[REF(src)];find=1'>&#09;[++i]. Link To A Server</a></dd>"
			if(auth)
				if(!linkedServer || (linkedServer.stat & (NOPOWER|BROKEN)))
					dat += "<dd><A>&#09;ERROR: Server not found!</A><br></dd>"
				else
					dat += "<dd><A href='byond://?src=[REF(src)];view=1'>&#09;[++i]. View Message Logs </a><br></dd>"
					dat += "<dd><A href='byond://?src=[REF(src)];viewr=1'>&#09;[++i]. View Requests Console Logs </a></br></dd>"
					dat += "<dd><A href='byond://?src=[REF(src)];clear=1'>&#09;[++i]. Clear Message Logs</a><br></dd>"
					dat += "<dd><A href='byond://?src=[REF(src)];clearr=1'>&#09;[++i]. Clear Requests Console Logs</a><br></dd>"
					dat += "<dd><A href='byond://?src=[REF(src)];pass=1'>&#09;[++i]. Set Custom Key</a><br></dd>"
					dat += "<dd><A href='byond://?src=[REF(src)];msg=1'>&#09;[++i]. Send Admin Message</a><br></dd>"
					dat += "<dd><A href='byond://?src=[REF(src)];spam=1'>&#09;[++i]. Modify Spam Filter</a><br></dd>"
			else
				for(var/n = ++i; n <= optioncount; n++)
					dat += "<dd><span class='notice'>&#09;[n]. ---------------</span><br></dd>"
			if((istype(user, /mob/living/silicon/ai) || istype(user, /mob/living/silicon/robot)) && (user.mind.special_role && user.mind.original == user))
				//Malf/Traitor AIs can bruteforce into the system to gain the Key.
				dat += "<dd><A href='byond://?src=[REF(src)];hack=1'><i><span class='warning'>*&@#. Bruteforce Key</span></i></font></a><br></dd>"
			else
				dat += "<br>"

			//Bottom message
			if(!auth)
				dat += "<br><hr><dd><span class='notice'>Please authenticate with the server in order to show additional options.</span>"
			else
				dat += "<br><hr><dd><span class='warning'>Reg, #514 forbids sending messages to a Head of Staff containing Erotic Rendering Properties.</span>"

		//Message Logs
		if(1)
			if(src.linkedServer?.stat & (NOPOWER|BROKEN))
				dat += "<br><hr><dd><span class='notice'>Server is currently not accepting connections, or is down.</span>"
			else
				var/index = 3000
				dat += "<br><hr><dd>" + SPAN_ALERT("Only the last [index] messages are stored!") + "</span>"

				dat += "<center><A href='byond://?src=[REF(src)];back=1'>Back</a> - <A href='byond://?src=[REF(src)];refresh=1'>Refresh</center><hr></a>"

				for(var/datum/data_pda_msg/message in src.linkedServer.pda_msgs)
					if(index-- <= 0)
						break
					dat += "<br><hr><dd><span class='notice'>[message.sender] --> [message.recipient]:</span> [message.message]"

		//Hacking screen.
		if(2)
			if(istype(user, /mob/living/silicon/ai) || istype(user, /mob/living/silicon/robot))
				dat += "Brute-forcing for server key.<br> It will take 20 seconds for every character that the password has."
				dat += "In the meantime, this console can reveal your true intentions if you let someone access it. Make sure no humans enter the room during that time."
			else
				//It's the same message as the one above but in binary. Because robots understand binary and humans don't... well I thought it was clever.
				dat += {"01000010011100100111010101110100011001010010110<br>
				10110011001101111011100100110001101101001011011100110011<br>
				10010000001100110011011110111001000100000011100110110010<br>
				10111001001110110011001010111001000100000011010110110010<br>
				10111100100101110001000000100100101110100001000000111011<br>
				10110100101101100011011000010000001110100011000010110101<br>
				10110010100100000001100100011000000100000011100110110010<br>
				10110001101101111011011100110010001110011001000000110011<br>
				00110111101110010001000000110010101110110011001010111001<br>
				00111100100100000011000110110100001100001011100100110000<br>
				10110001101110100011001010111001000100000011101000110100<br>
				00110000101110100001000000111010001101000011001010010000<br>
				00111000001100001011100110111001101110111011011110111001<br>
				00110010000100000011010000110000101110011001011100010000<br>
				00100100101101110001000000111010001101000011001010010000<br>
				00110110101100101011000010110111001110100011010010110110<br>
				10110010100101100001000000111010001101000011010010111001<br>
				10010000001100011011011110110111001110011011011110110110<br>
				00110010100100000011000110110000101101110001000000111001<br>
				00110010101110110011001010110000101101100001000000111100<br>
				10110111101110101011100100010000001110100011100100111010<br>
				10110010100100000011010010110111001110100011001010110111<br>
				00111010001101001011011110110111001110011001000000110100<br>
				10110011000100000011110010110111101110101001000000110110<br>
				00110010101110100001000000111001101101111011011010110010<br>
				10110111101101110011001010010000001100001011000110110001<br>
				10110010101110011011100110010000001101001011101000010111<br>
				00010000001001101011000010110101101100101001000000111001<br>
				10111010101110010011001010010000001101110011011110010000<br>
				00110100001110101011011010110000101101110011100110010000<br>
				00110010101101110011101000110010101110010001000000111010<br>
				00110100001100101001000000111001001101111011011110110110<br>
				10010000001100100011101010111001001101001011011100110011<br>
				10010000001110100011010000110000101110100001000000111010<br>
				001101001011011010110010100101110"}

		//Requests Console Logs
		if(4)

			var/index = 0
			/* 	data_rc_msg
				X												 - 5%
				var/rec_dpt = "Unspecified" //name of the person - 15%
				var/send_dpt = "Unspecified" //name of the sender- 15%
				var/message = "Blank" //transferred message		 - 300px
				var/stamp = "Unstamped"							 - 15%
				var/id_auth = "Unauthenticated"					 - 15%
				var/priority = "Normal"							 - 10%
			*/
			dat += "<center><A href='byond://?src=[REF(src)];back=1'>Back</a> - <A href='byond://?src=[REF(src)];refresh=1'>Refresh</center><hr>"
			dat += {"<table border='1' width='100%'><tr><th width = '5%'>X</th><th width='15%'>Sending Dep.</th><th width='15%'>Receiving Dep.</th>
			<th width='300px' word-wrap: break-word>Message</th><th width='15%'>Stamp</th><th width='15%'>ID Auth.</th><th width='15%'>Priority.</th></tr>"}
			for(var/datum/data_rc_msg/rc in src.linkedServer.rc_msgs)
				index++
				if(index > 3000)
					break
				// Del - Sender   - Recepient - Message
				// X   - Al Green - Your Mom  - WHAT UP!?
				dat += {"<tr><td width = '5%'><center><A href='byond://?src=[REF(src)];deleter=[REF(rc)]' style='color: rgb(255,0,0)'>X</a></center></td><td width='15%'>[rc.send_dpt]</td>
				<td width='15%'>[rc.rec_dpt]</td><td width='300px'>[rc.message]</td><td width='15%'>[rc.stamp]</td><td width='15%'>[rc.id_auth]</td><td width='15%'>[rc.priority]</td></tr>"}
			dat += "</table>"

		//Spam filter modification
		if(5)
			dat += "<center><A href='byond://?src=[REF(src)];back=1'>Back</a> - <A href='byond://?src=[REF(src)];refresh=1'>Refresh</center><hr>"
			var/index = 0
			for(var/token in src.linkedServer.spamfilter)
				index++
				if(index > 3000)
					break
				dat += "<dd>[index]&#09; <a href='byond://?src=[REF(src)];deltoken=[index]'>\[[token]\]</a><br></dd>"
			dat += "<hr>"
			if (linkedServer.spamfilter.len < linkedServer.spamfilter_limit)
				dat += "<a href='byond://?src=[REF(src)];addtoken=1'>Add token</a><br>"


	dat += "</body>"
	message = defaultmsg
	user << browse(HTML_SKELETON_TITLE("Message Monitor Console", dat), "window=message;size=700x700")
	onclose(user, "message")
	return

/obj/machinery/computer/message_monitor/attack_ai(mob/user as mob)
	if(!ai_can_interact(user))
		return
	return src.attack_hand(user)

/obj/machinery/computer/message_monitor/proc/BruteForce(mob/user as mob)
	if(isnull(linkedServer))
		to_chat(user, SPAN_WARNING("Could not complete brute-force: Linked Server Disconnected!"))
	else
		var/currentKey = src.linkedServer.decryptkey
		to_chat(user, SPAN_WARNING("Brute-force completed! The key is '[currentKey]'."))
	src.hacking = 0
	update_icon()
	src.screen = 0 // Return the screen back to normal

/obj/machinery/computer/message_monitor/proc/UnmagConsole()
	src.emag = 0
	update_icon()

/obj/machinery/computer/message_monitor/proc/ResetMessage()
	customsender 	= "System Administrator"
	custommessage 	= "This is a test, please ignore."
	customjob 		= "Admin"

/obj/machinery/computer/message_monitor/Topic(href, href_list)
	if(..())
		return 1
	//Authenticate
	if (href_list["auth"])
		if(auth)
			auth = 0
			screen = 0
		else
			var/dkey = trim(input(usr, "Please enter the decryption key.") as text|null)
			if(dkey && dkey != "")
				if(src.linkedServer.decryptkey == dkey)
					auth = 1
				else
					message = incorrectkey

	//Turn the server on/off.
	if (href_list["active"])
		if(auth) linkedServer.use_power = !linkedServer.use_power
	//Find a server
	if (href_list["find"])
		var/list/message_servers = list()
		for(var/obj/machinery/telecomms/message_server/M in SSmachinery.all_telecomms)
			message_servers += M

		if(message_servers.len > 1)
			linkedServer = input(usr,"Please select a server.", "Select a server.", null) as null|anything in message_servers
			message = SPAN_ALERT("NOTICE: Server selected.")
		else if(message_servers.len > 0)
			linkedServer = message_servers[1]
			message =  SPAN_NOTICE("NOTICE: Only Single Server Detected - Server selected.")
		else
			message = noserver

	//View the logs - KEY REQUIRED
	if (href_list["view"])
		if(src.linkedServer == null || (src.linkedServer.stat & (NOPOWER|BROKEN)))
			message = noserver
		else
			if(auth)
				src.screen = 1

	//Clears the logs - KEY REQUIRED
	if (href_list["clear"])
		if(!linkedServer || (src.linkedServer.stat & (NOPOWER|BROKEN)))
			message = noserver
		else
			if(auth)
				src.linkedServer.pda_msgs = list()
				message = SPAN_NOTICE("NOTICE: Logs cleared.")
	//Clears the requests console logs - KEY REQUIRED
	if (href_list["clearr"])
		if(!linkedServer || (src.linkedServer.stat & (NOPOWER|BROKEN)))
			message = noserver
		else
			if(auth)
				src.linkedServer.rc_msgs = list()
				message = SPAN_NOTICE("NOTICE: Logs cleared.")
	//Change the password - KEY REQUIRED
	if (href_list["pass"])
		if(!linkedServer || (src.linkedServer.stat & (NOPOWER|BROKEN)))
			message = noserver
		else
			if(auth)
				var/dkey = trim(input(usr, "Please enter the decryption key.") as text|null)
				if(dkey && dkey != "")
					if(src.linkedServer.decryptkey == dkey)
						var/newkey = trim(input(usr,"Please enter the new key (3 - 16 characters max):"))
						if(length(newkey) <= 3)
							message = SPAN_NOTICE("NOTICE: Decryption key too short!")
						else if(length(newkey) > 16)
							message = SPAN_NOTICE("NOTICE: Decryption key too long!")
						else if(newkey && newkey != "")
							src.linkedServer.decryptkey = newkey
						message = SPAN_NOTICE("NOTICE: Decryption key set.")
					else
						message = incorrectkey

	//Hack the Console to get the password
	if (href_list["hack"])
		if((istype(usr, /mob/living/silicon/ai) || istype(usr, /mob/living/silicon/robot)) && (usr.mind.special_role && usr.mind.original == usr))
			src.hacking = 1
			src.screen = 2
			update_icon()
			//Time it takes to bruteforce is dependant on the password length.
			spawn(100*length(src.linkedServer.decryptkey))
				if(src && src.linkedServer && usr)
					BruteForce(usr)
	//Delete the log.
	if (href_list["delete"])
		//Are they on the view logs screen?
		if(screen == 1)
			if(!linkedServer || (src.linkedServer.stat & (NOPOWER|BROKEN)))
				message = noserver
			else //if(istype(href_list["delete"], /datum/data_pda_msg))
				src.linkedServer.pda_msgs -= locate(href_list["delete"])
				message = SPAN_NOTICE("NOTICE: Log Deleted!")
	//Delete the requests console log.
	if (href_list["deleter"])
		//Are they on the view logs screen?
		if(screen == 4)
			if(!linkedServer || (src.linkedServer.stat & (NOPOWER|BROKEN)))
				message = noserver
			else //if(istype(href_list["delete"], /datum/data_pda_msg))
				src.linkedServer.rc_msgs -= locate(href_list["deleter"])
				message = SPAN_NOTICE("NOTICE: Log Deleted!")
	//Create a custom message
	if (href_list["msg"])
		if(src.linkedServer == null || (src.linkedServer.stat & (NOPOWER|BROKEN)))
			message = noserver
		else
			if(auth)
				src.screen = 3

	//Requests Console Logs - KEY REQUIRED
	if(href_list["viewr"])
		if(src.linkedServer == null || (src.linkedServer.stat & (NOPOWER|BROKEN)))
			message = noserver
		else
			if(auth)
				src.screen = 4

		//to_chat(usr, href_list["select"])

	if(href_list["spam"])
		if(src.linkedServer == null || (src.linkedServer.stat & (NOPOWER|BROKEN)))
			message = noserver
		else
			if(auth)
				src.screen = 5

	if(href_list["addtoken"])
		if(src.linkedServer == null || (src.linkedServer.stat & (NOPOWER|BROKEN)))
			message = noserver
		else
			src.linkedServer.spamfilter += input(usr,"Enter text you want to be filtered out","Token creation") as text|null

	if(href_list["deltoken"])
		if(src.linkedServer == null || (src.linkedServer.stat & (NOPOWER|BROKEN)))
			message = noserver
		else
			var/tokennum = text2num(href_list["deltoken"])
			src.linkedServer.spamfilter.Cut(tokennum,tokennum+1)

	if (href_list["back"])
		src.screen = 0

	return src.attack_hand(usr)


/obj/item/paper/monitorkey
	//..()
	name = "Monitor Decryption Key"
	var/obj/machinery/telecomms/message_server/server = null

/obj/item/paper/monitorkey/Initialize()
	..()
	return INITIALIZE_HINT_LATELOAD

/obj/item/paper/monitorkey/LateInitialize()
	for(var/obj/machinery/telecomms/message_server/server in SSmachinery.all_telecomms)
		if(!isnull(server))
			if(!isnull(server.decryptkey))
				info = "<center><h2>Daily Key Reset</h2></center><br>The new message monitor key is '[server.decryptkey]'.<br>Please keep this a secret and away from unauthorized personnel.<br>If necessary, change the password to a more secure one."
				info_links = info
				icon_state = "paper_words"
				break

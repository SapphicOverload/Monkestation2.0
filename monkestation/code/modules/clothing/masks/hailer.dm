/datum/action/item_action/dispatch
	name = "Signal dispatch"
	desc = "Opens up a quick select wheel for reporting crimes, including your current location, to your fellow security officers."
	button_icon_state = "dispatch"
	button_icon = 'monkestation/icons/mob/actions/sechailer.dmi'

/obj/item/clothing/mask/gas/sechailer
	var/obj/item/radio/hailer/radio
	var/radio_key = /obj/item/encryptionkey/headset_secmed //needs med to in order to request medical help for one of the things
	var/dispatch_cooldown = 25 SECONDS
	var/last_dispatch = 0
	var/static/list/options = list(
		"code 601 (Murder) in progress" = RADIO_CHANNEL_SECURITY,
		"code 101 (Resisting Arrest) in progress" = RADIO_CHANNEL_SECURITY,
		"code 309 (Breaking and entering) in progress" = RADIO_CHANNEL_SECURITY,
		"code 306 (Riot) in progress" = RADIO_CHANNEL_SECURITY,
		"code 401 (Assault, Officer) in progress" = RADIO_CHANNEL_SECURITY,
		"reporting an injured civilian" = RADIO_CHANNEL_MEDICAL,
	)

/obj/item/radio/hailer
	subspace_transmission = TRUE

/obj/item/clothing/mask/gas/sechailer/Initialize(mapload)
	. = ..()
	radio = new(src)
	radio.keyslot = new radio_key
	radio.recalculateChannels()
	RegisterSignal(radio, COMSIG_RADIO_RECEIVE_MESSAGE, PROC_REF(on_receive_message))

/obj/item/clothing/mask/gas/sechailer/Destroy()
	QDEL_NULL(radio)
	return ..()

/obj/item/clothing/mask/gas/sechailer/proc/dispatch(mob/user)
	if(world.time < last_dispatch + dispatch_cooldown)
		to_chat(user, span_notice("Dispatch radio broadcasting systems are recharging."))
		return FALSE
	var/list/display = list()
	for(var/option in options)
		display[option] = image(icon = 'monkestation/icons/effects/aiming.dmi', icon_state = option)
	var/message = show_radial_menu(user, user, display)
	if(!message)
		return FALSE
	radio.talk_into(src, "Dispatch, [message] in [get_area(src)], requesting assistance.", options[message], message_mods = list(MODE_HAIL = TRUE))
	last_dispatch = world.time

/obj/item/clothing/mask/gas/sechailer/proc/on_receive_message(datum/source, list/data)
	SIGNAL_HANDLER
	if(!ismob(loc))
		return RADIO_BLOCK_RECEPTION
	var/list/message_mods = data["mods"]
	if(!message_mods[MODE_HAIL])
		return RADIO_BLOCK_RECEPTION
	playsound(loc, "monkestation/sound/voice/dispatch_please_respond.ogg", 100, FALSE)

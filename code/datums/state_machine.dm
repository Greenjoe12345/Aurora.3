/// List and procs for caching state machine instances.
GLOBAL_LIST_INIT(state_machines, list())

/proc/get_state_machine(var/datum/holder, var/base_type)
	if(istype(holder) && base_type && holder.has_state_machine)
		var/list/machines = GLOB.state_machines["[REF(holder)]"]
		return islist(machines) && machines[base_type]

/proc/add_state_machine(var/datum/holder, var/base_type, var/fsm_type)
	if(istype(holder) && base_type)
		var/holder_ref = "[REF(holder)]"
		var/list/machines = GLOB.state_machines[holder_ref]
		if(!islist(machines))
			machines = list()
			GLOB.state_machines[holder_ref] = machines
		if(!machines[base_type])
			if(!fsm_type)
				fsm_type = base_type
			var/datum/state_machine/machine = new fsm_type(holder)
			machines[base_type] = machine
			holder.has_state_machine = TRUE
			return machine

/proc/remove_state_machine(var/datum/holder, var/base_type)
	if(istype(holder) && base_type && holder.has_state_machine)
		var/holder_ref = "[REF(holder)]"
		var/list/machines = GLOB.state_machines[holder_ref]
		if(length(machines))
			machines -= base_type
			if(!length(machines))
				GLOB.state_machines -= holder_ref
				holder.has_state_machine = FALSE
			return TRUE
	return FALSE

// This contains the current state of the FSM and should be held by whatever the FSM is controlling.
// Unlike the individual states and their transitions, the state machine objects are not singletons, and hence aren't `/decl`s.
/datum/state_machine
	var/datum/weakref/holder_ref
	var/base_type = /datum/state_machine
	var/expected_type = /datum
	var/singleton/state/current_state = null // Acts both as a ref to the current state and holds which state it will default to on init.

/datum/state_machine/New(var/datum/_holder)
	..()
	if(!istype(_holder))
		stack_trace("Non-datum holder supplied to [type] New().")
	else
		holder_ref = WEAKREF(_holder)
	set_state(current_state)

/datum/state_machine/Destroy()
	current_state = null
	return ..()

// Resets back to our initial state.
/datum/state_machine/proc/reset()
	var/datum/holder_instance = get_holder()
	if(istype(current_state))
		current_state.exited_state(holder_instance)
	current_state = initial(current_state)
	if(ispath(current_state, /singleton/state))
		current_state = GET_SINGLETON(current_state)
		current_state.entered_state(holder_instance)
	else
		current_state = null
	return current_state

// Retrieve and validate our holder instance from the cached weakref.
/datum/state_machine/proc/get_holder()
	var/datum/holder = holder_ref?.resolve()
	if(istype(holder) && !QDELETED(holder))
		return holder

// Makes the FSM enter a new state, if it can, based on it's current state, that state's transitions, and the holder's status.
// Call it in the holder's `process()`, or whenever you need to.
/datum/state_machine/proc/evaluate()
	var/datum/holder_instance = get_holder()
	var/list/options = current_state.get_open_transitions(holder_instance)
	if(LAZYLEN(options))
		var/singleton/state_transition/choice = choose_transition(options)
		handle_next_transition(holder_instance, choice)

// Decides which transition to walk into, to the next state.
// By default it chooses the first one on the list.
/datum/state_machine/proc/choose_transition(list/valid_transitions)
	return valid_transitions[1]

/// Handles changing the state, based on the state_transition chosen in `evaluate()`.
/datum/state_machine/proc/handle_next_transition(var/datum/holder_instance, var/singleton/state_transition/chosen_transition)
	current_state.exited_state(holder_instance)
	current_state = chosen_transition.target
	current_state.entered_state(holder_instance)

// Forces the FSM to switch to a specific state, no matter what.
// Use responsibly.
/datum/state_machine/proc/set_state(new_state_type)
	var/datum/holder_instance = get_holder()
	if(istype(current_state))
		current_state.exited_state(holder_instance)
	if(ispath(new_state_type))
		current_state = GET_SINGLETON(new_state_type)
	else // need to include null here, so we can't do an istype
		current_state = new_state_type
	if(istype(current_state))
		current_state.entered_state(holder_instance)
		return current_state

var/datum/controller/employment_controller/employment_controller

/datum/controller/employment_controller
	var/timerbuffer = 0 //buffer for time check
	var/checkbuffer = 0
/datum/controller/employment_controller/New()
	timerbuffer = 1 HOUR 
	checkbuffer = 5 MINUTES
	START_PROCESSING(SSprocessing, src)

/datum/controller/employment_controller/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	. = ..()

/datum/controller/employment_controller/Process()
	var/reset_timerbuffer = 0
	if(round_duration_in_ticks > checkbuffer)
		for(var/datum/world_faction/connected_faction in GLOB.all_world_factions)
			for(var/obj/item/organ/internal/stack/stack in connected_faction.connected_laces)
				var/datum/computer_file/crew_record/record = connected_faction.get_record(stack.get_owner_name())
				if(!record) continue
				if(stack.duty_status)
					for(var/mob/M in GLOB.player_list)
						if(M.real_name == stack.get_owner_name() && M.client && M.client.inactivity <= 10 * 60 * 10)
							record.worked += 1	
							break

				if(round_duration_in_ticks > timerbuffer)
					to_chat(stack.owner, "Your [stack] buzzes, letting you know that you should be getting paid.")
			if(round_duration_in_ticks > timerbuffer)
				reset_timerbuffer = 1
				for(var/datum/computer_file/crew_record/record in connected_faction.get_records())
					if(record.worked)
						var/datum/assignment/assignment = connected_faction.get_assignment(record.assignment_uid)
						if(!assignment) 
							record.worked = 0
							continue
						var/payscale = 0
						if(record.rank > 1)
							payscale = text2num(assignment.ranks[assignment.ranks[record.rank-1]])
						else
							payscale = assignment.payscale
						var/to_pay = connected_faction.payrate/12*record.worked*payscale
						if(!money_transfer(connected_faction.central_account,record.get_name(),"Payroll",to_pay))
							if(record.get_name() in connected_faction.debts)
								var/curr = text2num(connected_faction.debts[record.get_name()])
								connected_faction.debts[record.get_name()] = "[curr+to_pay]"
							else
								connected_faction.debts[record.get_name()] = "[to_pay]"
						record.worked = 0
					
		checkbuffer = round_duration_in_ticks + 5 MINUTES
		if(reset_timerbuffer)
			timerbuffer = round_duration_in_ticks + 1 HOUR
bodyguardamount = menu.add_feature("Bodyguards amount", "action_value_i", 0, function(f)
end)
bodyguardamount.min = 1
bodyguardamount.max = 32
bodyguardamount.mod = 1
bodyguardamount.value = 1

menu.add_feature("Spawn Bodyguards", "toggle", 0, function(feat)
	if not menu.is_trusted_mode_enabled(1 << 2) then
		menu.notify("Trusted mode > Natives is requiered to use this.")
		feat.on = false
		return
	end
	if feat.on then
        for i = 0, bodyguardamount.value do
			system.yield(0)
            menu.create_thread(function()
				if not streaming.has_model_loaded(0x61D4C771) then
					streaming.request_model(0x61D4C771)
					while not streaming.has_model_loaded(0x61D4C771) do
						system.yield(0)
					end
				end
				local bodyguard = ped.create_ped(0, 0x61D4C771, player.get_player_coords(player.player_id()) + v3(math.random(-5,5), math.random(-5,5), 0), 0, true, false)	
				native.call(0x299EEB23175895FC, native.call(0x0EDEC3C276198689, bodyguard):__tointeger(), 0)
				native.call(0x9F8AA94D6D97DBF4, bodyguard, 1)
				entity.set_entity_god_mode(bodyguard, true)
				weapon.give_delayed_weapon_to_ped(bodyguard, 0x84D6FAFD, 0, 0)
				local run_thread = false
				while feat.on and entity.is_an_entity(bodyguard) and not entity.is_entity_dead(bodyguard) do
					system.yield(0)

					-- Shoot those who shoot me
					local peds = ped.get_all_peds()
					for i = 1, #peds do
						if peds[i] ~= player.get_player_ped(player.player_id())
						and not entity.get_entity_god_mode(peds[i])
						and not entity.is_entity_dead(peds[i])
						and entity.get_entity_model_hash(peds[i]) ~= 0x61D4C771
						and ((ped.is_ped_shooting(peds[i]) or native.call(0xD1871251F3B5ACD7, peds[i]):__tointeger()) and select(2, ped.get_ped_last_weapon_impact(peds[i])):magnitude(player.get_player_coords(player.player_id())) < 1)
						and player.get_player_coords(player.player_id()):magnitude(entity.get_entity_coords(bodyguard)) < 30 
						and	entity.get_entity_coords(peds[i]):magnitude(entity.get_entity_coords(bodyguard)) < 100 then
							ai.task_shoot_at_entity(bodyguard, peds[i], -1, gameplay.get_hash_key("FIRING_PATTERN_FULL_AUTO"))
							while feat.on
							and not entity.is_entity_dead(bodyguard)
							and not entity.is_entity_dead(peds[i])
							and player.get_player_coords(player.player_id()):magnitude(entity.get_entity_coords(bodyguard)) < 30 
							and	entity.get_entity_coords(peds[i]):magnitude(entity.get_entity_coords(bodyguard)) < 100 do
								system.yield(0)
							end
							native.call(0x90D2156198831D69, bodyguard, 1)
						end
					end

					-- Shoot those I shoot
					if ped.is_ped_shooting(player.get_player_ped(player.player_id())) and player.get_entity_player_is_aiming_at(player.player_id()) and not entity.get_entity_god_mode(player.get_entity_player_is_aiming_at(player.player_id())) then
						local target = player.get_entity_player_is_aiming_at(player.player_id())
						ai.task_shoot_at_entity(bodyguard, target, -1, gameplay.get_hash_key("FIRING_PATTERN_FULL_AUTO"))
						while feat.on
						and not entity.is_entity_dead(target)
						and not entity.is_entity_dead(bodyguard) 
						and entity.is_an_entity(target)
						and player.get_player_coords(player.player_id()):magnitude(entity.get_entity_coords(bodyguard)) < 30 
						and	entity.get_entity_coords(target):magnitude(entity.get_entity_coords(bodyguard)) < 100 do
							system.yield(0)
						end
						native.call(0x90D2156198831D69, bodyguard, 1)
					end

					-- Run to you
					if player.get_player_coords(player.player_id()):magnitude(entity.get_entity_coords(bodyguard)) > 10 and run_thread == false then
						menu.create_thread(function()
							if player.get_player_coords(player.player_id()):magnitude(entity.get_entity_coords(bodyguard)) > 10 then
								run_thread = true
								ai.task_goto_entity(bodyguard, player.get_player_ped(player.player_id()), -1, 1, 2)
								while feat.on
								and not entity.is_entity_dead(bodyguard) 
								and player.get_player_coords(player.player_id()):magnitude(entity.get_entity_coords(bodyguard)) > 10 do
									system.yield(0)
								end
								native.call(0x90D2156198831D69, bodyguard, 1)
							end
							run_thread = false
						end, nil)
					end

					-- Auto regroup
					if player.get_player_coords(player.player_id()):magnitude(entity.get_entity_coords(bodyguard)) > 40 then
						if player.is_player_in_any_vehicle(player.player_id()) then
							local heading = math.rad((entity.get_entity_heading(player.get_player_ped(player.player_id())) - 0) * -1)
							local pos = player.get_player_coords(player.player_id())
							pos.x = pos.x + (math.sin(heading) * -20)
							pos.y = pos.y + (math.cos(heading) * -20)
							pos.z = pos.z + 1
							entity.set_entity_coords_no_offset(bodyguard, pos)
						else
							entity.set_entity_coords_no_offset(bodyguard, player.get_player_coords(player.player_id()) + v3(math.random(-5,5), math.random(-5,5), 0))
						end
					end

					-- TP in your vehicle
					if player.is_player_in_any_vehicle(player.player_id()) 
					and vehicle.get_free_seat(player.get_player_vehicle(player.player_id())) >= 0 then
						for i = -1, vehicle.get_vehicle_max_number_of_passengers(player.get_player_vehicle(player.player_id())) do
							if native.call(0x22AC59A870E6A669, player.get_player_vehicle(player.player_id()), i):__tointeger() 
							and not ped.is_ped_in_vehicle(bodyguard, player.get_player_vehicle(player.player_id())) then
								ped.set_ped_into_vehicle(bodyguard, player.get_player_vehicle(player.player_id()), i)
							end
						end
					end
					if not player.is_player_in_any_vehicle(player.player_id()) and ped.is_ped_in_any_vehicle(bodyguard) then
						ped.clear_ped_tasks_immediately(bodyguard)
					end
                end
				if entity.is_an_entity(bodyguard) then
					entity.set_entity_as_no_longer_needed(bodyguard)
					entity.delete_entity(bodyguard)
				end
            end, nil)
        end
    end
	streaming.set_model_as_no_longer_needed(0x61D4C771)
end)

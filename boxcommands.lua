--[[
Copyright © 2018, Makaria
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
* Neither the name of EasyNuke nor the
names of its contributors may be used to endorse or promote products
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Nyarlko, or it's members, BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

_addon.name    = 'BoxCommands'
_addon.author  = 'Makaria'
_addon.version = '1.1.0'
_addon.command = "box"

require ('commands')

windower.register_event('addon command', function (command, ...)
	local arg = {...}
	if command == 'setup' then
		setupCommands()
	elseif command == 'spelllevel' then
		set_spell_level(arg[1])
	elseif command == 'macro' then
		if arg[1] == 'default' then
			set_macro('default', 'main')
		else
			set_macro(arg[1], arg[2])
		end
	elseif command == 'setcaster' then
		set_caster(arg[1])
	elseif command == 'target' then
		set_target(arg[1])
	elseif command == 'cast' then
		local spellName = arg[1]
		if arg[2] then
			for i=2,#arg do
				spellName = spellName .. ' ' .. arg[i]
			end
		end
		
		local target_caster = caster 
		local local_player = windower.ffxi.get_player()
		
		if local_player and local_player.name:lower() ~= target_caster:lower() then
			local packet = '//box cast ' .. spellName
			windower.send_command('send ' .. target_caster .. ' ' .. packet)
		else
			cast_spell(spellName) 
		end

	elseif command == 'ja' then
		local abilityName = arg[1]
		if arg[2] then
			for i=2,#arg do
				abilityName = abilityName .. ' ' .. arg[i]
			end
		end

		local target_caster = caster 
		local local_player = windower.ffxi.get_player()
		
		if local_player and local_player.name:lower() ~= target_caster:lower() then
			local packet = '//box ja ' .. abilityName
			windower.send_command('send ' .. target_caster .. ' ' .. packet)
		else
			job_ability(nil, abilityName) 
		end

	elseif command == 'pet' then
		local abilityName = arg[1]
		if arg[2] then
			for i=2,#arg do
				abilityName = abilityName .. ' ' .. arg[i]
			end
		end

		local target_caster = caster 
		local local_player = windower.ffxi.get_player()
		
		if local_player and local_player.name:lower() ~= target_caster:lower() then
			local packet = '//box pet ' .. abilityName
			windower.send_command('send ' .. target_caster .. ' ' .. packet)
		else
			pet_command(abilityName) 
		end
	elseif command == 'bstpet' then
		local abilityName = arg[1]
		if arg[2] then
			for i=2,#arg do
				abilityName = abilityName .. ' ' .. arg[i]
			end
		end

		local target_caster = caster 
		local local_player = windower.ffxi.get_player()
		
		if local_player and local_player.name:lower() ~= target_caster:lower() then
			local packet = '//box bstpet ' .. abilityName
			windower.send_command('send ' .. target_caster .. ' ' .. packet)
		else
			bstpet_command(abilityName) 
		end
	elseif command == 'pact' then
		local pactName = arg[1]
		if arg[2] then
			for i=2,#arg do
				pactName = pactName .. ' ' .. arg[i]
			end
		end

		local target_caster = caster 
		local local_player = windower.ffxi.get_player()

		if local_player and local_player.name:lower() ~= target_caster:lower() then
			windower.send_command('send ' .. target_caster .. ' box pact ' .. pactName)
		else
			handle_dynamic_pact(pactName)
		end
	elseif command == 'storm' then
		handle_storm()
	elseif command == 'helix' then
		handle_helix()
	-- Replace the timer block in boxcommands.lua with this robust version:
	elseif command == 'pretimer' then
		local num_args = #arg
		
		-- Properly map from the end of the argument table to avoid space issues in the label
		local caster_name = arg[1]
		local abilityType = arg[2]
		local castTime = arg[3]
		
		-- Reconstruct the label from the middle arguments (indices 2 through num_args-2)
		local abilityName = arg[4]
		for i = 5, (num_args) do
			abilityName = abilityName .. ' ' .. arg[i]
		end
		if caster_name then
			windower.send_command('@wait ' .. castTime .. '; box timer ' .. caster_name .. ' ' .. abilityType .. ' ' .. abilityName) 
		end
	elseif command == 'timer' then
		local num_args = #arg
		
		-- Properly map from the end of the argument table to avoid space issues in the label
		local caster_name = arg[1]
		local abilityType = arg[2]
		
		-- Reconstruct the label from the middle arguments (indices 2 through num_args-2)
		local abilityName = arg[3]
		for i = 4, (num_args) do
			abilityName = abilityName .. ' ' .. arg[i]
		end
		if caster_name then
			get_duration(abilityType, abilityName, caster_name)
		end
	elseif command == 'timerui' then
		local num_args = #arg
		
		-- Properly map from the end of the argument table to avoid space issues in the label
		local duration = arg[1]
		local charge_duration = arg[2]
		local caster_name = arg[3]
		local abilityType = arg[4]
		local col_index = arg[5]
		
		-- Reconstruct the label from the middle arguments (indices 2 through num_args-2)
		local abilityName = arg[6]
		for i = 7, (num_args) do
			abilityName = abilityName .. ' ' .. arg[i]
		end
		if caster_name then
			create_network_timer(duration, charge_duration, abilityType, abilityName, caster_name, col_index)
		end
	end
end)

setupCommands()

if initialize_column_headers then
    initialize_column_headers()
end
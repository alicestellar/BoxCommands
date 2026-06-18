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

-- BoxCommands: Multi-boxing command addon for Windower/FFXI.
-- Dispatches //box commands to the appropriate handler in commands.lua,
-- routing actions to the designated caster character via IPC when needed.

_addon.name    = 'BoxCommands'
_addon.author  = 'Makaria'
_addon.version = '3.0.0'
_addon.command = "box"

local res = require('resources')
local settings_manager = require('settings_manager')
local macro_config = require('macro_config')

require ('commands')

-- ====================================================================
-- ADDON LOAD: Initialize settings, register character, set online
-- ====================================================================
settings_manager.load()

-- Track the last registered character name (used by shareslot command)
local last_registered_character = nil

local player_info = windower.ffxi.get_player()
if player_info then
    local player_name = player_info.name
    last_registered_character = player_name
    settings_manager.register_character(player_name)
    settings_manager.set_online(player_name, true)

    -- Update job info from current player state
    local main_job = res.jobs[player_info.main_job_id] and res.jobs[player_info.main_job_id].ens or ''
    local sub_job = res.jobs[player_info.sub_job_id] and res.jobs[player_info.sub_job_id].ens or ''
    settings_manager.update_job(player_name, main_job, sub_job)

    -- Update max HP for current job
    local max_hp = player_info.vitals and player_info.vitals.max_hp or 0
    if main_job ~= '' and max_hp > 0 then
        settings_manager.update_max_hp(player_name, main_job, max_hp)
    end

    settings_manager.save()

    -- Set initial caster from settings (position 1 character, or this character)
    local slot1_char = settings_manager.get_slot_character(1)
    if slot1_char then
        caster = slot1_char
    else
        caster = player_name
    end
end

-- ====================================================================
-- LOGIN EVENT: Detect character switch without addon reload
-- ====================================================================
windower.register_event('login', function(name)
    -- Re-register the new character on the same client
    settings_manager.load() -- Reload settings in case another box changed them
    settings_manager.register_character(name)
    settings_manager.set_online(name, true)

    local pl = windower.ffxi.get_player()
    if pl then
        local main_job = res.jobs[pl.main_job_id] and res.jobs[pl.main_job_id].ens or ''
        local sub_job = res.jobs[pl.sub_job_id] and res.jobs[pl.sub_job_id].ens or ''
        settings_manager.update_job(name, main_job, sub_job)

        local max_hp = pl.vitals and pl.vitals.max_hp or 0
        if main_job ~= '' and max_hp > 0 then
            settings_manager.update_max_hp(name, main_job, max_hp)
        end
    end

    settings_manager.save()

    -- Update last registered for shareslot
    last_registered_character = name

    -- Rebuild UI headers and keybinds for new character
    setupCommands()
    if initialize_column_headers then
        initialize_column_headers()
    end

    -- Notify other boxes to refresh their UI (this character is now online)
    windower.send_command('send @others box refreshui')
end)

-- ====================================================================
-- LOGOUT EVENT: Mark previous character offline
-- ====================================================================
windower.register_event('logout', function(name)
    settings_manager.set_online(name, false)
    settings_manager.save()
end)

-- ====================================================================
-- ADDON UNLOAD: Mark character offline and save settings
-- ====================================================================
windower.register_event('unload', function()
    local pl = windower.ffxi.get_player()
    if pl then
        settings_manager.set_online(pl.name, false)
        settings_manager.save()
    end
end)

-- ====================================================================
-- JOB CHANGE EVENT: Update job in settings, schedule HP refresh
-- ====================================================================
windower.register_event('job change', function(main_job_id, main_job_level, sub_job_id, sub_job_level)
    local main_job = res.jobs[main_job_id] and res.jobs[main_job_id].ens or ''
    local sub_job = res.jobs[sub_job_id] and res.jobs[sub_job_id].ens or ''
    local pl = windower.ffxi.get_player()
    if pl then
        settings_manager.update_job(pl.name, main_job, sub_job)
        settings_manager.save()
    end
    -- Delay HP update to allow gear to load
    windower.send_command('@wait 3; box refreshhp')
end)

-- ====================================================================
-- COMMAND DISPATCH
-- ====================================================================
windower.register_event('addon command', function (command, ...)
	local arg = {...}

	-- setup: Binds hotkeys for character switching and targeting
	if command == 'setup' then
		setupCommands()

	-- macro: Switch macro book/page. 'default' resets, otherwise slot+jobType
	elseif command == 'macro' then
		if arg[1] == 'default' then
			set_macro('default', 'main')
		else
			set_macro(arg[1], arg[2])
		end

	-- setcaster: Designate which character should execute subsequent commands
	elseif command == 'setcaster' then
		set_caster(arg[1])

	-- target: Set the spell/ability target (character name or <t>, <me>, etc.)
	elseif command == 'target' then
		set_target(arg[1])

	-- switchto: Switch caster to character at given position, update macro
	elseif command == 'switchto' then
		handle_switchto(tonumber(arg[1]))

	-- setslot: Set the current character's position slot
	elseif command == 'setslot' then
		handle_setslot(tonumber(arg[1]))

	-- refreshhp: Capture current max HP and save to settings
	elseif command == 'refreshhp' then
		handle_refreshhp()

	-- cast: Cast the highest available tier of a spell on the designated caster
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

	-- ja: Execute a job ability on the designated caster
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

	-- pet: Issue a pet command (SMN/PUP/DRG) on the designated caster
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

	-- bstpet: Issue a BST pet command on the designated caster
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

	-- pact: Execute a summoner blood pact by category (e.g., bp70, nuke4, cure)
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

	-- storm: Cast the optimal storm spell based on day/weather element
	elseif command == 'storm' then
		handle_storm()

	-- helix: Cast the optimal helix spell based on day/weather element
	elseif command == 'helix' then
		handle_helix()

	-- pretimer: Delayed timer trigger (waits for cast time, then starts recast timer)
	elseif command == 'pretimer' then
		local num_args = #arg
		
		local caster_name = arg[1]
		local abilityType = arg[2]
		local castTime = arg[3]
		
		-- Reconstruct ability name from remaining args (handles multi-word names)
		local abilityName = arg[4]
		for i = 5, (num_args) do
			abilityName = abilityName .. ' ' .. arg[i]
		end
		if caster_name then
			windower.send_command('@wait ' .. castTime .. '; box timer ' .. caster_name .. ' ' .. abilityType .. ' ' .. abilityName) 
		end

	-- timer: Query recast and create a timer bar for the given ability
	elseif command == 'timer' then
		local num_args = #arg
		
		local caster_name = arg[1]
		local abilityType = arg[2]
		
		-- Reconstruct ability name from remaining args (handles multi-word names)
		local abilityName = arg[3]
		for i = 4, (num_args) do
			abilityName = abilityName .. ' ' .. arg[i]
		end
		if caster_name then
			get_duration(abilityType, abilityName, caster_name)
		end

	-- timerui: Create a visual timer bar directly with explicit duration/column
	elseif command == 'timerui' then
		local num_args = #arg
		
		local duration = arg[1]
		local charge_duration = arg[2]
		local caster_name = arg[3]
		local abilityType = arg[4]
		local col_index = arg[5]
		
		-- Reconstruct ability name from remaining args (handles multi-word names)
		local abilityName = arg[6]
		for i = 7, (num_args) do
			abilityName = abilityName .. ' ' .. arg[i]
		end
		if caster_name then
			create_network_timer(duration, charge_duration, abilityType, abilityName, caster_name, col_index)
		end

	-- refreshui: Reload characters from settings and rebuild entire UI
	elseif command == 'refreshui' then
		handle_refreshui()
	end
end)

-- ====================================================================
-- SWITCHTO HANDLER: Switch caster to character at position N
-- ====================================================================

-----------------------------------------------------------
-- Handles the 'switchto' command. Looks up which character
-- is at the given position, sets them as caster, and switches
-- macro to their current job's book/set from macro_config.
-- @param position  Slot position number (1-6)
-----------------------------------------------------------
function handle_switchto(position)
    if not position or position < 1 or position > 6 then
        windower.add_to_chat(123, 'BoxCommands: Invalid position. Use 1-6.')
        return
    end

    local char_name = settings_manager.get_slot_character(position)
    if not char_name then
        windower.add_to_chat(123, 'BoxCommands: No character assigned to position ' .. position)
        return
    end

    -- Send setcaster to all boxes
    windower.send_command('send @all box setcaster ' .. char_name)

    -- Look up macro book/set for this character's current job
    local char_data = settings_manager.get_character(char_name)
    if char_data and char_data.main_job and char_data.main_job ~= '' then
        local job = char_data.main_job:upper()

        -- Check per-character override first, then fall back to global
        local macro_entry = nil
        if macro_config[char_name] and macro_config[char_name][job] then
            macro_entry = macro_config[char_name][job]
        elseif macro_config.global[job] then
            macro_entry = macro_config.global[job]
        end

        if macro_entry then
            set_macro_page(macro_entry.set, macro_entry.book)
        end
    end
end

-- ====================================================================
-- REFRESHHP HANDLER: Capture max HP and save to settings
-- ====================================================================

-----------------------------------------------------------
-- Captures the current player's max HP and saves it to
-- settings under their current main job.
-----------------------------------------------------------
function handle_refreshhp()
    local pl = windower.ffxi.get_player()
    if not pl then return end

    local main_job = res.jobs[pl.main_job_id] and res.jobs[pl.main_job_id].ens or ''
    local max_hp = pl.vitals and pl.vitals.max_hp or 0

    if main_job ~= '' and max_hp > 0 then
        settings_manager.update_max_hp(pl.name, main_job, max_hp)
    end
end

-- ====================================================================
-- SETSLOT HANDLER: Assign current character to a specific position
-- ====================================================================

-----------------------------------------------------------
-- Sets the current character's position slot in the
-- characters data file. Saves immediately.
-- @param position  Slot number to assign (1-6, or 0 for unassigned)
-----------------------------------------------------------
function handle_setslot(position)
    if not position or position < 0 or position > 18 then
        windower.add_to_chat(123, 'BoxCommands: Invalid position. Use 0-18 (0 = unassigned, 1-6 = party, 7-18 = alliance).')
        return
    end

    local pl = windower.ffxi.get_player()
    if not pl then
        windower.add_to_chat(123, 'BoxCommands: No player data available.')
        return
    end

    local current_name = pl.name
    settings_manager.reload_characters()
    local char_data = settings_manager.get_character(current_name)

    if not char_data then
        -- Register first if not in the file
        settings_manager.register_character(current_name)
        char_data = settings_manager.get_character(current_name)
    end

    if char_data then
        char_data.position = position
        settings_manager.save()
        windower.add_to_chat(207, 'BoxCommands: ' .. current_name .. ' set to position ' .. position .. '.')

        -- Rebuild UI to reflect the change
        setupCommands()
        if initialize_column_headers then
            initialize_column_headers()
        end
    end
end

-- ====================================================================
-- REFRESHUI HANDLER: Reload characters and rebuild UI
-- ====================================================================

-----------------------------------------------------------
-- Reloads character data from settings and rebuilds the
-- entire UI (keybinds, headers, status bars, buff icons).
-- Called when another box comes online and broadcasts refreshui.
-----------------------------------------------------------
function handle_refreshui()
    settings_manager.reload_characters()
    setupCommands()
    if initialize_column_headers then
        initialize_column_headers()
    end
end

-- ====================================================================
-- INITIAL SETUP ON LOAD
-- ====================================================================
setupCommands()

if initialize_column_headers then
    initialize_column_headers()
end

-- Notify other boxes to refresh their UI (this character is now online)
windower.send_command('send @others box refreshui')

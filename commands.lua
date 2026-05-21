require ('helper_functions')
local packets = require ('packets')
local res = require('resources')
local texts = require('texts')
local images = require('images') -- Load Windower's image primitive library

-- Active tracking table for ticking down live timers
active_network_timers = {}

-- ====================================================================
-- INITIALIZATION & COLUMN LAYOUT SETUP
-- ====================================================================
column_headers = {}
timer_display_rows = {} 

-- Storage tables to track graphical role icons
caster_icons = {}
target_icons = {}

function initialize_column_headers()
    local names = {'Makaria', 'Amaranti', 'Aenura', 'Midnaria', 'Entrapta', 'Luccaria'}
    local icon_base_path = windower.windower_path .. 'plugins/icons/'

    -- Clean up existing primitives first
    for _, header_id in pairs(column_headers) do header_id:destroy() end
    for _, img_id in pairs(caster_icons) do img_id:destroy() end
    for _, img_id in pairs(target_icons) do img_id:destroy() end
    
    column_headers = {}
    caster_icons = {}
    target_icons = {}

    for idx, char_name in ipairs(names) do
        local col_idx = idx - 1
        local header_x = UI_Layout.base_x + (col_idx * UI_Layout.column_width)
        
        -- Text Label
        local ui_id = texts.new(char_name .. '_header')
        ui_id:font('Arial')
        ui_id:size(10)
        ui_id:text(char_name:upper())
        ui_id:pos(header_x + 18, UI_Layout.base_y - 22)
        ui_id:visible(true) 
        column_headers[char_name] = ui_id

        -- Caster Icon: Shifted Up (-7) and Left (-5 from previous pos)
        local c_img = images.new()
        c_img:path(icon_base_path .. 'spells/00001.png')
        c_img:size(14, 14)
        c_img:pos(header_x - 3, UI_Layout.base_y - 29)
        c_img:visible(false)
        caster_icons[char_name] = c_img

        -- Target Icon: Shifted Up (-7)
        local t_img = images.new()
        t_img:path(icon_base_path .. 'abilities/00124.png')
        t_img:size(14, 14)
        t_img:pos(header_x + 85, UI_Layout.base_y - 29)
        t_img:visible(false)
        target_icons[char_name] = t_img
    end
end

player = initialize_globals(player)
party = windower.ffxi.get_party()
spelllevel = 'max'
language = 'english'
name = ''
target = '<t>'

caster = 'Makaria'

function set_caster(name)
    if name then
        caster = name
    end
end

function setupCommands() 
    windower.send_command('bind ^f1 exec Makaria.txt')
    windower.send_command('bind ^f2 exec Amaranti.txt')
    windower.send_command('bind ^f3 exec Aenura.txt')
    windower.send_command('bind ^f4 exec Midnaria.txt')
    windower.send_command('bind ^f5 exec Entrapta.txt')
    windower.send_command('bind ^f6 exec Luccaria.txt')

    windower.send_command('bind !f1 send @all box target Makaria')
	windower.send_command('bind !f2 send @all box target Amaranti')
	windower.send_command('bind !f3 send @all box target Aenura')
	windower.send_command('bind !f4 send @all box target Midnaria')
	windower.send_command('bind !f5 send @all box target Entrapta')
	windower.send_command('bind !f6 send @all box target Luccaria')

	windower.send_command('bind !` send @all box target <t>')
end

function set_macro(slot, jobType) 
	player = initialize_globals(player)
	party = windower.ffxi.get_party()
	if jobType == 'main' then
		if (slot == 'default') then
			set_macro_page(1, 1)
		else
			set_macro_page(2, macro_sets[tonumber(slot)])
			name = party['p'..slot].name
		end
	elseif jobType == 'sub' then
		set_macro_page(2, macro_sets[tonumber(slot)+6])
		name = party['p'..slot].name
	end
end

function set_spell_level(input)
	spelllevel = input
end

function set_target(t)
	target = t
end

function handle_dynamic_pact(category)
    local pet_mob = windower.ffxi.get_mob_by_target('pet')
    if not pet_mob or not pet_mob.name then
        windower.add_to_chat(123, "BoxCommands: Cannot use Blood Pact. No avatar currently active!")
        return
    end

    local avatar_name = pet_mob.name 
    local cat = category:lower()

    if not pacts or not pacts[cat] then
        windower.add_to_chat(123, "BoxCommands: Unknown pact category: [" .. category .. "]")
        return
    end

    local exact_pact_name = pacts[cat][avatar_name]
    if not exact_pact_name then
        windower.add_to_chat(122, "BoxCommands: " .. avatar_name .. " does not have a pact mapped to type [" .. category .. "].")
        return
    end

    local final_target = '<me>'
    if enemyTypePacts and enemyTypePacts:contains(cat) then
        final_target = target 
    elseif selfTypePacts and selfTypePacts:contains(cat) then
        final_target = '<me>'
    else
        final_target = '<st>' 
    end
	
    windower.send_command('input ' .. unify_prefix['/pet'] .. ' \"' .. exact_pact_name .. '\" ' .. final_target)
	trigger_pact_timer(avatar_name, exact_pact_name)
end

function cast_spell(ability_name)
    local spell_data = select_highest_spell(ability_name)
    if not spell_data then return end

    windower.send_command('input ' .. unify_prefix['/ma'] .. ' "' .. spell_data.en .. '" ' .. target)

	local castTime = spell_data.cast_time + 0.5

	windower.send_command('send ' .. caster .. ' box pretimer ' .. caster .. ' ' .. unify_prefix['/ma'] .. ' ' .. castTime .. ' ' .. spell_data.en)
end

function job_ability(job, input)
    windower.send_command('input ' .. unify_prefix['/ja'] .. ' \"' .. input .. '\" ' .. target)
    
	windower.send_command('send ' .. caster .. ' box pretimer ' .. caster .. ' ' .. unify_prefix['/ja'] .. ' 1.5 ' .. input)
end

function bstpet_command(input)
	windower.send_command('input /bstpet \"' .. input .. '\" ' .. target)
    
	windower.send_command('send ' .. caster .. ' box pretimer ' .. caster .. ' ' .. unify_prefix['/bstpet'] .. ' 1.5 ' .. input)
end

function pet_command(input)
    windower.send_command('input ' .. unify_prefix['/pet'] .. ' \"' .. input .. '\" ' .. target)
    
	windower.send_command('send ' .. caster .. ' box pretimer ' .. caster .. ' ' .. unify_prefix['/pet'] .. ' 1.5 ' .. input)
end

function handle_storm()
	local input = get_elements()
	local day_element = input['day_element']
	local weather_element = input['weather_element']
	local weather_intensity = input['weather_intensity']
	if weather_element ~= 'None' and (weather_intensity == 2 or weather_element ~= elements.weak_to[day_element]) then
		windower.send_command('box cast <me> '..elements.storm_of[weather_element])
	else
		windower.send_command('box cast <me> '..elements.storm_of[day_element])
	end
end

function handle_helix()
	local input = get_elements()
	local day_element = input['day_element']
	local weather_element = input['weather_element']
	local weather_intensity = input['weather_intensity']
	if weather_element ~= 'None' and (weather_intensity == 2 or weather_element ~= elements.weak_to[day_element]) then
		windower.send_command('box cast <t> '..elements.helix_of[weather_element])
	else
		windower.send_command('box cast <t> '..elements.helix_of[day_element])
	end
end

function get_duration(abilityType, abilityName, caster)
    local duration = 0
    local main_job = windower.ffxi.get_player().main_job
    
    -- Normalize input to lowercase for consistent comparison
    local name_lower = abilityName:lower()

    if abilityType == unify_prefix['/ma'] then
        local spell_recasts = windower.ffxi.get_spell_recasts()
        
        -- Case-insensitive search through resources
        local spell_id = res.spells:find(function(s) return s.en:lower() == name_lower end)
		local spell_data = res.spells[spell_id]
		abilityName = spell_data['en']
        
        local r_id = spell_data and (spell_data.recast_id or spell_data.id) or 0
        duration = (spell_recasts[r_id] and spell_recasts[r_id] > 0) and (spell_recasts[r_id] / 60) or 0
    end

    if abilityType == unify_prefix['/ja'] then
        local ja_recasts = windower.ffxi.get_ability_recasts()
        
        -- Case-insensitive search through resources
		local ja_id = res.job_abilities:find(function(j) return j.en:lower() == name_lower end)
		local ja_data = res.job_abilities[ja_id]
		abilityName = ja_data and ja_data['en'] or abilityName

		-- Your original line that was failing
		if type(ja_data) == 'table' and ja_data.recast_id then
			duration = ja_recasts[ja_data.recast_id] or 0
		end
        
        -- Fallback overrides
        if duration == 0 then
            if main_job == 'SCH' and (name_lower:contains('stratagem') or name_lower:contains('arts')) then
                duration = ja_recasts[231] or 0
				abilityName = "Stratagems"
            elseif main_job == 'PUP' and name_lower:contains('maneuver') then
                duration = ja_recasts[210] or 0
				abilityName = "Maneuver"
            elseif main_job == 'BST' then
                duration = ja_recasts[102] or 0
				abilityName = "Ready"
            end
        end
    end

    -- Create the timer
    if duration > 0 then
        local col = get_character_column(caster)
        -- Using abilityName here, but the lookup was handled via name_lower
        windower.send_command('send @all box timerui ' .. duration .. ' ' .. duration .. ' ' .. caster .. ' ' .. abilityType .. ' ' .. col .. ' "' .. abilityName .. '"')
    end
end

function create_network_timer(duration, charge_duration, abilityType, abilityName, casterName, col_index)
    local label = abilityName
	local index = casterName .. abilityName
	
	
    local ui_id = texts.new(index)
    ui_id:font('Arial')
    ui_id:size(9)
    ui_id:pos(UI_Layout.base_x + ((col_index - 1) * UI_Layout.column_width), UI_Layout.base_y + 20)
    ui_id:visible(true)
    
    active_network_timers[index] = {
        ui = ui_id,
        time_left = charge_duration,
        total_time = duration,
        column = col_index, 
        display_label = label,
        caster_name = casterName
    }
    
    reposition_column_elements(col_index)
end

windower.register_event('prerender', function()
    if not windower.ffxi.get_player() then return end
    
    local current_focus_target = target or ""
    local current_active_caster = caster or "Makaria" 
    
    for char_name, header_id in pairs(column_headers) do
        local is_caster = (char_name:lower() == current_active_caster:lower())
        local is_target = (current_focus_target ~= "<bt>" and current_focus_target ~= "" and char_name:lower() == current_focus_target:lower())
        
        local x, y = header_id:pos()

        if caster_icons[char_name] then
            caster_icons[char_name]:pos(x - 35, y - 7) 
            caster_icons[char_name]:visible(is_caster)
        end
        if target_icons[char_name] then
            target_icons[char_name]:pos(x + 67, y - 7) 
            target_icons[char_name]:visible(is_target)
        end
        
        header_id:text(char_name:upper())
    end

    local updated_columns = {}
    for label, timer in pairs(active_network_timers) do
        timer.time_left = timer.time_left - 0.0333
        if timer.time_left <= 0 then
            -- When time runs out, just destroy it. No more auto-renewing.
            timer.ui:destroy()
            updated_columns[timer.column] = true
            active_network_timers[label] = nil
        else
            -- Continue drawing the progress bar as normal
            local bar_visual = generate_progress_string(timer.time_left, timer.total_time)
            local countdown_seconds = string.format("%ds", math.ceil(timer.time_left))
            timer.ui:text(string.format(" %s %-12s %s ", bar_visual, timer.display_label, countdown_seconds))
        end
    end

    for col_index, _ in pairs(updated_columns) do
        reposition_column_elements(col_index)
    end
end)
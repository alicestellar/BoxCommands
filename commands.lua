require ('helper_functions')
local packets = require ('packets')
local res = require('resources')
local texts = require('texts')
local images = require('images') -- Load Windower's image primitive library

-- Active tracking table for ticking down live timers
active_network_timers = {}

-- Define your precise UI display layout adjustments
UI_Layout = {
    base_x = 20,      
    base_y = 200,      
    column_width = 160, 
    row_height = 18,    
    bar_width = 15,     
}

-- ====================================================================
-- INITIALIZATION & COLUMN LAYOUT SETUP
-- ====================================================================
column_headers = {}
timer_display_rows = {} 

-- Storage tables to track graphical role icons
caster_icons = {}
target_icons = {}

-- Normalized indexing table to ensure perfect mathematical mapping across all loops
local char_columns = {
    ['Makaria']  = 1,
    ['Amaranti'] = 2,
    ['Aenura']   = 3,
    ['Midnaria'] = 4,
    ['Entrapta'] = 5,
    ['Luccaria'] = 6
}

function get_character_column(char_name)
    if not char_name then return 1 end
    -- Normalize the input name to match the keys in your table
    local name = char_name:lower()
    for k, v in pairs(char_columns) do
        if k:lower() == name then
            return v
        end
    end
    return 1 -- Fallback
end

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

elements = {}
elements.list = S{'Light','Dark','Fire','Ice','Wind','Earth','Lightning','Water'}
elements.weak_to = {['Light']='Dark', ['Dark']='Light', ['Fire']='Ice', ['Ice']='Wind', ['Wind']='Earth', ['Earth']='Lightning', ['Lightning']='Water', ['Water']='Fire'}
elements.storm_of = {['Light']="Aurorastorm", ['Dark']="Voidstorm", ['Fire']="Firestorm", ['Earth']="Sandstorm", ['Water']="Rainstorm", ['Wind']="Windstorm", ['Ice']="Hailstorm", ['Lightning']="Thunderstorm"}
elements.helix_of = {['Light']="Luminohelix", ['Dark']="Noctohelix", ['Fire']="Pyrohelix", ['Earth']="Geohelix", ['Water']="Hydrohelix", ['Wind']="Anemohelix", ['Ice']="Cryohelix", ['Lightning']="Ionohelix"}
elements.of_helix = {['luminohelix']="Light", ['noctohelix']="Dark", ['pyrohelix']="Fire", ['geohelix']="Earth", ['hydrohelix']="Water", ['anemohelix']="Wind", ['cryohelix']="Ice", ['ionohelix']="Lightning"}
elements.strong_to = {['Light']='Dark', ['Dark']='Light', ['Fire']='Water', ['Ice']='Fire', ['Wind']='Ice', ['Earth']='Wind', ['Lightning']='Earth', ['Water']='Lightning'}
		
helix = {'Luminohelix','Noctohelix','Pyrohelix','Geohelix', 'Hydrohelix','Anemohelix','Cryohelix','Ionohelix'}

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

find_items = function(ids)
    local res_set = S{}
    local found = 0
    
    for bag_id = 0, 12 do 
        local bag_info = windower.ffxi.get_bag_info(bag_id)
        if bag_info and bag_info.enabled then
            for _, item in ipairs(windower.ffxi.get_items(bag_id)) do
                if item and ids:contains(item.id) then
                    local count = item.count
                    found = found + count
                    res_set:add({
                        bag = bag_id,
                        slot = item.slot,
                        count = count,
                        id = item.id,
                    })
                end
            end
        end
    end
    return res_set, found
end

function getNinjaTool(ability)
	local tools = {['katon'] = 'Uchitake', ['suiton'] = 'Mizu-Deppo', ['raiton'] = 'Hiraishin', ['doton'] = 'Makibishi',
		['huton'] = 'Kawahori-Ogi', ['hyoton'] = 'Tsurara', ['utsusemi'] = 'Shihei', ['migawari'] = 'Mokujin', ['kakka'] = 'Ryuno',
		['gekka'] = 'Ranka', ['yain'] = 'Furusumi', ['myoshu'] = 'Kabenro', ['monomi'] = 'Sanjaku-Tenugui', ['tonko'] = 'Shinobi-Tabi',
		['kurayami'] = 'Sairui-Ran', ['hojo'] = 'Kaginawa', ['dokumori'] = 'Kodoku', ['jubaku'] = 'Jusatsu', ['aisha'] = 'Soshi',
		['yurin'] = 'Jinko'}
	local bags = {['katon'] = 'Toolbag (Uchi)', ['suiton'] = 'Toolbag (Mizu)', ['raiton'] = 'Toolbag (Hira)', ['doton'] = 'Toolbag (Maki)',
		['huton'] = 'Toolbag (Kawa)', ['hyoton'] = 'Toolbag (Tsura)', ['utsusemi'] = 'Toolbag (Shihe)', ['migawari'] = 'Toolbag (Moku)', 
		['kakka'] = 'Toolbag (Ryuno)', ['gekka'] = 'Toolbag (Ranka)', ['yain'] = 'Toolbag (Furu)', ['myoshu'] = 'Toolbag (Kaben)', 
		['monomi'] = 'Toolbag (Sanja)', ['tonko'] = 'Toolbag (Shino)', ['kurayami'] = 'Toolbag (Sai)', ['hojo'] = 'Toolbag (Kagi)', 
		['dokumori'] = 'Toolbag (Kodo)', ['jubaku'] = 'Toolbag (Jusa)', ['aisha'] = 'Toolbag (Soshi)', ['yurin'] = 'Toolbag (Jinko)'}
	
	local item_name = tools[ability]
	local item_ids = (S(res.items:name(windower.wc_match-{item_name})) + S(res.items:name_log(windower.wc_match-{item_name}))):map(table.get-{'id'})
	
	item_name = bags[ability]
	local toolbag_ids = (S(res.items:name(windower.wc_match-{item_name})) + S(res.items:name_log(windower.wc_match-{item_name}))):map(table.get-{'id'})
	
	local specified_bag = ''
	if item_ids:length() == 0 then
		error('Unknown item: %s':format(item_name))
		return
	end
	local matches, results = find_items(item_ids)
	local toolbagMatches, toolbagResults = find_items(toolbag_ids)
	if (results == 0 and toolbagResults == 0) then
        error('Item "%s" not found in %s.':format(item_name, source_bag and res.bags[source_bag].name or 'any accessible bags'))
        return
    elseif (results == 0 and toolbagResults > 0) then
		for match in toolbagMatches:it() do
			windower.ffxi['get_item'](match.bag, match.slot, 1)
			windower.send_command('wait 1; input /item \'' .. item_name .. '\' <me>')
		end
	elseif results > 1 then
		for match in matches:it() do
			if match.bag == 0 then
				windower.ffxi['put_item'](6, match.slot, results - 1)
			end
		end
	else
		for match in matches:it() do
			windower.ffxi['get_item'](match.bag, match.slot, 1)
			windower.send_command('wait 1')
		end
	end
end

macro_sets = {[0] = 24, [1] = 25, [2] = 26, [3] = 27,
	[4] = 28, [5] = 29}

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

function send_set_target(t)
	windower.send_command('send '..name..' box target '..t)
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

function convertSpellLevel(input)
	local nin = {['I'] = 'Ichi', ['II'] = 'Ni', ['III'] = 'San'}
	return nin[input]
end

function select_highest_spell(ability)
	local prefix = '/ma'
    ability = ability:lower()
	
	local roman = {['II'] = 'II', ['III'] = 'III', ['IV'] = 'IV', ['V'] = 'V', ['VI'] = 'VI', ['VII'] = 'VII', ['VIII'] = 'VIII'}
	local nin = {['Ichi'] = 'Ichi', ['Ni'] = 'Ni', ['San'] = 'San'}
	local abilities = {}
	local abils = {}
	local number = 1
	local unified_prefix = unify_prefix[prefix]
	
	local check = roman
	local ninKey = ability:lower()
	if (validabils[language][unified_prefix][ability .. ': ' .. nin['Ichi']:lower()]) or tool_map[ability] then
		check = nin
		if tool_map[ability] then
			getNinjaTool(ability)
		end
		ability = ability .. ':'
	else 
		abils[number] = ability
	end
	number = number + 1
	for id, value in pairs(check) do
		abils[number] = ability .. ' ' .. value:lower()
		number = number + 1
	end
	
	number = 1
	for id, abil in pairs(abils) do 
		(function()
			local ability_id = validabils[language][unified_prefix][abil]

			if not (unified_prefix and ability_id) then
				return
			end
			
			r_line = copy_entry(res.spells[ability_id])
			
			if filter_pretarget(r_line) then
				abilities[number] = r_line
				number = number + 1
			end
		end)()
	end
	
	if not abilities[1] then
		windower.add_to_chat(122, "No valid ability with that name. "..ability)
		return
	end
	
	local maxid = '0'
	local abilityToUse
	local spell_recasts = windower.ffxi.get_spell_recasts()
	for id, value in pairs(abilities) do
		if tonumber(maxid) < tonumber(value['id']) then
			if value['mp_cost'] then
				if player.vitals.mp >= value['mp_cost'] then
					if unified_prefix == '/ma' and (value.recast_id or value.id) then
						if not spell_recasts[value.recast_id or value.id] or spell_recasts[value.recast_id or value.id] <= 0 then
							maxid = value['id']
							abilityToUse = value
						end
					end
				end
			else
				maxid = value['id']
				abilityToUse = value
			end
		end
	end
	
	if elements.of_helix[ability] and not abilityToUse then
		return select_highest_spell(elements.helix_of[elements.strong_to[elements.of_helix[ability]]])		
	end
	
	return abilityToUse
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

function trigger_pact_timer(avatar, pact_name)
    local ja_recasts = windower.ffxi.get_ability_recasts()
    local rage_recast = ja_recasts[173] or 0
    local ward_recast = ja_recasts[174] or 0
    local recast_duration = math.max(rage_recast, ward_recast)
    
    if recast_duration == 0 then recast_duration = 60 end 
	local name = rage_recast > 0 and 'Rage' or 'Ward'
    local recast_label = name
    local ward_label = pact_name

	local col = get_character_column(caster)
    windower.send_command('send @all box timerui ' .. recast_duration .. ' ' .. recast_duration .. ' ' .. caster .. ' ' .. unify_prefix['/pet'] .. ' ' .. col .. ' ' .. recast_label)

    if pact_wards.durations[pact_name] then
        local ward_duration = pact_wards.durations[pact_name]
        
        if ward_duration < 181 and player.skills and player.skills.summoning_magic then
            local skill = player.skills.summoning_magic
            if skill > 300 then
                local bonus = math.min(skill - 300, 200)
                ward_duration = ward_duration + bonus
            end
        end
		
        local col = get_character_column(caster)
    windower.send_command('send @all box timerui ' .. ward_duration .. ' ' .. ward_duration .. ' ' .. caster .. ' ' .. unify_prefix['/pet'] .. ' ' .. col .. ' ' .. ward_label)
    end
end

function get_duration(abilityType, abilityName, casterName)
    local duration = 0
    local main_job = windower.ffxi.get_player().main_job

    if abilityType == unify_prefix['/ma'] then
        local spell_recasts = windower.ffxi.get_spell_recasts()
        local spell_data = res.spells:with('en', abilityName)
        local r_id = spell_data and spell_data.recast_id or spell_data.id
        duration = spell_recasts[r_id] and (spell_recasts[r_id] / 60) or 30
    end

    if abilityType == unify_prefix['/ja'] then
        local ja_recasts = windower.ffxi.get_ability_recasts()
        local ja_data = res.job_abilities:with('en', abilityName)
        
        -- Primary lookup attempt
        if ja_data then
            duration = ja_recasts[ja_data.recast_id] or 0
        end
        
        -- Fallback overrides for charge-based abilities if the name lookup fails
        if duration == 0 then
            local name_lower = abilityName:lower()
            
            if main_job == 'SCH' and (name_lower:contains('stratagem') or name_lower:contains('arts')) then
                duration = ja_recasts[231] or 0
            elseif main_job == 'PUP' and name_lower:contains('maneuver') then
                duration = ja_recasts[210] or 0
            elseif main_job == 'BST' then
                duration = ja_recasts[102] or 0
            end
        end
    end

    -- Create the timer using the total duration for both max and current time limits
    if duration > 0 then
        local col = get_character_column(caster)
        -- Note: Changed unify_prefix['/ma'] to abilityType to ensure JAs are passed correctly
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

function reposition_column_elements(col_index)
    local current_row = 0
    for _, timer in pairs(active_network_timers) do
        if timer.column == col_index then
            local target_y = UI_Layout.base_y + (current_row * UI_Layout.row_height)
            local current_x = UI_Layout.base_x + ((col_index - 1) * UI_Layout.column_width)
            timer.ui:pos(current_x, target_y)
            current_row = current_row + 1
        end
    end
end

local function generate_progress_string(time_left, total_time)
    local max_segments = UI_Layout.bar_width
    local filled_segments = math.max(0, math.floor((time_left / total_time) * max_segments))
    local empty_segments = max_segments - filled_segments
    return "[" .. string.rep("|", filled_segments) .. string.rep(".", empty_segments) .. "]"
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
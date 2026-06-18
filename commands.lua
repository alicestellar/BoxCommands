require ('helper_functions')
local res = require('resources')
local texts = require('texts')
local settings_manager = require('settings_manager')
local macro_config = require('macro_config')

-- Active tracking table for ticking down live timers
active_network_timers = {}

-- Global flag for menu-based UI hiding (FR-4f Phase 1)
ui_hidden = false
ui_hidden_since = 0

-- Track modifier key state for menu hiding exception
local ctrl_held = false
local alt_held = false
local modifier_release_time = 0  -- Timestamp of last Ctrl/Alt release

-- Keyboard event: track Ctrl/Alt held state with release cooldown
windower.register_event('keyboard', function(dik, pressed, flags, blocked)
    if dik == 29 or dik == 157 then  -- LCtrl or RCtrl
        if pressed then
            ctrl_held = true
        else
            ctrl_held = false
            modifier_release_time = os.clock()
        end
    elseif dik == 56 or dik == 184 then  -- LAlt or RAlt
        if pressed then
            alt_held = true
        else
            alt_held = false
            modifier_release_time = os.clock()
        end
    end
end)

-- ====================================================================
-- INITIALIZATION & COLUMN LAYOUT SETUP
-- ====================================================================
column_headers = {}

-- Storage tables to track graphical role icons (arrows)
caster_icons = {}
target_icons = {}

-- Header background images
header_bgs = {}

-----------------------------------------------------------
-- Creates column header backgrounds, styled text labels,
-- and animated caster/target arrow indicators for the timer
-- UI. One column per character position (1-6).
-- Uses bar_bg.png scaled to header dimensions with
-- XivParty-inspired text styling.
-----------------------------------------------------------
function initialize_column_headers()
    -- Clean up existing primitives first
    for _, header_id in pairs(column_headers) do header_id:destroy() end
    for _, img_id in pairs(caster_icons) do img_id:destroy() end
    for _, img_id in pairs(target_icons) do img_id:destroy() end
    for _, img_id in pairs(header_bgs) do img_id:destroy() end
    
    column_headers = {}
    caster_icons = {}
    target_icons = {}
    header_bgs = {}

    -- PASS 1: Create header backgrounds FIRST (renders behind everything else)
    for i = 1, 6 do
        local char_name = settings_manager.get_slot_character(i)
        if char_name then
            local col_idx = i - 1
            local header_x = UI_Layout.base_x + (col_idx * UI_Layout.column_width)
            local header_y = UI_Layout.base_y - 24

            local hdr_bg = images.new()
            hdr_bg:fit(false)
            hdr_bg:path(windower.addon_path .. 'graphics/bar_bg.png')
            hdr_bg:size(UI_Layout.header_width, UI_Layout.header_height)
            hdr_bg:pos(header_x, header_y)
            hdr_bg:show()
            header_bgs[char_name] = hdr_bg
        end
    end

    -- PASS 2: Create arrows and text AFTER backgrounds (renders in front)
    for i = 1, 6 do
        local char_name = settings_manager.get_slot_character(i)
        if char_name then
            local col_idx = i - 1
            local header_x = UI_Layout.base_x + (col_idx * UI_Layout.column_width)
            local header_y = UI_Layout.base_y - 24

            -- Styled text label (transparent background)
            local ui_id = texts.new('box_hdr_' .. i)
            ui_id:font(UI_Style.header_font)
            ui_id:size(UI_Style.header_font_size)
            ui_id:color(UI_Style.text_color.r, UI_Style.text_color.g, UI_Style.text_color.b)
            ui_id:stroke_width(UI_Style.header_stroke_width)
            ui_id:stroke_color(UI_Style.stroke_color.r, UI_Style.stroke_color.g, UI_Style.stroke_color.b)
            ui_id:bg_visible(false)
            ui_id:text(char_name:upper())
            ui_id:pos(header_x + 4, header_y + 1)
            ui_id:visible(true)
            column_headers[char_name] = ui_id

            -- Caster arrow (cursor-r.png points right, floats LEFT of header)
            local c_img = images.new()
            c_img:fit(false)
            c_img:path(windower.addon_path .. 'graphics/cursor-r.png')
            c_img:size(16, 16)
            c_img:pos(header_x - 20, header_y + 2)
            c_img:visible(false)
            caster_icons[char_name] = c_img

            -- Target arrow (cursor-l.png points left, floats RIGHT of header)
            local t_img = images.new()
            t_img:fit(false)
            t_img:path(windower.addon_path .. 'graphics/cursor-l.png')
            t_img:size(16, 16)
            t_img:pos(header_x + UI_Layout.header_width + 2, header_y + 2)
            t_img:visible(false)
            target_icons[char_name] = t_img
        end
    end
end

-- ====================================================================
-- GLOBAL STATE
-- ====================================================================
player = initialize_globals(player)
party = windower.ffxi.get_party()
language = 'english'
target = '<t>'

-- Caster initialized from settings (position 1) or empty string.
-- Will be overwritten by boxcommands.lua on load once settings are ready.
caster = ''

-----------------------------------------------------------
-- Sets the active caster character for subsequent commands.
-- @param name  Character name string
-----------------------------------------------------------
function set_caster(name)
    if name then
        caster = name
    end
end

-----------------------------------------------------------
-- Binds hotkeys for quick character switching and targeting.
-- Ctrl+F1-F6 trigger switchto command (settings-driven).
-- Alt+F1-F6 set targets from settings positions.
-----------------------------------------------------------
function setupCommands()
    -- Read characters from settings at positions 1-6
    for i = 1, 6 do
        local char_name = settings_manager.get_slot_character(i)
        if char_name then
            -- Ctrl+F{N}: Switch caster to position N and update macro
            windower.send_command('bind ^f' .. i .. ' box switchto ' .. i)
            -- Alt+F{N}: Set target to character at position N
            windower.send_command('bind !f' .. i .. ' send @all box target ' .. char_name)
        else
            -- Unbind positions that have no character assigned
            windower.send_command('bind ^f' .. i .. ' echo BoxCommands: No character at position ' .. i)
            windower.send_command('bind !f' .. i .. ' echo BoxCommands: No character at position ' .. i)
        end
    end

    -- Alt+` targets <t> (current target) on all boxes
    windower.send_command('bind !` send @all box target <t>')
end

-----------------------------------------------------------
-- Switches macro book/set based on job using macro_config.
-- @param slot     Character name or 'default'
-- @param jobType  'main' or 'sub' job context
-----------------------------------------------------------
function set_macro(slot, jobType)
    player = initialize_globals(player)
    party = windower.ffxi.get_party()
    if not party then return end

    if jobType == 'main' then
        if slot == 'default' then
            set_macro_page(1, 1)
        else
            -- Look up current job for the caster from settings
            local char_data = settings_manager.get_character(caster)
            local job = ''
            if char_data and char_data.main_job then
                job = char_data.main_job:upper()
            end

            if job ~= '' then
                -- Check per-character override first, then global
                local macro_entry = nil
                if macro_config[caster] and macro_config[caster][job] then
                    macro_entry = macro_config[caster][job]
                elseif macro_config.global[job] then
                    macro_entry = macro_config.global[job]
                end

                if macro_entry then
                    set_macro_page(macro_entry.set, macro_entry.book)
                end
            end
        end
    elseif jobType == 'sub' then
        -- Look up sub job for the caster from settings
        local char_data = settings_manager.get_character(caster)
        local job = ''
        if char_data and char_data.sub_job then
            job = char_data.sub_job:upper()
        end

        if job ~= '' then
            local macro_entry = nil
            if macro_config[caster] and macro_config[caster][job] then
                macro_entry = macro_config[caster][job]
            elseif macro_config.global[job] then
                macro_entry = macro_config.global[job]
            end

            if macro_entry then
                set_macro_page(macro_entry.set, macro_entry.book)
            end
        end
    end
end

-----------------------------------------------------------
-- Sets the target for subsequent spell/ability commands.
-- @param t  Target string (character name, <t>, <me>, etc.)
-----------------------------------------------------------
function set_target(t)
	target = t
end

-----------------------------------------------------------
-- Resolves a pact category to the correct Blood Pact for
-- the currently active avatar, then executes it.
-- Handles Astral Flow activation and pact timers.
-- @param category  Pact category string (e.g., 'bp70', 'nuke4')
-----------------------------------------------------------
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

    -- Astral Flow pacts require the Astral Flow buff to be active first
    if cat == 'astralflow' then
        refresh_player()
        if not buffactive[369] and not buffactive['astral flow'] then
            windower.send_command('input /ja "Astral Flow" <me>; wait 1.5; input ' .. unify_prefix['/pet'] .. ' "' .. exact_pact_name .. '" ' .. final_target)
            trigger_pact_timer(avatar_name, exact_pact_name)
            return
        end
    end
	
    windower.send_command('input ' .. unify_prefix['/pet'] .. ' \"' .. exact_pact_name .. '\" ' .. final_target)
	trigger_pact_timer(avatar_name, exact_pact_name)
end

-----------------------------------------------------------
-- Casts the highest available tier of a spell on the
-- current target. Sends pretimer/timer commands for the
-- recast UI across all characters.
-- @param ability_name  Base spell name (e.g., 'cure', 'fire')
-----------------------------------------------------------
function cast_spell(ability_name)
    local spell_data = select_highest_spell(ability_name)
    if not spell_data then return end

    windower.send_command('input ' .. unify_prefix['/ma'] .. ' "' .. spell_data.en .. '" ' .. target)

	local castTime = spell_data.cast_time + 0.5
	local local_player = windower.ffxi.get_player()

	-- If we are the caster, handle pretimer locally instead of via send
	if local_player and local_player.name:lower() == caster:lower() then
		windower.send_command('@wait ' .. castTime .. '; box timer ' .. caster .. ' ' .. unify_prefix['/ma'] .. ' ' .. spell_data.en)
	else
		windower.send_command('send ' .. caster .. ' box pretimer ' .. caster .. ' ' .. unify_prefix['/ma'] .. ' ' .. castTime .. ' ' .. spell_data.en)
	end
end

-----------------------------------------------------------
-- Executes a job ability and sends a pretimer for recast tracking.
-- @param job    Unused (kept for interface compatibility)
-- @param input  Job ability name string
-----------------------------------------------------------
function job_ability(job, input)
    windower.send_command('input ' .. unify_prefix['/ja'] .. ' \"' .. input .. '\" ' .. target)
    
	windower.send_command('send ' .. caster .. ' box pretimer ' .. caster .. ' ' .. unify_prefix['/ja'] .. ' 1.5 ' .. input)
end

-----------------------------------------------------------
-- Executes a BST pet command and sends a pretimer.
-- @param input  BST pet ability name
-----------------------------------------------------------
function bstpet_command(input)
	windower.send_command('input /bstpet \"' .. input .. '\" ' .. target)
    
	windower.send_command('send ' .. caster .. ' box pretimer ' .. caster .. ' ' .. unify_prefix['/bstpet'] .. ' 1.5 ' .. input)
end

-----------------------------------------------------------
-- Executes a pet command (SMN ward, PUP maneuver, etc.)
-- and sends a pretimer for recast tracking.
-- @param input  Pet ability name
-----------------------------------------------------------
function pet_command(input)
    windower.send_command('input ' .. unify_prefix['/pet'] .. ' \"' .. input .. '\" ' .. target)
    
	windower.send_command('send ' .. caster .. ' box pretimer ' .. caster .. ' ' .. unify_prefix['/pet'] .. ' 1.5 ' .. input)
end

-----------------------------------------------------------
-- Casts the optimal storm spell based on current weather
-- and day element. Prefers weather element unless day is
-- stronger or weather is absent.
-----------------------------------------------------------
function handle_storm()
	local input = get_elements()
	local day_element = input['day_element']
	local weather_element = input['weather_element']
	local weather_intensity = input['weather_intensity']
	local old_target = target
	target = '<me>'
	if weather_element ~= 'None' and (weather_intensity == 2 or weather_element ~= elements.weak_to[day_element]) then
		cast_spell(elements.storm_of[weather_element])
	else
		cast_spell(elements.storm_of[day_element])
	end
	target = old_target
end

-----------------------------------------------------------
-- Casts the optimal helix spell based on current weather
-- and day element. Same logic as handle_storm for element
-- selection.
-----------------------------------------------------------
function handle_helix()
	local input = get_elements()
	local day_element = input['day_element']
	local weather_element = input['weather_element']
	local weather_intensity = input['weather_intensity']
	if weather_element ~= 'None' and (weather_intensity == 2 or weather_element ~= elements.weak_to[day_element]) then
		cast_spell(elements.helix_of[weather_element])
	else
		cast_spell(elements.helix_of[day_element])
	end
end

-----------------------------------------------------------
-- Queries the game for an ability's recast duration and
-- broadcasts a timerui command to all characters.
-- Handles spell recasts, JA recasts, and special cases
-- (stratagems, maneuvers, BST ready).
-- @param abilityType  Unified prefix ('/ma', '/ja', etc.)
-- @param abilityName  Ability name string
-- @param caster       Character name who used the ability
-----------------------------------------------------------
function get_duration(abilityType, abilityName, caster)
    local duration = 0
    local main_job = windower.ffxi.get_player().main_job
    
    local name_lower = abilityName:lower()

    if abilityType == unify_prefix['/ma'] then
        local spell_recasts = windower.ffxi.get_spell_recasts()
        
        local spell_id = res.spells:find(function(s) return s.en:lower() == name_lower end)
		local spell_data = res.spells[spell_id]
		abilityName = spell_data['en']
        
        local r_id = spell_data and (spell_data.recast_id or spell_data.id) or 0
        duration = (spell_recasts[r_id] and spell_recasts[r_id] > 0) and (spell_recasts[r_id] / 60) or 0
    end

    if abilityType == unify_prefix['/ja'] then
        local ja_recasts = windower.ffxi.get_ability_recasts()
        
		local ja_id = res.job_abilities:find(function(j) return j.en:lower() == name_lower end)
		local ja_data = res.job_abilities[ja_id]
		abilityName = ja_data and ja_data['en'] or abilityName

		if type(ja_data) == 'table' and ja_data.recast_id then
			duration = ja_recasts[ja_data.recast_id] or 0
		end
        
        -- Fallback overrides for shared-recast abilities
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

    if duration > 0 then
        local col = get_character_column(caster)
        windower.send_command('send @all box timerui ' .. duration .. ' ' .. duration .. ' ' .. caster .. ' ' .. abilityType .. ' ' .. col .. ' "' .. abilityName .. '"')
    end
end

-----------------------------------------------------------
-- Creates a visual timer bar in the UI for a specific
-- ability on a specific character's column. Stores the
-- ability name as a text label on the bar.
-- @param duration         Total timer duration in seconds
-- @param charge_duration  Charge time (unused, reserved)
-- @param abilityType      Unified prefix for the ability
-- @param abilityName      Display label for the timer
-- @param casterName       Character who owns this timer
-- @param col_index        UI column index for placement
-----------------------------------------------------------
function create_network_timer(duration, charge_duration, abilityType, abilityName, casterName, col_index)
    local label = abilityName
	local index = casterName .. abilityName

	-- Ensure numeric types (args come in as strings from command parsing)
	duration = tonumber(duration) or 0
	col_index = tonumber(col_index) or 1

	local x = UI_Layout.base_x + ((col_index - 1) * UI_Layout.column_width)

	-- Stack below existing timers in this column
	local row_count = 0
	for _, timer in pairs(active_network_timers) do
		if timer.column == col_index then
			row_count = row_count + 1
		end
	end
	local y = UI_Layout.base_y + UI_Layout.status_bar_gap + (row_count * UI_Layout.row_height)
	
	local new_timer = {
		time_left = duration,
		total_time = duration,
		column = col_index,
		ui = create_timer_ui(x, y, abilityName)
	}
	-- Store the label reference at the timer level for easy access
	new_timer.label = new_timer.ui.label
	active_network_timers[abilityName] = new_timer
    
    reposition_column_elements(col_index)
end

-- Prerender event: animates arrows, updates timer bars, repositions labels,
-- and handles menu-based UI hiding (FR-4f Phase 1).
windower.register_event('prerender', function()
    if not windower.ffxi.get_player() then return end

    -- ================================================================
    -- Menu hiding logic (FR-4f Phase 1)
    -- Hide UI when menu is open UNLESS Ctrl or Alt is held (macro palette).
    -- ================================================================
    local info = windower.ffxi.get_info()
    local modifier_active = ctrl_held or alt_held or (os.clock() - modifier_release_time) < 0.5
    local menu_open = info and info.menu_open and not modifier_active

    if menu_open and not ui_hidden then
        -- Menu just opened — hide all UI elements
        ui_hidden = true
        ui_hidden_since = os.clock()
        for _, hdr in pairs(column_headers) do hdr:visible(false) end
        for _, bg in pairs(header_bgs) do bg:visible(false) end
        for _, icon in pairs(caster_icons) do icon:visible(false) end
        for _, icon in pairs(target_icons) do icon:visible(false) end
        for _, timer in pairs(active_network_timers) do
            if timer.ui and timer.ui.bg then timer.ui.bg:visible(false) end
            if timer.ui and timer.ui.fg then timer.ui.fg:visible(false) end
            if timer.label then timer.label:visible(false) end
        end
        return
    elseif not menu_open and ui_hidden then
        -- Menu closed (or Ctrl/Alt now held) — show all UI elements
        ui_hidden = false
        ui_hidden_since = 0
        for _, hdr in pairs(column_headers) do hdr:visible(true) end
        for _, bg in pairs(header_bgs) do bg:visible(true) end
        for _, timer in pairs(active_network_timers) do
            if timer.ui and timer.ui.bg then timer.ui.bg:visible(true) end
            if timer.ui and timer.ui.fg then timer.ui.fg:visible(true) end
            if timer.label then timer.label:visible(true) end
        end
    end

    -- Safety: if hidden for more than 60 seconds, force-show
    if ui_hidden and (os.clock() - ui_hidden_since) > 60 then
        ui_hidden = false
        ui_hidden_since = 0
        for _, hdr in pairs(column_headers) do hdr:visible(true) end
        for _, bg in pairs(header_bgs) do bg:visible(true) end
        for _, timer in pairs(active_network_timers) do
            if timer.ui and timer.ui.bg then timer.ui.bg:visible(true) end
            if timer.ui and timer.ui.fg then timer.ui.fg:visible(true) end
            if timer.label then timer.label:visible(true) end
        end
    end

    -- If still hidden, skip all rendering updates
    if ui_hidden then return end

    -- ================================================================
    -- Arrow animation: gentle sine-wave oscillation (~2px, ~4 sec period)
    -- ================================================================
    local time = os.clock()
    local arrow_offset = math.sin(time * 1.57) * 2

    local current_focus_target = target or ""
    local current_active_caster = caster or "" 
    
    -- Update column header icons to reflect current caster/target
    for char_name, header_id in pairs(column_headers) do
        local is_caster = (char_name:lower() == current_active_caster:lower())
        local is_target = (current_focus_target ~= "<bt>" and current_focus_target ~= "" and char_name:lower() == current_focus_target:lower())

        -- Get header bg position as anchor for arrows
        local hdr_bg = header_bgs[char_name]
        if hdr_bg then
            local bx, by = hdr_bg:pos()

            -- Animate caster arrow (left side, floats left-to-right)
            if caster_icons[char_name] then
                local caster_base_x = bx - 18
                caster_icons[char_name]:pos(caster_base_x + arrow_offset, by + 2)
                caster_icons[char_name]:visible(is_caster)
            end

            -- Animate target arrow (right side, floats opposite direction)
            if target_icons[char_name] then
                local target_base_x = bx + UI_Layout.header_width + 2
                target_icons[char_name]:pos(target_base_x - arrow_offset, by + 2)
                target_icons[char_name]:visible(is_target)
            end
        end
        
        header_id:text(char_name:upper())
    end

    -- ================================================================
    -- Tick down active timers, update bar widths, reposition labels
    -- ================================================================
    local updated_columns = {}
    local expired_timers = {}
    for label, timer in pairs(active_network_timers) do
        if not timer or not timer.ui or not timer.ui.fg or not timer.ui.bg then
            expired_timers[#expired_timers + 1] = label
        else
            timer.time_left = timer.time_left - 0.0333
            
            if timer.time_left <= 0 then
                if timer.ui.bg then timer.ui.bg:destroy() end
                if timer.ui.fg then timer.ui.fg:destroy() end
                if timer.label then timer.label:destroy() end
                updated_columns[timer.column] = true
                expired_timers[#expired_timers + 1] = label
            else
                local percent = timer.time_left / timer.total_time
                local new_width = math.max(1, math.floor(UI_Style.bar_width * percent))
                timer.ui.fg:size(new_width, UI_Style.bar_height - 4)
                timer.ui.bg:size(UI_Style.bar_width, UI_Style.bar_height)

                -- Keep label positioned above its bar
                if timer.label then
                    local bx, by = timer.ui.bg:pos()
                    timer.label:pos(bx + 2, by - 6)
                end
            end
        end
    end

    for _, label in ipairs(expired_timers) do
        active_network_timers[label] = nil
    end

    for col_index, _ in pairs(updated_columns) do
        reposition_column_elements(col_index)
    end
end)

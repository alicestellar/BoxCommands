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
local modifier_press_time = 0    -- Timestamp of last Ctrl/Alt press

-- Keyboard event: track Ctrl/Alt held state
windower.register_event('keyboard', function(dik, pressed, flags, blocked)
    if dik == 29 or dik == 157 then  -- LCtrl or RCtrl
        ctrl_held = pressed
        if pressed then modifier_press_time = os.clock()
        else modifier_release_time = os.clock() end
    elseif dik == 56 or dik == 184 then  -- LAlt or RAlt
        alt_held = pressed
        if pressed then modifier_press_time = os.clock()
        else modifier_release_time = os.clock() end
    end
end)

-- ====================================================================
-- INITIALIZATION & COLUMN LAYOUT SETUP
-- ====================================================================
column_headers = {}

-- Storage tables to track graphical role icons (arrows)
caster_icons = {}
target_icons = {}

-- Storage for buff icon images per character
buff_icons = {}
-- Track last known buffs to avoid unnecessary redraws
buff_icons_last = {}

-- Header background images
header_bgs = {}

-- Storage for HP/MP/TP status bar elements per character
status_bars = {}

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
    for _, char_icons in pairs(buff_icons) do
        for _, icon in pairs(char_icons) do
            icon:destroy()
        end
    end
    for _, char_bars in pairs(status_bars) do
        for _, bar in pairs(char_bars) do
            if type(bar) == 'table' then
                if bar.bg then bar.bg:destroy() end
                if bar.fill then bar.fill:destroy() end
                if bar.label then bar.label:destroy() end
            end
        end
        -- Cleanup TP dots
        if char_bars.tp_dots then
            for _, dot in pairs(char_bars.tp_dots) do
                if dot.bg then dot.bg:destroy() end
                if dot.fill then dot.fill:destroy() end
            end
        end
    end
    
    column_headers = {}
    caster_icons = {}
    target_icons = {}
    header_bgs = {}
    status_bars = {}
    buff_icons = {}
    buff_icons_last = {}

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

            -- HP/MP/TP status bars (positioned below header)
            local bar_y_start = header_y + UI_Layout.header_height + 2
            local status_bar_height = 8
            local status_bar_spacing = 10

            local char_bars = {}

            for bar_idx, bar_type in ipairs({'HP', 'MP', 'TP'}) do
                local bar_y = bar_y_start + ((bar_idx - 1) * status_bar_spacing)
                local label_width = 16
                local bar_x = header_x + label_width
                local bar_actual_width = UI_Layout.header_width - label_width

                -- Background (border) — uses bar_bg.png which scales reliably
                local bg = images.new()
                bg:fit(false)
                bg:path(windower.addon_path .. 'graphics/bar_bg.png')
                bg:size(bar_actual_width, status_bar_height)
                bg:pos(bar_x, bar_y)
                bg:show()

                -- Fill (resized based on percentage) — uses bar_fg.png which scales reliably
                local fill = images.new()
                fill:fit(false)
                fill:path(windower.addon_path .. 'graphics/bar_fg.png')
                fill:size(bar_actual_width - 2, status_bar_height - 2)
                fill:pos(bar_x + 1, bar_y + 1)
                fill:show()

                -- Label text ("HP", "MP", "TP")
                local lbl = texts.new('box_stat_' .. i .. '_' .. bar_type)
                lbl:font(UI_Style.label_font)
                lbl:size(7)
                lbl:color(UI_Style.text_color.r, UI_Style.text_color.g, UI_Style.text_color.b)
                lbl:stroke_width(1)
                lbl:stroke_color(UI_Style.stroke_color.r, UI_Style.stroke_color.g, UI_Style.stroke_color.b)
                lbl:bg_visible(false)
                lbl:text(bar_type)
                lbl:pos(header_x, bar_y - 1)
                lbl:visible(true)

                char_bars[bar_type] = {
                    bg = bg,
                    fill = fill,
                    label = lbl,
                    max_width = bar_actual_width - 2
                }
            end

            -- TP dots: two squares side by side at the RIGHT end of the TP bar area
            -- The TP bar is shortened to make room for them
            local tp_bar_y = bar_y_start + (2 * status_bar_spacing)  -- TP is the 3rd bar (index 2)
            local tp_bar_x = header_x + 16  -- same as bar_x
            local tp_bar_actual_width = UI_Layout.header_width - 16
            local dot_size = status_bar_height  -- full bar height (8px)
            local dot_area_width = (dot_size * 2) + 2  -- two dots side by side with 2px gap
            -- Position dots at the right edge of the TP bar area
            local dot_start_x = tp_bar_x + tp_bar_actual_width - dot_area_width

            char_bars.tp_dots = {}
            -- Left dot (represents 1000 TP) — fills first
            local dot1_bg = images.new()
            dot1_bg:fit(false)
            dot1_bg:path(windower.addon_path .. 'graphics/bar_bg.png')
            dot1_bg:size(dot_size, dot_size)
            dot1_bg:pos(dot_start_x, tp_bar_y)
            dot1_bg:show()

            local dot1_fill = images.new()
            dot1_fill:fit(false)
            dot1_fill:path(windower.addon_path .. 'graphics/bar_fg.png')
            dot1_fill:size(dot_size - 2, dot_size - 2)
            dot1_fill:pos(dot_start_x + 1, tp_bar_y + 1)
            dot1_fill:visible(false)

            -- Right dot (represents 2000 TP)
            local dot2_x = dot_start_x + dot_size + 2
            local dot2_bg = images.new()
            dot2_bg:fit(false)
            dot2_bg:path(windower.addon_path .. 'graphics/bar_bg.png')
            dot2_bg:size(dot_size, dot_size)
            dot2_bg:pos(dot2_x, tp_bar_y)
            dot2_bg:show()

            local dot2_fill = images.new()
            dot2_fill:fit(false)
            dot2_fill:path(windower.addon_path .. 'graphics/bar_fg.png')
            dot2_fill:size(dot_size - 2, dot_size - 2)
            dot2_fill:pos(dot2_x + 1, tp_bar_y + 1)
            dot2_fill:visible(false)

            char_bars.tp_dots = {
                [1] = { bg = dot1_bg, fill = dot1_fill },
                [2] = { bg = dot2_bg, fill = dot2_fill }
            }
            -- Store the reduced max width for TP bar (shortened to make room for dots)
            char_bars.TP.max_width = tp_bar_actual_width - dot_area_width - 3
            -- Also shrink the TP background bar to not overlap the dots
            char_bars.TP.bg:size(tp_bar_actual_width - dot_area_width - 1, status_bar_height)

            status_bars[char_name] = char_bars

            -- Buff icon slots (positioned above header, stacking upward)
            local icon_size = UI_Style.buff_icon_size
            local icons_per_row = UI_Style.buff_icons_per_row
            local max_icons = UI_Style.buff_max_icons
            local char_buff_images = {}

            for slot = 1, max_icons do
                local row = math.ceil(slot / icons_per_row)  -- 1-based row (1 = bottom, closest to header)
                local col = ((slot - 1) % icons_per_row)     -- 0-based column

                local icon_x = header_x + (col * icon_size)
                local icon_y = header_y - (row * icon_size)  -- stack upward from header

                local icon_img = images.new()
                icon_img:fit(false)
                icon_img:size(icon_size, icon_size)
                icon_img:pos(icon_x, icon_y)
                icon_img:visible(false)

                char_buff_images[slot] = icon_img
            end

            buff_icons[char_name] = char_buff_images
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
-- Supports both named abilities and numeric shortcuts (/bstpet 1, 2, etc.)
-- @param input  BST pet ability name or number
-----------------------------------------------------------
function bstpet_command(input)
	windower.send_command('input /bstpet \"' .. input .. '\" ' .. target)
    
	windower.send_command('send ' .. caster .. ' box pretimer ' .. caster .. ' ' .. unify_prefix['/ja'] .. ' 1.5 Ready')
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
-- writes it to the shared timer file for all boxes to read.
-- Handles spell recasts, JA recasts, and special cases
-- (stratagems, maneuvers, BST ready).
-- For charge-based abilities, calculates charges on cooldown
-- and per-charge recast time.
-- @param abilityType  Unified prefix ('/ma', '/ja', etc.)
-- @param abilityName  Ability name string
-- @param caster       Character name who used the ability
-----------------------------------------------------------
function get_duration(abilityType, abilityName, caster)
    local duration = 0
    local main_job = windower.ffxi.get_player().main_job
    
    local name_lower = abilityName:lower()
    local charges_on_cooldown = 0
    local max_charges = 0
    local charge_base = 0

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

		-- Check if this is a stratagem (recast_id 231) or another shared-recast ability
		local is_stratagem = false
		if type(ja_data) == 'table' then
			-- Stratagems share recast_id 231 and have type "Scholar"
			-- Note: Light Arts (228) and Dark Arts (232) have different recast_ids
			if ja_data.recast_id == 231 then
				is_stratagem = true
			end
		end
		-- Fallback: known stratagem names (in case resource lookup failed)
		-- Does NOT include Light Arts or Dark Arts (those have separate recasts)
		if not is_stratagem then
			local stratagem_names = S{
				'addendum: white', 'addendum: black',
				'penury', 'celerity', 'accession', 'rapture', 'altruism', 'tranquility',
				'perpetuance', 'immanence', 'ebullience', 'parsimony', 'alacrity',
				'manifestation', 'indulgence', 'focalization', 'equanimity',
				'enlightenment', 'stormsurge', 'klimaform'
			}
			if stratagem_names:contains(name_lower) then
				is_stratagem = true
			end
		end

		-- For stratagems, always use the shared recast timer
		if is_stratagem then
			duration = ja_recasts[231] or 0
			abilityName = "Stratagems"
		elseif type(ja_data) == 'table' and ja_data.recast_id then
			duration = ja_recasts[ja_data.recast_id] or 0
		end
        
        -- Fallback overrides for shared-recast abilities (only if duration still 0)
        if duration == 0 then
            local pl_check = windower.ffxi.get_player()
            local sub_job = pl_check and pl_check.sub_job or ''
            if (main_job == 'SCH' or sub_job == 'SCH') and (name_lower:contains('stratagem') or name_lower:contains('arts')) then
                duration = ja_recasts[231] or 0
				abilityName = "Stratagems"
				is_stratagem = true
            elseif (main_job == 'PUP' or sub_job == 'PUP') and name_lower:contains('maneuver') then
                duration = ja_recasts[210] or 0
				abilityName = "Maneuver"
            elseif (main_job == 'BST' or sub_job == 'BST') and name_lower == 'ready' then
                duration = ja_recasts[102] or 0
				abilityName = "Ready"
            end
        end

        -- Detect charge-based abilities and calculate charge info
        local charge_info = get_charge_info(abilityName, main_job, duration)
        if charge_info then
            charge_base = charge_info.charge_base
            max_charges = charge_info.max_charges
            charges_on_cooldown = charge_info.charges_on_cooldown
            -- Keep duration as the FULL total recast (all charges)
            -- The prerender will use fmod to show per-charge bar progress
        end
    end

    if duration > 0 then
        local col = get_character_column(caster)
        local ts = require('timer_sync')
        ts.add_timer(abilityName, duration, abilityName, abilityType, col, charges_on_cooldown, max_charges, charge_base)
        -- Also create local UI timer immediately (don't wait for poll)
        create_network_timer(duration, duration, abilityType, abilityName, caster, col, charges_on_cooldown, max_charges, charge_base)
        -- Signal other boxes to check the file now
        windower.send_command('send @others box synctimers')
    end
end

-----------------------------------------------------------
-- Determines charge info for charge-based abilities.
-- Returns nil for non-charge-based abilities.
-- @param ability_name  Normalized ability name
-- @param main_job      Player's main job abbreviation
-- @param total_recast  Total recast duration from get_ability_recasts()
-- @return Table with: charge_base, max_charges, charges_on_cooldown, next_charge_recast
--         or nil if not a charge-based ability
-----------------------------------------------------------
function get_charge_info(ability_name, main_job, total_recast)
    local charge_base = 0
    local max_charges = 0

    if ability_name == "Ready" then
        -- BST Ready: 3 charges, base 30s per charge (reduced by merits/JP/gear)
        -- For now use base 30s; can refine later with merit/JP data
        charge_base = 30
        max_charges = 3
    elseif ability_name == "Stratagems" then
        -- SCH Stratagems: charges depend on SCH level (main or sub)
        -- Level 10: 2, Level 30: 3, Level 50: 4, Level 70+: 5
        local pl = windower.ffxi.get_player()
        local sch_level = 0
        if pl then
            if pl.main_job == 'SCH' then
                sch_level = pl.main_job_level or 0
            elseif pl.sub_job == 'SCH' then
                sch_level = pl.sub_job_level or 0
            end
        end
        if sch_level >= 90 then max_charges = 5
        elseif sch_level >= 70 then max_charges = 4
        elseif sch_level >= 50 then max_charges = 3
        elseif sch_level >= 30 then max_charges = 2
        else max_charges = 1
        end
        -- Total recast is always 240s base. JP 550 gift reduces to 33s/charge (165s total).
        local total_recast_base = 240
        if pl and pl.main_job == 'SCH' and sch_level >= 99 then
            local jp = pl.job_points and pl.job_points.SCH and pl.job_points.SCH.jp_spent or 0
            if jp >= 550 then
                total_recast_base = 165  -- 33s * 5 charges
            end
        end
        charge_base = math.floor(total_recast_base / max_charges)
    elseif ability_name == "Maneuver" then
        -- PUP Maneuver: 3 charges, base 10s per charge
        charge_base = 10
        max_charges = 3
    else
        return nil  -- Not a charge-based ability
    end

    if charge_base <= 0 or max_charges <= 0 then return nil end

    -- Calculate charges currently on cooldown and time to next charge
    local charges_available = math.floor(((charge_base * max_charges) - total_recast) / charge_base)
    local charges_on_cooldown = max_charges - charges_available
    -- Dots shown = charges_on_cooldown - 1 (the bar itself represents one charge)
    -- But we store total charges_on_cooldown; the UI will subtract 1 for dot display
    local next_charge_recast = math.fmod(total_recast, charge_base)
    if next_charge_recast <= 0 and total_recast > 0 then
        next_charge_recast = charge_base
    end

    return {
        charge_base = charge_base,
        max_charges = max_charges,
        charges_on_cooldown = charges_on_cooldown,
        next_charge_recast = next_charge_recast,
    }
end

-----------------------------------------------------------
-- Creates a visual timer bar in the UI for a specific
-- ability on a specific character's column. Stores the
-- ability name as a text label on the bar.
-- Uses os.clock() start_time for accurate time calculation.
-- For charge-based abilities, renders dots to the right of the bar.
-- @param duration         Total timer duration in seconds
-- @param charge_duration  Charge time (unused, reserved for FR-11)
-- @param abilityType      Unified prefix for the ability
-- @param abilityName      Display label for the timer
-- @param casterName       Character who owns this timer
-- @param col_index        UI column index for placement
-- @param charges_on_cooldown  Number of charges currently on cooldown (0 = none)
-- @param max_charges      Maximum charges for this ability (0 = not charge-based)
-----------------------------------------------------------
function create_network_timer(duration, charge_duration, abilityType, abilityName, casterName, col_index, charges_on_cooldown, max_charges, charge_base_time)
    local label = abilityName
	local index = casterName .. abilityName

	-- Ensure numeric types (args come in as strings from command parsing)
	duration = tonumber(duration) or 0
	col_index = tonumber(col_index) or 1
	charges_on_cooldown = tonumber(charges_on_cooldown) or 0
	max_charges = tonumber(max_charges) or 0
	charge_base_time = tonumber(charge_base_time) or 0

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
		start_time = os.clock(),
		column = col_index,
		ui = create_timer_ui(x, y, abilityName),
		from_file = false,
		charges_on_cooldown = charges_on_cooldown,
		max_charges = max_charges,
		charge_base = charge_base_time,
	}
	-- Store the label reference at the timer level for easy access
	new_timer.label = new_timer.ui.label

	-- Create charge dots if this is a charge-based ability
	-- Dots shown = max_charges - 1 (the bar itself is one "charge")
	local num_dots = max_charges > 0 and (max_charges - 1) or 0
	if num_dots > 0 then
		local dot_size = 8  -- Same as TP dots
		local dot_area_width = (num_dots * dot_size) + ((num_dots - 1) * 2) + 2  -- dots + gaps + padding
		-- Shrink the timer bar to make room for dots (like TP bar)
		local bar_width = UI_Style.bar_width - dot_area_width - 2
		if new_timer.ui.bg then
			new_timer.ui.bg:size(bar_width, UI_Style.bar_height)
		end
		if new_timer.ui.fg then
			new_timer.ui.fg:size(bar_width - 4, UI_Style.bar_height - 4)
		end
		-- Store reduced bar width for percentage calculations
		new_timer.bar_width = bar_width

		new_timer.charge_dots = {}
		-- Position dots to the right of the shortened bar
		local dot_start_x = x + bar_width + 2
		for dot_idx = 1, num_dots do
			local dot_x = dot_start_x + ((dot_idx - 1) * (dot_size + 2))
			local dot_y = y + math.floor((UI_Style.bar_height - dot_size) / 2)

			local dot_bg = images.new()
			dot_bg:fit(false)
			dot_bg:path(windower.addon_path .. 'graphics/bar_bg.png')
			dot_bg:size(dot_size, dot_size)
			dot_bg:pos(dot_x, dot_y)
			dot_bg:show()

			local dot_fill = images.new()
			dot_fill:fit(false)
			dot_fill:path(windower.addon_path .. 'graphics/bar_fg.png')
			dot_fill:size(dot_size - 2, dot_size - 2)
			dot_fill:pos(dot_x + 1, dot_y + 1)
			-- Filled = charge is on cooldown (queued behind the bar)
			-- charges_on_cooldown includes the one the bar is tracking,
			-- so dots filled = charges_on_cooldown - 1
			local dots_filled = charges_on_cooldown > 0 and (charges_on_cooldown - 1) or 0
			dot_fill:visible(dot_idx <= dots_filled)

			new_timer.charge_dots[dot_idx] = { bg = dot_bg, fill = dot_fill }
		end
	end

	-- Destroy any existing timer with the same key (prevents orphaned UI elements)
	local existing = active_network_timers[abilityName]
	if existing then
		if existing.ui and existing.ui.bg then existing.ui.bg:destroy() end
		if existing.ui and existing.ui.fg then existing.ui.fg:destroy() end
		if existing.label then existing.label:destroy() end
		if existing.charge_dots then
			for _, dot in pairs(existing.charge_dots) do
				if dot.bg then dot.bg:destroy() end
				if dot.fill then dot.fill:destroy() end
			end
		end
		active_network_timers[abilityName] = nil
	end

	active_network_timers[abilityName] = new_timer
    
    reposition_column_elements(col_index)

	-- If UI is currently hidden, immediately hide the new timer elements
	if ui_hidden then
		if new_timer.ui.bg then new_timer.ui.bg:visible(false) end
		if new_timer.ui.fg then new_timer.ui.fg:visible(false) end
		if new_timer.label then new_timer.label:visible(false) end
		if new_timer.charge_dots then
			for _, dot in pairs(new_timer.charge_dots) do
				if dot.bg then dot.bg:visible(false) end
				if dot.fill then dot.fill:visible(false) end
			end
		end
	end
end

-- Prerender event: animates arrows, updates timer bars, repositions labels,
-- and handles menu-based UI hiding (FR-4f Phase 1).
windower.register_event('prerender', function()
    if not windower.ffxi.get_player() then return end

    -- ================================================================
    -- Menu hiding logic (FR-4f Phase 1)
    -- Hide UI when menu is open UNLESS:
    -- - Ctrl or Alt is held (macro palette)
    -- - Player is in combat (engaged status = 1)
    -- ================================================================
    local info = windower.ffxi.get_info()
    local pl_mob = windower.ffxi.get_mob_by_target('me')
    local in_combat = pl_mob and pl_mob.status == 1
    
    -- Track how long menu has been closed (for stuck modifier reset)
    if info and info.menu_open then
        _menu_closed_since = nil
    else
        if not _menu_closed_since then
            _menu_closed_since = os.clock()
        end
        -- If menu has been closed for more than 1 second AND no recent keypress, reset stuck modifiers
        if (os.clock() - _menu_closed_since) > 1 and (os.clock() - modifier_press_time) > 0.5 then
            ctrl_held = false
            alt_held = false
        end
    end
    
    local modifier_active = ctrl_held or alt_held or (os.clock() - modifier_release_time) < 0.5
    local menu_open = info and info.menu_open and not modifier_active and not in_combat

    if menu_open and not ui_hidden then
        -- Menu just opened — hide all UI elements
        ui_hidden = true
        ui_hidden_since = os.clock()
        for _, hdr in pairs(column_headers) do hdr:visible(false) end
        for _, bg in pairs(header_bgs) do bg:visible(false) end
        for _, icon in pairs(caster_icons) do icon:visible(false) end
        for _, icon in pairs(target_icons) do icon:visible(false) end
        for _, char_bars in pairs(status_bars) do
            for key, bar in pairs(char_bars) do
                if key ~= 'tp_dots' then
                    if bar.bg then bar.bg:visible(false) end
                    if bar.fill then bar.fill:visible(false) end
                    if bar.label then bar.label:visible(false) end
                end
            end
            if char_bars.tp_dots then
                for _, dot in pairs(char_bars.tp_dots) do
                    if dot.bg then dot.bg:visible(false) end
                    if dot.fill then dot.fill:visible(false) end
                end
            end
        end
        for _, timer in pairs(active_network_timers) do
            if timer.ui and timer.ui.bg then timer.ui.bg:visible(false) end
            if timer.ui and timer.ui.fg then timer.ui.fg:visible(false) end
            if timer.label then timer.label:visible(false) end
            if timer.charge_dots then
                for _, dot in pairs(timer.charge_dots) do
                    if dot.bg then dot.bg:visible(false) end
                    if dot.fill then dot.fill:visible(false) end
                end
            end
        end
        for _, char_icons in pairs(buff_icons) do
            for _, icon in pairs(char_icons) do
                icon:visible(false)
            end
        end
        return
    elseif not menu_open and ui_hidden then
        -- Menu closed (or Ctrl/Alt now held or combat) — show all UI elements
        ui_hidden = false
        ui_hidden_since = 0
        for _, hdr in pairs(column_headers) do hdr:visible(true) end
        for _, bg in pairs(header_bgs) do bg:visible(true) end
        for _, char_bars in pairs(status_bars) do
            for key, bar in pairs(char_bars) do
                if key ~= 'tp_dots' then
                    if bar.bg then bar.bg:visible(true) end
                    if bar.fill then bar.fill:visible(true) end
                    if bar.label then bar.label:visible(true) end
                end
            end
            if char_bars.tp_dots then
                for _, dot in pairs(char_bars.tp_dots) do
                    if dot.bg then dot.bg:visible(true) end
                end
            end
        end
        for _, timer in pairs(active_network_timers) do
            if timer.ui and timer.ui.bg then timer.ui.bg:visible(true) end
            if timer.ui and timer.ui.fg then timer.ui.fg:visible(true) end
            if timer.label then timer.label:visible(true) end
            if timer.charge_dots then
                for _, dot in pairs(timer.charge_dots) do
                    if dot.bg then dot.bg:visible(true) end
                    -- dot.fill visibility depends on charge state; just show bg
                end
            end
        end
        buff_icons_last = {}
    end

    -- Safety: if hidden for more than 60 seconds, force-show
    if ui_hidden and (os.clock() - ui_hidden_since) > 60 then
        ui_hidden = false
        ui_hidden_since = 0
        for _, hdr in pairs(column_headers) do hdr:visible(true) end
        for _, bg in pairs(header_bgs) do bg:visible(true) end
        for _, char_bars in pairs(status_bars) do
            for key, bar in pairs(char_bars) do
                if key ~= 'tp_dots' then
                    if bar.bg then bar.bg:visible(true) end
                    if bar.fill then bar.fill:visible(true) end
                    if bar.label then bar.label:visible(true) end
                end
            end
            if char_bars.tp_dots then
                for _, dot in pairs(char_bars.tp_dots) do
                    if dot.bg then dot.bg:visible(true) end
                end
            end
        end
        for _, timer in pairs(active_network_timers) do
            if timer.ui and timer.ui.bg then timer.ui.bg:visible(true) end
            if timer.ui and timer.ui.fg then timer.ui.fg:visible(true) end
            if timer.label then timer.label:visible(true) end
            if timer.charge_dots then
                for _, dot in pairs(timer.charge_dots) do
                    if dot.bg then dot.bg:visible(true) end
                end
            end
        end
        buff_icons_last = {}
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
    -- Update HP/MP/TP status bars from party data
    -- ================================================================
    local party_data = windower.ffxi.get_party()
    local local_player = windower.ffxi.get_player()
    
    if party_data then
        for char_name, bars in pairs(status_bars) do
            -- Find this character in the party data
            local hpp, mpp, tp = 0, 0, 0
            
            -- Check if this is the local player first (most reliable source)
            if local_player and local_player.name and local_player.name:lower() == char_name:lower() then
                hpp = local_player.vitals and local_player.vitals.hpp or 0
                mpp = local_player.vitals and local_player.vitals.mpp or 0
                tp = local_player.vitals and local_player.vitals.tp or 0
            else
                -- Search party data for this character
                for key, member in pairs(party_data) do
                    if type(member) == 'table' and member.name and member.name:lower() == char_name:lower() then
                        hpp = member.hpp or 0
                        mpp = member.mpp or 0
                        tp = member.tp or 0
                        break
                    end
                end
            end

            -- Update HP bar fill width
            if bars.HP and bars.HP.fill then
                local hp_width = math.max(1, math.floor(bars.HP.max_width * hpp / 100))
                bars.HP.fill:size(hp_width, 6)
            end

            -- Update MP bar fill width
            if bars.MP and bars.MP.fill then
                local mp_width = math.max(1, math.floor(bars.MP.max_width * mpp / 100))
                bars.MP.fill:size(mp_width, 6)
            end

            -- Update TP bar fill width (TP is 0-3000)
            -- Bar shows current "segment" (0-1000 within each thousand)
            -- Dots show completed thousands (top dot = 1000+, bottom dot = 2000+)
            if bars.TP and bars.TP.fill then
                local thousands = math.floor(tp / 1000)  -- 0, 1, or 2
                local remainder = tp - (thousands * 1000)  -- 0-999 within current segment
                local tp_pct = remainder / 1000  -- 0.0 to 0.999
                
                -- At exactly 3000 (capped), show full bar + 2 dots
                if tp >= 3000 then
                    thousands = 2
                    tp_pct = 1.0
                end
                
                local tp_width = math.max(1, math.floor(bars.TP.max_width * tp_pct))
                bars.TP.fill:size(tp_width, 6)
                
                -- Update TP dot fills (backgrounds always visible, fills toggle)
                if bars.tp_dots then
                    for dot_idx = 1, 2 do
                        local dot = bars.tp_dots[dot_idx]
                        if dot and dot.fill then
                            dot.fill:visible(thousands >= dot_idx)
                        end
                    end
                end
            end
        end
    end

    -- ================================================================
    -- Update buff/debuff icons from party data
    -- ================================================================
    local local_pl = windower.ffxi.get_player()
    if party_data then
        for char_name, icon_slots in pairs(buff_icons) do
            -- Get buff list for this character
            local buffs = {}

            -- Local player: use get_player().buffs (more reliable)
            if local_pl and local_pl.name and local_pl.name:lower() == char_name:lower() then
                if local_pl.buffs then
                    for _, buff_id in pairs(local_pl.buffs) do
                        if buff_id and buff_id ~= 255 then
                            buffs[#buffs + 1] = buff_id
                        end
                    end
                end
            else
                -- Other party members: use get_party() buffs
                for key, member in pairs(party_data) do
                    if type(member) == 'table' and member.name and member.name:lower() == char_name:lower() then
                        if member.buffs then
                            for _, buff_id in pairs(member.buffs) do
                                if buff_id and buff_id ~= 255 then
                                    buffs[#buffs + 1] = buff_id
                                end
                            end
                        end
                        break
                    end
                end
            end

            -- Check if buffs changed since last frame (avoid unnecessary path changes)
            local buffs_key = table.concat(buffs, ',')
            if buffs_key ~= (buff_icons_last[char_name] or '') then
                buff_icons_last[char_name] = buffs_key

                -- Update icon images
                for slot = 1, UI_Style.buff_max_icons do
                    local icon_img = icon_slots[slot]
                    if icon_img then
                        if buffs[slot] then
                            icon_img:path(windower.addon_path .. 'graphics/buffIcons/' .. buffs[slot] .. '.png')
                            icon_img:visible(true)
                        else
                            icon_img:visible(false)
                        end
                    end
                end
            end
        end
    end

    -- ================================================================
    -- Timer sync: poll file every 5 seconds, sync other boxes' timers
    -- ================================================================
    local ts = require('timer_sync')
    local timers_changed, all_timers, online_changed = ts.poll()

    -- If online status changed, rebuild UI
    if online_changed then
        setupCommands()
        if initialize_column_headers then
            initialize_column_headers()
        end
    end

    -- If timers changed from file, sync UI: create new, remove gone
    if timers_changed then
        local active_from_file = ts.get_active_timers()
        local my_name = ts.get_character()

        -- Build a set of timer keys that should currently exist from OTHER boxes
        local expected_keys = {}
        for char_name, timers in pairs(active_from_file) do
            if char_name:lower() ~= (my_name or ''):lower() then
                for timer_key, entry in pairs(timers) do
                    local full_key = char_name .. ':' .. timer_key
                    expected_keys[full_key] = entry
                end
            end
        end

        -- Create UI for new timers from other boxes
        for full_key, entry in pairs(expected_keys) do
            if not active_network_timers[full_key] then
                local col_index = entry.column or 1
                local x = UI_Layout.base_x + ((col_index - 1) * UI_Layout.column_width)
                local row_count = 0
                for _, timer in pairs(active_network_timers) do
                    if timer.column == col_index then
                        row_count = row_count + 1
                    end
                end
                local y = UI_Layout.base_y + UI_Layout.status_bar_gap + (row_count * UI_Layout.row_height)

                local file_charges = entry.charges or 0
                local file_max_charges = entry.max_charges or 0
                local num_dots = file_max_charges > 0 and (file_max_charges - 1) or 0

                local new_file_timer = {
                    time_left = entry.time_left,
                    total_time = entry.total_duration,
                    start_time = entry.start_time,
                    column = col_index,
                    ui = create_timer_ui(x, y, entry.ability_name),
                    from_file = true,
                    charges_on_cooldown = file_charges,
                    max_charges = file_max_charges,
                    charge_base = entry.charge_base or 0,
                }
                new_file_timer.label = new_file_timer.ui.label

                -- Shrink bar and add dots for charge-based abilities
                if num_dots > 0 then
                    local dot_size = 8
                    local dot_area_width = (num_dots * dot_size) + ((num_dots - 1) * 2) + 2
                    local bar_width = UI_Style.bar_width - dot_area_width - 2
                    if new_file_timer.ui.bg then
                        new_file_timer.ui.bg:size(bar_width, UI_Style.bar_height)
                    end
                    if new_file_timer.ui.fg then
                        new_file_timer.ui.fg:size(bar_width - 4, UI_Style.bar_height - 4)
                    end
                    new_file_timer.bar_width = bar_width

                    new_file_timer.charge_dots = {}
                    local dot_start_x = x + bar_width + 2
                    for dot_idx = 1, num_dots do
                        local dot_x = dot_start_x + ((dot_idx - 1) * (dot_size + 2))
                        local dot_y = y + math.floor((UI_Style.bar_height - dot_size) / 2)

                        local dot_bg = images.new()
                        dot_bg:fit(false)
                        dot_bg:path(windower.addon_path .. 'graphics/bar_bg.png')
                        dot_bg:size(dot_size, dot_size)
                        dot_bg:pos(dot_x, dot_y)
                        dot_bg:show()

                        local dot_fill = images.new()
                        dot_fill:fit(false)
                        dot_fill:path(windower.addon_path .. 'graphics/bar_fg.png')
                        dot_fill:size(dot_size - 2, dot_size - 2)
                        dot_fill:pos(dot_x + 1, dot_y + 1)
                        local dots_filled = file_charges > 0 and (file_charges - 1) or 0
                        dot_fill:visible(dot_idx <= dots_filled)

                        new_file_timer.charge_dots[dot_idx] = { bg = dot_bg, fill = dot_fill }
                    end
                end

                active_network_timers[full_key] = new_file_timer
            end
        end

        -- Remove UI for timers from other boxes that no longer exist in file
        -- Only targets keys with "CharName:" prefix (other boxes' timers)
        -- Local character's restored timers use plain ability names (no colon)
        local to_remove = {}
        for label, timer in pairs(active_network_timers) do
            if timer.from_file and label:find(':') and not expected_keys[label] then
                if timer.ui and timer.ui.bg then timer.ui.bg:destroy() end
                if timer.ui and timer.ui.fg then timer.ui.fg:destroy() end
                if timer.label then timer.label:destroy() end
                if timer.charge_dots then
                    for _, dot in pairs(timer.charge_dots) do
                        if dot.bg then dot.bg:destroy() end
                        if dot.fill then dot.fill:destroy() end
                    end
                end
                to_remove[#to_remove + 1] = label
            end
        end
        for _, label in ipairs(to_remove) do
            active_network_timers[label] = nil
        end
    end

    -- ================================================================
    -- Update active timers: calculate time_left, update bar widths
    -- ================================================================
    local now = os.clock()
    local now_epoch = os.time()
    local updated_columns = {}
    local expired_timers = {}
    for label, timer in pairs(active_network_timers) do
        if not timer or not timer.ui or not timer.ui.fg or not timer.ui.bg then
            expired_timers[#expired_timers + 1] = label
        else
            -- Calculate total remaining time
            local total_remaining
            if timer.from_file then
                total_remaining = timer.total_time - (now_epoch - timer.start_time)
            elseif timer.start_time then
                total_remaining = timer.total_time - (now - timer.start_time)
            else
                timer.time_left = timer.time_left - 0.0333
                total_remaining = timer.time_left
            end
            timer.time_left = total_remaining
            
            if total_remaining <= 0 then
                if timer.ui.bg then timer.ui.bg:destroy() end
                if timer.ui.fg then timer.ui.fg:destroy() end
                if timer.label then timer.label:destroy() end
                if timer.charge_dots then
                    for _, dot in pairs(timer.charge_dots) do
                        if dot.bg then dot.bg:destroy() end
                        if dot.fill then dot.fill:destroy() end
                    end
                end
                updated_columns[timer.column] = true
                expired_timers[#expired_timers + 1] = label

                if not timer.from_file then
                    ts.remove_timer(label)
                end
            else
                local effective_bar_width = timer.bar_width or UI_Style.bar_width
                local percent

                -- Charge-based timers: bar shows current charge progress, dots show queued charges
                if timer.max_charges and timer.max_charges > 0 and timer.charges_on_cooldown and timer.charges_on_cooldown > 0 then
                    local cb = (timer.charge_base and timer.charge_base > 0) and timer.charge_base or 48
                    -- Current charge bar progress: fmod of total remaining by charge_base
                    local bar_remaining = math.fmod(total_remaining, cb)
                    if bar_remaining <= 0 and total_remaining > 0 then
                        bar_remaining = cb
                    end
                    percent = bar_remaining / cb

                    -- Dynamically update dot fills based on current charges on cooldown
                    local current_charges_on_cooldown = math.ceil(total_remaining / cb)
                    local dots_filled = current_charges_on_cooldown > 0 and (current_charges_on_cooldown - 1) or 0
                    if timer.charge_dots then
                        for dot_idx, dot in pairs(timer.charge_dots) do
                            if dot.fill then
                                dot.fill:visible(dot_idx <= dots_filled)
                            end
                        end
                    end
                else
                    -- Standard timer: simple percentage
                    percent = total_remaining / timer.total_time
                end

                local new_width = math.max(1, math.floor((effective_bar_width - 4) * percent))
                timer.ui.fg:size(new_width, UI_Style.bar_height - 4)
                timer.ui.bg:size(effective_bar_width, UI_Style.bar_height)

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

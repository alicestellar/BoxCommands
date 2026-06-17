-- settings_manager.lua
-- Manages character roster data via a custom Lua file (data/characters.lua).
-- Global addon settings still use Windower's config library (data/settings.xml).
-- Character data is fully controlled by us — no library interference.

local config = require('config')
local files = require('files')

local settings_manager = {}

-- ====================================================================
-- GLOBAL SETTINGS (via Windower config library)
-- ====================================================================
local global_defaults = {
    collapse_ui = false,
    dynamic_keybinds = false,
    skillchain_timeout = 1.0,
}

local global_settings = nil

-- ====================================================================
-- CHARACTER DATA (via custom Lua file)
-- ====================================================================
local characters = {}
local characters_file_path = windower.addon_path .. 'data/characters.lua'

-- Default per-character entry template
local character_defaults = {
    position = 0,
    online = false,
    main_job = '',
    sub_job = '',
    max_hp = {},
    show_in_ui = true,
    cure_potency = 0,
    healing_received = 0,
}

-- ====================================================================
-- SERIALIZATION HELPERS
-- ====================================================================

-----------------------------------------------------------
-- Serializes a Lua value to a source-code string.
-- Handles strings, numbers, booleans, and tables (nested).
-- @param val    The value to serialize
-- @param indent Current indentation level (for pretty-print)
-- @return String representation of the value
-----------------------------------------------------------
local function serialize_value(val, indent)
    indent = indent or 1
    local pad = string.rep('    ', indent)
    local pad_prev = string.rep('    ', indent - 1)

    if type(val) == 'string' then
        return string.format('%q', val)
    elseif type(val) == 'number' then
        return tostring(val)
    elseif type(val) == 'boolean' then
        return tostring(val)
    elseif type(val) == 'table' then
        local parts = {}
        -- Check if it's an array-like table or a dict-like table
        local is_array = (#val > 0)
        for k, v in pairs(val) do
            local key_str
            if type(k) == 'string' then
                -- Use bracket notation for keys with special chars, plain for simple keys
                if k:match('^[%a_][%w_]*$') then
                    key_str = k
                else
                    key_str = '[' .. string.format('%q', k) .. ']'
                end
            elseif type(k) == 'number' then
                key_str = '[' .. k .. ']'
            else
                key_str = '[' .. tostring(k) .. ']'
            end
            parts[#parts + 1] = pad .. key_str .. ' = ' .. serialize_value(v, indent + 1)
        end
        if #parts == 0 then
            return '{}'
        end
        return '{\n' .. table.concat(parts, ',\n') .. ',\n' .. pad_prev .. '}'
    else
        return 'nil'
    end
end

-----------------------------------------------------------
-- Serializes the entire characters table to a Lua file.
-- @param data  The characters table to serialize
-- @return String of valid Lua source that returns the table
-----------------------------------------------------------
local function serialize_characters(data)
    local lines = {}
    lines[#lines + 1] = '-- BoxCommands Character Data (auto-generated, safe to hand-edit)'
    lines[#lines + 1] = '-- Position: UI slot number (1-6 for party, 0 = unassigned)'
    lines[#lines + 1] = '-- Characters sharing a position are on the same account'
    lines[#lines + 1] = ''
    lines[#lines + 1] = 'return {'

    -- Sort by position for readability
    local sorted_names = {}
    for name, _ in pairs(data) do
        sorted_names[#sorted_names + 1] = name
    end
    table.sort(sorted_names, function(a, b)
        local pos_a = data[a].position or 0
        local pos_b = data[b].position or 0
        if pos_a == pos_b then return a < b end
        return pos_a < pos_b
    end)

    for _, name in ipairs(sorted_names) do
        local char_data = data[name]
        lines[#lines + 1] = '    [' .. string.format('%q', name) .. '] = {'
        lines[#lines + 1] = '        position = ' .. (char_data.position or 0) .. ','
        lines[#lines + 1] = '        online = ' .. tostring(char_data.online or false) .. ','
        lines[#lines + 1] = '        main_job = ' .. string.format('%q', char_data.main_job or '') .. ','
        lines[#lines + 1] = '        sub_job = ' .. string.format('%q', char_data.sub_job or '') .. ','
        -- max_hp table
        local hp_parts = {}
        if char_data.max_hp then
            for job, hp in pairs(char_data.max_hp) do
                hp_parts[#hp_parts + 1] = '[' .. string.format('%q', job) .. '] = ' .. hp
            end
        end
        if #hp_parts > 0 then
            lines[#lines + 1] = '        max_hp = { ' .. table.concat(hp_parts, ', ') .. ' },'
        else
            lines[#lines + 1] = '        max_hp = {},'
        end
        lines[#lines + 1] = '        show_in_ui = ' .. tostring(char_data.show_in_ui ~= false) .. ','
        lines[#lines + 1] = '        cure_potency = ' .. (char_data.cure_potency or 0) .. ','
        lines[#lines + 1] = '        healing_received = ' .. (char_data.healing_received or 0) .. ','
        lines[#lines + 1] = '    },'
    end

    lines[#lines + 1] = '}'
    return table.concat(lines, '\n')
end

-- ====================================================================
-- PUBLIC API
-- ====================================================================

-----------------------------------------------------------
-- Loads global settings (config library) and character data
-- (custom Lua file). Creates data directory if needed.
-----------------------------------------------------------
function settings_manager.load()
    -- Load global settings via Windower config
    global_settings = config.load(global_defaults)

    -- Ensure data directory exists
    local data_dir = windower.addon_path .. 'data/'
    if not windower.dir_exists(data_dir) then
        windower.create_dir(data_dir)
    end

    -- Load character data from custom file
    settings_manager.reload_characters()
end

-----------------------------------------------------------
-- Re-reads character data from disk. Call before writing
-- to avoid overwriting manual edits made while addon is running.
-----------------------------------------------------------
function settings_manager.reload_characters()
    local f = loadfile(characters_file_path)
    if f then
        local ok, result = pcall(f)
        if ok and type(result) == 'table' then
            characters = result
        else
            if not next(characters) then
                characters = {}
            end
            windower.add_to_chat(167, 'BoxCommands: Error reading characters.lua, keeping in-memory data.')
        end
    else
        -- File doesn't exist yet — keep whatever is in memory (may be empty)
        if not next(characters) then
            characters = {}
        end
    end
end

-----------------------------------------------------------
-- Saves character data to the custom Lua file.
-----------------------------------------------------------
function settings_manager.save()
    local content = serialize_characters(characters)
    local f = io.open(characters_file_path, 'w')
    if f then
        f:write(content)
        f:close()
    else
        windower.add_to_chat(123, 'BoxCommands: Failed to write characters.lua!')
    end
end

-----------------------------------------------------------
-- Returns the global settings table.
-- @return Global settings (collapse_ui, dynamic_keybinds, etc.)
-----------------------------------------------------------
function settings_manager.get_global_settings()
    return global_settings
end

-----------------------------------------------------------
-- Registers a new character if not already present.
-- Auto-assigns the lowest available position (1-6).
-- If all slots are taken, assigns position 0 with a chat message.
-- @param name  Character name to register
-----------------------------------------------------------
function settings_manager.register_character(name)
    if not name or name == '' then return end

    -- Case-insensitive check for existing entry
    for existing_name, _ in pairs(characters) do
        if existing_name:lower() == name:lower() then
            return -- Already registered
        end
    end

    -- Find the lowest available position (1-6)
    local used_positions = {}
    for _, char_data in pairs(characters) do
        if char_data.position and char_data.position > 0 then
            used_positions[char_data.position] = true
        end
    end

    local assigned_position = 0
    for i = 1, 6 do
        if not used_positions[i] then
            assigned_position = i
            break
        end
    end

    -- Create the new character entry
    local new_char = {}
    for k, v in pairs(character_defaults) do
        if type(v) == 'table' then
            new_char[k] = {}
        else
            new_char[k] = v
        end
    end
    new_char.position = assigned_position

    characters[name] = new_char

    if assigned_position == 0 then
        windower.add_to_chat(207, 'BoxCommands: New character "' .. name .. '" registered at position 0 (unassigned). Edit data/characters.lua to assign a slot.')
    else
        windower.add_to_chat(207, 'BoxCommands: Registered "' .. name .. '" at position ' .. assigned_position .. '.')
    end

    settings_manager.save()
end

-----------------------------------------------------------
-- Updates the online status for a character.
-- Re-reads the file first to avoid overwriting manual edits.
-- @param name    Character name
-- @param status  Boolean online status
-----------------------------------------------------------
function settings_manager.set_online(name, status)
    -- Re-read file to pick up any manual edits before writing
    settings_manager.reload_characters()
    local char_data = settings_manager.get_character(name)
    if not char_data then return end
    char_data.online = status
    settings_manager.save()
end

-----------------------------------------------------------
-- Updates the main and sub job fields for a character.
-- Re-reads the file first to avoid overwriting manual edits.
-- @param name      Character name
-- @param main_job  Main job abbreviation (e.g., 'WHM')
-- @param sub_job   Sub job abbreviation (e.g., 'SCH')
-----------------------------------------------------------
function settings_manager.update_job(name, main_job, sub_job)
    -- Re-read file to pick up any manual edits before writing
    settings_manager.reload_characters()
    local char_data = settings_manager.get_character(name)
    if not char_data then return end
    char_data.main_job = main_job or ''
    char_data.sub_job = sub_job or ''
end

-----------------------------------------------------------
-- Updates the max HP value for a specific job on a character.
-- Re-reads the file first to avoid overwriting manual edits.
-- @param name  Character name
-- @param job   Job abbreviation (e.g., 'WHM')
-- @param hp    Max HP value for that job
-----------------------------------------------------------
function settings_manager.update_max_hp(name, job, hp)
    -- Re-read file to pick up any manual edits before writing
    settings_manager.reload_characters()
    local char_data = settings_manager.get_character(name)
    if not char_data then return end
    if not char_data.max_hp then
        char_data.max_hp = {}
    end
    char_data.max_hp[job] = hp
    settings_manager.save()
end

-----------------------------------------------------------
-- Returns the data table for a specific character.
-- Case-insensitive lookup.
-- @param name  Character name
-- @return Character data table, or nil if not found
-----------------------------------------------------------
function settings_manager.get_character(name)
    if not name then return nil end
    -- Direct match first
    if characters[name] then return characters[name] end
    -- Case-insensitive fallback
    for existing_name, data in pairs(characters) do
        if existing_name:lower() == name:lower() then
            return data
        end
    end
    return nil
end

-----------------------------------------------------------
-- Returns a list of online characters ordered by position.
-- @return Ordered table of {name=, data=} entries
-----------------------------------------------------------
function settings_manager.get_online_characters()
    local online_chars = {}
    for name, data in pairs(characters) do
        if data.online then
            online_chars[#online_chars + 1] = { name = name, data = data }
        end
    end

    table.sort(online_chars, function(a, b)
        local pos_a = a.data.position or 0
        local pos_b = b.data.position or 0
        if pos_a == 0 then return false end
        if pos_b == 0 then return true end
        return pos_a < pos_b
    end)

    return online_chars
end

-----------------------------------------------------------
-- Returns the online character assigned to a given slot position.
-- @param position  Slot number (1-6)
-- @return Character name at that position (online preferred), or first found
-----------------------------------------------------------
function settings_manager.get_slot_character(position)
    -- Prefer online character at this position
    for name, data in pairs(characters) do
        if data.position == position and data.online then
            return name
        end
    end
    -- Fallback: any character at this position
    for name, data in pairs(characters) do
        if data.position == position then
            return name
        end
    end
    return nil
end

return settings_manager

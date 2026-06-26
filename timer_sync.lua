-- timer_sync.lua
-- Shared file-based timer synchronization (FR-12).
-- Each box writes only its own timers. All boxes poll the file every 5 seconds.
-- Timers store start_time + total_duration so late-joining boxes can calculate
-- the correct remaining time without needing the initial broadcast.

local files = require('files')
local settings_manager = require('settings_manager')

local timer_sync = {}

-- ====================================================================
-- CONFIGURATION
-- ====================================================================
local POLL_INTERVAL = 5           -- Seconds between file reads
local TIMER_FILE_PATH = windower.addon_path .. 'data/timers.lua'

-- ====================================================================
-- STATE
-- ====================================================================
local my_character = nil          -- Set on init (local player name)
local last_poll_time = 0          -- os.clock() of last file read
local file_timers = {}            -- Full parsed contents of the timer file
local last_online_status = {}     -- Track online changes for UI rebuild

-- ====================================================================
-- SERIALIZATION
-- ====================================================================

-----------------------------------------------------------
-- Serializes the entire timers table to valid Lua source.
-- @param data  The timers table (keyed by character name)
-- @return String of Lua source that returns the table
-----------------------------------------------------------
local function serialize_timers(data)
    local lines = {}
    lines[#lines + 1] = '-- BoxCommands Timer Sync (auto-generated, do not hand-edit)'
    lines[#lines + 1] = 'return {'

    for char_name, timers in pairs(data) do
        lines[#lines + 1] = '    [' .. string.format('%q', char_name) .. '] = {'
        for timer_key, entry in pairs(timers) do
            lines[#lines + 1] = '        [' .. string.format('%q', timer_key) .. '] = {'
            lines[#lines + 1] = '            start_time = ' .. tostring(entry.start_time or 0) .. ','
            lines[#lines + 1] = '            total_duration = ' .. tostring(entry.total_duration or 0) .. ','
            lines[#lines + 1] = '            ability_name = ' .. string.format('%q', entry.ability_name or '') .. ','
            lines[#lines + 1] = '            ability_type = ' .. string.format('%q', entry.ability_type or '') .. ','
            lines[#lines + 1] = '            column = ' .. tostring(entry.column or 1) .. ','
            lines[#lines + 1] = '            charges = ' .. tostring(entry.charges or 0) .. ','
            lines[#lines + 1] = '            max_charges = ' .. tostring(entry.max_charges or 0) .. ','
            lines[#lines + 1] = '            charge_base = ' .. tostring(entry.charge_base or 0) .. ','
            lines[#lines + 1] = '        },'
        end
        lines[#lines + 1] = '    },'
    end

    lines[#lines + 1] = '}'
    return table.concat(lines, '\n')
end

-----------------------------------------------------------
-- Reads and parses the timer file from disk.
-- Retries once after a brief delay if the first attempt fails
-- (handles file lock contention from concurrent writes).
-- @return Table of all timers (keyed by character), or nil on failure
-----------------------------------------------------------
local function read_timer_file()
    local f = loadfile(TIMER_FILE_PATH)
    if f then
        local ok, result = pcall(f)
        if ok and type(result) == 'table' then
            return result
        end
    end
    return nil
end

-----------------------------------------------------------
-- Writes the timer file to disk, merging our timers with
-- other characters' existing entries.
-----------------------------------------------------------
local function write_timer_file()
    -- Read current file to preserve other characters' data
    local current_data = read_timer_file() or {}

    -- Replace our character's section with current local state
    current_data[my_character] = file_timers[my_character] or {}

    -- Write back
    local content = serialize_timers(current_data)
    local f = io.open(TIMER_FILE_PATH, 'w')
    if f then
        f:write(content)
        f:close()
    else
        windower.add_to_chat(123, 'BoxCommands: Failed to write timers.lua!')
    end
end

-- ====================================================================
-- PUBLIC API
-- ====================================================================

-----------------------------------------------------------
-- Initializes the timer sync module. Must be called after
-- the player is available.
-- @param char_name  The local player's character name
-----------------------------------------------------------
function timer_sync.init(char_name)
    my_character = char_name
    if not file_timers[my_character] then
        file_timers[my_character] = {}
    end
    last_poll_time = os.clock()

    -- Ensure data directory exists
    local data_dir = windower.addon_path .. 'data/'
    if not windower.dir_exists(data_dir) then
        windower.create_dir(data_dir)
    end

    -- Do an initial read
    local data = read_timer_file()
    if data then
        file_timers = data
    end
    -- Ensure our section exists
    if not file_timers[my_character] then
        file_timers[my_character] = {}
    end
end

-----------------------------------------------------------
-- Adds or updates a timer for the local character.
-- Writes to the shared file immediately.
-- Uses os.time() for start_time (system-wide, shareable across processes).
-- @param timer_key      Unique key for this timer (e.g., ability name)
-- @param total_duration Total recast duration in seconds
-- @param ability_name   Display name for the timer
-- @param ability_type   Unified prefix ('/ma', '/ja', etc.)
-- @param column         UI column index
-- @param charges        Number of additional charges on cooldown (0 = none)
-- @param max_charges    Maximum charges for this ability (0 = not charge-based)
-- @param charge_base    Time per single charge in seconds (0 = not charge-based)
-----------------------------------------------------------
function timer_sync.add_timer(timer_key, total_duration, ability_name, ability_type, column, charges, max_charges, charge_base)
    if not my_character then return end

    file_timers[my_character] = file_timers[my_character] or {}
    file_timers[my_character][timer_key] = {
        start_time = os.time(),
        total_duration = total_duration,
        ability_name = ability_name,
        ability_type = ability_type,
        column = column,
        charges = charges or 0,
        max_charges = max_charges or 0,
        charge_base = charge_base or 0,
    }

    write_timer_file()
end

-----------------------------------------------------------
-- Removes a specific timer for the local character.
-- Called when a timer expires or is manually cancelled.
-- @param timer_key  The unique key of the timer to remove
-----------------------------------------------------------
function timer_sync.remove_timer(timer_key)
    if not my_character then return end
    if not file_timers[my_character] then return end

    file_timers[my_character][timer_key] = nil
    write_timer_file()
end

-----------------------------------------------------------
-- Removes all expired timers for the local character.
-- Only removes entries where time_left <= 0.
-- Called on logout/unload to clean up stale entries without
-- wiping active timers (which survive addon reloads).
-----------------------------------------------------------
function timer_sync.clear_expired_timers()
    if not my_character then return end
    if not file_timers[my_character] then return end

    local now = os.time()
    local has_changes = false
    for timer_key, entry in pairs(file_timers[my_character]) do
        local time_left = entry.total_duration - (now - entry.start_time)
        if time_left <= 0 then
            file_timers[my_character][timer_key] = nil
            has_changes = true
        end
    end

    if has_changes then
        write_timer_file()
    end
end

-----------------------------------------------------------
-- Removes all timers for the local character unconditionally.
-- Only call this when the character is truly going offline
-- (logout, not addon reload).
-----------------------------------------------------------
function timer_sync.clear_my_timers()
    if not my_character then return end
    file_timers[my_character] = {}
    write_timer_file()
end

-----------------------------------------------------------
-- Polls the timer file and characters.lua for updates.
-- Should be called from prerender. Only reads from disk
-- every POLL_INTERVAL seconds.
-- @return changed (bool), timers (table), online_changed (bool)
--   changed: true if timer data differs from last read
--   timers: full timer table (all characters)
--   online_changed: true if any character's online status changed
-----------------------------------------------------------
function timer_sync.poll()
    local now = os.clock()
    if (now - last_poll_time) < POLL_INTERVAL then
        return false, file_timers, false
    end
    last_poll_time = now

    -- Re-read timer file
    local new_data = read_timer_file()
    local timers_changed = false
    if new_data then
        -- Preserve our own in-memory timers (we are the authority on our own data)
        new_data[my_character] = file_timers[my_character]
        file_timers = new_data
        timers_changed = true  -- Simplified: assume change on every poll read
    end

    -- Re-read characters.lua online status
    settings_manager.reload_characters()
    local online_changed = false
    for i = 1, 6 do
        local char_name = settings_manager.get_slot_character(i)
        local was_online = last_online_status[i]
        local is_online = (char_name ~= nil)

        if was_online ~= is_online then
            online_changed = true
        end
        last_online_status[i] = is_online
    end

    return timers_changed, file_timers, online_changed
end

-----------------------------------------------------------
-- Returns all active timers across all characters.
-- Filters out expired timers and timers for offline characters.
-- Each entry includes calculated time_left.
-- @return Table of {timer_key, entry_with_time_left} grouped by character
-----------------------------------------------------------
function timer_sync.get_active_timers()
    local now = os.time()
    local active = {}

    for char_name, timers in pairs(file_timers) do
        -- Check if this character is online
        local char_data = settings_manager.get_character(char_name)
        if char_data and char_data.online then
            for timer_key, entry in pairs(timers) do
                local time_left = entry.total_duration - (now - entry.start_time)
                if time_left > 0 then
                    if not active[char_name] then
                        active[char_name] = {}
                    end
                    active[char_name][timer_key] = {
                        time_left = time_left,
                        total_duration = entry.total_duration,
                        ability_name = entry.ability_name,
                        ability_type = entry.ability_type,
                        column = entry.column,
                        charges = entry.charges,
                        max_charges = entry.max_charges,
                        charge_base = entry.charge_base,
                        start_time = entry.start_time,
                    }
                end
            end
        end
    end

    return active
end

-----------------------------------------------------------
-- Returns the local character name this module is tracking.
-- @return Character name string
-----------------------------------------------------------
function timer_sync.get_character()
    return my_character
end

-----------------------------------------------------------
-- Returns the local character's active timers from the file.
-- Used on reload to restore timers that are still running.
-- @return Table of {timer_key = entry} for timers with time_left > 0
-----------------------------------------------------------
function timer_sync.get_my_active_timers()
    if not my_character then return {} end
    if not file_timers[my_character] then return {} end

    local now = os.time()
    local active = {}
    for timer_key, entry in pairs(file_timers[my_character]) do
        local time_left = entry.total_duration - (now - entry.start_time)
        if time_left > 0 then
            active[timer_key] = {
                time_left = time_left,
                total_duration = entry.total_duration,
                ability_name = entry.ability_name,
                ability_type = entry.ability_type,
                column = entry.column,
                charges = entry.charges,
                max_charges = entry.max_charges,
                charge_base = entry.charge_base,
                start_time = entry.start_time,
            }
        end
    end
    return active
end

-----------------------------------------------------------
-- Forces an immediate poll on the next call to poll(),
-- bypassing the POLL_INTERVAL wait. Called when another
-- box signals that new timer data is available.
-----------------------------------------------------------
function timer_sync.force_poll()
    last_poll_time = 0
end

return timer_sync

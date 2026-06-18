require('tables')
res = require('resources')
require('data_tables')
images = require('images') -- Load Windower's image primitive library

buffactive = {}

-----------------------------------------------------------
-- Creates an empty equipment item table for a given slot.
-- @param slot  The inventory slot index
-- @return Table with zeroed fields and slot set
-----------------------------------------------------------
function make_empty_item_table(slot)
    return {id=0,
    count = 0,
    bazaar = 0,
    extdata = string.char(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    status = 0,
    slot = slot}
end

-----------------------------------------------------------
-- Normalizes a key for case-insensitive table lookups.
-- @param val  The key value (string or other)
-- @return Lowercased string, or original value if not string
-----------------------------------------------------------
function user_key_filter(val)
    if type(val) == 'string' then
        val = string.lower(val)
    end
    return val
end

user_data_table = {
    __newindex = function(tab, key, val)
            rawset(tab, user_key_filter(key), val)
        end,

    __index = function(tab, key)
        return rawget(tab, user_key_filter(key))
    end
    }

-----------------------------------------------------------
-- Creates a table with case-insensitive string keys.
-- @return New table with user_data_table metatable applied
-----------------------------------------------------------
function make_user_table()
    return setmetatable({}, user_data_table)
end

-----------------------------------------------------------
-- Registers a single ability into the validabils lookup
-- for one language.
-- @param abil  Resource entry (spell/JA/WS/item)
-- @param lang  Language key ('english', 'french', etc.)
-- @param i     Resource ID for lookup
-----------------------------------------------------------
function make_abil(abil,lang,i)
    if not abil[lang] or not abil.prefix then return end
    local sp,pref = abil[lang]:lower(), unify_prefix[abil.prefix:lower()]
    validabils[lang][pref][sp] = i
end

-----------------------------------------------------------
-- Registers an ability across all four languages.
-- @param v  Resource entry
-- @param i  Resource ID
-----------------------------------------------------------
function make_entry(v,i)
    make_abil(v,'english',i)
    make_abil(v,'german',i)
    make_abil(v,'french',i)
    make_abil(v,'japanese',i)
end

-- Populate validabils lookup tables from game resources
for i,v in pairs(res.spells) do
    if not T{363,364}:contains(i) then
        make_entry(v,i)
    end
end

for i,v in pairs(res.job_abilities) do
    make_entry(v,i)
end

for i,v in pairs(res.weapon_skills) do
    v.type = 'WeaponSkill'
    make_entry(v,i)
end

for i,v in pairs(res.monster_skills) do
    v.type = 'MonsterSkill'
    make_entry(v,i)
end

for i,v in pairs(res.items) do
    v.prefix = '/item'
    if not validabils['english'][v.prefix][v.english:lower()] or v.cast_delay then
        make_entry(v,i)
    end
end

-----------------------------------------------------------
-- Deep-copies a resource entry preserving its metatable.
-- @param tab  Source table to copy
-- @return New table with same contents and metatable, or nil
-----------------------------------------------------------
function copy_entry(tab)
    if not tab then return nil end
    local ret = setmetatable(table.reassign({},tab),getmetatable(tab))
    return ret
end

-----------------------------------------------------------
-- Validates whether a spell can be cast by the current player.
-- Checks: known spells, job access, addendum requirements,
-- blue magic sets, and ninjutsu tool availability.
-- @param available_spells  Table from windower.ffxi.get_spells()
-- @param spell             Spell resource entry to validate
-- @return true if castable, or false + error message string
-----------------------------------------------------------
function check_spell(available_spells,spell)
    refresh_player()
	-- Filter for spells that you do not know.
    -- Exclude Impact / Dispelga / Honor March if the respective slots are enabled.
    local spell_jobs = copy_entry(res.spells[spell.id].levels)
    if not available_spells[spell.id] and not (
            (not disable_table[5] and not disable_table[4] and spell.id == 503) or -- Body + Head + Impact
            (not disable_table[2] and (spell.id == 417 or spell.id == 418)) or -- Range + Honor March + Aria of Passion
            ((not disable_table[0] or not disable_table[1]) and spell.id == 360) -- Main or Sub + Dispelga
        ) then
        return false,"Unable to execute command. You do not know that spell ("..(res.spells[spell.id][language] or spell.id)..")"
    elseif (not spell_jobs[player.main_job_id] or not (spell_jobs[player.main_job_id] <= player.main_job_level or
        (spell_jobs[player.main_job_id] >= 100 and number_of_jps(player.job_points[__raw.lower(res.jobs[player.main_job_id].ens)]) >= spell_jobs[player.main_job_id]) ) ) and
        (not spell_jobs[player.sub_job_id] or not (spell_jobs[player.sub_job_id] <= player.sub_job_level)) and not (player.main_job_id == 23) then
        return false,"Unable to execute command. You do not have access to that spell ("..(res.spells[spell.id][language] or spell.id)..")"
    elseif player.main_job_id == 20 and ((addendum_white[spell.id] and not buffactive[401] and not buffactive[416]) or
        (addendum_black[spell.id] and not buffactive[402] and not buffactive[416])) and
        not (spell_jobs[player.sub_job_id] and spell_jobs[player.sub_job_id] <= player.sub_job_level) then
        return false,"Unable to execute command. Addendum required for that spell ("..(res.spells[spell.id][language] or spell.id)..")"
    elseif player.sub_job_id == 20 and ((addendum_white[spell.id] and not buffactive[401] and not buffactive[416]) or
        (addendum_black[spell.id] and not buffactive[402] and not buffactive[416])) and
        not (spell_jobs[player.main_job_id] and (spell_jobs[player.main_job_id] <= player.main_job_level or
        (spell_jobs[player.main_job_id] >= 100 and number_of_jps(player.job_points[__raw.lower(res.jobs[player.main_job_id].ens)]) >= spell_jobs[player.main_job_id]) ) ) then
        return false,"Unable to execute command. Addendum required for that spell ("..(res.spells[spell.id][language] or spell.id)..")"
    elseif spell.type == 'BlueMagic' and not ((player.main_job_id == 16 and table.contains(windower.ffxi.get_mjob_data().spells,spell.id)) 
        or unbridled_learning_set[spell.english]) and
        not (player.sub_job_id == 16 and table.contains(windower.ffxi.get_sjob_data().spells,spell.id)) then
        return false,"Unable to execute command. Blue magic must be set to cast that spell ("..(res.spells[spell.id][language] or spell.id)..")"
    elseif spell.type == 'Ninjutsu'  then
        if player.main_job_id ~= 13 and player.sub_job_id ~= 13 then
            return false,"Unable to make action packet. You do not have access to that spell ("..(spell[language] or spell.id)..")"
        elseif not player.inventory[tool_map[spell.english][language]] and not (player.main_job_id == 13 and player.inventory[universal_tool_map[spell.english][language]]) then
            return false,"Unable to make action packet. You do not have the proper tools."
        end
    end
    return true
end

-----------------------------------------------------------
-- Pre-target validation for outgoing actions.
-- Checks spell knowledge, WS/JA availability, and
-- monstrosity access before allowing an action to proceed.
-- @param action  The action resource entry to validate
-- @return true if action is permitted, false otherwise
-----------------------------------------------------------
function filter_pretarget(action)
    local category = outgoing_action_category_table[unify_prefix[action.prefix]]
    local bool = true
    local err
    if category == 3 then
        local available_spells = windower.ffxi.get_spells()
        bool,err = check_spell(available_spells,action)
    elseif category == 7 then
        local available = windower.ffxi.get_abilities().weapon_skills
        if not table.contains(available,action.id) then
            bool,err = false,"Unable to execute command. You do not have access to that weapon skill."
        end
    elseif category == 9 then
        local available = windower.ffxi.get_abilities().job_abilities
        if not table.contains(available,action.id) then
            bool,err = false,"Unable to execute command. You do not have access to that job ability."
        end
    elseif category == 25 and (not player.main_job_id == 23 or not windower.ffxi.get_mjob_data().species or
        not res.monstrosity[windower.ffxi.get_mjob_data().species] or not res.monstrosity[windower.ffxi.get_mjob_data().species].tp_moves[action.id] or
        not (res.monstrosity[windower.ffxi.get_mjob_data().species].tp_moves[action.id] <= player.main_job_level)) then
        msg.debugging("Unable to execute command. You do not have access to that monsterskill ("..(res.monster_skills[action.id][language] or action.id)..")")
        return false
    end

    if err then
        --windower.add_to_chat(1, err)
    end
    return bool
end

-----------------------------------------------------------
-- Initializes the global player, pet, fellow, and items
-- state from the current game data.
-- @param player  Existing player table (will be replaced)
-- @return Fully initialized player table
-----------------------------------------------------------
function initialize_globals(player)
    local pl = windower.ffxi.get_player()
    if not pl then
        player = make_user_table()
        player.vitals = {}
        player.buffs = {}
        player.skills = {}
        player.jobs = {}
        player.merits = {}
    else
        player = make_user_table()
        table.reassign(player,pl)
        if not player.vitals then player.vitals = {} end
        if not player.buffs then player.buffs = {} end
        if not player.skills then player.skills = {} end
        if not player.jobs then player.jobs = {} end
        if not player.merits then player.merits = {} end
    end

    player.equipment = make_user_table()
    pet = make_user_table()
    pet.isvalid = false
    fellow = make_user_table()
    fellow.isvalid = false
    partybuffs = {}

    items = windower.ffxi.get_items()
    if not items then
        items = {
                equipment = {},
            }
        for id,name in pairs(default_slot_map) do
            items.equipment[name] = {slot = empty,bag_id=0}
        end
    else
        if not items.equipment then
            items.equipment = {}
            for id,name in pairs(default_slot_map) do
                items.equipment[name] = {slot = empty,bag_id=0}
            end
        else
            for id,name in pairs(default_slot_map) do
                items.equipment[name] = {
                    slot   = items.equipment[name],
                    bag_id = items.equipment[name..'_bag']
                    }
                    items.equipment[name..'_bag'] = nil
                if items.equipment[name].slot == 0 then items.equipment[name].slot = empty end
            end
        end
    end
    for i in pairs(windower.ffxi.get_bag_info()) do
        if not items[i] then items[i] = make_inventory_table()
        else items[i][0] = make_empty_item_table(0) end
    end
	return player
end

-----------------------------------------------------------
-- Refreshes party/alliance data from the game state.
-- Splits party members into alliance[1..3][1..6] structure
-- with count fields and leader references.
-- @param party      Current party reference (reassigned)
-- @param partyinfo  Game info table (reassigned)
-- @return party, partyinfo  Updated references
-----------------------------------------------------------
function refresh_group_info(party, partyinfo)
    if not alliance or #alliance == 0 then
        alliance = make_alliance()
    end
    
	partyinfo = windower.ffxi.get_info()
	
    local c_alliance = make_alliance()
    
    local j = windower.ffxi.get_party() or {}
    
    c_alliance.leader = j.alliance_leader
    c_alliance[1].leader = j.party1_leader
    c_alliance[2].leader = j.party2_leader
    c_alliance[3].leader = j.party3_leader
    
    for i,v in pairs(j) do
        if type(v) == 'table' and v.mob and v.mob.race then
            v.mob.race_id = v.mob.race
            v.mob.race = res.races[v.mob.race][language]
			v.job = 0
        end
        
        local allyIndex
        local partyIndex
        
        if i:sub(1,1) == 'p' and tonumber(i:sub(2)) then
            allyIndex = 1
            partyIndex = tonumber(i:sub(2))+1
        elseif tonumber(i:sub(2,2)) and tonumber(i:sub(3)) then
            allyIndex = tonumber(i:sub(2,2))+1
            partyIndex = tonumber(i:sub(3))+1
        end
        
        if allyIndex and partyIndex then
            c_alliance[allyIndex][partyIndex] = v
            c_alliance[allyIndex].count = c_alliance[allyIndex].count + 1
            c_alliance.count = c_alliance.count + 1
            
            if v.mob then
                if v.mob.id == c_alliance[1].leader then
                    c_alliance[1].leader = v
                elseif v.mob.id == c_alliance[2].leader then
                    c_alliance[2].leader = v
                elseif v.mob.id == c_alliance[3].leader then
                    c_alliance[3].leader = v
                end
                
                if v.mob.id == c_alliance.leader then
                    c_alliance.leader = v
                end
            end
        end
    end

    -- Clear the old structure while maintaining the party references:
    for ally_party = 1,3 do
        for i,v in pairs(alliance[ally_party]) do
            alliance[ally_party][i] = nil
        end
        alliance[ally_party].count = 0
    end
    alliance.count = 0
    alliance.leader = nil
    
    -- Reassign to the new structure
    table.reassign(alliance[1],c_alliance[1])
    table.reassign(alliance[2],c_alliance[2])
    table.reassign(alliance[3],c_alliance[3])
    alliance.count = c_alliance.count
    alliance.leader = c_alliance.leader
	party = alliance[1]
	return party, partyinfo
end

-----------------------------------------------------------
-- Creates a blank alliance structure with 3 parties.
-- @return Empty alliance table with count/leader fields
-----------------------------------------------------------
function make_alliance()
    local all = make_user_table()
    all[1]={count=0,leader=nil}
    all[2]={count=0,leader=nil}
    all[3]={count=0,leader=nil}
    all.count=0
    all.leader=nil
    return all
end

-----------------------------------------------------------
-- Debug utility: recursively serializes a table to string.
-- @param o  Value to serialize
-- @return String representation of the value
-----------------------------------------------------------
function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

-----------------------------------------------------------
-- Filters a timer list to only entries with recast > 0.
-- @param timer_list  Table of {key = recast_seconds}
-- @return Table containing only active (>0) timers
-----------------------------------------------------------
function filter_active_timers(timer_list)
    local active_list = {}
    
    for key, value in pairs(timer_list) do
        if value > 0 then
            active_list[key] = value
        end
    end
    
    return active_list
end

-----------------------------------------------------------
-- Sets the in-game macro page and optionally book.
-- @param set   Macro set number (1-10)
-- @param book  Optional macro book number (1-40)
-----------------------------------------------------------
function set_macro_page(set,book)
	if not tonumber(set) then
		windower.add_to_chat(1,'Error setting macro page: Set is not a valid number ('..tostring(set)..').')
		return
	end
	if set < 1 or set > 10 then
		windower.add_to_chat(1,'Error setting macro page: Macro set ('..tostring(set)..') must be between 1 and 10.')
		return
	end

	if book then
		if not tonumber(book) then
			windower.add_to_chat(1,'Error setting macro page: book is not a valid number ('..tostring(book)..').')
			return
		end
		if book < 1 or book > 40 then
			windower.add_to_chat(1,'Error setting macro page: Macro book ('..tostring(book)..') must be between 1 and 40.')
			return
		end
		windower.send_command('@input /macro book '..tostring(book)..';wait .1;input /macro set '..tostring(set))
	else
		windower.send_command('@input /macro set '..tostring(set))
	end
end

-----------------------------------------------------------
-- Queries current day and weather elements from the game.
-- @return Table with day_element, weather_element, weather_intensity
-----------------------------------------------------------
function get_elements()
	local info = windower.ffxi.get_info()
	local output = {['day_element']='',['weather_element']='',['weather_intensity']=''}
	for i,v in pairs(info) do
        if i == 'day' and res.days[v] then
			output['day_element'] = res.elements[res.days[v].element][language]
        elseif i == 'weather' and res.weather[v] then
            local elements = weather_update(v)
			output['weather_element'] = elements['element']
			output['weather_intensity'] = elements['intensity']
		end
    end
	return output
end

-----------------------------------------------------------
-- Extracts element name and intensity from a weather ID.
-- @param id  Weather resource ID
-- @return Table with 'element' and 'intensity' keys
-----------------------------------------------------------
function weather_update(id)
	local output = {['element']='',['intensity']=''}
	weather_id = id
	output['element'] = res.elements[res.weather[id].element][language]
	output['intensity'] = res.weather[weather_id].intensity
	return output
end

-----------------------------------------------------------
-- Checks if a value exists in an ipairs-iterable table.
-- @param tab  Table to search
-- @param val  Value to find
-- @return true if found, false otherwise
-----------------------------------------------------------
function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

-----------------------------------------------------------
-- Debug utility: prints a table recursively with indentation.
-- Detects cyclic references to prevent infinite recursion.
-- @param t  Table to print
-----------------------------------------------------------
function print_r(t)
    indent = 0
    local indent_str = string.rep("  ", indent)

    local printed_tables = printed_tables or {}
    if printed_tables[t] then
        print(indent_str .. "table: " .. tostring(t) .. " (cyclic)")
        return
    end
    printed_tables[t] = true

    print(indent_str .. "{")
    for key, value in pairs(t) do
        local key_str = tostring(key)
        io.write(indent_str .. "  [" .. key_str .. "] = ")

        if type(value) == "table" then
            print_r(value, indent + 1)
        else
            print(tostring(value))
        end
    end
    print(indent_str .. "}")

    printed_tables[t] = nil
end

-----------------------------------------------------------
-- Refreshes the global player state and buffactive table
-- from current game data.
-----------------------------------------------------------
function refresh_player()
    local pl, player_mob_table
	local temp = {}
	pl = windower.ffxi.get_player()
	if not pl or not pl.vitals then return end

	player_mob_table = windower.ffxi.get_mob_by_index(pl.index)
	if not player_mob_table then return end

	table.reassign(temp,pl)
	
	table.reassign(buffactive,convert_buff_list(temp.buffs))
	player = pl
end

-----------------------------------------------------------
-- Converts a raw buff ID list into a name-indexed count table.
-- Each buff is indexed by both its string name and numeric ID.
-- @param bufflist  Array of active buff IDs
-- @return Table keyed by buff name/id with count values
-----------------------------------------------------------
function convert_buff_list(bufflist)
    local buffarr = {}
    for _,id in pairs(bufflist) do
        if res.buffs[id] then
            local buff = res.buffs[id][language]:lower()
            if buffarr[buff] then
                buffarr[buff] = buffarr[buff] +1
            else
                buffarr[buff] = 1
            end

            if buffarr[id] then
                buffarr[id] = buffarr[id] +1
            else
                buffarr[id] = 1
            end
        end
    end
    return buffarr
end

-----------------------------------------------------------
-- Returns the UI column index for a character name.
-- Reads from settings_manager positions (1-6).
-- @param char_name  Character name to look up
-- @return Column index (1-based), defaults to 1 if not found
-----------------------------------------------------------
function get_character_column(char_name)
    if not char_name then return 1 end
    local sm = require('settings_manager')
    local char_data = sm.get_character(char_name)
    if char_data and char_data.position and char_data.position > 0 then
        return char_data.position
    end
    return 1
end

-----------------------------------------------------------
-- Searches all accessible inventory bags for items matching
-- a set of IDs.
-- @param ids  Set of item IDs to search for
-- @return res_set (Set of match tables), found (total count)
-----------------------------------------------------------
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

-----------------------------------------------------------
-- Ensures ninjutsu tools are available in inventory.
-- Retrieves from storage or opens toolbags as needed.
-- @param ability  Ninjutsu base name (e.g., 'katon', 'utsusemi')
-----------------------------------------------------------
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

-----------------------------------------------------------
-- Selects and validates the highest tier of a spell the
-- player can currently cast. Handles roman numeral tiers,
-- ninjutsu tiers, MP cost checks, and recast timers.
-- Falls back to the opposing-element helix if unavailable.
-- @param ability  Base spell name (e.g., 'cure', 'katon')
-- @return Spell resource entry of the highest castable tier, or nil
-----------------------------------------------------------
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

-----------------------------------------------------------
-- Triggers Blood Pact recast and ward duration timers
-- after a summoner pact is executed.
-- @param avatar     Name of the active avatar
-- @param pact_name  Name of the pact that was used
-----------------------------------------------------------
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

-----------------------------------------------------------
-- Repositions all timer bars and their labels in a column
-- after one expires. Stacks remaining timers vertically
-- without gaps.
-- @param col_index  Column index to reposition (1-based)
-----------------------------------------------------------
function reposition_column_elements(col_index)
    local current_row = 0
    for _, timer in pairs(active_network_timers) do
        if timer.column == col_index then
            local target_y = UI_Layout.base_y + UI_Layout.status_bar_gap + (current_row * UI_Layout.row_height)
            local current_x = UI_Layout.base_x + ((col_index - 1) * UI_Layout.column_width)
            
            if timer.ui.bg then
                timer.ui.bg:pos(current_x, target_y)
                timer.ui.bg:size(UI_Style.bar_width, UI_Style.bar_height)
            end
            
            if timer.ui.fg then
                timer.ui.fg:pos(current_x + UI_Layout.bar_padding.x, target_y + UI_Layout.bar_padding.y)
            end

            -- Reposition the text label above the bar
            if timer.label then
                timer.label:pos(current_x + 2, target_y - 6)
            end
            
            current_row = current_row + 1
        end
    end
end

-----------------------------------------------------------
-- Creates a new timer bar UI element (background + foreground)
-- with an overlaid text label showing the ability name.
-- Each timer gets its own image and text instances.
-- @param x           X position for the bar
-- @param y           Y position for the bar
-- @param label_text  Optional ability name to display on the bar
-- @return Table with .bg, .fg image handles and .label text handle
-----------------------------------------------------------
function create_timer_ui(x, y, label_text)
    local bar = {}
    
    bar.bg = images.new()
    bar.bg:fit(false)
    bar.bg:path(windower.addon_path .. 'graphics/bar_bg.png')
    bar.bg:size(UI_Style.bar_width, UI_Style.bar_height)
    bar.bg:pos(x, y)
    bar.bg:show()

    bar.fg = images.new()
    bar.fg:fit(false)
    bar.fg:path(windower.addon_path .. 'graphics/bar_fg.png')
    bar.fg:size(UI_Style.bar_width - 4, UI_Style.bar_height - 4)
    bar.fg:pos(x + UI_Layout.bar_padding.x, y + UI_Layout.bar_padding.y)
    bar.fg:show()

    -- Text label overlaid on the bar (transparent background, XivParty-style)
    if label_text then
        local unique_name = 'box_lbl_' .. tostring(os.clock()):gsub('%.', '') .. '_' .. tostring(math.random(1000, 9999))
        local texts = require('texts')
        bar.label = texts.new(unique_name)
        bar.label:font(UI_Style.label_font)
        bar.label:size(UI_Style.label_font_size)
        bar.label:color(UI_Style.text_color.r, UI_Style.text_color.g, UI_Style.text_color.b)
        bar.label:stroke_width(UI_Style.label_stroke_width)
        bar.label:stroke_color(UI_Style.stroke_color.r, UI_Style.stroke_color.g, UI_Style.stroke_color.b)
        bar.label:bg_visible(false)
        bar.label:text(label_text)
        bar.label:pos(x + 2, y - 6)
        bar.label:show()
    end
    
    return bar
end

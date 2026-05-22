require('tables')
socket = require 'socket'
extdata = require('extdata')
res = require('resources')
require('data_tables')
images = require('images') -- Load Windower's image primitive library

buffactive = {}

-----------------------------------------------------------------------------------
----Name: make_empty_item_table(slot)
-- Make an empty item table with slot = slot
----Args:
-- slot - The index of the item table
-----------------------------------------------------------------------------------
----Returns:
-- A zero'd table with slot = slot
-----------------------------------------------------------------------------------
function make_empty_item_table(slot)
    return {id=0,
    count = 0,
    bazaar = 0,
    extdata = string.char(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
    status = 0,
    slot = slot}
end

-----------------------------------------------------------------------------------
--Name: user_key_filter()
--Args:
---- val (key): potential key to be modified
-----------------------------------------------------------------------------------
--Returns:
---- Filtered key
-----------------------------------------------------------------------------------
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

-----------------------------------------------------------------------------------
--Name: make_user_table()
--Args:
---- None
-----------------------------------------------------------------------------------
--Returns:
---- Table with case-insensitive keys
-----------------------------------------------------------------------------------
function make_user_table()
    return setmetatable({}, user_data_table)
end

function make_abil(abil,lang,i)
    if not abil[lang] or not abil.prefix then return end
    local sp,pref = abil[lang]:lower(), unify_prefix[abil.prefix:lower()]
    validabils[lang][pref][sp] = i
end

function make_entry(v,i)
    make_abil(v,'english',i)
    make_abil(v,'german',i)
    make_abil(v,'french',i)
    make_abil(v,'japanese',i)
end

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

function copy_entry(tab)
    if not tab then return nil end
    local ret = setmetatable(table.reassign({},tab),getmetatable(tab))
    return ret
end

function check_spell(available_spells,spell)
    refresh_player()
	-- Filter for spells that you do not know.
    -- Exclude Impact / Dispelga / Honor March if the respective slots are enabled.
    -- Need to add logic to check whether the equipment is already on
    local spell_jobs = copy_entry(res.spells[spell.id].levels)
    if not available_spells[spell.id] and not (
            (not disable_table[5] and not disable_table[4] and spell.id == 503) or -- Body + Head + Impact
            (not disable_table[2] and (spell.id == 417 or spell.id == 418)) or -- Range + Honor March + Aria of Passion
            ((not disable_table[0] or not disable_table[1]) and spell.id == 360) -- Main or Sub + Dispelga
        ) then
        return false,"Unable to execute command. You do not know that spell ("..(res.spells[spell.id][language] or spell.id)..")"
    -- Filter for spells that you know, but do not currently have access to
    elseif (not spell_jobs[player.main_job_id] or not (spell_jobs[player.main_job_id] <= player.main_job_level or
        (spell_jobs[player.main_job_id] >= 100 and number_of_jps(player.job_points[__raw.lower(res.jobs[player.main_job_id].ens)]) >= spell_jobs[player.main_job_id]) ) ) and
        (not spell_jobs[player.sub_job_id] or not (spell_jobs[player.sub_job_id] <= player.sub_job_level)) and not (player.main_job_id == 23) then
        return false,"Unable to execute command. You do not have access to that spell ("..(res.spells[spell.id][language] or spell.id)..")"
    -- At this point, we know that it is technically castable by this job combination if the right conditions are met.
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
        -- This code isn't hurting anything, but it doesn't need to be here either.
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
        -- Monstrosity filtering
        msg.debugging("Unable to execute command. You do not have access to that monsterskill ("..(res.monster_skills[action.id][language] or action.id)..")")
        return false
    end

    if err then
        --windower.add_to_chat(1, err)
    end
    return bool
end

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

    -- GearSwap effectively needs to maintain two inventory structures:
    --  one is the proposed current inventory based on equip packets sent to the server,
    --  the other is the currently reported inventory based on packets sent from the server.
    -- The problem with proposed_inv is that it doesn't know when actions force items to unequip or prevent them from equipping.
    -- The problem with reported_inv is that packets can be dropped, so it doesn't always report everything accurately.
    -- In an ideal world, gearswap would maintain a registry of expected changes for each slot,
    --  and would advance along the registry as changes are reported by the server.
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

-----------------------------------------------------------------------------------
--Name: refresh_group_info()
--Args:
---- None
-----------------------------------------------------------------------------------
--Returns:
---- None
----
---- Takes the mob arrays from windower.ffxi.get_party() and splits them from p0~5, a10~15, a20~25
---- into alliance[1][1~6], alliance[2][1~6], alliance[3][1~6], respectively.
---- Also adds a "count" field to alliance (total number of people in alliance) and
---- to the individual subtables (total number of people in each party.
-----------------------------------------------------------------------------------
function refresh_group_info(party, partyinfo)
    if not alliance or #alliance == 0 then
        alliance = make_alliance()
    end
    
	partyinfo = windower.ffxi.get_info()
	
    local c_alliance = make_alliance()
    
    local j = windower.ffxi.get_party() or {}
    
    c_alliance.leader = j.alliance_leader -- Test whether this works
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
        
        -- For 'p#', ally index is 1, party index is the second char
        if i:sub(1,1) == 'p' and tonumber(i:sub(2)) then
            allyIndex = 1
            partyIndex = tonumber(i:sub(2))+1
        -- For 'a##', ally index is the second char, party index is the third char
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

-----------------------------------------------------------------------------------
--Name: make_alliance()
--Args:
---- none
-----------------------------------------------------------------------------------
--Returns:
---- one blank alliance structure
-----------------------------------------------------------------------------------
function make_alliance()
    local all = make_user_table()
    all[1]={count=0,leader=nil}
    all[2]={count=0,leader=nil}
    all[3]={count=0,leader=nil}
    all.count=0
    all.leader=nil
    return all
end

-----------------------------------------------------------------------------------
--Name: convert_buff_list(bufflist)
--Args:
---- bufflist (table): List of buffs from windower.ffxi.get_player()['buffs']
-----------------------------------------------------------------------------------
--Returns:
---- buffarr (table)
---- buffarr is indexed by the string buff name and has a value equal to the number
---- of that string present in the buff array. So two marches would give
---- buffarr.march==2.
-----------------------------------------------------------------------------------
function convert_buff_list(bufflist)
    local buffarr = {}
    for i,v in pairs(bufflist) do
        if res.buffs[v] then -- For some reason we always have buff 255 active, which doesn't have an entry.
            local buff = res.buffs[v][language]:lower()
            if buffarr[buff] then
                buffarr[buff] = buffarr[buff] +1
            else
                buffarr[buff] = 1
            end
            
            if buffarr[v] then
                buffarr[v] = buffarr[v] +1
            else
                buffarr[v] = 1
            end
        end
    end
    return buffarr
end

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

function filter_active_timers(timer_list)
    local active_list = {}
    
    for key, value in pairs(timer_list) do
        -- Check if the value (recast) is greater than 0
        if value > 0 then
            active_list[key] = value
        end
    end
    
    return active_list
end

-------------------------------------------------------------------------------------------------------------------
-- Function to easily change to a given macro set or book.  Book value is optional.
-------------------------------------------------------------------------------------------------------------------

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

function weather_update(id)
	local output = {['element']='',['intensity']=''}
	weather_id = id
	output['element'] = res.elements[res.weather[id].element][language]
	output['intensity'] = res.weather[weather_id].intensity
	return output
end

function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function print_r(t)
    indent = 0
    local indent_str = string.rep("  ", indent)

    -- Detect and prevent infinite recursion with cyclic tables
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

function send_set_target(t)
	windower.send_command('send '..name..' box target '..t)
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

function reposition_column_elements(col_index)
    local current_row = 0
    for _, timer in pairs(active_network_timers) do
        if timer.column == col_index then
            local target_y = UI_Layout.base_y + (current_row * UI_Layout.row_height)
            local current_x = UI_Layout.base_x + ((col_index - 1) * UI_Layout.column_width)
            
            -- Update Background Position
            if timer.ui.bg then
                timer.ui.bg:pos(current_x, target_y)
            end
            
            -- Update Foreground Position (Apply padding to keep it inside the border)
            if timer.ui.fg then
                timer.ui.fg:pos(current_x + UI_Layout.bar_padding.x, target_y + UI_Layout.bar_padding.y)
            end
            
            current_row = current_row + 1
        end
    end
end

function generate_progress_string(time_left, total_time)
    local max_segments = UI_Layout.bar_width
    local filled_segments = math.max(0, math.floor((time_left / total_time) * max_segments))
    local empty_segments = max_segments - filled_segments
    return "[" .. string.rep("|", filled_segments) .. string.rep(".", empty_segments) .. "]"
end

function create_timer_ui(x, y)
    local bar = {}
    
    -- 1. Create the objects as empty primitives first
    bar.bg = master_textures.bg
    bar.fg = master_textures.fg
    
    -- 3. Set your specific sizes
    bar.bg:size(120, 14) 
    bar.fg:size(116, 10)
    
    -- 4. Position and show
    bar.bg:pos(x, y)
    bar.fg:pos(x + 2, y + 2)
    
    bar.bg:show()
    bar.fg:show()
    
    return bar
end
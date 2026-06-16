-- data_tables.lua
-- Static configuration tables for BoxCommands: UI layout, elemental mappings,
-- ability prefix unification, ninjutsu tools, and summoner pact data.

require('sets')
local res = require('resources')

-- ====================================================================
-- UI & LAYOUT TABLES
-- ====================================================================
UI_Layout = {
    base_x = 20,      
    base_y = 200,      
    column_width = 160, 
    row_height = 18,    
    bar_width = 15,     
}

-- Maps character names to their UI column index (1-based)
char_columns = {
    ['Makaria']  = 1,
    ['Amaranti'] = 2,
    ['Aenura']   = 3,
    ['Midnaria'] = 4,
    ['Entrapta'] = 5,
    ['Luccaria'] = 6
}

-- ====================================================================
-- MAGIC & ELEMENTAL TABLES
-- ====================================================================
elements = {}
elements.list = S{'Light','Dark','Fire','Ice','Wind','Earth','Lightning','Water'}
elements.weak_to = {['Light']='Dark', ['Dark']='Light', ['Fire']='Ice', ['Ice']='Wind', ['Wind']='Earth', ['Earth']='Lightning', ['Lightning']='Water', ['Water']='Fire'}
elements.storm_of = {['Light']="Aurorastorm", ['Dark']="Voidstorm", ['Fire']="Firestorm", ['Earth']="Sandstorm", ['Water']="Rainstorm", ['Wind']="Windstorm", ['Ice']="Hailstorm", ['Lightning']="Thunderstorm"}
elements.helix_of = {['Light']="Luminohelix", ['Dark']="Noctohelix", ['Fire']="Pyrohelix", ['Earth']="Geohelix", ['Water']="Hydrohelix", ['Wind']="Anemohelix", ['Ice']="Cryohelix", ['Lightning']="Ionohelix"}
elements.of_helix = {['luminohelix']="Light", ['noctohelix']="Dark", ['pyrohelix']="Fire", ['geohelix']="Earth", ['hydrohelix']="Water", ['anemohelix']="Wind", ['cryohelix']="Ice", ['ionohelix']="Lightning"}
elements.strong_to = {['Light']='Dark', ['Dark']='Light', ['Fire']='Water', ['Ice']='Fire', ['Wind']='Ice', ['Earth']='Wind', ['Lightning']='Earth', ['Water']='Lightning'}

-- ====================================================================
-- GAME DATA & CONFIGURATION TABLES
-- ====================================================================

-- Maps party slot indices to macro book numbers
macro_sets = {[0] = 24, [1] = 25, [2] = 26, [3] = 27, [4] = 28, [5] = 29}

-- Ability lookup tables indexed by [language][prefix][name] = resource_id
validabils = {}
validabils['english'] = {['/ma'] = {}, ['/ja'] = {}, ['/ws'] = {}, ['/item'] = {}, ['/ra'] = {}, ['/ms'] = {}, ['/pet'] = {}, ['/trig'] = {}, ['/echo'] = {}}
validabils['french'] = {['/ma'] = {}, ['/ja'] = {}, ['/ws'] = {}, ['/item'] = {}, ['/ra'] = {}, ['/ms'] = {}, ['/pet'] = {}, ['/trig'] = {}, ['/echo'] = {}}
validabils['german'] = {['/ma'] = {}, ['/ja'] = {}, ['/ws'] = {}, ['/item'] = {}, ['/ra'] = {}, ['/ms'] = {}, ['/pet'] = {}, ['/trig'] = {}, ['/echo'] = {}}
validabils['japanese'] = {['/ma'] = {}, ['/ja'] = {}, ['/ws'] = {}, ['/item'] = {}, ['/ra'] = {}, ['/ms'] = {}, ['/pet'] = {}, ['/trig'] = {}, ['/echo'] = {}}

-- Equipment slot disable flags (indexed 0-14), used by check_spell for Impact/Dispelga/Honor March
disable_table = {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false}
disable_table[0] = false

-- Normalizes all command prefix variants to their canonical form
unify_prefix = {['/ma'] = '/ma', ['/magic']='/ma',['/jobability'] = '/ja',['/ja']='/ja',['/item']='/item',['/song']='/ma',
['/so']='/ma',['/ninjutsu']='/ma',['/weaponskill']='/ws',['/ws']='/ws',['/ra']='/ra',['/rangedattack']='/ra',['/nin']='/ma',
['/throw']='/ra',['/range']='/ra',['/shoot']='/ra',['/monsterskill']='/ms',['/ms']='/ms',['/pet']='/ja',['Monster']='Monster',['/bstpet']='/ja'}

-- Maps unified prefixes to outgoing action packet category IDs
outgoing_action_category_table = {['/ma']=3,['/ws']=7,['/ja']=9,['/ra']=16,['/ms']=25}

-- Equipment slot index to name mapping
default_slot_map = T{'sub','range','ammo','head','body','hands','legs','feet','neck','waist', 'left_ear', 'right_ear', 'left_ring', 'right_ring','back'}
default_slot_map[0]= 'main'

-- Scholar addendum spell lists (spells requiring Addendum: White/Black)
addendum_white = {[14]="Poisona",[15]="Paralyna",[16]="Blindna",[17]="Silena",[18]="Stona",[19]="Viruna",[20]="Cursna",
    [143]="Erase",[13]="Raise II",[140]="Raise III",[141]="Reraise II",[142]="Reraise III",[135]="Reraise"}

addendum_black = {[253]="Sleep",[259]="Sleep II",[260]="Dispel",[162]="Stone IV",[163]="Stone V",[167]="Thunder IV",
    [168]="Thunder V",[157]="Aero IV",[158]="Aero V",[152]="Blizzard IV",[153]="Blizzard V",[147]="Fire IV",[148]="Fire V",
    [172]="Water IV",[173]="Water V",[255]="Break"}

-- ====================================================================
-- NINJUTSU TOOL MAPPING
-- ====================================================================

-- Maps ninjutsu spell names to their required tool
tool_map = {
    ['Utsusemi: Ichi'] = {english='Shihei'}, ['Utsusemi: Ni'] = {english='Shihei'}, ['Utsusemi: San'] = {english='Shihei'},
    ['Monomi: Ichi'] = {english='Sanjaku-Tenugui'}, ['Tonko: Ichi'] = {english='Shinobi-Tabi'}, ['Tonko: Ni'] = {english='Shinobi-Tabi'},
    ['Katon: Ichi'] = {english='Uchitake'}, ['Katon: Ni'] = {english='Uchitake'}, ['Katon: San'] = {english='Uchitake'},
    ['Hyoton: Ichi'] = {english='Tsurara'}, ['Hyoton: Ni'] = {english='Tsurara'}, ['Hyoton: San'] = {english='Tsurara'},
    ['Huton: Ichi'] = {english='Kawahori-Ogi'}, ['Huton: Ni'] = {english='Kawahori-Ogi'}, ['Huton: San'] = {english='Kawahori-Ogi'},
    ['Doton: Ichi'] = {english='Makibishi'}, ['Doton: Ni'] = {english='Makibishi'}, ['Doton: San'] = {english='Makibishi'},
    ['Raiton: Ichi'] = {english='Hiraishin'}, ['Raiton: Ni'] = {english='Hiraishin'}, ['Raiton: San'] = {english='Hiraishin'},
    ['Suiton: Ichi'] = {english='Mizu-Deppo'}, ['Suiton: Ni'] = {english='Mizu-Deppo'}, ['Suiton: San'] = {english='Mizu-Deppo'},
    ['Kurayami: Ichi'] = {english='Sairui-Ran'}, ['Kurayami: Ni'] = {english='Sairui-Ran'},
    ['Hojo: Ichi'] = {english='Kaginawa'}, ['Hojo: Ni'] = {english='Kaginawa'},
    ['Dokumori: Ichi'] = {english='Kodoku'}, ['Jubaku: Ichi'] = {english='Jusatsu'},
    ['Migawari: Ichi'] = {english='Mokujin'}, ['Kakka: Ichi'] = {english='Ryuno'},
    ['Gekka: Ichi'] = {english='Ranka'}, ['Yain: Ichi'] = {english='Furusumi'},
    ['Myoshu: Ichi'] = {english='Kabenro'}, ['Aisha: Ichi'] = {english='Soshi'},
    ['Yurin: Ichi'] = {english='Jinko'}
}

-- Maps ninjutsu spell names to universal (NIN main only) substitute tools
universal_tool_map = {
    ['Utsusemi: Ichi'] = {english='Ino-Shika-Cho'}, ['Utsusemi: Ni'] = {english='Ino-Shika-Cho'}, ['Utsusemi: San'] = {english='Ino-Shika-Cho'},
    ['Monomi: Ichi'] = {english='Chonmage'}, ['Tonko: Ichi'] = {english='Chonmage'}, ['Tonko: Ni'] = {english='Chonmage'},
    ['Katon: Ichi'] = {english='Sanjaku-Tenugui'}, ['Katon: Ni'] = {english='Sanjaku-Tenugui'}, ['Katon: San'] = {english='Sanjaku-Tenugui'},
    ['Hyoton: Ichi'] = {english='Sanjaku-Tenugui'}, ['Hyoton: Ni'] = {english='Sanjaku-Tenugui'}, ['Hyoton: San'] = {english='Sanjaku-Tenugui'},
    ['Huton: Ichi'] = {english='Sanjaku-Tenugui'}, ['Huton: Ni'] = {english='Sanjaku-Tenugui'}, ['Huton: San'] = {english='Sanjaku-Tenugui'},
    ['Doton: Ichi'] = {english='Sanjaku-Tenugui'}, ['Doton: Ni'] = {english='Sanjaku-Tenugui'}, ['Doton: San'] = {english='Sanjaku-Tenugui'},
    ['Raiton: Ichi'] = {english='Sanjaku-Tenugui'}, ['Raiton: Ni'] = {english='Sanjaku-Tenugui'}, ['Raiton: San'] = {english='Sanjaku-Tenugui'},
    ['Suiton: Ichi'] = {english='Sanjaku-Tenugui'}, ['Suiton: Ni'] = {english='Sanjaku-Tenugui'}, ['Suiton: San'] = {english='Sanjaku-Tenugui'},
    ['Kurayami: Ichi'] = {english='Sanjaku-Tenugui'}, ['Kurayami: Ni'] = {english='Sanjaku-Tenugui'},
    ['Hojo: Ichi'] = {english='Sanjaku-Tenugui'}, ['Hojo: Ni'] = {english='Sanjaku-Tenugui'},
    ['Dokumori: Ichi'] = {english='Sanjaku-Tenugui'}, ['Jubaku: Ichi'] = {english='Sanjaku-Tenugui'},
    ['Migawari: Ichi'] = {english='Ino-Shika-Cho'}, ['Kakka: Ichi'] = {english='Chonmage'},
    ['Gekka: Ichi'] = {english='Chonmage'}, ['Yain: Ichi'] = {english='Chonmage'},
    ['Myoshu: Ichi'] = {english='Chonmage'}, ['Aisha: Ichi'] = {english='Soshi'},
    ['Yurin: Ichi'] = {english='Jinko'}
}

-- ====================================================================
-- SUMMONER BLOOD PACT DATA TABLES
-- ====================================================================

-- Maps pact categories to avatar-specific pact names
pacts = {
    ['cure'] = {['Carbuncle']='Healing Ruby'},
    ['curaga'] = {['Carbuncle']='Healing Ruby II', ['Garuda']='Whispering Wind', ['Leviathan']='Spring Water'},
    ['buffoffense'] = {['Carbuncle']='Glittering Ruby', ['Ifrit']='Crimson Howl', ['Garuda']='Hastega', ['Ramuh']='Rolling Thunder', ['Fenrir']='Ecliptic Growl', ['Siren']='Katabatic Blades'},
    ['buffdefense'] = {['Carbuncle']='Shining Ruby', ['Shiva']='Frost Armor', ['Garuda']='Aerial Armor', ['Titan']='Earthen Ward', ['Ramuh']='Lightning Armor', ['Fenrir']='Ecliptic Howl', ['Diabolos']='Noctoshield', ['Cait Sith']='Reraise II', ['Siren']='Chinook'},
    ['buffspecial'] = {['Ifrit']='Inferno Howl', ['Garuda']='Fleet Wind', ['Titan']='Earthen Armor', ['Diabolos']='Dream Shroud', ['Carbuncle']='Soothing Ruby', ['Fenrir']='Heavenward Howl', ['Cait Sith']='Raise II', ['Siren']="Wind's Blessing"},
    ['debuff1'] = {['Shiva']='Diamond Storm', ['Ramuh']='Shock Squall', ['Leviathan']='Tidal Roar', ['Fenrir']='Lunar Cry', ['Diabolos']='Pavor Nocturnus', ['Cait Sith']='Eerie Eye', ['Siren']='Sonic Buffet'},
    ['debuff2'] = {['Shiva']='Sleepga', ['Leviathan']='Slowga', ['Fenrir']='Lunar Roar', ['Diabolos']='Somnolence', ['Siren']='Bitter Elegy'},
    ['sleep'] = {['Shiva']='Sleepga', ['Diabolos']='Nightmare', ['Cait Sith']='Mewing Lullaby', ['Siren']='Lunatic Voice'},
    ['nuke2'] = {['Ifrit']='Fire II', ['Shiva']='Blizzard II', ['Garuda']='Aero II', ['Titan']='Stone II', ['Ramuh']='Thunder II', ['Leviathan']='Water II'},
    ['nuke4'] = {['Ifrit']='Fire IV', ['Shiva']='Blizzard IV', ['Garuda']='Aero IV', ['Titan']='Stone IV', ['Ramuh']='Thunder IV', ['Leviathan']='Water IV'},
    ['bp70'] = {['Ifrit']='Flaming Crush', ['Shiva']='Rush', ['Garuda']='Predator Claws', ['Titan']='Mountain Buster', ['Ramuh']='Chaotic Strike', ['Leviathan']='Spinning Dive', ['Carbuncle']='Meteorite', ['Fenrir']='Eclipse Bite', ['Diabolos']='Nether Blast', ['Cait Sith']='Regal Scratch', ['Siren']='Roundhouse'},
    ['bp75'] = {['Ifrit']='Meteor Strike', ['Shiva']='Heavenly Strike', ['Garuda']='Wind Blade', ['Titan']='Geocrush', ['Ramuh']='Thunderstorm', ['Leviathan']='Grand Fall', ['Carbuncle']='Holy Mist', ['Fenrir']='Lunar Bay', ['Diabolos']='Night Terror', ['Cait Sith']='Level ? Holy', ['Siren']='Tornado II'},
    ['astralflow'] = {['Ifrit']='Inferno', ['Shiva']='Diamond Dust', ['Garuda']='Aerial Blast', ['Titan']='Earthen Fury', ['Ramuh']='Judgment Bolt', ['Leviathan']='Tidal Wave', ['Carbuncle']='Searing Light', ['Fenrir']='Howling Moon', ['Diabolos']='Ruinous Omen', ['Siren']='Clarsach Call'},
    ['astralward'] = {['Cait Sith']="Altana's Favor"},
    ['rage'] = {['Ifrit']='Punch', ['Shiva']='Axe Kick', ['Garuda']='Claw', ['Titan']='Rock Throw', ['Ramuh']='Shock Strike', ['Leviathan']='Barracuda Dive', ['Carbuncle']='Poison Nails', ['Fenrir']='Moonlit Charge', ['Diabolos']='Camisado', ['Cait Sith']='Regal Scratch', ['Siren']='Welt'},
    ['rage2'] = {['Ifrit']='Burning Strike', ['Leviathan']='Tail Whip', ['Ramuh']='Thunderspark', ['Shiva']='Double Slap', ['Titan']='Rock Buster', ['Diabolos']='Somnolence', ['Fenrir']='Crescent Fang'},
    ['rage3'] = {['Ifrit']='Double Punch', ['Titan']='Megalith Throw'},
    ['finalrage'] = {['Ifrit']='Conflag Strike', ['Ramuh']='Volt Strike', ['Titan']='Crag Throw', ['Diabolos']='Blindside', ['Fenrir']='Impact', ['Siren']='Hysteric Assault', ['Cait Sith']='Regal Gash'},
    ['finalward'] = {['Carbuncle']='Pacifying Ruby', ['Leviathan']='Soothing Current', ['Shiva']='Crystal Blessing', ['Garuda']='Hastega II'}
}

-- Pact categories that target enemies
enemyTypePacts = S{'rage', 'rage2', 'rage3', 'finalrage', 'nuke2', 'nuke4', 'debuff1', 'debuff2', 'sleep', 'bp70', 'bp75', 'astralflow'}
-- Pact categories that target self/party
selfTypePacts = S{'buffoffense', 'buffdefense', 'buffspecial', 'finalward', 'curaga', 'astralward', 'cure'}

-- Ward pact durations (seconds) and icon paths for timer display
pact_wards = {
    durations = {
        ['Crimson Howl'] = 60, ['Earthen Armor'] = 60, ['Inferno Howl'] = 60, ['Heavenward Howl'] = 60,
        ['Rolling Thunder'] = 120, ['Fleet Wind'] = 120,
        ['Shining Ruby'] = 180, ['Frost Armor'] = 180, ['Lightning Armor'] = 180, ['Ecliptic Growl'] = 180,
        ['Glittering Ruby'] = 180, ['Hastega'] = 180, ['Noctoshield'] = 180, ['Ecliptic Howl'] = 180,
        ['Dream Shroud'] = 180, ['Hastega II'] = 180,
        ['Reraise II'] = 3600,
        ['Katabatic Blades'] = 120, ['Chinook'] = 900, ["Wind's Blessing"] = 60
    },
    icons = {
        ['Earthen Armor']    = 'spells/00299.png',
        ['Shining Ruby']     = 'spells/00043.png',
        ['Dream Shroud']     = 'spells/00304.png',
        ['Noctoshield']      = 'spells/00106.png',
        ['Inferno Howl']     = 'spells/00298.png',
        ['Hastega']          = 'spells/00358.png',
        ['Hastega II']       = 'spells/00511.png',
        ['Rolling Thunder']  = 'spells/00104.png',
        ['Frost Armor']      = 'spells/00250.png',
        ['Lightning Armor']  = 'spells/00251.png',
        ['Reraise II']       = 'spells/00135.png',
        ['Fleet Wind']       = 'abilities/00074.png',
        ['Katabatic Blades'] = 'spells/00102.png',
        ['Chinook']          = 'spells/00055.png',
        ["Wind's Blessing"]  = 'spells/00106.png',
        ['Glittering Ruby']  = 'spells/00296.png'
    }
}

-- Avatar icon paths for UI display
avatar_icons = {
    ['Carbuncle']   = 'spells/00296.png',
    ['Cait Sith']   = 'spells/00296.png',
    ['Titan']       = 'spells/00299.png',
    ['Leviathan']   = 'spells/00300.png',
    ['Garuda']      = 'spells/00301.png',
    ['Siren']       = 'spells/00307.png',
    ['Ifrit']       = 'spells/00298.png',
    ['Shiva']       = 'spells/00302.png',
    ['Ramuh']       = 'spells/00303.png',
    ['Fenrir']      = 'spells/00297.png',
    ['Diabolos']    = 'spells/00304.png'
}

-- Timer bar styling constants
UI_Style = {
    bar_width = 120,
    bar_height = 14,
}

-- Padding offset to center the foreground bar inside the background border
UI_Layout.bar_padding = {x = 2, y = 2}

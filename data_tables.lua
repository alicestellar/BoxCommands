-- data_tables.lua
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

-- Note: Removed 'local' so this is globally accessible
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
        
helix = {'Luminohelix','Noctohelix','Pyrohelix','Geohelix', 'Hydrohelix','Anemohelix','Cryohelix','Ionohelix'}

-- ====================================================================
-- GAME DATA & CONFIGURATION TABLES
-- ====================================================================
macro_sets = {[0] = 24, [1] = 25, [2] = 26, [3] = 27, [4] = 28, [5] = 29}

validabils = {}
validabils['english'] = {['/ma'] = {}, ['/ja'] = {}, ['/ws'] = {}, ['/item'] = {}, ['/ra'] = {}, ['/ms'] = {}, ['/pet'] = {}, ['/trig'] = {}, ['/echo'] = {}}
validabils['french'] = {['/ma'] = {}, ['/ja'] = {}, ['/ws'] = {}, ['/item'] = {}, ['/ra'] = {}, ['/ms'] = {}, ['/pet'] = {}, ['/trig'] = {}, ['/echo'] = {}}
validabils['german'] = {['/ma'] = {}, ['/ja'] = {}, ['/ws'] = {}, ['/item'] = {}, ['/ra'] = {}, ['/ms'] = {}, ['/pet'] = {}, ['/trig'] = {}, ['/echo'] = {}}
validabils['japanese'] = {['/ma'] = {}, ['/ja'] = {}, ['/ws'] = {}, ['/item'] = {}, ['/ra'] = {}, ['/ms'] = {}, ['/pet'] = {}, ['/trig'] = {}, ['/echo'] = {}}

disable_table = {false,false,false,false,false,false,false,false,false,false,false,false,false,false,false}
disable_table[0] = false

unify_prefix = {['/ma'] = '/ma', ['/magic']='/ma',['/jobability'] = '/ja',['/ja']='/ja',['/item']='/item',['/song']='/ma',
['/so']='/ma',['/ninjutsu']='/ma',['/weaponskill']='/ws',['/ws']='/ws',['/ra']='/ra',['/rangedattack']='/ra',['/nin']='/ma',
['/throw']='/ra',['/range']='/ra',['/shoot']='/ra',['/monsterskill']='/ms',['/ms']='/ms',['/pet']='/ja',['Monster']='Monster',['/bstpet']='/ja'}
        
bag_ids = res.bags:key_map(string.gsub-{' ', ''} .. string.lower .. table.get-{'english'} .. table.get+{res.bags}):map(table.get-{'id'})

outgoing_action_category_table = {['/ma']=3,['/ws']=7,['/ja']=9,['/ra']=16,['/ms']=25}

default_slot_map = T{'sub','range','ammo','head','body','hands','legs','feet','neck','waist', 'left_ear', 'right_ear', 'left_ring', 'right_ring','back'}
default_slot_map[0]= 'main'

region_to_zone_map = { 
    [4] = S{100,101,139,140,141,142,167,190},
    [5] = S{102,103,108,193,196,248},
    [6] = S{1,2,104,105,149,150,195},
    [7] = S{106,107,143,144,172,173,191},
    [8] = S{109,110,147,148,197},
    [9] = S{115,116,145,146,169,170,192,194},
    [10] = S{3,4,117,118,198,213,249},
    [11] = S{7,8,119,120,151,152,200},
    [12] = S{9,10,111,166,203,204,206},
    [13] = S{5,6,112,161,162,165},
    [14] = S{126,127,157,158,179,184},
    [15] = S{121,122,153,154,202,251},
    [16] = S{114,125,168,208,209,247},
    [17] = S{113,128,174,201,212},
    [18] = S{123,176,250,252},
    [19] = S{124,159,160,163,205,207,211},
    [20] = S{130,177,178,180,181},
    [22] = S{11,12,13},
    [24] = S{24,25,26,27,28,29,30,31,32},
}

addendum_white = {[14]="Poisona",[15]="Paralyna",[16]="Blindna",[17]="Silena",[18]="Stona",[19]="Viruna",[20]="Cursna",
    [143]="Erase",[13]="Raise II",[140]="Raise III",[141]="Reraise II",[142]="Reraise III",[135]="Reraise"}

addendum_black = {[253]="Sleep",[259]="Sleep II",[260]="Dispel",[162]="Stone IV",[163]="Stone V",[167]="Thunder IV",
    [168]="Thunder V",[157]="Aero IV",[158]="Aero V",[152]="Blizzard IV",[153]="Blizzard V",[147]="Fire IV",[148]="Fire V",
    [172]="Water IV",[173]="Water V",[255]="Break"}

-- ====================================================================
-- NINJUTSU TOOL MAPPING PATCH
-- ====================================================================
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
pacts = {
    ['cure'] = {['Carbuncle']='Healing Ruby', ['Garuda']='Whispering Wind', ['Leviathan']='Spring Water'},
    ['curaga'] = {['Carbuncle']='Healing Ruby II', ['Garuda']='Whispering Wind', ['Leviathan']='Spring Water'},
    ['buffoffense'] = {['Carbuncle']='Shining Ruby', ['Ifrit']='Crimson Howl', ['Garuda']='Hastega II', ['Titan']='Earthen Ward', ['Ramuh']='Rolling Thunder', ['Fenrir']='Ecliptic Growl', ['Diabolos']='Dream Shroud', ['Siren']='Katabatic Blades'},
    ['buffdefense'] = {['Carbuncle']='Shining Ruby', ['Shiva']='Frost Armor', ['Garuda']='Aerial Armor', ['Titan']='Earthen Ward', ['Ramuh']='Lightning Armor', ['Leviathan']='Slowga', ['Fenrir']='Ecliptic Spurn', ['Diabolos']='Noctoshield', ['Siren']='Chinook'},
    ['buffspecial'] = {['Carbuncle']='Glittering Ruby', ['Ifrit']='Crimson Howl', ['Shiva']='Sleepga', ['Garuda']='Fleet Wind', ['Titan']='Stone Skin', ['Ramuh']='Shock Squall', ['Leviathan']='Soothing Current', ['Fenrir']='Heavenward Howl', ['Diabolos']='Pavor Nocturnus', ['Siren']="Wind's Blessing"},
    ['debuff1'] = {['Carbuncle']='Soothing Ruby', ['Ifrit']='Pyroclast', ['Shiva']='Diamond Storm', ['Garuda']='Shock Wave', ['Titan']='Rock Throw', ['Ramuh']='Shock Squall', ['Leviathan']='Slowga', ['Fenrir']='Lunar Cry', ['Diabolos']='Somnolence', ['Siren']='Sonic Buffet'},
    ['debuff2'] = {['Carbuncle']='Soothing Ruby', ['Ifrit']='Pyroclast', ['Shiva']='Sleepga', ['Garuda']='Intimidate', ['Titan']='Rock Throw', ['Ramuh']='Thunderspark', ['Leviathan']='Tidal Roar', ['Fenrir']='Lunar Cry', ['Diabolos']='Ultimate Terror', ['Siren']='Bitter Elegy'},
    ['sleep'] = {['Shiva']='Sleepga', ['Diabolos']='Nightmare'},
    ['nuke2'] = {['Ifrit']='Burning Strike', ['Shiva']='Blizzard II', ['Garuda']='Claw', ['Titan']='Rock Buster', ['Ramuh']='Thunderspark', ['Leviathan']='Barracuda Dive', ['Fenrir']='Crescent Fang'},
    ['nuke4'] = {['Ifrit']='Double Slap', ['Shiva']='Blizzard IV', ['Garuda']='Predatory Claws', ['Titan']='Mountain Buster', ['Ramuh']='Chaotic Strike', ['Leviathan']='Spinning Dive', ['Fenrir']='Eclipse Bite'},
    ['bp70'] = {['Ifrit']='Flaming Crush', ['Shiva']='Rush', ['Garuda']='Predatory Claws', ['Titan']='Mountain Buster', ['Ramuh']='Chaotic Strike', ['Leviathan']='Spinning Dive', ['Fenrir']='Eclipse Bite', ['Diabolos']='Blindside', ['Siren']='Hysteric Assault'},
    ['bp75'] = {['Ifrit']='Meteor Strike', ['Shiva']='Heavenly Strike', ['Garuda']='Wind Blade', ['Titan']='Geocrush', ['Ramuh']='Thunderstorm', ['Leviathan']='Grand Fall', ['Fenrir']='Lunar Bay', ['Diabolos']='Night Terror', ['Siren']='Sonic Buffet'},
    ['bpray70'] = {['Ifrit']='Flaming Crush', ['Shiva']='Rush', ['Garuda']='Predatory Claws', ['Titan']='Mountain Buster', ['Ramuh']='Chaotic Strike', ['Leviathan']='Spinning Dive', ['Fenrir']='Eclipse Bite', ['Diabolos']='Blindside', ['Siren']='Hysteric Assault'},
    ['astral'] = {['Carbuncle']='Searing Light', ['Ifrit']='Inferno', ['Shiva']='Diamond Dust', ['Garuda']='Aerial Blast', ['Titan']='Earthen Fury', ['Ramuh']='Judgment Bolt', ['Leviathan']='Tidal Wave', ['Fenrir']='Howling Moon', ['Diabolos']='Ruinous Omen', ['Siren']='Clarsach Call'}
}

enemyTypePacts = S{'debuff1', 'debuff2', 'nuke2', 'nuke4', 'bp70', 'bp75', 'bpray70', 'astral'}
selfTypePacts = S{'cure', 'curaga', 'buffoffense', 'buffdefense', 'buffspecial', 'sleep'}

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
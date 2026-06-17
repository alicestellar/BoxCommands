-- macro_config.lua
-- Maps job abbreviations to macro book and set numbers.
-- Edit this file to match your macro setup.
-- See README.md for instructions.

local macro_config = {}

-- Global job-to-macro mapping (used for all characters by default)
-- Format: [job] = { book = <number>, set = <number> }
macro_config.global = {
    ['WAR'] = { book = 1, set = 1 },
    ['MNK'] = { book = 2, set = 1 },
    ['WHM'] = { book = 3, set = 1 },
    ['BLM'] = { book = 4, set = 1 },
    ['RDM'] = { book = 5, set = 1 },
    ['THF'] = { book = 6, set = 1 },
    ['PLD'] = { book = 7, set = 1 },
    ['DRK'] = { book = 8, set = 1 },
    ['BST'] = { book = 9, set = 1 },
    ['BRD'] = { book = 10, set = 1 },
    ['RNG'] = { book = 11, set = 1 },
    ['SAM'] = { book = 12, set = 1 },
    ['NIN'] = { book = 13, set = 1 },
    ['DRG'] = { book = 14, set = 1 },
    ['SMN'] = { book = 15, set = 1 },
    ['BLU'] = { book = 16, set = 1 },
    ['COR'] = { book = 17, set = 1 },
    ['PUP'] = { book = 18, set = 1 },
    ['DNC'] = { book = 19, set = 1 },
    ['SCH'] = { book = 20, set = 1 },
    ['GEO'] = { book = 21, set = 1 },
    ['RUN'] = { book = 22, set = 1 },
}

-- Per-character overrides (optional)
-- Uncomment and duplicate the block below for characters that need
-- different macro books than the global defaults.
-- You can have up to 18 character overrides for a full alliance.
--
-- macro_config['CharacterName'] = {
--     ['WAR'] = { book = 12, set = 1 },
--     ['MNK'] = { book = 13, set = 1 },
--     ['WHM'] = { book = 14, set = 1 },
--     -- ... add jobs as needed
-- }

return macro_config

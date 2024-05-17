--[[ Default Config Settings ]]
                                --
Config        = {}

Config.UseQBTarget = true --qb-target
Config.RelateStates = {
    WAR = 5,
    NEUTRAL = 3,
    FRIEND = 0,
    RESPECT = 1,
    LIKE = 2,
    DISLIKE = 4,
}

-- DONT CHANGE THIS IF YOU DONT CHANGE ANYTHING IN DB!!!!
Config.DBData = {
    tableName = 'npcguards',
    frationColumnName = 'fraction_name',
    relationColumnName = 'relations_data',
}

Config.StaticRelations = true
Config.StaticRelationsList = {
    -- ['zombie'] = {
    --     name = 'ZOMBIE',
    --     state = Config.RelateStates.WAR
    -- },
    -- ['raiders'] = {
    --     name = 'RAIDERS',
    --     state = Config.RelateStates.WAR
    -- },
}

Config.GuardsAreMortal = true
Config.DespawnDeadTimer = 60 -- time in seconds
Config.NpcList = {
    ['aztecas'] = {
        control = {
            coords = vector4(402.97, 3626.44, 33.32, 264.55),
            model = 'g_m_m_chicold_01',
        },
        coords = {
            vector4(402.97, 3606.44, 33.32, 264.55),
            vector4(399.17, 3596.3, 33.32, 269.83),
            vector4(403.05, 3566.97, 38.5, 274.65),
            vector4(397.05, 3597.61, 37.27, 254.53),
        },
        models = {
            'g_m_m_chicold_01',
        },
        weapons = {
            guardArea = 10.0,
            ammo = 10000,
            list = {
                "WEAPON_PISTOL",
                "WEAPON_COMBATPISTOL",
                "WEAPON_ASSAULTRIFLE",
            }
        },
    },
    ['ballas'] = {
        control = {
            coords = vector4(1982.96, 3062.76, 47.18, 221.6),
            model = 'g_m_m_chicold_01',
        },
        coords = {
            vector4(1984.38, 3056.79, 54.18, 7.94),
            vector4(1994.81, 3042.7, 54.55, 207.37),
            vector4(1988.15, 3018.11, 51.68, 191.15),
            vector4(1963.11, 3038.19, 61.89, 43.58),
            vector4(1975.9, 3082.47, 47.03, 63.32),
            vector4(1971.0, 3071.01, 46.91, 62.15)
        },
        models = {
            'g_m_m_chicold_01',
        },
        weapons = {
            guardArea = 2.0,
            ammo = 10000,
            list = {
                "WEAPON_PISTOL",
                "WEAPON_COMBATPISTOL",
                "WEAPON_ASSAULTRIFLE",
            }
        },
    }
}
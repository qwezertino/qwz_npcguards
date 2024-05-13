# qwz_npcguards
NPC Guards system

## !!!ATTENTION!!!

ALL NPC ARE SYNCED NOW!!!

System just store to DB names for gangs and data with relations to all another stored gangs. NPC can attack or not all players and peds base on relation they have to their group

DON FORGET TO ADD NEW GANG WHEN YOU ADD SOME TO qb-core/shared/gangs.lua !!

## INSTALLATION
 - Download the latest realese
 - Take `npcguards.sql` and upload to your Database
 - Just place `qwz_npcguards` in your server scripts folder and ensure it!

## REQUIREMENTS
 - `qb-core`
 - `ox_lib`
 - `ox_target` or `qb-target`
 - `oxmysql`

## Config

In the config u can find all you need. This is example with some explanation

```lua
    ['aztecas'] = {
        control = { -- Here is data for spawning ped with CONTROL menu for all ur guards
            coords = vector4(402.97, 3626.44, 33.32, 264.55), -- Coords for this ped
            model = 'g_m_m_chicold_01', -- Mode for ped
        },
        coords = { -- Coordinates for all peds that you want to spawn
            vector4(402.97, 3606.44, 33.32, 264.55),
            vector4(399.17, 3596.3, 33.32, 269.83),
            vector4(403.05, 3566.97, 38.5, 274.65),
            vector4(397.05, 3597.61, 37.27, 254.53),
        },
        models = { -- List of models name for yours peds. Models picks randomly
            'g_m_m_chicold_01',
        },.
        weapons = { -- Weapons section
            guardArea = 10.0, -- Area that ped gonna guard around him, THIS OPTION NEED IF freeze IS SET TO FALSE! Just leave it 10.0
            ammo = 10000, -- Amount of ammo we giving to ped
            list = { -- List of weapons that we give to ped
                "WEAPON_PISTOL",
                "WEAPON_COMBATPISTOL",
                "WEAPON_ASSAULTRIFLE",
            }
        },
    },
```
This part is responsible for static relations. For example you have peds with relations group named `zombie` and you want to all your peds attack this group

```lua
    Config.StaticRelations = true
    Config.StaticRelationsList = {
        ['zombie'] = { -- just name for the table
            name = 'ZOMBIE', -- NAME OF YOUR RELATION STRING
            state = Config.RelateStates.WAR
        },
    }
```

If you want to change some table names in Database - you can do changes here, but strongly NOT recommended to do this if you dont know what to do

```lua
    Config.DBData = {
        tableName = 'npcguards',
        frationColumnName = 'fraction_name',
        relationColumnName = 'relations_data',
    }
```

## COMMANDS
 - `/storegangs` - Gets all yours gangs from the `/qb-core/shared/gangs.lua` and save it into DB with all NEUTRAL relations between each other
 - `/relmenu` - Shows an Control Menu with buttons to create, update and delete fractions with relations
 - `/createrel` - Show a menu to create a NEW gang (or fraction) with some new custom relations to all another gangs
 - `/updaterel` - Show a menu to update a gang (or fraction) with relations
 - `/deleterel` - Show a menu to delete a gang and removes all relations to it

 ## TODO list
 - Auto sync Gangs list from qb-core shared config, checks if there is new gangs and insert it into DB
 - Create functionality to place peds using ingame menu with saving all positions and data in Database
 - Create som interesting features xD

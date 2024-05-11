# qz-npcguards
NPC Guards system

## !!!ATTENTION!!!

All NPCs are created LOCALLY, they are not synchronized, since this is not necessary for this system. All peds play the role of essentially static turrets! If you want, you can remake the script to create synchronized peds

System just store to DB names for gangs and data with relations to all another stored gangs. NPC can attack or not all players and peds base on relation they have to their group

DON FORGET TO ADD NEW GANG WHEN YOU ADD SOME TO qb-core/shared/gangs.lua !!

## INSTALLATION
 - Download the latest realese
 - Take `npcguards.sql` and upload to your Database
 - Just place `qz-npcguards` in your server scripts folder end ensure it!

## REQUIREMENTS
 - `qb-core`
 - `ox_lib`
 - `ox_target`

## COMMANDS

 - `/storegangs` - Gets all yours gangs from the `/qb-core/shared/gangs.lua` and save it into DB with all NEUTRAL relations between each other
 - `/createrel` - Show a menu to create a NEW gang (or fraction) with some new custom relations to all another gangs
 - `/updaterel` - Show a menu to update a gang (or fraction) with relations
 - `/deleterel` - Show a menu to delete a gang and removes all relations to it

 ## TODO list
 - Automatic sync Gangs list from qb-core shared config, checks if there is new gangs and insert it into DB
 - Create som interesting features xD

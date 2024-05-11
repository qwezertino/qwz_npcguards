QBCore = exports['qb-core']:GetCoreObject()

local function SetupGuardianPed(ped)
    if IsPedHuman(ped) and not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, true) then
        SetPedCombatAttributes(ped, 46, true) -- set the ped's combat attributes to make them use cover and avoid vehicles
        SetPedCombatAttributes(ped, 0, true) -- set the ped's combat attributes to make them use cover and avoid vehicles
        SetPedCombatAttributes(ped, 5, true) -- set the ped's combat attributes to make them use cover and avoid vehicles

        SetPedCombatAbility(ped, 0) -- set the ped's combat ability to 100%
        SetPedAccuracy(ped, 100)
        SetPedCombatRange(ped, 2) -- set the ped's combat range to 2 (short range)
        SetPedCombatMovement(ped, 1) -- set the ped's combat movement to aggressive

        SetPedSeeingRange(ped, 100.0)
        SetPedHearingRange(ped, 50.0)

        SetPedArmour(ped, 100)
        SetEntityHealth(ped, 200)

        SetEntityInvincible(ped, true)
    end
end

--
---Function to get the relation state between two groups
---@param relations table
---@param group1 string
---@param group2 string
---@return integer
local function getRelationState(relations, group1, group2)
    return group1 == group2 and 0 or relations[group1] and relations[group1][group2] or 3
end

---Get relations table from DB
---@return table
local function getAllRelationsFromDB()
    return lib.callback.await("qz-npcguards:server:GetAllRelationsFromDB", false)
end

---Get relations table for fraction
---@param fractionName string
---@return table
local function getRelationFromDB(fractionName)
    return lib.callback.await("qz-npcguards:server:GetRelationFromDB", false, fractionName)
end

---Init Load Relations and set it for player and npc
---@return nil
local function LoadRelations()
    local relations = getAllRelationsFromDB()
    if not relations then return print('no relations!!!') end

    for groupName1, values in pairs(relations) do
        local fracHash1 = GetHashKey(groupName1)
        for groupName2, relation in pairs(values) do
            local fracHash2 = GetHashKey(groupName2)
            SetRelationshipBetweenGroups(relation, fracHash1, fracHash2)
            SetRelationshipBetweenGroups(relation, fracHash2, fracHash1)
            -- print('set relation', groupName1, groupName2, relation)
        end

        local playerGroup = GetPedRelationshipGroupHash(cache.ped)
        local playerGang = QBCore.Functions.GetPlayerData().gang.name
        local plRelState = getRelationState(relations, groupName1, playerGang)
        SetRelationshipBetweenGroups(plRelState, GetHashKey(groupName1), playerGroup)

        local relateState = getRelationState(relations, groupName1, groupName1)
        SetRelationshipBetweenGroups(relateState, GetHashKey(groupName1), GetHashKey(groupName1))

        if Config.StaticRelations then
            for _, value in pairs(Config.StaticRelationsList) do
                SetRelationshipBetweenGroups(value.state, fracHash1, GetHashKey(value.name))
            end
        end
    end
end

---Create ped with params
---@param coords table
---@param models table | string
---@param weapons table
---@param fractionHash integer
---@param isFreeze boolean
local function createAndSetPed(coords, models, weapons, fractionHash, isFreeze)
    local randModel = type(models) == 'table' and GetHashKey(models[math.random(#models)]) or GetHashKey(models)
    local ped = CreatePed(4, randModel, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)
    SetPedRelationshipGroupHash(ped, fractionHash)
    SetupGuardianPed(ped)

    if isFreeze then
        FreezeEntityPosition(ped, true)
    end

    TaskStandGuard(ped, coords.x, coords.y, coords.z - 1.0, coords.w, 'WORLD_HUMAN_GUARD_STAND')
    TaskGuardCurrentPosition(ped, weapons.guardArea, weapons.guardArea, true)
    TaskCombatHatedTargetsAroundPed(ped, 50.0, 0)

    if type(weapons.list) == 'table' then
        for _, modelName in ipairs(weapons.list) do
            GiveWeaponToPed(ped, GetHashKey(modelName), weapons.ammo, false, true)
        end
    elseif type(weapons.list) == 'string' then
        GiveWeaponToPed(ped, GetHashKey(weapons.list), weapons.ammo, false, true)
    end
end


local function showUpdateRelMenu(fractionName)
    local relations = getRelationFromDB(fractionName)
    if not relations then return end

    local inputs = {}
    for fracName, relation in pairs(relations[fractionName]) do
        inputs[#inputs+1] = {
            type = 'select',
            label = QBCore.Shared.Gangs[fracName]?.label or fracName,
            default = fracName .. ":".. relation,
            options = {
                {value = fracName .. ":" .. Config.RelateStates.FRIEND, label = Lang:t('menu.friend')},
                {value = fracName .. ":" .. Config.RelateStates.NEUTRAL, label = Lang:t('menu.neutral')},
                {value = fracName .. ":" .. Config.RelateStates.WAR, label = Lang:t('menu.war')},
            }
        }
    end

    local input = lib.inputDialog(Lang:t('menu.input_dialog_title'), inputs)

    if input then
        local newRelTable = {}
        for _, value in ipairs(input) do
            local delimiter = ":"
            local fracName, relation = value:match("([^" .. delimiter .. "]+)" .. delimiter .. "(.*)")
            print('DATA', fracName, relation)
            newRelTable[fracName] = tonumber(relation)
        end
        TriggerServerEvent('qz-npcguards:server:UpdateRelations', newRelTable, fractionName)
    end
end

local function LoadControlPedMenu()
    for fractionName, value in pairs(Config.NpcList) do
        local pedCoords = value.control.coords
        local models = value.control.model

        local ped = CreatePed(4, GetHashKey(models), pedCoords.x, pedCoords.y, pedCoords.z - 1.0, pedCoords.w, false, false)
        SetupGuardianPed(ped)
        TaskStandGuard(ped, pedCoords.x, pedCoords.y, pedCoords.z - 1.0, pedCoords.w, 'WORLD_HUMAN_GUARD_STAND')
        GiveWeaponToPed(ped, GetHashKey('WEAPON_ASSAULTRIFLE'), 100, false, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)

        lib.registerContext({
            id = 'guards_control_menu',
            title = Lang:t('menu.context_menu_title'),
            options = {
                {
                    title = Lang:t('menu.context_menu_button1'),
                    description = Lang:t('menu.context_menu_button1_desc'),
                    icon = 'circle',
                    onSelect = function()
                        showUpdateRelMenu(fractionName)
                    end,
                },
            }
        })

        if Config.UseQBTarget then
            local options = {
                type = "client",
                icon = "fas fa-id-card",
                label = Lang:t('ped.target_menu_open'),
                canInteract = function(entity, distance, data)
                    local playerData = QBCore.Functions.GetPlayerData()
                    return fractionName == playerData.gang.name and playerData.gang.isboss
                end,
                action = function(entity)
                    if IsPedAPlayer(entity) then return false end
                    lib.showContext('guards_control_menu')
                end,
                distance = 2.0
            }
            exports['qb-target']:AddTargetEntity(ped, { options = {options}})
        else
            local options = {
                type = "client",
                icon = "fas fa-id-card",
                label = Lang:t('ped.target_menu_open'),
                canInteract = function(entity, distance, coords, name, bone)
                    local playerData = QBCore.Functions.GetPlayerData()
                    return fractionName == playerData.gang.name and playerData.gang.isboss
                end,
                onSelect = function(data)
                    if IsPedAPlayer(data.entity) then return false end
                    lib.showContext('guards_control_menu')
                end,
                distance = 2.0
            }
            exports.ox_target:addLocalEntity(ped, options)
        end
    end
end
---Load NPC Guards
local function LoadNpsGuards()
    for frac_name, data in pairs(Config.NpcList) do
        local fracHash = GetHashKey(frac_name)
        AddRelationshipGroup(frac_name)
        if type(data.models) == 'table' then
            for _, model in pairs(data.models) do
                lib.requestModel(GetHashKey(model))
            end
        elseif type(data.models) == 'string' then
            lib.requestModel(GetHashKey(data.models))
        end
        for _, coords in pairs(data.coords) do
            createAndSetPed(coords, data.models, data.weapons, fracHash, data.freeze)
        end
    end
end

RegisterNetEvent('qz-npcguards:client:UpdateRelaions', function()
    LoadRelations()
end)

RegisterNetEvent('qz-npcguards:client:ShowUpdateMenu', function()
    local input = lib.inputDialog(Lang:t('menu.update_dialog_title'), {
        {type = 'input', label = Lang:t('menu.update_dialog_label'),
            description = Lang:t('menu.update_dialog_desc'), required = true, min = 1, max = 64},
    })

    if not input then return end
    local exist = lib.callback.await("qz-npcguards:server:GetRelationFromDB", false, input[1])

    if not exist then return end

    showUpdateRelMenu(input[1])
end)

RegisterNetEvent('qz-npcguards:client:ShowCreateMenu', function()
    local input = lib.inputDialog(Lang:t('menu.create_dialog_title'), {
        {type = 'input', label = Lang:t('menu.create_dialog_label'),
            description = Lang:t('menu.create_dialog_desc'), required = true, min = 1, max = 64},
    })

    if not input then return end
    local created = lib.callback.await("qz-npcguards:server:CreateNewRelation", false, input[1])

    if not created then return end

    showUpdateRelMenu(input[1])
end)

RegisterNetEvent('qz-npcguards:client:ShowDeleteMenu', function()
    local input = lib.inputDialog(Lang:t('menu.delete_dialog_title'), {
        {type = 'input', label = Lang:t('menu.delete_dialog_label'),
            description = Lang:t('menu.delete_dialog_desc'), required = true, min = 1, max = 64},
    })

    if not input then return end
    local deleted = lib.callback.await("qz-npcguards:server:DeleteRelation", false, input[1])

    if not deleted then return end

    QBCore.Functions.Notify('Success DELETED!', 'success', 7500)
end)


RegisterNetEvent('QBCore:Client:OnGangUpdate', function(gang)
    local playerGroup = GetPedRelationshipGroupHash(cache.ped)
    local relations = getAllRelationsFromDB()
    if not relations then return print('no relations!!!') end
    for groupName1, _ in pairs(relations) do
        local relation = getRelationState(relations, groupName1, gang.name)
        SetRelationshipBetweenGroups(relation, GetHashKey(groupName1), playerGroup)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    LoadNpsGuards()
    LoadRelations()
    LoadControlPedMenu()
end)

AddEventHandler('onResourceStart', function(r)
    if GetCurrentResourceName() ~= r then return end
    LoadNpsGuards()
    LoadRelations()
    LoadControlPedMenu()
end)
QBCore = exports['qb-core']:GetCoreObject()

-- function DrawText3D(msg, coords)
--     AddTextEntry('esxFloatingHelpNotification', msg)
--     SetFloatingHelpTextWorldPosition(1, coords)
--     SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
--     BeginTextCommandDisplayHelp('esxFloatingHelpNotification')
--     EndTextCommandDisplayHelp(2, false, false, -1)
-- end

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
        SetPedHearingRange(ped, 100.0)

        SetPedArmour(ped, 100)
        SetEntityHealth(ped, 200)

        if not Config.GuardsAreMortal then SetEntityInvincible(ped, true) end
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
    return lib.callback.await("qwz_npcguards:server:GetAllRelationsFromDB", false)
end

---Get relations table for fraction
---@param fractionName string
---@return table
local function getRelationFromDB(fractionName)
    return lib.callback.await("qwz_npcguards:server:GetRelationFromDB", false, fractionName)
end

---Init Load Relations and set it for player and npc
---@return nil
local function LoadRelations()
    local relations = getAllRelationsFromDB()
    if not relations then return print('no relations!!!') end

    for groupName, _ in pairs(relations) do
        if not DoesRelationshipGroupExist(GetHashKey(groupName)) then
            AddRelationshipGroup(groupName)
            print('relate created', groupName)
        end
    end

    for groupName1, values in pairs(relations) do
        local fracHash1 = GetHashKey(groupName1)
        for groupName2, relation in pairs(values) do
            local fracHash2 = GetHashKey(groupName2)
            SetRelationshipBetweenGroups(relation, fracHash1, fracHash2)
            SetRelationshipBetweenGroups(relation, fracHash2, fracHash1)
            print('set relation', groupName1, groupName2, relation)
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
local function setGuardianPed(ped, weapons, fractionHash)
    SetPedRelationshipGroupHash(ped, fractionHash)
    SetupGuardianPed(ped)
    TaskGuardCurrentPosition(ped, weapons.guardArea, weapons.guardArea, true)

    if type(weapons.list) == 'table' then
        for _, modelName in ipairs(weapons.list) do
            GiveWeaponToPed(ped, GetHashKey(modelName), weapons.ammo, true, true)
        end
    elseif type(weapons.list) == 'string' then
        GiveWeaponToPed(ped, GetHashKey(weapons.list), weapons.ammo, true, true)
    end

    CreateThread(function()
        while true do
            local taskStatus = GetScriptTaskStatus(ped, "SCRIPT_TASK_GUARD_CURRENT_POSITION") --TASK_FOLLOW_NAV_MESH_TO_COORD
            if taskStatus == 7 then
                TaskGuardCurrentPosition(ped, weapons.guardArea, weapons.guardArea, true)
            end
            local hasweap, weaphash = GetCurrentPedWeapon(ped, true)
            if hasweap then
                local currAmmo = GetAmmoInPedWeapon(ped, weaphash)
                if currAmmo <= 100 then
                    SetPedAmmo(ped, weaphash, weapons.ammo)
                end
            end
            Wait(1000)
        end
    end)

end


local function showUpdateRelMenu(fractionName)
    local relations = getRelationFromDB(fractionName)
    if not relations then return end
    if not next(relations) then return QBCore.Functions.Notify('NO RELATIONS IN DB | USE /storegangs command!', 'error', 7500) end

    local inputs = {}
    for fracName, relation in pairs(relations[fractionName]) do
        local relateOptions = {}
        for key, value in pairs(Config.RelateStates) do
            relateOptions[#relateOptions+1] = {value = fracName .. ":" .. value, label = Lang:t('menu.' .. key:lower())}
        end
        inputs[#inputs+1] = {
            type = 'select',
            label = QBCore.Shared.Gangs[fracName]?.label or fracName,
            default = fracName .. ":".. relation,
            options = relateOptions
        }
    end

    local input = lib.inputDialog(Lang:t('menu.input_dialog_title'), inputs)

    if input then
        local newRelTable = {}
        for _, value in ipairs(input) do
            local delimiter = ":"
            local fracName, relation = value:match("([^" .. delimiter .. "]+)" .. delimiter .. "(.*)")
            newRelTable[fracName] = tonumber(relation)
        end
        TriggerServerEvent('qwz_npcguards:server:UpdateRelations', newRelTable, fractionName)
    end
end

local function LoadControlPedMenu()
    for fractionName, value in pairs(Config.NpcList) do
        local pedCoords = value.control.coords
        local models = value.control.model

        lib.requestModel(models)
        local ped = CreatePed(4, GetHashKey(models), pedCoords.x, pedCoords.y, pedCoords.z - 1.0, pedCoords.w, false, false)
        while not DoesEntityExist(ped) do
            Wait(10)
        end
        SetPedArmour(ped, 100)
        SetEntityHealth(ped, 200)
        SetEntityInvincible(ped, true)
        TaskStandGuard(ped, pedCoords.x, pedCoords.y, pedCoords.z - 1.0, pedCoords.w, 'WORLD_HUMAN_GUARD_STAND')
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

RegisterNetEvent('qwz_npcguards:client:UpdateRelaions', function()
    LoadRelations()
end)

RegisterNetEvent('qwz_npcguards:client:SetGuardStats', function(netIds)
    LoadRelations()
    for _, data in ipairs(netIds) do
        local ped = NetToPed(data.netId)
        while not DoesEntityExist(ped) do
            ped = NetToPed(data.netId)
            Wait(10)
        end
        if not Entity(ped).state.isGuardian then
            Entity(ped).state:set('isGuardian', true, true) -- isGuardian
        end
        setGuardianPed(ped, data.weapons, data.fractionHash)
    end
end)

local function showUpdateMenu()
    local relations = getAllRelationsFromDB()
    if not next(relations) then return end

    local inputOptions = {}
    for fractionName, _ in pairs(relations) do
        inputOptions[#inputOptions+1] = {
            value = fractionName, label = QBCore.Shared.Gangs[fractionName]?.label or fracName
        }
    end
    local input = lib.inputDialog(Lang:t('menu.update_dialog_title'), {
        {
            type = 'select',
            label = Lang:t('menu.update_dialog_label'),
            options = inputOptions
        }
    })

    if not input then return end
    showUpdateRelMenu(input[1])
end

local function showCreateMenu()
    local input = lib.inputDialog(Lang:t('menu.create_dialog_title'), {
        {type = 'input', label = Lang:t('menu.create_dialog_label'),
            description = Lang:t('menu.create_dialog_desc'), required = true, min = 1, max = 64},
    })

    if not input then return end
    local created = lib.callback.await("qwz_npcguards:server:CreateNewRelation", false, input[1])

    if not created then return end

    showUpdateRelMenu(input[1])
end

local function showDeleteMenu()
    local relations = getAllRelationsFromDB()
    if not next(relations) then return end

    local inputOptions = {}
    for fractionName, _ in pairs(relations) do
        inputOptions[#inputOptions+1] = {
            value = fractionName, label = QBCore.Shared.Gangs[fractionName]?.label or fracName
        }
    end

    local input = lib.inputDialog(Lang:t('menu.delete_dialog_title'), {
        {
            type = 'select',
            label = Lang:t('menu.update_dialog_label'),
            options = inputOptions
        }
    })

    if not input then return end
    local deleted = lib.callback.await("qwz_npcguards:server:DeleteRelation", false, input[1])
    if not deleted then return end

    QBCore.Functions.Notify('Success DELETED!', 'success', 7500)
end

RegisterNetEvent('qwz_npcguards:client:ShowAdminMenu', function(data)
    lib.registerContext({
        id = 'relations_admin_menu',
        title = Lang:t('menu.admin_title'),
        options = {
            {
                title = Lang:t('menu.admin_create'),
                description = Lang:t('menu.admin_create_desc'),
                icon = 'circle',
                onSelect = function()
                    showCreateMenu()
                end,
            },
            {
                title = Lang:t('menu.admin_update'),
                description = Lang:t('menu.admin_update_desc'),
                icon = 'circle',
                onSelect = function()
                    showUpdateMenu()
                end,
            },
            {
                title = Lang:t('menu.admin_delete'),
                description = Lang:t('menu.admin_delete_desc'),
                icon = 'circle',
                onSelect = function()
                    showDeleteMenu()
                end,
            },
        }
    })
    lib.showContext('relations_admin_menu')
end)

RegisterNetEvent('qwz_npcguards:client:ShowUpdateMenu', function()
    showUpdateMenu()
end)

RegisterNetEvent('qwz_npcguards:client:ShowCreateMenu', function()
    showCreateMenu()
end)

RegisterNetEvent('qwz_npcguards:client:ShowDeleteMenu', function()
    showDeleteMenu()
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
    LoadRelations()
    LoadControlPedMenu()
    LocalPlayer.state:set('canUpdateGuardians', true, true)
end)

AddEventHandler('onResourceStart', function(r)
    if GetCurrentResourceName() ~= r then return end
    LoadRelations()
    LoadControlPedMenu()
end)

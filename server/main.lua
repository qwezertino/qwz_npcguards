local QBCore = exports['qb-core']:GetCoreObject()


AddEventHandler('onResourceStart', function(resource)
   if resource ~= GetCurrentResourceName() then
      return
   end
end)

local function getAllRelationsFromDB()
    local query = ("SELECT %s, %s FROM %s"):format(Config.DBData.frationColumnName, Config.DBData.relationColumnName, Config.DBData.tableName)
    return MySQL.query.await(query, {})
end

local function getRelationFromDB(fractionName)
    local query = ("SELECT %s, %s FROM %s WHERE %s = :fraction_name"):format(Config.DBData.frationColumnName, Config.DBData.relationColumnName, Config.DBData.tableName, Config.DBData.frationColumnName)
    return MySQL.query.await(query, {["fraction_name"] = fractionName})
end

local function deleteRelation(relName)
    -- Fetch all existing relation data from the database
    local query = ("SELECT %s, %s FROM %s"):format(Config.DBData.frationColumnName, Config.DBData.relationColumnName, Config.DBData.tableName)
    local fractionData = MySQL.query.await(query, {})

    if not fractionData then
        print("No relations found in the database.")
        return
    end

    for _, value in pairs(fractionData) do
        local fractionName = value[Config.DBData.frationColumnName]
        local relationsData = json.decode(value[Config.DBData.relationColumnName])

        relationsData[relName] = nil

        local updateQuery = ("UPDATE %s SET %s = :new_relation WHERE %s = :fraction_name"):format(
        Config.DBData.tableName, Config.DBData.relationColumnName, Config.DBData.frationColumnName)
        local success = MySQL.update.await(updateQuery,
            { [':new_relation'] = json.encode(relationsData), [':fraction_name'] = fractionName })
        if success then
            print("Relation removed successfully from fraction:", relName)
        else
            print("Failed to remove relation from fraction:", relName)
        end
    end

    local delQuery = ("DELETE FROM %s WHERE %s = :fraction_name"):format(Config.DBData.tableName, Config.DBData.frationColumnName)
    MySQL.query.await(delQuery, { ['fraction_name'] = relName })

    TriggerClientEvent('qz-npcguards:client:UpdateRelaions', -1)

    return true
end

---Create new relation for fraction
---@param relName string
local function createNewRelation(relName)
    -- local relName = args[1]
    -- Fetch existing relations from the database
    local query = ("SELECT %s, %s FROM %s"):format(Config.DBData.frationColumnName, Config.DBData.relationColumnName, Config.DBData.tableName)
    local fractions = MySQL.query.await(query, {})

    -- Initialize a new relation table with existing relations
    local newRelations = {}
    for _, fraction in pairs(fractions) do
        newRelations[fraction.fraction_name] = json.decode(fraction.relations_data)
    end

    -- Add the new relation with NEUTRAL status to the relation table
    for _, relation in pairs(newRelations) do
        relation[relName] = Config.RelateStates.NEUTRAL
    end

    local newRelTable = {}
    for _, value in pairs(fractions) do
        newRelTable[value.fraction_name] = Config.RelateStates.NEUTRAL
    end

    local queryInsert = ("INSERT INTO %s (%s, %s) VALUES (:fraction_name, :relation_data)"):format(Config.DBData.tableName, Config.DBData.frationColumnName, Config.DBData.relationColumnName)

    local insertId = MySQL.insert.await(queryInsert,  {
        ["fraction_name"] = relName,
        ["relation_data"] = json.encode(newRelTable),
    })

    if insertId then
        for fractionName, relationsData in pairs(newRelations) do
            local updatedRelations = json.encode(relationsData)
            local updateQuery = ("UPDATE %s SET %s = :relation_data WHERE %s = :fraction_name"):format(Config.DBData.tableName, Config.DBData.relationColumnName, Config.DBData.frationColumnName)

            MySQL.update.await(updateQuery,{["fraction_name"] = fractionName, ["relation_data"] = updatedRelations})
        end
        -- Trigger client event to update relations
        TriggerClientEvent('qz-npcguards:client:UpdateRelaions', -1)
        return true
    else
        return false
    end
end
exports('createNewRelation', createNewRelation)

---Update Relations Functions
---@param relName string
---@param targetRelName string
---@param relationState integer
local function updateRelations(relName, targetRelName, relationState)
    -- Fetch the existing relation data from the database for the target relation
    local query = ("SELECT %s FROM %s WHERE %s = :target_fraction"):format(Config.DBData.relationColumnName, Config.DBData.tableName, Config.DBData.frationColumnName)
    local fractionData = MySQL.query.await(query, {[':target_fraction'] = targetRelName})

    if not fractionData[1] then
        print("Fraction not found:", targetRelName)
        return
    end

    -- Convert the relation data from JSON to Lua table
    local relations = json.decode(fractionData[1][Config.DBData.relationColumnName])

    -- Update the relation data with the new value bidirectionally
    relations[relName] = relationState

    -- Fetch the existing relation data from the database for the relation being updated
    local queryTarget = ("SELECT %s FROM %s WHERE %s = :target_fraction"):format(Config.DBData.relationColumnName, Config.DBData.tableName, Config.DBData.frationColumnName)
    local fractionDataTarget = MySQL.query.await(queryTarget, {[':target_fraction'] = relName})

    if not fractionDataTarget[1] then
        print("Fraction not found:", relName)
        return
    end

    -- Convert the relation data from JSON to Lua table
    local relationsTarget = json.decode(fractionDataTarget[1][Config.DBData.relationColumnName])

    -- Update the relation data with the new value bidirectionally
    relationsTarget[targetRelName] = relationState

    -- Update the relation data in the database for the target relation
    local updateQuery = ("UPDATE %s SET %s = :new_relation WHERE %s = :target_fraction"):format(Config.DBData.tableName, Config.DBData.relationColumnName, Config.DBData.frationColumnName)
    local success = MySQL.update.await(updateQuery, {[':new_relation'] = json.encode(relations), [':target_fraction'] = targetRelName})

    if success then
        print("Relations updated successfully")
    else
        print("Failed to update relations.")
        return
    end

    -- Update the relation data in the database for the relation being updated
    local updateQueryTarget = ("UPDATE %s SET %s = :new_relation WHERE %s = :target_fraction"):format(Config.DBData.tableName, Config.DBData.relationColumnName, Config.DBData.frationColumnName)
    local successTarget = MySQL.update.await(updateQueryTarget, {[':new_relation'] = json.encode(relationsTarget), [':target_fraction'] = relName})

    if successTarget then
        print("Relations updated successfully:")
    else
        print("Failed to update relations.")
    end
end
exports('updateRelations', updateRelations)

---Format json format to array way
---@param response table
---@return table
local function formatDataToArray(response)
    -- Create a table to store the relations
    local relations = {}
    -- Iterate through each object in the data
    for _, item in ipairs(response) do
        local fraction = item.fraction_name
        local relationsData = json.decode(item.relations_data)

        -- Create a sub-table for the current fraction
        relations[fraction] = {}

        -- Iterate through each relation in the relationsData
        for key, value in pairs(relationsData) do
            relations[fraction][key] = value
        end
    end
    return relations
end

lib.callback.register("qz-npcguards:server:GetAllRelationsFromDB", function(source)
    return formatDataToArray(getAllRelationsFromDB())
end)

lib.callback.register("qz-npcguards:server:GetRelationFromDB", function(source, fractionName)
    return formatDataToArray(getRelationFromDB(fractionName))
end)

lib.callback.register("qz-npcguards:server:CreateNewRelation", function(source, fractionName)
    return createNewRelation(fractionName)
end)

lib.callback.register("qz-npcguards:server:DeleteRelation", function(source, fractionName)
    return deleteRelation(fractionName)
end)

RegisterNetEvent('qz-npcguards:server:UpdateRelations', function(relationsTable, targetFrac)
    if type(relationsTable) == 'table' then
        for fractionName, relation in pairs(relationsTable) do
            updateRelations(targetFrac, fractionName, tonumber(relation))
        end
        TriggerClientEvent('qz-npcguards:client:UpdateRelaions', -1)
    end
end)


QBCore.Commands.Add('storegangs', Lang:t("commands.store_gangs_relation"), {}, false, function(source, args)
    local gangs = QBCore.Shared.Gangs
    for gangName, _ in pairs(gangs) do
        createNewRelation(gangName)
    end
end, 'admin')

QBCore.Commands.Add('createrel', Lang:t("commands.create_new_relation"), {}, false, function(source, args)
    TriggerClientEvent('qz-npcguards:client:ShowCreateMenu', source)
end, 'admin')

QBCore.Commands.Add('updaterel', Lang:t("commands.update_relation"), {}, false, function(source, args)
    TriggerClientEvent('qz-npcguards:client:ShowUpdateMenu', source)
end, 'admin')

QBCore.Commands.Add('deleterel', Lang:t("commands.delete_relation"), {}, false, function(source, args)
    TriggerClientEvent('qz-npcguards:client:ShowDeleteMenu', source)
end, 'admin')
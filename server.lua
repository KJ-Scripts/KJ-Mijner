local ESX = exports["es_extended"]:getSharedObject()
local playersXP = {}

Citizen.CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `KJ_Mijner` (
            `identifier` varchar(60) NOT NULL,
            `xp` int(11) NOT NULL DEFAULT 0,
            `level` int(11) NOT NULL DEFAULT 1,
            PRIMARY KEY (`identifier`)
        )
    ]])
end)

function GetPlayerXP(identifier)
    local xp = 0
    local level = 1
    
    if playersXP[identifier] then
        return playersXP[identifier].xp, playersXP[identifier].level
    end
    
    local result = MySQL.query.await('SELECT xp, level FROM KJ_Mijner WHERE identifier = ?', {identifier})
    
    if result and #result > 0 then
        xp = result[1].xp
        level = result[1].level
    else
        MySQL.insert('INSERT INTO KJ_Mijner (identifier, xp, level) VALUES (?, ?, ?)', {
            identifier,
            xp,
            level
        })
    end
    
    playersXP[identifier] = {
        xp = xp,
        level = level
    }
    
    return xp, level
end

function UpdatePlayerXP(identifier, xp, level)
    playersXP[identifier] = {
        xp = xp,
        level = level
    }
    
    MySQL.update('UPDATE KJ_Mijner SET xp = ?, level = ? WHERE identifier = ?', {
        xp,
        level,
        identifier
    })
end

function AddPlayerXP(source, xpToAdd)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    local identifier = xPlayer.getIdentifier()
    local currentXP, currentLevel = GetPlayerXP(identifier)
    
    currentXP = currentXP + xpToAdd
    
    local requiredXP = currentLevel * Config.XP.levelMultiplier
    local leveledUp = false
    
    while currentXP >= requiredXP do
        currentXP = currentXP - requiredXP
        currentLevel = currentLevel + 1
        requiredXP = currentLevel * Config.XP.levelMultiplier
        leveledUp = true
    end
    
    UpdatePlayerXP(identifier, currentXP, currentLevel)
    
    TriggerClientEvent('KJ-Mijner:updateXP', source, currentXP, currentLevel, xpToAdd)
    
    if leveledUp then
        TriggerClientEvent('KJ-Mijner:levelUp', source, currentLevel)
    end
    
    return currentXP, currentLevel
end

RegisterNetEvent('KJ-Mijner:getPlayerXP')
AddEventHandler('KJ-Mijner:getPlayerXP', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    local xp, level = GetPlayerXP(xPlayer.getIdentifier())
    TriggerClientEvent('KJ-Mijner:setPlayerXP', source, xp, level)
end)

RegisterNetEvent('KJ-Mijner:rentAxe')
AddEventHandler('KJ-Mijner:rentAxe', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    if xPlayer.job.name ~= Config.MinerJob.name then
        TriggerClientEvent('KJ-Mijner:notifyPlayer', source, 
            Config.Locales[Config.Locale]['mining_job_title'], 
            Config.Locales[Config.Locale]['wrong_job'],
            'error')
        return
    end
    
    if exports.ox_inventory:Search(source, 'count', Config.Items.miningAxe) > 0 then
        TriggerClientEvent('KJ-Mijner:notifyPlayer', source, 
            Config.Locales[Config.Locale]['mining_job_title'], 
            Config.Locales[Config.Locale]['already_have_axe'],
            'error')
        return
    end
    
    if xPlayer.getMoney() < Config.AxeRentalPrice then
        TriggerClientEvent('KJ-Mijner:notifyPlayer', source, 
            Config.Locales[Config.Locale]['mining_job_title'], 
            Config.Locales[Config.Locale]['not_enough_money'],
            'error')
        return
    end
    
    if not exports.ox_inventory:CanCarryItem(source, Config.Items.miningAxe, 1) then
        TriggerClientEvent('KJ-Mijner:notifyPlayer', source, 
            Config.Locales[Config.Locale]['mining_job_title'], 
            Config.Locales[Config.Locale]['inventory_full'],
            'error')
        return
    end
    
    xPlayer.removeMoney(Config.AxeRentalPrice)
    
    local success = exports.ox_inventory:AddItem(source, Config.Items.miningAxe, 1)
    
    if success then
        TriggerClientEvent('KJ-Mijner:notifyPlayer', source, 
            Config.Locales[Config.Locale]['mining_job_title'], 
            string.format(Config.Locales[Config.Locale]['axe_rented'], Config.AxeRentalPrice),
            'success')
    else
        xPlayer.addMoney(Config.AxeRentalPrice)
        TriggerClientEvent('KJ-Mijner:notifyPlayer', source, 
            Config.Locales[Config.Locale]['mining_job_title'], 
            "Er ging iets mis bij het huren van een pikhouweel. Probeer het opnieuw.",
            'error')
    end
end)

RegisterNetEvent('KJ-Mijner:returnAxe')
AddEventHandler('KJ-Mijner:returnAxe', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    if xPlayer.job.name ~= Config.MinerJob.name then
        TriggerClientEvent('KJ-Mijner:notifyPlayer', source, 
            Config.Locales[Config.Locale]['mining_job_title'], 
            Config.Locales[Config.Locale]['wrong_job'],
            'error')
        return
    end
    
    if exports.ox_inventory:Search(source, 'count', Config.Items.miningAxe) <= 0 then
        TriggerClientEvent('KJ-Mijner:notifyPlayer', source, 
            Config.Locales[Config.Locale]['mining_job_title'], 
            Config.Locales[Config.Locale]['no_axe_to_return'],
            'error')
        return
    end
    
    exports.ox_inventory:RemoveItem(source, Config.Items.miningAxe, 1)
    
    local refundAmount = math.floor(Config.AxeRentalPrice * 0.75)
    
    xPlayer.addMoney(refundAmount)
    
    local message = string.format(Config.Locales[Config.Locale]['axe_deposit_returned'], refundAmount)
    
    TriggerClientEvent('KJ-Mijner:notifyPlayer', source, 
        Config.Locales[Config.Locale]['mining_job_title'], 
        message,
        'success')
end)

RegisterNetEvent('KJ-Mijner:mineResource')
AddEventHandler('KJ-Mijner:mineResource', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    if xPlayer.job.name ~= Config.MinerJob.name then
        TriggerClientEvent('KJ-Mijner:notifyPlayer', source, 
            Config.Locales[Config.Locale]['mining_job_title'], 
            Config.Locales[Config.Locale]['wrong_job'],
            'error')
        return
    end
    
    if exports.ox_inventory:Search(source, 'count', Config.Items.miningAxe) <= 0 then
        TriggerClientEvent('KJ-Mijner:notifyPlayer', source, 
            Config.Locales[Config.Locale]['mining_job_title'], 
            Config.Locales[Config.Locale]['need_axe'],
            'error')
        return
    end
    
    local _, level = GetPlayerXP(xPlayer.getIdentifier())
    
    local resource = DetermineResourceByLevel(level)
    
    local canCarry = exports.ox_inventory:CanCarryItem(source, resource.name, 1)
    
    if canCarry then
        exports.ox_inventory:AddItem(source, resource.name, 1)
        
        TriggerClientEvent('KJ-Mijner:notifyPlayer', source, 
            Config.Locales[Config.Locale]['mining_job_title'], 
            string.format(Config.Locales[Config.Locale]['mining_success'], resource.label),
            'success')
        
        AddPlayerXP(source, Config.XP.perMining)
    else
        TriggerClientEvent('KJ-Mijner:notifyPlayer', source, 
            Config.Locales[Config.Locale]['mining_job_title'], 
            Config.Locales[Config.Locale]['inventory_full'],
            'error')
    end
end)

function DetermineResourceByLevel(playerLevel)
    local items = {}
    local totalProbability = 0
    
    for i, item in ipairs(Config.MiningItems) do
        local adjustedProbability = item.baseProbability
        
        if i > 1 then
            adjustedProbability = adjustedProbability + (playerLevel * Config.XP.probabilityBonus)
        end
        
        table.insert(items, {
            name = item.name,
            label = item.label,
            probability = adjustedProbability,
            sellPrice = item.sellPrice
        })
        
        totalProbability = totalProbability + adjustedProbability
    end
    
    for i, item in ipairs(items) do
        item.probability = (item.probability / totalProbability) * 100
    end
    
    local random = math.random(1, 100)
    local cumulativeProbability = 0
    
    for _, item in ipairs(items) do
        cumulativeProbability = cumulativeProbability + item.probability
        
        if random <= cumulativeProbability then
            return item
        end
    end
    
    return items[1]
end

RegisterNetEvent('KJ-Mijner:sellAllResources')
AddEventHandler('KJ-Mijner:sellAllResources', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    if xPlayer.job.name ~= Config.MinerJob.name then
        TriggerClientEvent('KJ-Mijner:notifyPlayer', source, 
            Config.Locales[Config.Locale]['npc_title'], 
            Config.Locales[Config.Locale]['wrong_job'],
            'error')
        return
    end
    
    local totalEarnings = 0
    local anythingSold = false
    
    for _, item in ipairs(Config.MiningItems) do
        local count = exports.ox_inventory:Search(source, 'count', item.name)
        
        if count > 0 then
            local earnings = count * item.sellPrice
            exports.ox_inventory:RemoveItem(source, item.name, count)
            totalEarnings = totalEarnings + earnings
            anythingSold = true
        end
    end
    
    if anythingSold then
        xPlayer.addMoney(totalEarnings)
        
        local message = 'Je hebt al je grondstoffen verkocht voor $' .. totalEarnings
        
        TriggerClientEvent('KJ-Mijner:notifyPlayer', source, 
            Config.Locales[Config.Locale]['npc_title'], 
            message,
            'success')
    else
        TriggerClientEvent('KJ-Mijner:notifyPlayer', source, 
            Config.Locales[Config.Locale]['npc_title'], 
            Config.Locales[Config.Locale]['nothing_to_sell'],
            'error')
    end
end)

RegisterNetEvent('KJ-Mijner:sellResource')
AddEventHandler('KJ-Mijner:sellResource', function(resourceName)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    if xPlayer.job.name ~= Config.MinerJob.name then
        TriggerClientEvent('KJ-Mijner:notifyPlayer', source, 
            Config.Locales[Config.Locale]['npc_title'], 
            Config.Locales[Config.Locale]['wrong_job'],
            'error')
        return
    end
    
    local resourceData = nil
    for _, item in ipairs(Config.MiningItems) do
        if item.name == resourceName then
            resourceData = item
            break
        end
    end
    
    if not resourceData then return end
    
    local count = exports.ox_inventory:Search(source, 'count', resourceName)
    
    if count > 0 then
        local earnings = count * resourceData.sellPrice
        exports.ox_inventory:RemoveItem(source, resourceName, count)
        xPlayer.addMoney(earnings)
        
        TriggerClientEvent('KJ-Mijner:notifyPlayer', source, 
            Config.Locales[Config.Locale]['npc_title'], 
            string.format(Config.Locales[Config.Locale]['sold_item'], resourceData.label, count, earnings),
            'success')
    else
        TriggerClientEvent('KJ-Mijner:notifyPlayer', source, 
            Config.Locales[Config.Locale]['npc_title'], 
            Config.Locales[Config.Locale]['nothing_to_sell'],
            'error')
    end
end)

AddEventHandler('playerDropped', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if xPlayer then
        local identifier = xPlayer.getIdentifier()
        
        if playersXP[identifier] then
            MySQL.update('UPDATE KJ_Mijner SET xp = ?, level = ? WHERE identifier = ?', {
                playersXP[identifier].xp,
                playersXP[identifier].level,
                identifier
            })
            
            playersXP[identifier] = nil
        end
    end
end)

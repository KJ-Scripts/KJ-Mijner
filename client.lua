local ESX = exports["es_extended"]:getSharedObject()
local PlayerData = {}
local miningSpots = {}
local miningBlips = {}
local isProcessingAction = false
local npcMiner

if not Config.Locale or not Config.Locales or not Config.Locales[Config.Locale] then
    if not Config.Locale then Config.Locale = 'nl' end
    if not Config.Locales then Config.Locales = {} end
    if not Config.Locales[Config.Locale] then Config.Locales[Config.Locale] = {} end
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    TriggerServerEvent('KJ-Mijner:getPlayerXP')
    InitializeMining()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    local oldJob = PlayerData.job
    PlayerData.job = job
    
    if oldJob.name ~= job.name then
        if job.name == Config.MinerJob.name then
            for _, blip in pairs(miningBlips) do
                RemoveBlip(blip)
            end
            miningBlips = {}
            
            CreateMinerBlip()
            
            for i = 1, #Config.MiningSpots do
                local spot = Config.MiningSpots[i]
                if spot and spot.coords then
                    local blip = AddBlipForCoord(spot.coords.x, spot.coords.y, spot.coords.z)
                    SetBlipSprite(blip, 618)
                    SetBlipDisplay(blip, 4)
                    SetBlipScale(blip, 0.5)
                    SetBlipColour(blip, 5)
                    SetBlipAsShortRange(blip, true)
                    BeginTextCommandSetBlipName("STRING")
                    if Config.Locales and Config.Locale and Config.Locales[Config.Locale] and Config.Locales[Config.Locale]['mine_here'] then
                        AddTextComponentString(Config.Locales[Config.Locale]['mine_here'])
                    else
                        AddTextComponentString("Mijn Hier")
                    end
                    EndTextCommandSetBlipName(blip)
                    table.insert(miningBlips, blip)
                end
            end
        elseif oldJob.name == Config.MinerJob.name then
            for _, blip in pairs(miningBlips) do
                RemoveBlip(blip)
            end
            miningBlips = {}
            
            for i, zoneId in pairs(activeTargetZones) do
                if zoneId then
                    exports.ox_target:removeZone(zoneId)
                end
            end
            activeTargetZones = {}
        end
    end
end)

RegisterNetEvent('KJ-Mijner:setPlayerXP')
AddEventHandler('KJ-Mijner:setPlayerXP', function(xp, level)
    PlayerData.miningXP = xp
    PlayerData.miningLevel = level
end)

function InitializeMining()
    SpawnNPC()
    
    CreateMiningSpots()
    
    InitializeNPCTargets()
end

function SpawnNPC()
    ESX.Streaming.RequestModel(Config.MinerNPC.model)
    
    npcMiner = CreatePed(4, GetHashKey(Config.MinerNPC.model), 
        Config.MinerNPC.coords.x, Config.MinerNPC.coords.y, Config.MinerNPC.coords.z - 1.0, 
        Config.MinerNPC.coords.w, false, true)
    
    SetEntityHeading(npcMiner, Config.MinerNPC.coords.w)
    FreezeEntityPosition(npcMiner, true)
    SetEntityInvincible(npcMiner, true)
    SetBlockingOfNonTemporaryEvents(npcMiner, true)
    
    if Config.MinerNPC.scenario then
        TaskStartScenarioInPlace(npcMiner, Config.MinerNPC.scenario, 0, true)
    end
    
    if PlayerData.job and PlayerData.job.name == Config.MinerJob.name then
        CreateMinerBlip()
    end
end

function CreateMinerBlip()
    local blipConfig = Config.MinerNPC.blip
    local minerBlip = AddBlipForCoord(Config.MinerNPC.coords.x, Config.MinerNPC.coords.y, Config.MinerNPC.coords.z)
    
    SetBlipSprite(minerBlip, blipConfig.sprite)
    SetBlipDisplay(minerBlip, blipConfig.display)
    SetBlipScale(minerBlip, blipConfig.scale)
    SetBlipColour(minerBlip, blipConfig.color)
    SetBlipAsShortRange(minerBlip, true)
    
    BeginTextCommandSetBlipName("STRING")
    if Config.Locales and Config.Locale and Config.Locales[Config.Locale] and Config.Locales[Config.Locale]['mining_job_title'] then
        AddTextComponentString(Config.Locales[Config.Locale]['mining_job_title'])
    else
        AddTextComponentString("Mijnwerker Job")
    end
    EndTextCommandSetBlipName(minerBlip)
    
    table.insert(miningBlips, minerBlip)
end

function InitializeNPCTargets()
    exports.ox_target:addLocalEntity(npcMiner, {
        {
            name = 'mining_foreman',
            icon = 'fas fa-hard-hat',
            label = Config.Locales and Config.Locale and Config.Locales[Config.Locale] and Config.Locales[Config.Locale]['npc_context'] or "Talk to Mining Foreman",
            onSelect = function()
                if PlayerData.job and PlayerData.job.name == Config.MinerJob.name then
                    OpenMinerMenu()
                else
                    local title = Config.Locales and Config.Locale and Config.Locales[Config.Locale] and Config.Locales[Config.Locale]['npc_title'] or "Mining Foreman"
                    local desc = Config.Locales and Config.Locale and Config.Locales[Config.Locale] and Config.Locales[Config.Locale]['wrong_job'] or "You are not a miner"
                    
                    lib.notify({
                        title = title,
                        description = desc,
                        type = 'error'
                    })
                end
            end,
            distance = 2.0
        }
    })
end

local activeTargetZones = {}

function SelectRandomMiningSpots()
    Config.MiningSpots = {}
    
    local availableSpots = {}
    for i, spot in ipairs(Config.AllMiningSpots) do
        table.insert(availableSpots, {
            index = i,
            coords = spot.coords
        })
    end
    
    for i = 1, math.min(Config.ActiveMiningSpots, #availableSpots) do
        local randomIndex = math.random(1, #availableSpots)
        local selectedSpot = availableSpots[randomIndex]
        
            table.insert(Config.MiningSpots, {
            originalIndex = selectedSpot.index,
            coords = selectedSpot.coords
        })
        
        table.remove(availableSpots, randomIndex)
    end
end

function ReplaceMiningSpot(spotIndex)
    local minedSpot = Config.MiningSpots[spotIndex]
    if not minedSpot then return end
    
    if activeTargetZones[spotIndex] then
        exports.ox_target:removeZone(activeTargetZones[spotIndex])
        activeTargetZones[spotIndex] = nil
    end
    
    for i, blip in ipairs(miningBlips) do
        local blipCoords = GetBlipCoords(blip)
        local distance = #(vector3(blipCoords.x, blipCoords.y, blipCoords.z) - minedSpot.coords)
        
        if distance < 1.0 then
            RemoveBlip(blip)
            table.remove(miningBlips, i)
            break
        end
    end
    
    local availableSpots = {}
    for i, spot in ipairs(Config.AllMiningSpots) do
        local isActive = false
        
        for _, activeSpot in ipairs(Config.MiningSpots) do
            if activeSpot.originalIndex == i then
                isActive = true
                break
            end
        end
        
        if not isActive then
            table.insert(availableSpots, {
                index = i,
                coords = spot.coords
            })
        end
    end
    
    if #availableSpots > 0 then
        local randomIndex = math.random(1, #availableSpots)
        local newSpot = availableSpots[randomIndex]
        
        Config.MiningSpots[spotIndex] = {
            originalIndex = newSpot.index,
            coords = newSpot.coords
        }
        
        CreateSingleMiningSpot(spotIndex)
    end
end

function CreateSingleMiningSpot(spotIndex)
    local spot = Config.MiningSpots[spotIndex]
    if not spot then return end
    
    if PlayerData.job and PlayerData.job.name == Config.MinerJob.name then
        local blip = AddBlipForCoord(spot.coords.x, spot.coords.y, spot.coords.z)
        SetBlipSprite(blip, 618)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 0.5)
        SetBlipColour(blip, 5)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        if Config.Locales and Config.Locale and Config.Locales[Config.Locale] and Config.Locales[Config.Locale]['mine_here'] then
            AddTextComponentString(Config.Locales[Config.Locale]['mine_here'])
        else
            AddTextComponentString("Mijn Hier")
        end
        EndTextCommandSetBlipName(blip)
        table.insert(miningBlips, blip)
    end
    
    local targetId = "mining_spot_" .. spotIndex
    activeTargetZones[spotIndex] = exports.ox_target:addSphereZone({
        coords = vector3(spot.coords.x, spot.coords.y, spot.coords.z),
        radius = 1.5,
        options = {
            {
                name = targetId,
                icon = 'fas fa-arrow-down',
                iconColor = 'rgb(0, 255, 0)',
                label = Config.Locales and Config.Locale and Config.Locales[Config.Locale] and Config.Locales[Config.Locale]['mine_here'] or "Mijn Hier",
                onSelect = function()
                    StartMining(spotIndex)
                end,
                distance = 2.0
            }
        }
    })
end

function CreateMiningSpots()
    SelectRandomMiningSpots()
    
    for i = 1, #Config.MiningSpots do
        CreateSingleMiningSpot(i)
    end
end

function OpenMinerMenu()
    local xp = PlayerData.miningXP or 0
    local level = PlayerData.miningLevel or 1
    local nextLevelXP = level * Config.XP.levelMultiplier
    local neededXP = nextLevelXP - xp
    
    local options = {}
    
    local xpText = string.format(Config.Locales[Config.Locale]['xp_level'], level, xp, nextLevelXP)
    local neededXPText = string.format(Config.Locales[Config.Locale]['xp_next_level'], neededXP)
    
    table.insert(options, {
        title = "Level: " .. level .. " - XP: " .. xp .. "/" .. nextLevelXP,
        description = neededXPText,
        disabled = true,
        icon = 'fas fa-star',
        iconColor = 'yellow',
    })
    
    local hasAxe = exports.ox_inventory:Search('count', Config.Items.miningAxe) > 0
    
    if hasAxe then
        table.insert(options, {
            title = Config.Locales[Config.Locale]['return_axe'],
            description = "Breng je pikhouweel terug",
            icon = 'fas fa-undo',
            onSelect = function()
                ReturnMiningAxe()
            end
        })
    else
        table.insert(options, {
            title = string.format(Config.Locales[Config.Locale]['rent_axe'], Config.AxeRentalPrice),
            description = "Huur een pikhouweel om mee te graven",
            icon = 'fas fa-shopping-cart',
            iconColor = 'white',
            onSelect = function()
                RentMiningAxe()
            end
        })
    end
    
    table.insert(options, {
        title = Config.Locales[Config.Locale]['sell_resources'],
        description = "Verkoop je grondstoffen voor geld",
        icon = 'fas fa-dollar-sign',
        iconColor = 'white',
        onSelect = function()
            OpenResourceSellerMenu()
        end
    })
    
    lib.registerContext({
        id = 'miner_menu',
        title = Config.Locales[Config.Locale]['npc_title'],
        options = options
    })
    
    lib.showContext('miner_menu')
end

function OpenXPMenu()
    local xp = PlayerData.miningXP or 0
    local level = PlayerData.miningLevel or 1
    local nextLevelXP = level * Config.XP.levelMultiplier
    local neededXP = nextLevelXP - xp
    
    lib.alertDialog({
        header = Config.Locales[Config.Locale]['xp_menu_title'],
        content = {
            {
                icon = 'fas fa-star',
                header = string.format(Config.Locales[Config.Locale]['xp_level'], level, xp, nextLevelXP),
                text = string.format(Config.Locales[Config.Locale]['xp_next_level'], neededXP),
                iconColor = 'white'
            }
        },
        centered = true,
        size = 'sm',
        showCancel = false
    })
end

function RentMiningAxe()
    TriggerServerEvent('KJ-Mijner:rentAxe')
end

function ReturnMiningAxe()
    TriggerServerEvent('KJ-Mijner:returnAxe')
end

function StartMining(spotIndex)
    if isProcessingAction then
        return
    end
    
    if not (PlayerData.job and PlayerData.job.name == Config.MinerJob.name) then
        local title = Config.Locales and Config.Locale and Config.Locales[Config.Locale] and Config.Locales[Config.Locale]['mining_job_title'] or "Mining Job"
        local desc = Config.Locales and Config.Locale and Config.Locales[Config.Locale] and Config.Locales[Config.Locale]['wrong_job'] or "You are not a miner"
        
        lib.notify({
            title = title,
            description = desc,
            type = 'error'
        })
        return
    end
    
    if exports.ox_inventory:Search('count', Config.Items.miningAxe) <= 0 then
        local title = Config.Locales and Config.Locale and Config.Locales[Config.Locale] and Config.Locales[Config.Locale]['mining_job_title'] or "Mining Job"
        local desc = Config.Locales and Config.Locale and Config.Locales[Config.Locale] and Config.Locales[Config.Locale]['need_axe'] or "You need a mining axe"
        
        lib.notify({
            title = title,
            description = desc,
            type = 'error'
        })
        return
    end
    
    isProcessingAction = true
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    
    lib.requestAnimDict('melee@large_wpn@streamed_core')
    
    local axeModel = `prop_tool_pickaxe`
    lib.requestModel(axeModel)
    
    local axe = CreateObject(axeModel, coords.x, coords.y, coords.z, true, true, true)
    AttachEntityToEntity(axe, playerPed, GetPedBoneIndex(playerPed, 57005), 0.18, -0.02, -0.02, 350.0, 100.00, 140.0, true, true, false, true, 1, true)
    
    if lib.progressBar({
        duration = Config.MiningDuration,
        label = Config.Locales[Config.Locale]['mining_in_progress'],
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'melee@large_wpn@streamed_core',
            clip = 'ground_attack_on_spot'
        },
    }) then
        DeleteEntity(axe)
        TriggerServerEvent('KJ-Mijner:mineResource')
        
        if spotIndex then
            Citizen.SetTimeout(500, function()
                ReplaceMiningSpot(spotIndex)
            end)
        end
    else
        DeleteEntity(axe)
        lib.notify({
            title = Config.Locales[Config.Locale]['mining_job_title'],
            description = Config.Locales[Config.Locale]['mining_failed'],
            type = 'error'
        })
    end
    
    isProcessingAction = false
end

function OpenResourceSellerMenu()
    local options = {
        {
            title = Config.Locales[Config.Locale]['sell_all'],
            icon = 'fas fa-dollar-sign',
            onSelect = function()
                TriggerServerEvent('KJ-Mijner:sellAllResources')
            end
        }
    }
    
    local individualOptions = {}
    local hasItems = false
    
    for _, item in ipairs(Config.MiningItems) do
        local count = exports.ox_inventory:Search('count', item.name)
        if count > 0 then
            hasItems = true
            table.insert(individualOptions, {
                title = string.format(Config.Locales[Config.Locale]['sell_item'], item.label, count, count * item.sellPrice),
                icon = 'fas fa-dollar-sign',
                onSelect = function()
                    TriggerServerEvent('KJ-Mijner:sellResource', item.name)
                end
            })
        end
    end
    
    if hasItems then
        table.insert(options, {
            title = Config.Locales[Config.Locale]['sell_individual'],
            icon = 'fas fa-list',
            menu = 'individual_sell_menu'
        })
        
        lib.registerContext({
            id = 'individual_sell_menu',
            title = Config.Locales[Config.Locale]['sell_resources'],
            menu = 'resource_seller_menu',
            options = individualOptions
        })
    else
        table.insert(options, {
            title = Config.Locales[Config.Locale]['nothing_to_sell'],
            icon = 'fas fa-times',
            disabled = true
        })
    end
    
    lib.registerContext({
        id = 'resource_seller_menu',
        title = Config.Locales[Config.Locale]['sell_resources'],
        options = options
    })
    
    lib.showContext('resource_seller_menu')
end

RegisterNetEvent('KJ-Mijner:notifyPlayer')
AddEventHandler('KJ-Mijner:notifyPlayer', function(title, message, type)
    lib.notify({
        title = title,
        description = message,
        type = type or 'info'
    })
end)

RegisterNetEvent('KJ-Mijner:setPlayerXP')
AddEventHandler('KJ-Mijner:setPlayerXP', function(xp, level)
    PlayerData.miningXP = xp
    PlayerData.miningLevel = level
end)

RegisterNetEvent('KJ-Mijner:updateXP')
AddEventHandler('KJ-Mijner:updateXP', function(xp, level, gained)
    PlayerData.miningXP = xp
    PlayerData.miningLevel = level
    
    if gained then
        lib.notify({
            title = Config.Locales[Config.Locale]['xp_menu_title'],
            description = string.format(Config.Locales[Config.Locale]['xp_gained'], gained),
            type = 'success'
        })
    end
end)

RegisterNetEvent('KJ-Mijner:levelUp')
AddEventHandler('KJ-Mijner:levelUp', function(level)
    lib.notify({
        title = Config.Locales[Config.Locale]['xp_menu_title'],
        description = string.format(Config.Locales[Config.Locale]['xp_level_up'], level),
        type = 'success',
        icon = 'fas fa-star'
    })
    
    PlaySoundFrontend(-1, "RACE_PLACED", "HUD_AWARDS", 1)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if DoesEntityExist(npcMiner) then
            DeleteEntity(npcMiner)
        end
        
        for _, blip in pairs(miningBlips) do
            RemoveBlip(blip)
        end
        
        for i, zoneId in pairs(activeTargetZones) do
            if zoneId then
                exports.ox_target:removeZone(zoneId)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while ESX == nil do
        Citizen.Wait(100)
    end
    
    PlayerData = ESX.GetPlayerData()
    TriggerServerEvent('KJ-Mijner:getPlayerXP')
    InitializeMining()
end)

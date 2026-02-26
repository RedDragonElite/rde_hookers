local Ox = require '@ox_core.lib.init'
local ox_inventory = exports.ox_inventory

-- ═══════════════════════════════════════════════════
--  🌐  Locale Helper
-- ═══════════════════════════════════════════════════

---Translate a key, with optional string.format args.
---Falls back to EN if key missing in active locale.
---@param key string
---@param ... any
local function T(key, ...)
    local locale = Config.Locales[Config.Locale] or Config.Locales['en']
    local str    = locale[key] or Config.Locales['en'][key] or key
    if select('#', ...) > 0 then
        return str:format(...)
    end
    return str
end

-- ═══════════════════════════════════════════════════
--  🎯  State Management
-- ═══════════════════════════════════════════════════
local State = {
    activeHooker      = nil,
    trackedHookers    = {},
    isNearHooker      = false,
    inService         = false,
    vehicleStationary = false,
    lastVehicleSpeed  = 0,
    uiVisible         = false,
    hookerInVehicle   = false,
    lastInviteTime    = 0,
}

-- ═══════════════════════════════════════════════════
--  🛠️  Utility
-- ═══════════════════════════════════════════════════

local function Debug(...)
    if not Config.Debug then return end
    print(('[^5HOOKER CLIENT^7] %s'):format(table.concat({...}, ' ')))
end

local function GetCurrentVehicle()
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    return vehicle ~= 0 and vehicle or nil
end

local function IsDriver(vehicle)
    return vehicle and GetPedInVehicleSeat(vehicle, -1) == cache.ped
end

local function GetVehicleSpeedKmh(vehicle)
    return GetEntitySpeed(vehicle) * 3.6
end

local function IsVehicleStationary(vehicle)
    if not vehicle then return false end
    local speed    = GetVehicleSpeedKmh(vehicle)
    local avgSpeed = (speed + (State.lastVehicleSpeed or 0)) / 2
    State.lastVehicleSpeed = speed
    local engineOff = not GetIsVehicleEngineRunning(vehicle)
    local inNeutral = GetVehicleCurrentGear(vehicle) == 0
    return avgSpeed < Config.MaxServiceSpeed and (engineOff or inNeutral or GetVehicleHandbrake(vehicle))
end

local function ValidateHooker(hooker)
    if not hooker or not DoesEntityExist(hooker) then
        return false, T('hooker_invalid')
    end
    local state = Entity(hooker).state
    if not state then
        return false, T('hooker_invalid')
    end
    if state.withPlayer and state.withPlayer ~= cache.serverId then
        return false, T('hooker_invalid')
    end
    return true
end

local function HideUI()
    if State.uiVisible then
        lib.hideTextUI()
        State.uiVisible = false
    end
end

-- ═══════════════════════════════════════════════════
--  🎬  Hooker Management
-- ═══════════════════════════════════════════════════

function InviteHooker(hooker)
    local now = GetGameTimer()
    if now - State.lastInviteTime < 2000 then
        Debug('⚠️ Throttled: Too many invite attempts')
        return
    end
    State.lastInviteTime = now

    if not DoesEntityExist(hooker) then
        Debug('❌ Hooker entity does not exist')
        return
    end

    local valid, reason = ValidateHooker(hooker)
    if not valid then
        lib.notify({ title = Config.Icons.error .. ' ' .. T('not_available'), description = reason, type = 'error' })
        return
    end

    local vehicle = GetCurrentVehicle()
    if not vehicle then
        lib.notify({ title = Config.Icons.error .. ' ' .. T('not_available'), description = T('no_vehicle'), type = 'error' })
        return
    end

    if not IsDriver(vehicle) then
        lib.notify({ title = Config.Icons.error .. ' ' .. T('not_available'), description = T('not_driver'), type = 'error' })
        return
    end

    if State.activeHooker then
        lib.notify({ title = Config.Icons.error .. ' ' .. T('not_available'), description = T('already_busy'), type = 'error' })
        return
    end

    Debug('💋 Inviting hooker to vehicle...')
    TriggerServerEvent('hooker:inviteHooker', NetworkGetNetworkIdFromEntity(hooker))
end

function DismissHooker(hooker)
    if not DoesEntityExist(hooker) then return end
    Debug('👋 Dismissing hooker...')
    TriggerServerEvent('hooker:dismissHooker', NetworkGetNetworkIdFromEntity(hooker))
end

-- ═══════════════════════════════════════════════════
--  📨  Network Events — Hooker Lifecycle
-- ═══════════════════════════════════════════════════

RegisterNetEvent('hooker:invitationAccepted', function(hookerNetId)
    local hooker  = NetworkGetEntityFromNetworkId(hookerNetId)
    local vehicle = GetCurrentVehicle()

    if not DoesEntityExist(hooker) or not vehicle then
        Debug('❌ Hooker or vehicle missing on invitationAccepted')
        return
    end

    Debug('✅ Invitation accepted — entity:', hooker)

    SetEntityAsMissionEntity(hooker, true, true)
    SetBlockingOfNonTemporaryEvents(hooker, true)
    ClearPedTasksImmediately(hooker)
    TaskEnterVehicle(hooker, vehicle, -1, 0, 1.0, 1, 0)

    CreateThread(function()
        local timeout = 0
        while timeout < 100 do
            Wait(100)
            timeout += 1
            if IsPedInVehicle(hooker, vehicle, false) then
                PlayAmbientSpeech1(hooker,
                    Config.Speech.greeting[math.random(#Config.Speech.greeting)],
                    'SPEECH_PARAMS_FORCE')

                lib.notify({
                    title       = Config.Icons.success .. ' ' .. T('shes_in'),
                    description = T('shes_in_desc'),
                    type        = 'success',
                    duration    = 5000,
                })

                State.activeHooker         = hooker
                State.hookerInVehicle      = true
                State.trackedHookers[hooker] = true
                Debug('🎉 Hooker successfully entered vehicle')
                return
            end
        end

        Debug('⚠️ Hooker enter timeout — auto-dismissing')
        TriggerServerEvent('hooker:dismissHooker', hookerNetId)
    end)
end)

RegisterNetEvent('hooker:dismissed', function(hookerNetId)
    local hooker = NetworkGetEntityFromNetworkId(hookerNetId)

    if State.activeHooker == hooker then
        State.activeHooker    = nil
        State.hookerInVehicle = false
        State.inService       = false
    end
    State.trackedHookers[hooker] = nil
    HideUI()

    if DoesEntityExist(hooker) then
        PlayAmbientSpeech1(hooker,
            Config.Speech.leaving[math.random(#Config.Speech.leaving)],
            'SPEECH_PARAMS_FORCE')
        Wait(1000)

        local hookerVeh = GetVehiclePedIsIn(hooker, false)
        if hookerVeh ~= 0 then
            TaskLeaveVehicle(hooker, hookerVeh, 0)
            Wait(2000)
        end

        TaskWanderStandard(hooker, 10.0, 10)

        SetTimeout(10000, function()
            if DoesEntityExist(hooker) then
                SetEntityAsMissionEntity(hooker, false, true)
            end
        end)
    end

    lib.notify({ title = Config.Icons.info .. ' ' .. T('hooker_left'), description = T('hooker_left_desc'), type = 'info' })
    Debug('✅ Hooker dismissed')
end)

RegisterNetEvent('hooker:serviceAborted', function()
    State.inService = false
    Debug('⚠️ Service aborted by server')
end)

-- ═══════════════════════════════════════════════════
--  🎭  Service Menu & Execution
-- ═══════════════════════════════════════════════════

function OpenServiceMenu()
    if not State.activeHooker or not DoesEntityExist(State.activeHooker) then
        Debug('❌ No active hooker')
        return
    end

    if State.inService then
        lib.notify({ title = Config.Icons.error .. ' ' .. T('not_available'), description = T('service_busy'), type = 'error' })
        return
    end

    local vehicle = GetCurrentVehicle()
    if not vehicle or not State.vehicleStationary then
        lib.notify({ title = Config.Icons.car .. ' ' .. T('not_available'), description = T('vehicle_moving'), type = 'error' })
        return
    end

    PlayAmbientSpeech1(State.activeHooker, Config.Speech.offer[1], 'SPEECH_PARAMS_FORCE_SHOUTED_CLEAR')

    lib.registerContext({
        id      = 'hooker_service_menu',
        title   = T('menu_title'),
        options = {
            {
                title       = T('blowjob_title'),
                description = Config.Icons.money .. ' **$' .. Config.BlowjobPrice .. '** • ' .. Config.BlowjobDuration .. 's • ' .. T('blowjob_desc'),
                icon        = 'fa-solid fa-lips',
                iconColor   = '#ff69b4',
                onSelect    = function()
                    State.inService = true
                    TriggerServerEvent('hooker:requestService', 'blowjob', NetworkGetNetworkIdFromEntity(State.activeHooker))
                end,
            },
            {
                title       = T('sex_title'),
                description = Config.Icons.money .. ' **$' .. Config.SexPrice .. '** • ' .. Config.SexDuration .. 's • ' .. T('sex_desc'),
                icon        = 'fa-solid fa-fire',
                iconColor   = '#ff1493',
                onSelect    = function()
                    State.inService = true
                    TriggerServerEvent('hooker:requestService', 'sex', NetworkGetNetworkIdFromEntity(State.activeHooker))
                end,
            },
            {
                title       = T('dismiss_title'),
                description = T('dismiss_desc'),
                icon        = 'fa-solid fa-door-open',
                iconColor   = '#ffa500',
                onSelect    = function()
                    DismissHooker(State.activeHooker)
                end,
            },
            {
                title       = T('cancel_title'),
                description = T('cancel_desc'),
                icon        = 'fa-solid fa-xmark',
                iconColor   = '#808080',
                onSelect    = function()
                    lib.hideContext()
                end,
            },
        },
    })
    lib.showContext('hooker_service_menu')
end

RegisterNetEvent('hooker:startService', function(serviceType, hookerNetId)
    local hooker = NetworkGetEntityFromNetworkId(hookerNetId)
    if not DoesEntityExist(hooker) then
        Debug('❌ Hooker not found for service start')
        State.inService = false
        return
    end

    local vehicle = GetCurrentVehicle()
    if not vehicle then
        lib.notify({ title = Config.Icons.error .. ' ' .. T('not_available'), description = T('no_vehicle'), type = 'error' })
        State.inService = false
        return
    end

    Debug('🔥 Starting service:', serviceType)

    local cfg         = Config.Animations[serviceType]
    local duration    = serviceType == 'blowjob' and Config.BlowjobDuration or Config.SexDuration
    local serviceName = serviceType == 'blowjob' and T('blowjob_title') or T('sex_title')

    lib.requestAnimDict(cfg.hooker.dict)
    lib.requestAnimDict(cfg.player.dict)

    local wasEngineOn = GetIsVehicleEngineRunning(vehicle)
    SetVehicleEngineOn(vehicle, false, true, true)
    FreezeEntityPosition(vehicle, true)

    TaskPlayAnim(hooker,    cfg.hooker.dict, cfg.hooker.anim, 8.0, -8.0, -1, cfg.hooker.flag, 0, false, false, false)
    TaskPlayAnim(cache.ped, cfg.player.dict, cfg.player.anim, 8.0, -8.0, -1, cfg.player.flag, 0, false, false, false)

    local speechLines = serviceType == 'blowjob' and Config.Speech.during_blowjob or Config.Speech.during_sex
    CreateThread(function()
        for _ = 1, 5 do
            Wait(math.floor((duration / 5) * 1000))
            if DoesEntityExist(hooker) and State.inService then
                PlayAmbientSpeech1(hooker, speechLines[math.random(#speechLines)], 'SPEECH_PARAMS_FORCE_SHOUTED_CLEAR')
            end
        end
    end)

    local success = lib.progressCircle({
        duration     = duration * 1000,
        position     = 'bottom',
        label        = serviceName .. ' ' .. T('service_in_progress'),
        useWhileDead = false,
        canCancel    = false,
        disable      = { move = true, car = true, combat = true, mouse = false },
    })

    ClearPedTasks(cache.ped)
    if DoesEntityExist(hooker) then ClearPedTasks(hooker) end
    FreezeEntityPosition(vehicle, false)
    if wasEngineOn then SetVehicleEngineOn(vehicle, true, true, false) end

    if success and DoesEntityExist(hooker) then
        PlayAmbientSpeech1(hooker, Config.Speech.finished[1],    'SPEECH_PARAMS_FORCE_SHOUTED_CLEAR')
        Wait(2500)
        PlayAmbientSpeech1(hooker, Config.Speech.offer_again[1], 'SPEECH_PARAMS_FORCE_SHOUTED_CLEAR')
        lib.notify({ title = Config.Icons.success .. ' ' .. T('service_complete'), description = T('service_complete_desc'), type = 'success' })
    end

    State.inService = false
    Debug('✅ Service completed:', serviceType)
end)

-- ═══════════════════════════════════════════════════
--  🎯  ox_target Integration
-- ═══════════════════════════════════════════════════

CreateThread(function()
    while not Ox or not exports.ox_target or not exports.ox_inventory do
        Wait(100)
    end

    exports.ox_target:addModel(Config.HookerModels, {
        {
            name        = 'hooker_invite',
            icon        = 'fa-solid fa-heart',
            label       = '💋 ' .. T('invite_accepted'),
            distance    = Config.Advanced.InteractionDistance or 3.0,
            canInteract = function(entity)
                local vehicle = GetCurrentVehicle()
                if not vehicle                                       then return false end
                if not IsDriver(vehicle)                             then return false end
                if not IsVehicleSeatFree(vehicle, 0)                then return false end
                if IsPedInAnyVehicle(entity, false)                 then return false end
                local st = Entity(entity).state
                if st.withPlayer and st.withPlayer ~= cache.serverId then return false end
                return true
            end,
            onSelect    = function(data) InviteHooker(data.entity) end,
        },
        {
            name        = 'hooker_dismiss',
            icon        = 'fa-solid fa-door-open',
            label       = T('dismiss_title'),
            distance    = Config.Advanced.InteractionDistance or 3.0,
            canInteract = function(entity)
                local vehicle = GetCurrentVehicle()
                if not vehicle                                          then return false end
                if GetVehiclePedIsIn(entity, false) ~= vehicle          then return false end
                local st = Entity(entity).state
                if not st.withPlayer or st.withPlayer ~= cache.serverId then return false end
                return true
            end,
            onSelect    = function(data) DismissHooker(data.entity) end,
        },
    })

    Debug('🎯 ox_target registered')
end)

-- ═══════════════════════════════════════════════════
--  🔄  Main Threads
-- ═══════════════════════════════════════════════════

-- Thread 1: Auto-open service menu after stationary timer
CreateThread(function()
    local stationaryTimer = 0
    local menuOpened      = false

    while true do
        local sleep = 500

        if State.activeHooker and DoesEntityExist(State.activeHooker) then
            local vehicle = GetCurrentVehicle()

            if vehicle and GetVehiclePedIsIn(State.activeHooker, false) == vehicle then
                State.hookerInVehicle   = true
                State.vehicleStationary = IsVehicleStationary(vehicle)

                if State.vehicleStationary and not State.inService then
                    sleep = 100
                    stationaryTimer = stationaryTimer + sleep

                    if not State.uiVisible then
                        lib.showTextUI(T('menu_enjoying') .. '   ' .. T('menu_dismiss_hint'), {
                            position  = 'right-center',
                            icon      = 'fa-solid fa-heart',
                            iconColor = '#ff69b4',
                        })
                        State.uiVisible = true
                    end

                    local delay = Config.Advanced.AutoMenuDelay or 2500
                    if stationaryTimer >= delay and not menuOpened and not State.inService then
                        menuOpened = true
                        HideUI()
                        OpenServiceMenu()
                    end

                    -- [X] / FRONTEND_CANCEL — kein Konflikt im Fahrzeug
                    if IsControlJustPressed(0, 194) then
                        DismissHooker(State.activeHooker)
                    end

                else
                    stationaryTimer = 0
                    menuOpened      = false
                    HideUI()
                end
            else
                State.hookerInVehicle = false
                stationaryTimer       = 0
                menuOpened            = false
                HideUI()
            end
        else
            State.hookerInVehicle = false
            stationaryTimer       = 0
            menuOpened            = false
            HideUI()
        end

        Wait(sleep)
    end
end)

-- Thread 2: Statebag validation
CreateThread(function()
    while true do
        Wait(Config.Advanced.StateValidationInterval or 2000)

        if State.activeHooker and DoesEntityExist(State.activeHooker) then
            local st = Entity(State.activeHooker).state
            if not st.withPlayer or st.withPlayer ~= cache.serverId then
                Debug('⚠️ Statebag mismatch — cleaning up local state')
                State.activeHooker    = nil
                State.hookerInVehicle = false
                State.inService       = false
                HideUI()
            end
        end
    end
end)

-- Thread 3: Auto-dismiss on death or hooker falling out
CreateThread(function()
    while true do
        Wait(1000)

        if State.activeHooker and DoesEntityExist(State.activeHooker) then
            local hookerVeh = GetVehiclePedIsIn(State.activeHooker, false)

            if IsEntityDead(cache.ped) then
                Debug('🧹 Player died — dismissing hooker')
                DismissHooker(State.activeHooker)
            elseif State.hookerInVehicle and hookerVeh == 0 then
                Debug('🧹 Hooker left vehicle unexpectedly — dismissing')
                DismissHooker(State.activeHooker)
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════
--  📡  Statebag Change Handlers
-- ═══════════════════════════════════════════════════

AddStateBagChangeHandler('withPlayer', nil, function(bagName, _, value, _unused, replicated)
    if not replicated then return end

    local entity = GetEntityFromStateBagName(bagName)
    if entity == 0 or not DoesEntityExist(entity) then return end

    local model    = GetEntityModel(entity)
    local isHooker = false
    for _, hookerModel in ipairs(Config.HookerModels) do
        if model == hookerModel then isHooker = true; break end
    end
    if not isHooker then return end

    if value == cache.serverId then
        Debug('📡 Hooker assigned to us:', entity)
        State.trackedHookers[entity] = true
    elseif State.trackedHookers[entity] then
        Debug('📡 Hooker no longer ours:', entity)
        if State.activeHooker == entity then
            State.activeHooker    = nil
            State.hookerInVehicle = false
        end
        State.trackedHookers[entity] = nil
    end
end)

-- ═══════════════════════════════════════════════════
--  🧹  Resource Cleanup
-- ═══════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Debug('🛑 Resource stopping — cleaning up…')

    HideUI()

    for hooker in pairs(State.trackedHookers) do
        if DoesEntityExist(hooker) then
            Entity(hooker).state:set('withPlayer', nil, true)
            SetEntityAsMissionEntity(hooker, false, true)
            ClearPedTasksImmediately(hooker)
            TaskWanderStandard(hooker, 10.0, 10)
        end
    end

    State.activeHooker    = nil
    State.trackedHookers  = {}
    State.inService       = false
    State.hookerInVehicle = false

    Debug('✅ Cleanup complete')
end)

Debug('✅ Client initialised | Locale: ' .. Config.Locale)
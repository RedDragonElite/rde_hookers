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
local ServerState = {
    hookerData    = {},
    playerHookers = {},
    serviceStats  = {
        totalInvites  = 0,
        totalServices = 0,
        totalRevenue  = 0,
        blowjobs      = 0,
        fullServices  = 0,
    },
}

-- ═══════════════════════════════════════════════════
--  🛠️  Utility
-- ═══════════════════════════════════════════════════

local function GetPedName(playerId)
    return GetPlayerName(playerId) or 'Unknown'
end

local function Debug(...)
    if not Config.Debug then return end
    print(('[^5HOOKER^7][^3SERVER^7][^2%s^7] %s'):format(
        os.date('%H:%M:%S'),
        table.concat({...}, ' ')
    ))
end

-- ═══════════════════════════════════════════════════
--  📡  Nostr Logger — Optional Integration
-- ═══════════════════════════════════════════════════

local function NostrLog(message, tags)
    if GetResourceState('rde_nostr_log') ~= 'started' then return end
    local ok, err = pcall(function()
        exports['rde_nostr_log']:postLog(message, tags or {})
    end)
    if not ok and Config.Debug then
        print(('[^5HOOKER^7][^1NOSTR-ERR^7] %s'):format(tostring(err)))
    end
end

local function NostrInvite(playerId, hookerNetId)
    NostrLog(('💋 [HOOKER] %s (ID:%d) invited hooker (NetID:%d)'):format(GetPedName(playerId), playerId, hookerNetId), {
        { 'script', 'rde_hookers' }, { 'event', 'hooker_invite' },
        { 'player_id', tostring(playerId) }, { 'player_name', GetPedName(playerId) },
        { 'hooker_net', tostring(hookerNetId) },
    })
end

local function NostrService(playerId, serviceType, price)
    local emoji = serviceType == 'blowjob' and '👄' or '🔥'
    NostrLog(('%s [HOOKER] %s (ID:%d) purchased %s for $%d'):format(emoji, GetPedName(playerId), playerId, serviceType, price), {
        { 'script', 'rde_hookers' }, { 'event', 'hooker_service' },
        { 'player_id', tostring(playerId) }, { 'player_name', GetPedName(playerId) },
        { 'service_type', serviceType }, { 'price', tostring(price) },
    })
end

local function NostrServiceAbort(playerId, serviceType, reason)
    NostrLog(('❌ [HOOKER] %s (ID:%d) – service "%s" aborted: %s'):format(GetPedName(playerId), playerId, serviceType, reason), {
        { 'script', 'rde_hookers' }, { 'event', 'hooker_service_abort' },
        { 'player_id', tostring(playerId) }, { 'player_name', GetPedName(playerId) },
        { 'service_type', serviceType }, { 'reason', reason },
    })
end

local function NostrDismiss(playerId, hookerNetId, reason)
    NostrLog(('👋 [HOOKER] %s (ID:%d) dismissed hooker (NetID:%d) – %s'):format(GetPedName(playerId), playerId, hookerNetId, reason or 'manual'), {
        { 'script', 'rde_hookers' }, { 'event', 'hooker_dismiss' },
        { 'player_id', tostring(playerId) }, { 'player_name', GetPedName(playerId) },
        { 'hooker_net', tostring(hookerNetId) }, { 'reason', reason or 'manual' },
    })
end

local function NostrDisconnect(playerId, playerName, reason)
    NostrLog(('🚪 [HOOKER] %s (ID:%d) disconnected with active hooker – %s'):format(playerName, playerId, reason or '?'), {
        { 'script', 'rde_hookers' }, { 'event', 'hooker_dc_cleanup' },
        { 'player_id', tostring(playerId) }, { 'player_name', playerName },
        { 'dc_reason', reason or '?' },
    })
end

local function NostrAdmin(adminId, action, detail)
    NostrLog(('👑 [HOOKER ADMIN] %s (ID:%d) – %s%s'):format(GetPedName(adminId), adminId, action, detail and (' | ' .. detail) or ''), {
        { 'script', 'rde_hookers' }, { 'event', 'hooker_admin' },
        { 'admin_id', tostring(adminId) }, { 'admin_name', GetPedName(adminId) },
        { 'action', action }, { 'detail', detail or '' },
    })
end

-- ═══════════════════════════════════════════════════
--  💰  Money Helpers
-- ═══════════════════════════════════════════════════

local function GetPlayerMoney(playerId)
    local count = ox_inventory:GetItem(playerId, Config.Currency, nil, true)
    return type(count) == 'number' and count or 0
end

local function HasEnoughMoney(playerId, amount)
    local balance = GetPlayerMoney(playerId)
    return balance >= amount, balance
end

local function RemovePlayerMoney(playerId, amount)
    local hasEnough, balance = HasEnoughMoney(playerId, amount)
    if not hasEnough then
        local shortage = amount - balance
        Debug('❌ Player', playerId, 'lacks $' .. shortage)
        return false, shortage
    end
    local ok = ox_inventory:RemoveItem(playerId, Config.Currency, amount)
    if ok then
        ServerState.serviceStats.totalRevenue += amount
        Debug('✅ Removed $' .. amount .. ' from player', playerId)
        return true, 0
    end
    Debug('❌ RemoveItem failed for player', playerId)
    return false, amount
end

-- ═══════════════════════════════════════════════════
--  🔎  Validation / Cleanup
-- ═══════════════════════════════════════════════════

local function GetOxPlayer(playerId)
    local player = Ox.GetPlayer(playerId)
    if not player then Debug('⚠️ GetPlayer nil for source', playerId) end
    return player
end

local function ValidateHooker(hooker, playerId)
    if not hooker or not DoesEntityExist(hooker) then
        return false, T('hooker_invalid')
    end
    local state = Entity(hooker).state
    if not state then return false, T('hooker_invalid') end
    if playerId and state.withPlayer and state.withPlayer ~= playerId then
        return false, T('hooker_invalid')
    end
    return true
end

local function CleanupHooker(hooker, playerId)
    if not DoesEntityExist(hooker) then return end
    Debug('🧹 Cleaning up hooker:', hooker, '| player:', playerId or 'any')

    local state = Entity(hooker).state
    if state then
        state:set('withPlayer', nil, true)
        state:set('inService',  nil, true)
        state:set('invitedAt',  nil, true)
    end

    local entry = ServerState.hookerData[hooker]
    if entry then
        local owner = entry.player
        if owner and ServerState.playerHookers[owner] == hooker then
            ServerState.playerHookers[owner] = nil
        end
        ServerState.hookerData[hooker] = nil
    end

    if playerId and ServerState.playerHookers[playerId] == hooker then
        ServerState.playerHookers[playerId] = nil
    end
end

-- ═══════════════════════════════════════════════════
--  📨  Network Events
-- ═══════════════════════════════════════════════════

RegisterNetEvent('hooker:inviteHooker', function(hookerNetId)
    local src = source
    if not src or src == 0 then return end

    if not GetOxPlayer(src) then
        TriggerClientEvent('ox_lib:notify', src, { title = Config.Icons.error .. ' ' .. T('not_available'), description = T('session_error'), type = 'error' })
        return
    end

    local ok, err = pcall(function()
        local hooker = NetworkGetEntityFromNetworkId(hookerNetId)
        if not DoesEntityExist(hooker) then error(T('hooker_invalid')) end

        local valid, reason = ValidateHooker(hooker, src)
        if not valid then error(reason) end

        if ServerState.playerHookers[src] then error(T('already_busy')) end

        local state = Entity(hooker).state
        if state.withPlayer and state.withPlayer ~= src then error(T('hooker_invalid')) end

        Entity(hooker).state:set('withPlayer', src,       true)
        Entity(hooker).state:set('invitedAt',  os.time(), true)

        ServerState.hookerData[hooker] = { player = src, invitedAt = os.time(), entity = hooker, netId = hookerNetId }
        ServerState.playerHookers[src] = hooker
        ServerState.serviceStats.totalInvites += 1

        Debug('✅ Player', src, GetPedName(src), 'invited hooker netId:', hookerNetId)
        NostrInvite(src, hookerNetId)

        TriggerClientEvent('hooker:invitationAccepted', src, hookerNetId)
        TriggerClientEvent('ox_lib:notify', src, {
            title       = Config.Icons.success .. ' ' .. T('shes_coming'),
            description = T('shes_coming_desc'),
            type        = 'success',
        })
    end)

    if not ok then
        Debug('❌ hooker:inviteHooker error:', err)
        TriggerClientEvent('ox_lib:notify', src, {
            title       = Config.Icons.error .. ' ' .. T('not_available'),
            description = tostring(err):gsub('^.-: ', ''),
            type        = 'error',
        })
    end
end)

-- ────────────────────────────────────────────────────

RegisterNetEvent('hooker:requestService', function(serviceType, hookerNetId)
    local src = source
    if not src or src == 0 then return end

    if serviceType ~= 'blowjob' and serviceType ~= 'sex' then
        Debug('❌ Invalid service type from player', src, ':', serviceType)
        return
    end

    if not GetOxPlayer(src) then return end

    local ok, err = pcall(function()
        local hooker = NetworkGetEntityFromNetworkId(hookerNetId)
        if not DoesEntityExist(hooker) then error(T('hooker_invalid')) end

        local valid, reason = ValidateHooker(hooker, src)
        if not valid then error(reason) end

        if ServerState.playerHookers[src] ~= hooker then error(T('hooker_invalid')) end

        local state = Entity(hooker).state
        if state.inService then error(T('service_busy')) end

        local price       = serviceType == 'blowjob' and Config.BlowjobPrice or Config.SexPrice
        local serviceName = serviceType == 'blowjob' and T('blowjob_title') or T('sex_title')

        local paid, shortage = RemovePlayerMoney(src, price)
        if not paid then
            error(('$%d %s'):format(shortage, serviceName))
        end

        ServerState.serviceStats.totalServices += 1
        if serviceType == 'blowjob' then
            ServerState.serviceStats.blowjobs += 1
        else
            ServerState.serviceStats.fullServices += 1
        end

        Debug('💰 Player', src, GetPedName(src), 'paid $' .. price, 'for', serviceType)
        NostrService(src, serviceType, price)

        Entity(hooker).state:set('inService', { player = src, type = serviceType, startTime = os.time() }, true)

        local duration = serviceType == 'blowjob' and Config.BlowjobDuration or Config.SexDuration
        SetTimeout((duration + 10) * 1000, function()
            if DoesEntityExist(hooker) then
                Entity(hooker).state:set('inService', nil, true)
            end
        end)

        TriggerClientEvent('hooker:startService', src, serviceType, hookerNetId)
        TriggerClientEvent('ox_lib:notify', src, {
            title       = Config.Icons.success .. ' ' .. T('service_started'),
            description = T('service_started_desc', Config.Icons.money, price, serviceName),
            type        = 'success',
        })
    end)

    if not ok then
        Debug('❌ hooker:requestService error:', err)
        local cleanErr = tostring(err):gsub('^.-: ', '')
        NostrServiceAbort(src, serviceType, cleanErr)
        TriggerClientEvent('ox_lib:notify', src, {
            title       = Config.Icons.error .. ' ' .. T('cannot_start'),
            description = cleanErr,
            type        = 'error',
        })
        TriggerClientEvent('hooker:serviceAborted', src)
    end
end)

-- ────────────────────────────────────────────────────

RegisterNetEvent('hooker:dismissHooker', function(hookerNetId)
    local src = source
    if not src or src == 0 then return end

    local ok, err = pcall(function()
        local hooker = NetworkGetEntityFromNetworkId(hookerNetId)
        if not DoesEntityExist(hooker) then error(T('hooker_invalid')) end

        local valid, reason = ValidateHooker(hooker, src)
        if not valid then error(reason) end

        Debug('👋 Player', src, 'dismissed hooker netId:', hookerNetId)
        NostrDismiss(src, hookerNetId, 'manual')
        CleanupHooker(hooker, src)
        TriggerClientEvent('hooker:dismissed', src, hookerNetId)
    end)

    if not ok then
        Debug('❌ hooker:dismissHooker error:', err)
    end
end)

-- ═══════════════════════════════════════════════════
--  🔔  Player Disconnect
-- ═══════════════════════════════════════════════════

AddEventHandler('playerDropped', function(reason)
    local src  = source
    local name = GetPedName(src)
    Debug('🚪 Player', src, name, 'disconnected:', reason)

    local hooker = ServerState.playerHookers[src]
    if hooker then
        NostrDisconnect(src, name, reason)
        CleanupHooker(hooker, src)
    end
end)

-- ═══════════════════════════════════════════════════
--  📡  Statebag Monitoring (debug)
-- ═══════════════════════════════════════════════════

if Config.Debug then
    AddStateBagChangeHandler('withPlayer', nil, function(bagName, _, value)
        if value then Debug('📡 Statebag:', bagName, '→ withPlayer =', value)
        else          Debug('📡 Statebag:', bagName, '→ withPlayer cleared') end
    end)
    AddStateBagChangeHandler('inService', nil, function(bagName, _, value)
        if value then Debug('📡 Service started:', bagName, '→ Player:', value.player, '| Type:', value.type)
        else          Debug('📡 Service ended:', bagName) end
    end)
end

-- ═══════════════════════════════════════════════════
--  🎮  Admin Commands
-- ═══════════════════════════════════════════════════

lib.addCommand('hookerstats', { help = 'Show hooker system statistics', restricted = 'group.admin' }, function(src)
    local active, inSvc = 0, 0
    for hooker in pairs(ServerState.hookerData) do
        if DoesEntityExist(hooker) then
            active += 1
            if Entity(hooker).state.inService then inSvc += 1 end
        end
    end
    local s = ServerState.serviceStats
    NostrAdmin(src, 'hookerstats', ('active=%d inService=%d revenue=$%d'):format(active, inSvc, s.totalRevenue))
    TriggerClientEvent('ox_lib:notify', src, {
        title       = Config.Icons.info .. ' ' .. T('stats_title'),
        description = ('📊 **Active:** %d  🔥 **In Service:** %d\n\n💰 **Revenue:** $%d\n👋 **Invites:** %d  🎯 **Services:** %d\n👄 **BJs:** %d  🔥 **Full:** %d'):format(
            active, inSvc, s.totalRevenue, s.totalInvites, s.totalServices, s.blowjobs, s.fullServices),
        type = 'info', duration = 15000,
    })
end)

lib.addCommand('hookercleanup', { help = 'Cleanup all active hookers', restricted = 'group.admin' }, function(src)
    local count = 0
    for hooker, data in pairs(ServerState.hookerData) do
        if DoesEntityExist(hooker) then
            if data.player then TriggerClientEvent('hooker:dismissed', data.player, NetworkGetNetworkIdFromEntity(hooker)) end
            CleanupHooker(hooker, data.player)
            count += 1
        end
    end
    ServerState.hookerData    = {}
    ServerState.playerHookers = {}
    NostrAdmin(src, 'hookercleanup', ('removed %d hooker(s)'):format(count))
    TriggerClientEvent('ox_lib:notify', src, {
        title = Config.Icons.success .. ' ' .. T('cleanup_complete'),
        description = T('cleanup_desc', count), type = 'success',
    })
    Debug('🧹 Admin cleanup: removed', count, 'hooker(s)')
end)

lib.addCommand('hookerresetstats', { help = 'Reset hooker system statistics', restricted = 'group.admin' }, function(src)
    ServerState.serviceStats = { totalInvites = 0, totalServices = 0, totalRevenue = 0, blowjobs = 0, fullServices = 0 }
    NostrAdmin(src, 'hookerresetstats', 'all statistics reset')
    TriggerClientEvent('ox_lib:notify', src, {
        title = Config.Icons.success .. ' ' .. T('stats_reset'),
        description = T('stats_reset_desc'), type = 'success',
    })
    Debug('📊 Admin reset statistics')
end)

-- ═══════════════════════════════════════════════════
--  📤  Exports
-- ═══════════════════════════════════════════════════

exports('HasEnoughMoney',       function(src, amount) return HasEnoughMoney(src, amount) end)
exports('GetServicePrice',      function(t) return t == 'blowjob' and Config.BlowjobPrice or Config.SexPrice end)
exports('GetStatistics',        function() return ServerState.serviceStats end)
exports('PlayerHasHooker',      function(src) return ServerState.playerHookers[src] ~= nil end)
exports('GetActiveHookerCount', function()
    local c = 0
    for h in pairs(ServerState.hookerData) do if DoesEntityExist(h) then c += 1 end end
    return c
end)

-- ═══════════════════════════════════════════════════
--  🚀  Startup Banner
-- ═══════════════════════════════════════════════════
CreateThread(function()
    local version     = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '1.0.0'
    local libVersion  = GetResourceMetadata('ox_lib',  'version', 0) or '?'
    local coreVersion = GetResourceMetadata('ox_core', 'version', 0) or '?'

    print('^5═══════════════════════════════════════════════════════^7')
    print('^5██╗  ██╗ ██████╗  ██████╗ ██╗  ██╗███████╗██████╗ ^7')
    print('^5██║  ██║██╔═══██╗██╔═══██╗██║ ██╔╝██╔════╝██╔══██╗^7')
    print('^5███████║██║   ██║██║   ██║█████╔╝ █████╗  ██████╔╝^7')
    print('^5██╔══██║██║   ██║██║   ██║██╔═██╗ ██╔══╝  ██╔══██╗^7')
    print('^5██║  ██║╚██████╔╝╚██████╔╝██║  ██╗███████╗██║  ██║^7')
    print('^5╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝^7')
    print('^5═══════════════════════════════════════════════════════^7')
    print('^5  RDE Hooker System ^3v' .. version .. '^7')
    print(('^5  ox_lib ^3%s^5  •  ox_core ^3%s^7'):format(libVersion, coreVersion))
    print('^5═══════════════════════════════════════════════════════^7')

    if Config.Debug then
        print('^3[HOOKER]^7 ^1' .. T('debug_enabled') .. '^7')
        print(('  💰 Blowjob: ^2$%d^7 / ^2%ds^7'):format(Config.BlowjobPrice, Config.BlowjobDuration))
        print(('  🔥 Full:    ^2$%d^7 / ^2%ds^7'):format(Config.SexPrice,     Config.SexDuration))
        print(('  🧸 Currency: ^2%s^7   Models: ^2%d^7'):format(Config.Currency, #Config.HookerModels))
        print(('  🌐 Locale:   ^2%s^7'):format(Config.Locale))
        print('  Commands: /hookerstats  /hookercleanup  /hookerresetstats')
    end

    print('^2[HOOKER]^7 ' .. T('server_ready'))
    print('^5═══════════════════════════════════════════════════════^7')
end)

Debug('✅ Server initialised | Locale: ' .. Config.Locale)
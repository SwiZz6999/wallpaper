if type(Config) ~= 'table' then
    error('[criticalgunoe] Config is niet geladen. Controleer of shared/config.lua bestaat en in fxmanifest.lua bij shared_scripts staat.', 0)
end

local state = {
    inMatch = false,
    status = 'idle',
    arena = nil,
    level = 1,
    maxLevel = #Config.Weapons,
    weapon = nil,
    scoreboard = {},
    localDead = false,
    menuOpen = false,
    outsideSince = 0,
    lastBoundsDamage = 0
}

local function sendUi(action, payload)
    SendNUIMessage({
        action = action,
        payload = payload or {}
    })
end

local function notify(kind, message)
    TriggerEvent('chat:addMessage', {
        args = { _L('prefix'), message }
    })

    sendUi('toast', {
        kind = kind or 'info',
        message = message
    })
end

local function arenaList()
    local arenas = {}

    for _, arena in ipairs(Config.Arenas) do
        arenas[#arenas + 1] = {
            id = arena.id,
            label = arena.label,
            radius = arena.radius
        }
    end

    return arenas
end

local function setMenu(open)
    state.menuOpen = open
    SetNuiFocus(open, open)

    sendUi('menu', {
        open = open,
        arenas = arenaList(),
        inMatch = state.inMatch,
        currentArena = state.arena and state.arena.id or nil
    })
end

local function applyWeapon(weaponData)
    local ped = PlayerPedId()

    if Config.Match.stripWeaponsOnJoin then
        RemoveAllPedWeapons(ped, true)
    end

    if not weaponData or not weaponData.weapon then
        return
    end

    local weaponHash = GetHashKey(weaponData.weapon)
    GiveWeaponToPed(ped, weaponHash, weaponData.ammo or 100, false, true)
    SetPedAmmo(ped, weaponHash, weaponData.ammo or 100)
    SetCurrentPedWeapon(ped, weaponHash, true)

    if weaponData.components then
        for _, component in ipairs(weaponData.components) do
            GiveWeaponComponentToPed(ped, weaponHash, GetHashKey(component))
        end
    end
end

local function applySpawn(payload)
    local ped = PlayerPedId()
    local spawn = payload.spawn or {}
    local heading = spawn.w or spawn.heading or 0.0

    DoScreenFadeOut(150)
    Wait(200)

    NetworkResurrectLocalPlayer(spawn.x or 0.0, spawn.y or 0.0, spawn.z or 72.0, heading, true, false)
    ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, spawn.x or 0.0, spawn.y or 0.0, spawn.z or 72.0, false, false, false)
    SetEntityHeading(ped, heading)
    ClearPedBloodDamage(ped)
    ClearPedTasksImmediately(ped)
    SetEntityInvincible(ped, false)
    SetPedCanRagdoll(ped, true)
    SetPedArmour(ped, Config.Match.giveFullArmorOnSpawn and 100 or 0)
    SetEntityHealth(ped, 200)

    if payload.lobby then
        if Config.Match.stripWeaponsOnJoin then
            RemoveAllPedWeapons(ped, true)
        end
    else
        applyWeapon(payload.weapon)
    end

    Wait(150)
    DoScreenFadeIn(250)
end

local function resetLocalState()
    state.inMatch = false
    state.status = 'idle'
    state.arena = nil
    state.level = 1
    state.weapon = nil
    state.scoreboard = {}
    state.localDead = false
    state.outsideSince = 0
    state.lastBoundsDamage = 0

    sendUi('state', {
        inMatch = false,
        status = 'idle'
    })
    sendUi('scoreboard', {})
end

RegisterNetEvent('criticalgunoe:client:notify', function(kind, message)
    notify(kind, message)
end)

RegisterNetEvent('criticalgunoe:client:feed', function(message)
    sendUi('feed', {
        message = message
    })
end)

RegisterNetEvent('criticalgunoe:client:state', function(payload)
    state.inMatch = payload.status ~= 'idle'
    state.status = payload.status
    state.arena = payload.arena
    state.level = payload.level or state.level
    state.maxLevel = payload.maxLevel or state.maxLevel
    state.weapon = payload.weapon or state.weapon

    payload.inMatch = state.inMatch
    sendUi('state', payload)
end)

RegisterNetEvent('criticalgunoe:client:scoreboard', function(scoreboard)
    state.scoreboard = scoreboard or {}
    sendUi('scoreboard', state.scoreboard)
end)

RegisterNetEvent('criticalgunoe:client:countdown', function(payload)
    local seconds = type(payload) == 'table' and payload.seconds or payload

    sendUi('countdown', {
        seconds = seconds
    })
end)

RegisterNetEvent('criticalgunoe:client:spawn', function(payload)
    state.inMatch = true
    state.status = payload.status or state.status
    state.arena = payload.arena or state.arena
    state.level = payload.level or state.level
    state.weapon = payload.weapon or state.weapon
    state.localDead = false

    sendUi('state', {
        inMatch = true,
        status = state.status,
        arena = state.arena,
        level = state.level,
        maxLevel = state.maxLevel,
        weapon = state.weapon
    })

    applySpawn(payload)
end)

RegisterNetEvent('criticalgunoe:client:setWeapon', function(level, weaponData)
    if type(level) == 'table' then
        weaponData = level.weapon
        state.maxLevel = level.maxLevel or state.maxLevel
        level = level.level
    end

    if not level or not weaponData then
        return
    end

    state.level = level
    state.weapon = weaponData
    applyWeapon(weaponData)
    notify('success', _L('weapon_level', level, state.maxLevel, weaponData.label))

    sendUi('state', {
        inMatch = state.inMatch,
        status = state.status,
        arena = state.arena,
        level = state.level,
        maxLevel = state.maxLevel,
        weapon = state.weapon
    })
end)

RegisterNetEvent('criticalgunoe:client:death', function()
    state.localDead = true
    notify('danger', _L('death'))
    sendUi('death', {})
end)

RegisterNetEvent('criticalgunoe:client:healReward', function(reward)
    local ped = PlayerPedId()
    local health = math.min(reward.maxHealth or 200, GetEntityHealth(ped) + (reward.health or 0))
    local armor = math.min(reward.maxArmor or 100, GetPedArmour(ped) + (reward.armor or 0))

    SetEntityHealth(ped, health)
    SetPedArmour(ped, armor)
end)

RegisterNetEvent('criticalgunoe:client:finish', function(payload)
    if Config.Match.stripWeaponsOnExit then
        RemoveAllPedWeapons(PlayerPedId(), true)
    end

    sendUi('finish', payload or {})
    resetLocalState()
end)

RegisterNetEvent('criticalgunoe:client:cleanup', function()
    if Config.Match.stripWeaponsOnExit then
        RemoveAllPedWeapons(PlayerPedId(), true)
    end

    resetLocalState()
end)

RegisterNetEvent('criticalgunoe:client:leave', function()
    TriggerEvent('criticalgunoe:client:cleanup')
end)

RegisterCommand(Config.Commands.menu, function()
    setMenu(not state.menuOpen)
end, false)

RegisterNUICallback('close', function(_, cb)
    setMenu(false)
    cb({ ok = true })
end)

RegisterNUICallback('join', function(data, cb)
    TriggerServerEvent('criticalgunoe:server:join', data and data.arena or nil)
    setMenu(false)
    cb({ ok = true })
end)

RegisterNUICallback('leave', function(_, cb)
    TriggerServerEvent('criticalgunoe:server:leave')
    setMenu(false)
    cb({ ok = true })
end)

RegisterNUICallback('arenas', function(_, cb)
    cb({
        arenas = arenaList(),
        inMatch = state.inMatch
    })
end)

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' or not state.inMatch or state.localDead then
        return
    end

    local victim = args[1]
    local attacker = args[2]
    local fatal = args[4] == true or args[4] == 1 or args[6] == true or args[6] == 1
    local ped = PlayerPedId()

    if victim ~= ped or (not fatal and not IsEntityDead(ped)) then
        return
    end

    state.localDead = true

    local killerServerId = 0
    local weaponHash = GetPedCauseOfDeath(ped)

    if attacker and attacker ~= 0 and IsEntityAPed(attacker) and IsPedAPlayer(attacker) then
        local killerPlayer = NetworkGetPlayerIndexFromPed(attacker)

        if killerPlayer and killerPlayer ~= -1 then
            killerServerId = GetPlayerServerId(killerPlayer)
        end
    end

    TriggerServerEvent('criticalgunoe:server:reportDeath', killerServerId, weaponHash)
end)

CreateThread(function()
    while true do
        local sleep = 750

        if state.inMatch and state.status == 'running' then
            sleep = 0

            if Config.Match.disableVehicles then
                DisableControlAction(0, 23, true)
                DisableControlAction(0, 75, true)
                DisableControlAction(0, 86, true)
            end

            DisablePlayerVehicleRewards(PlayerId())
        end

        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        Wait(1000)

        if not Config.Bounds.enabled or not state.inMatch or state.status ~= 'running' or not state.arena then
            state.outsideSince = 0
        else
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local center = state.arena.center
            local distance = #(coords - vector3(center.x, center.y, center.z))

            if distance > (state.arena.radius or 100.0) then
                if state.outsideSince == 0 then
                    state.outsideSince = GetGameTimer()
                    notify('warning', _L('out_of_bounds'))
                elseif GetGameTimer() - state.outsideSince > (Config.Bounds.warningSeconds * 1000)
                    and GetGameTimer() - state.lastBoundsDamage > Config.Bounds.tickMs then
                    state.lastBoundsDamage = GetGameTimer()
                    ApplyDamageToPed(ped, Config.Bounds.damagePerTick, false)
                    notify('warning', _L('out_of_bounds'))
                end
            else
                state.outsideSince = 0
            end
        end
    end
end)

CreateThread(function()
    Wait(1000)
    sendUi('boot', {
        resource = 'criticalgunoe',
        arenas = arenaList(),
        commands = Config.Commands
    })
    notify('info', _L('help'))
end)

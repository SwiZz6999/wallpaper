if type(Config) ~= 'table' then
    error('[criticalgunoe] Config is niet geladen. Controleer of shared/config.lua bestaat en in fxmanifest.lua bij shared_scripts staat.', 0)
end

local matches = {}
local players = {}
local nextMatchId = 1

local function now()
    return GetGameTimer()
end

local function debugLog(message)
    if Config.Debug then
        print(('[criticalgunoe] %s'):format(message))
    end
end

local function playerName(source)
    return GetPlayerName(source) or ('ID %s'):format(source)
end

local function countPlayers(match)
    local count = 0

    for _ in pairs(match.players) do
        count = count + 1
    end

    return count
end

local function findArena(arenaId)
    if not arenaId or arenaId == '' then
        return Config.Arenas[1]
    end

    local wanted = tostring(arenaId):lower()

    for _, arena in ipairs(Config.Arenas) do
        if arena.id:lower() == wanted or arena.label:lower() == wanted then
            return arena
        end
    end

    return nil
end

local function getWeapon(level)
    return Config.Weapons[level] or Config.Weapons[#Config.Weapons]
end

local function notify(target, kind, key, ...)
    TriggerClientEvent('criticalgunoe:client:notify', target, kind or 'info', _L(key, ...))
end

local function broadcast(match, kind, key, ...)
    local message = _L(key, ...)

    for source in pairs(match.players) do
        TriggerClientEvent('criticalgunoe:client:notify', source, kind or 'info', message)
    end
end

local function chat(target, key, ...)
    TriggerClientEvent('chat:addMessage', target, {
        args = { _L('prefix'), _L(key, ...) }
    })
end

local function matchByArena(arenaId, includeRunning)
    for _, match in pairs(matches) do
        if match.arena.id == arenaId and match.status ~= 'finished' then
            if match.status ~= 'running' or includeRunning then
                return match
            end
        end
    end

    return nil
end

local function createMatch(arena)
    local match = {
        id = nextMatchId,
        status = 'waiting',
        arena = arena,
        players = {},
        startedAt = nil,
        endsAt = nil,
        countdownToken = 0
    }

    nextMatchId = nextMatchId + 1
    matches[match.id] = match

    return match
end

local function getOpenMatch(arena)
    local match = matchByArena(arena.id, Config.JoinInProgress)

    if match then
        return match
    end

    return createMatch(arena)
end

local function buildScoreboard(match)
    local rows = {}

    for source in pairs(match.players) do
        local data = players[source]

        if data then
            rows[#rows + 1] = {
                id = source,
                name = data.name,
                level = data.level,
                maxLevel = #Config.Weapons,
                weapon = getWeapon(data.level).label,
                kills = data.kills,
                deaths = data.deaths,
                streak = data.streak
            }
        end
    end

    table.sort(rows, function(a, b)
        if a.level ~= b.level then
            return a.level > b.level
        end

        if a.kills ~= b.kills then
            return a.kills > b.kills
        end

        return a.deaths < b.deaths
    end)

    return rows
end

local function buildState(source, match)
    local data = players[source]

    return {
        matchId = match.id,
        status = match.status,
        arena = {
            id = match.arena.id,
            label = match.arena.label,
            center = match.arena.center,
            radius = match.arena.radius
        },
        level = data and data.level or 1,
        maxLevel = #Config.Weapons,
        kills = data and data.kills or 0,
        deaths = data and data.deaths or 0,
        streak = data and data.streak or 0,
        weapon = getWeapon(data and data.level or 1),
        playerCount = countPlayers(match),
        requiredPlayers = Config.RequiredPlayers,
        roundTimeSeconds = Config.RoundTimeSeconds,
        timeRemainingMs = match.endsAt and math.max(0, match.endsAt - now()) or nil
    }
end

local function sendScoreboard(match)
    local scoreboard = buildScoreboard(match)

    for source in pairs(match.players) do
        TriggerClientEvent('criticalgunoe:client:scoreboard', source, scoreboard)
    end
end

local function sendState(match)
    for source in pairs(match.players) do
        TriggerClientEvent('criticalgunoe:client:state', source, buildState(source, match))
    end

    sendScoreboard(match)
end

local function randomSpawn(arena)
    local spawns = arena.spawns

    if not spawns or #spawns == 0 then
        return arena.lobby or arena.center
    end

    return spawns[math.random(1, #spawns)]
end

local function spawnPlayer(source, match, isLobby)
    local data = players[source]

    if not data then
        return
    end

    local spawn = isLobby and (match.arena.lobby or randomSpawn(match.arena)) or randomSpawn(match.arena)
    data.dead = false

    TriggerClientEvent('criticalgunoe:client:spawn', source, {
        arena = match.arena,
        spawn = spawn,
        level = data.level,
        weapon = getWeapon(data.level),
        lobby = isLobby == true,
        status = match.status
    })
end

local function removeMatch(matchId)
    matches[matchId] = nil
end

local function bestPlayer(match)
    local rows = buildScoreboard(match)

    if rows[1] then
        return rows[1].id
    end

    return nil
end

local function finishMatch(match, reason, winner)
    if not match or match.status == 'finished' then
        return
    end

    match.status = 'finished'

    local winnerName = winner and playerName(winner) or nil
    local timeLeft = match.endsAt and math.max(0, math.floor((match.endsAt - now()) / 1000)) or 0
    local finalScoreboard = buildScoreboard(match)

    for source in pairs(match.players) do
        local data = players[source]

        if data then
            players[source] = nil
            SetPlayerRoutingBucket(source, Config.DefaultRoutingBucket)
        end

        TriggerClientEvent('criticalgunoe:client:finish', source, {
            reason = reason,
            winner = winner,
            winnerName = winnerName,
            arena = match.arena,
            scoreboard = finalScoreboard
        })
    end

    if winnerName then
        if timeLeft > 0 and reason == 'winner' then
            TriggerClientEvent('chat:addMessage', -1, {
                args = { _L('prefix'), _L('winner_time', winnerName, match.arena.label, ('%ss'):format(timeLeft)) }
            })
        else
            TriggerClientEvent('chat:addMessage', -1, {
                args = { _L('prefix'), _L('winner', winnerName, match.arena.label) }
            })
        end
    end

    SetTimeout(Config.IntermissionSeconds * 1000, function()
        removeMatch(match.id)
    end)
end

local function ensurePopulation(match)
    local playerCount = countPlayers(match)

    if match.status == 'running' and playerCount <= 1 then
        local remaining = bestPlayer(match)

        if remaining then
            finishMatch(match, 'not_enough_players', remaining)
        else
            finishMatch(match, 'not_enough_players')
        end

        return false
    end

    if (match.status == 'waiting' or match.status == 'countdown') and playerCount < Config.RequiredPlayers then
        if match.status == 'countdown' then
            match.status = 'waiting'
            match.countdownToken = match.countdownToken + 1
            broadcast(match, 'warning', 'countdown_cancelled')
            sendState(match)
        end

        return false
    end

    return true
end

local function startMatch(match)
    if not match or match.status == 'running' then
        return
    end

    if countPlayers(match) < Config.RequiredPlayers then
        match.status = 'waiting'
        sendState(match)
        return
    end

    match.status = 'running'
    match.startedAt = now()
    match.endsAt = now() + (Config.RoundTimeSeconds * 1000)

    for source in pairs(match.players) do
        local data = players[source]

        if data then
            data.level = 1
            data.kills = 0
            data.deaths = 0
            data.streak = 0
            data.dead = false
            data.lastVictimAt = {}

            spawnPlayer(source, match, false)
            notify(source, 'success', 'match_started', #Config.Weapons)
        end
    end

    sendState(match)

    SetTimeout(Config.RoundTimeSeconds * 1000, function()
        if matches[match.id] and matches[match.id].status == 'running' then
            broadcast(match, 'warning', 'round_timeout')
            finishMatch(match, 'timeout', bestPlayer(match))
        end
    end)
end

local function startCountdown(match)
    if not match or match.status == 'running' or match.status == 'countdown' then
        return
    end

    if countPlayers(match) < Config.RequiredPlayers then
        return
    end

    match.status = 'countdown'
    match.countdownToken = match.countdownToken + 1

    local token = match.countdownToken

    broadcast(match, 'info', 'countdown_started', match.arena.label, Config.CountdownSeconds)
    sendState(match)

    local function tick(secondsLeft)
        if not matches[match.id] or match.status ~= 'countdown' or match.countdownToken ~= token then
            return
        end

        if countPlayers(match) < Config.RequiredPlayers then
            ensurePopulation(match)
            return
        end

        for source in pairs(match.players) do
            TriggerClientEvent('criticalgunoe:client:countdown', source, {
                matchId = match.id,
                seconds = secondsLeft
            })
        end

        if secondsLeft <= 0 then
            startMatch(match)
            return
        end

        SetTimeout(1000, function()
            tick(secondsLeft - 1)
        end)
    end

    tick(Config.CountdownSeconds)
end

local function leavePlayer(source, silent, kicked)
    local data = players[source]

    if not data then
        if not silent then
            notify(source, 'warning', 'not_in_match')
        end

        return
    end

    local match = matches[data.matchId]

    players[source] = nil
    SetPlayerRoutingBucket(source, Config.DefaultRoutingBucket)
    TriggerClientEvent('criticalgunoe:client:cleanup', source, {
        kicked = kicked == true
    })

    if not silent then
        notify(source, 'info', 'left')
    end

    if match then
        match.players[source] = nil

        if kicked then
            notify(source, 'warning', 'admin_kicked')
        end

        broadcast(match, 'info', 'player_left', data.name, countPlayers(match), Config.RequiredPlayers)
        sendState(match)
        ensurePopulation(match)

        if countPlayers(match) == 0 then
            removeMatch(match.id)
        end
    end
end

local function joinPlayer(source, arenaId)
    if source == 0 then
        print(_L('no_console'))
        return
    end

    if players[source] then
        notify(source, 'warning', 'already_in_match')
        return
    end

    local arena = findArena(arenaId)

    if not arena then
        notify(source, 'error', 'arena_missing', arenaId or '')
        return
    end

    local match = getOpenMatch(arena)

    match.players[source] = true
    players[source] = {
        matchId = match.id,
        name = playerName(source),
        level = 1,
        kills = 0,
        deaths = 0,
        streak = 0,
        dead = false,
        lastVictimAt = {}
    }

    SetPlayerRoutingBucket(source, 7000 + match.id)
    spawnPlayer(source, match, match.status ~= 'running')
    notify(source, 'success', 'joined', arena.label, countPlayers(match), Config.RequiredPlayers)
    notify(source, 'info', 'menu_hint')
    broadcast(match, 'info', 'player_joined', playerName(source), countPlayers(match), Config.RequiredPlayers)

    if match.status == 'running' then
        notify(source, 'success', 'match_started', #Config.Weapons)
    else
        startCountdown(match)
    end

    sendState(match)
end

local function respawnAfterDeath(source, matchId)
    SetTimeout(Config.RespawnDelayMs, function()
        local data = players[source]
        local match = data and matches[data.matchId]

        if not data or not match or match.id ~= matchId or match.status ~= 'running' then
            return
        end

        spawnPlayer(source, match, false)
        sendState(match)
    end)
end

local function applyDeath(source)
    local data = players[source]

    if not data or data.dead then
        return nil, nil
    end

    local match = matches[data.matchId]

    if not match or match.status ~= 'running' then
        return nil, nil
    end

    data.dead = true
    data.deaths = data.deaths + 1
    data.streak = 0

    return data, match
end

local function handleSuicide(victim, victimData, match)
    victimData = victimData or nil
    match = match or nil

    if not victimData or not match then
        victimData, match = applyDeath(victim)
    end

    if not victimData then
        return
    end

    if Config.Death.demoteOnSuicide and victimData.level > 1 then
        victimData.level = math.max(1, victimData.level - Config.Death.demoteLevels)
    end

    notify(victim, 'warning', 'suicide')
    respawnAfterDeath(victim, match.id)
    sendState(match)
end

RegisterNetEvent('criticalgunoe:server:join', function(arenaId)
    joinPlayer(source, arenaId)
end)

RegisterNetEvent('criticalgunoe:server:leave', function()
    leavePlayer(source, false)
end)

RegisterNetEvent('criticalgunoe:server:reportDeath', function(killerServerId)
    local victim = source
    local victimData, match = applyDeath(victim)

    if not victimData then
        return
    end

    killerServerId = tonumber(killerServerId)

    if not killerServerId or killerServerId <= 0 or killerServerId == victim then
        handleSuicide(victim, victimData, match)
        return
    end

    local killerData = players[killerServerId]

    if not killerData or killerData.matchId ~= match.id then
        handleSuicide(victim, victimData, match)
        return
    end

    if Config.AntiFarm.enabled then
        local lastKillAt = killerData.lastVictimAt[victim] or 0

        if now() - lastKillAt < Config.AntiFarm.sameVictimCooldownMs then
            notify(killerServerId, 'warning', 'anti_farm')
            respawnAfterDeath(victim, match.id)
            sendState(match)
            return
        end

        killerData.lastVictimAt[victim] = now()
    end

    local killerWasFinal = killerData.level >= #Config.Weapons

    killerData.kills = killerData.kills + 1
    killerData.streak = killerData.streak + 1

    if not killerWasFinal then
        killerData.level = math.min(#Config.Weapons, killerData.level + 1)
    end

    TriggerClientEvent('criticalgunoe:client:healReward', killerServerId, Config.KillReward)
    TriggerClientEvent('criticalgunoe:client:setWeapon', killerServerId, {
        level = killerData.level,
        maxLevel = #Config.Weapons,
        weapon = getWeapon(killerData.level)
    })

    local killMessage = _L('killed', killerData.name, victimData.name, killerData.level, #Config.Weapons)

    for target in pairs(match.players) do
        TriggerClientEvent('criticalgunoe:client:notify', target, 'info', killMessage)
        TriggerClientEvent('criticalgunoe:client:feed', target, killMessage)
    end

    if not killerWasFinal and killerData.level >= #Config.Weapons then
        broadcast(match, 'warning', 'final_level', killerData.name, getWeapon(killerData.level).label)
    end

    TriggerClientEvent('criticalgunoe:client:death', victim, {
        killer = killerServerId,
        killerName = killerData.name,
        respawnDelayMs = Config.RespawnDelayMs
    })

    if killerWasFinal then
        finishMatch(match, 'winner', killerServerId)
        return
    end

    respawnAfterDeath(victim, match.id)
    sendState(match)
end)

RegisterCommand(Config.Commands.join, function(source, args)
    joinPlayer(source, args[1])
end, false)

RegisterCommand(Config.Commands.leave, function(source)
    leavePlayer(source, false)
end, false)

RegisterCommand(Config.Commands.status, function(source)
    if source == 0 then
        print(_L('status_header'))
    else
        chat(source, 'status_header')
    end

    for _, arena in ipairs(Config.Arenas) do
        local match = matchByArena(arena.id, true)
        local status = match and match.status or _L('status_empty')
        local count = match and countPlayers(match) or 0
        local line = _L('status_line', arena.label, arena.id, status, count)

        if source == 0 then
            print(line)
        else
            TriggerClientEvent('chat:addMessage', source, {
                args = { _L('prefix'), line }
            })
        end
    end
end, false)

RegisterCommand(Config.Commands.admin, function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, Config.AdminAce) then
        notify(source, 'error', 'no_permission')
        return
    end

    local action = args[1] and args[1]:lower() or nil

    if action == 'start' then
        local arena = findArena(args[2])

        if not arena then
            notify(source, 'error', 'arena_missing', args[2] or '')
            return
        end

        local match = getOpenMatch(arena)
        startMatch(match)
        broadcast(match, 'success', 'admin_started', arena.label)
    elseif action == 'stop' then
        local arena = findArena(args[2])

        if not arena then
            notify(source, 'error', 'arena_missing', args[2] or '')
            return
        end

        local match = matchByArena(arena.id, true)

        if match then
            broadcast(match, 'warning', 'admin_stopped', arena.label)
            finishMatch(match, 'admin')
        end
    elseif action == 'kick' then
        local target = tonumber(args[2])

        if not target or not players[target] then
            notify(source, 'error', 'invalid_player')
            return
        end

        leavePlayer(target, true, true)
    elseif action == 'setlevel' then
        local target = tonumber(args[2])
        local level = tonumber(args[3])

        if not target or not players[target] then
            notify(source, 'error', 'invalid_player')
            return
        end

        if not level or level < 1 or level > #Config.Weapons then
            notify(source, 'error', 'invalid_level', #Config.Weapons)
            return
        end

        local data = players[target]
        data.level = level

        TriggerClientEvent('criticalgunoe:client:setWeapon', target, {
            level = data.level,
            maxLevel = #Config.Weapons,
            weapon = getWeapon(data.level)
        })
        notify(target, 'info', 'admin_setlevel', level)

        local match = matches[data.matchId]

        if match then
            sendState(match)
        end
    else
        if source == 0 then
            print(_L('admin_usage'))
        else
            notify(source, 'info', 'admin_usage')
        end
    end
end, false)

AddEventHandler('playerDropped', function()
    leavePlayer(source, true)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    for source in pairs(players) do
        SetPlayerRoutingBucket(source, Config.DefaultRoutingBucket)
        TriggerClientEvent('criticalgunoe:client:cleanup', source, {})
    end

    debugLog('resource stopped, player state cleaned')
end)

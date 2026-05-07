Locales = {}

Locales.nl = {
    prefix = '^1[CriticalGunOE]^7',
    no_console = 'Dit commando kan alleen in-game worden gebruikt.',
    no_permission = 'Je hebt geen toestemming om dit commando te gebruiken.',
    arena_missing = 'Arena "%s" bestaat niet. Gebruik /ggstatus voor beschikbare arena\'s.',
    already_in_match = 'Je zit al in een GunGame. Gebruik /ggleave om te verlaten.',
    not_in_match = 'Je zit momenteel niet in een GunGame.',
    joined = 'Je bent GunGame "%s" gejoined. Wachten op spelers: %d/%d.',
    left = 'Je hebt de GunGame verlaten.',
    player_joined = '%s is gejoined (%d/%d).',
    player_left = '%s heeft de GunGame verlaten (%d/%d).',
    countdown_started = 'GunGame "%s" start over %d seconden.',
    countdown_cancelled = 'Countdown geannuleerd: niet genoeg spelers.',
    match_started = 'GunGame gestart! Bereik level %d om te winnen.',
    match_finished = 'GunGame afgelopen.',
    winner = '%s wint de GunGame op "%s"!',
    winner_time = '%s wint de GunGame op "%s" met nog %s over!',
    not_enough_players = 'GunGame gestopt: niet genoeg spelers.',
    round_timeout = 'Tijd is om. Hoogste speler wint.',
    killed = '%s schakelde %s uit en gaat naar level %d/%d.',
    final_level = '%s staat op het laatste level: %s.',
    death = 'Je bent uitgeschakeld. Respawn over enkele seconden.',
    suicide = 'Je bent dood gegaan.',
    weapon_level = 'Level %d/%d: %s',
    status_header = 'CriticalGunOE arena\'s:',
    status_line = '%s (%s): %s - %d speler(s)',
    status_empty = 'geen actieve match',
    admin_usage = 'Gebruik: /ggadmin start <arena>, /ggadmin stop <arena>, /ggadmin kick <id>, /ggadmin setlevel <id> <level>',
    admin_started = 'Admin heeft GunGame "%s" gestart.',
    admin_stopped = 'Admin heeft GunGame "%s" gestopt.',
    admin_kicked = 'Je bent door een admin uit GunGame verwijderd.',
    admin_setlevel = 'Je GunGame-level is aangepast naar %d.',
    invalid_player = 'Speler niet gevonden.',
    invalid_level = 'Ongeldig level. Kies 1 t/m %d.',
    anti_farm = 'Kill genegeerd: anti-farm cooldown actief.',
    out_of_bounds = 'Keer terug naar de arena!',
    menu_hint = 'Gebruik /ggmenu om het GunGame-menu te openen.',
    help = 'Commands: /ggjoin [arena], /ggleave, /ggstatus, /ggmenu'
}

Locales.en = {
    prefix = '^1[CriticalGunOE]^7',
    no_console = 'This command can only be used in-game.',
    no_permission = 'You do not have permission to use this command.',
    arena_missing = 'Arena "%s" does not exist. Use /ggstatus for available arenas.',
    already_in_match = 'You are already in a GunGame. Use /ggleave to leave.',
    not_in_match = 'You are not in a GunGame.',
    joined = 'You joined GunGame "%s". Waiting for players: %d/%d.',
    left = 'You left the GunGame.',
    player_joined = '%s joined (%d/%d).',
    player_left = '%s left the GunGame (%d/%d).',
    countdown_started = 'GunGame "%s" starts in %d seconds.',
    countdown_cancelled = 'Countdown cancelled: not enough players.',
    match_started = 'GunGame started! Reach level %d to win.',
    match_finished = 'GunGame finished.',
    winner = '%s wins GunGame on "%s"!',
    winner_time = '%s wins GunGame on "%s" with %s remaining!',
    not_enough_players = 'GunGame stopped: not enough players.',
    round_timeout = 'Time is up. Highest player wins.',
    killed = '%s eliminated %s and moved to level %d/%d.',
    final_level = '%s is on the final level: %s.',
    death = 'You were eliminated. Respawning soon.',
    suicide = 'You died.',
    weapon_level = 'Level %d/%d: %s',
    status_header = 'CriticalGunOE arenas:',
    status_line = '%s (%s): %s - %d player(s)',
    status_empty = 'no active match',
    admin_usage = 'Usage: /ggadmin start <arena>, /ggadmin stop <arena>, /ggadmin kick <id>, /ggadmin setlevel <id> <level>',
    admin_started = 'Admin started GunGame "%s".',
    admin_stopped = 'Admin stopped GunGame "%s".',
    admin_kicked = 'An admin removed you from GunGame.',
    admin_setlevel = 'Your GunGame level was changed to %d.',
    invalid_player = 'Player not found.',
    invalid_level = 'Invalid level. Choose 1 through %d.',
    anti_farm = 'Kill ignored: anti-farm cooldown is active.',
    out_of_bounds = 'Return to the arena!',
    menu_hint = 'Use /ggmenu to open the GunGame menu.',
    help = 'Commands: /ggjoin [arena], /ggleave, /ggstatus, /ggmenu'
}

local function translate(key, ...)
    local locale = (Config and Config.Locale) or 'nl'
    local text = (Locales[locale] and Locales[locale][key])
        or (Locales.en and Locales.en[key])
        or key

    if select('#', ...) > 0 then
        return string.format(text, ...)
    end

    return text
end

_L = translate

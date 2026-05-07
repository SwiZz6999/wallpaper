# criticalgunoe

Standalone FiveM GunGame-resource met arena matchmaking, weapon progression, NUI-HUD, scorebord en admin commands.

## Installatie

1. Plaats de map `criticalgunoe` in je server resources-map.
2. Voeg toe aan `server.cfg`:

```cfg
ensure criticalgunoe
```

3. Geef admins optioneel toegang tot beheercommando's:

```cfg
add_ace group.admin criticalgunoe.admin allow
```

De resource is standalone en heeft geen ESX, QBCore of database nodig.

## Speler commands

- `/ggjoin [arena]` - join een arena. Zonder arena wordt de eerste arena gebruikt.
- `/ggleave` - verlaat je huidige GunGame.
- `/ggstatus` - toon arena's en actieve matches.
- `/ggmenu` - open het NUI-menu.

## Admin commands

Vereist ACE-permissie `criticalgunoe.admin`.

- `/ggadmin start <arena>` - forceer start/countdown van een arena.
- `/ggadmin stop <arena>` - stop de actieve match in een arena.
- `/ggadmin kick <id>` - verwijder een speler uit GunGame.
- `/ggadmin setlevel <id> <level>` - zet het GunGame-level van een speler.

## Configuratie

Alle gameplay-instellingen staan in `config.lua`:

- `Config.RequiredPlayers` - minimum aantal spelers voor automatische start.
- `Config.CountdownSeconds` - wachttijd voor de start.
- `Config.RoundTimeSeconds` - maximale rondetijd.
- `Config.JoinInProgress` - spelers laten joinen tijdens lopende matches.
- `Config.Weapons` - volledige wapenprogressie.
- `Config.Arenas` - arena's, lobbyplek, radius en spawnpoints.
- `Config.Bounds` - out-of-bounds waarschuwingen en damage.
- `Config.KillReward` - health/armor beloning per kill.

## Nieuwe arena toevoegen

Voeg in `Config.Arenas` een object toe:

```lua
{
    id = 'mijnarena',
    label = 'Mijn Arena',
    center = { x = 0.0, y = 0.0, z = 72.0 },
    radius = 120.0,
    lobby = { x = 0.0, y = 0.0, z = 72.0, w = 90.0 },
    spawns = {
        { x = 10.0, y = 0.0, z = 72.0, w = 180.0 },
        { x = -10.0, y = 0.0, z = 72.0, w = 0.0 }
    }
}
```

## Werking

- De server bewaakt matches, levels, kills, deaths, wincondities en routing buckets.
- Clients melden hun eigen death-event; de server valideert dat killer en slachtoffer in dezelfde lopende match zitten.
- Iedere kill verhoogt het level van de killer. Een kill op het laatste wapen wint de match.
- Bij gelijkstand na timeout wint de speler met hoogste level, daarna meeste kills, daarna minste deaths.
- Het NUI-HUD toont level, wapen, timer, scorebord, countdown, killfeed en meldingen.

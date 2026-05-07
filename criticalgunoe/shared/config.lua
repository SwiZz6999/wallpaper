Config = {}

Config.Locale = 'nl'
Config.Debug = false

Config.Commands = {
    join = 'ggjoin',
    leave = 'ggleave',
    status = 'ggstatus',
    menu = 'ggmenu',
    admin = 'ggadmin'
}

Config.AdminAce = 'criticalgunoe.admin'
Config.RequiredPlayers = 2
Config.CountdownSeconds = 15
Config.RoundTimeSeconds = 900
Config.RespawnDelayMs = 2500
Config.IntermissionSeconds = 8
Config.DefaultRoutingBucket = 0
Config.JoinInProgress = true

Config.KillReward = {
    health = 25,
    armor = 15,
    maxHealth = 200,
    maxArmor = 100
}

Config.AntiFarm = {
    enabled = true,
    sameVictimCooldownMs = 3500
}

Config.Death = {
    demoteOnSuicide = false,
    demoteLevels = 1
}

Config.Bounds = {
    enabled = true,
    warningSeconds = 10,
    damagePerTick = 12,
    tickMs = 3000
}

Config.Match = {
    stripWeaponsOnJoin = true,
    stripWeaponsOnExit = true,
    giveFullArmorOnSpawn = false,
    disableVehicles = true,
    friendlyFire = false
}

Config.Weapons = {
    { label = 'Pistol', weapon = 'WEAPON_PISTOL', ammo = 72, components = { 'COMPONENT_AT_PI_FLSH' } },
    { label = 'Combat Pistol', weapon = 'WEAPON_COMBATPISTOL', ammo = 72, components = { 'COMPONENT_AT_PI_FLSH' } },
    { label = 'Heavy Pistol', weapon = 'WEAPON_HEAVYPISTOL', ammo = 60, components = { 'COMPONENT_AT_PI_FLSH' } },
    { label = 'AP Pistol', weapon = 'WEAPON_APPISTOL', ammo = 90, components = { 'COMPONENT_AT_PI_FLSH' } },
    { label = 'Micro SMG', weapon = 'WEAPON_MICROSMG', ammo = 120, components = { 'COMPONENT_AT_PI_FLSH' } },
    { label = 'SMG', weapon = 'WEAPON_SMG', ammo = 150, components = { 'COMPONENT_AT_AR_FLSH' } },
    { label = 'Assault SMG', weapon = 'WEAPON_ASSAULTSMG', ammo = 150, components = { 'COMPONENT_AT_AR_FLSH' } },
    { label = 'Combat PDW', weapon = 'WEAPON_COMBATPDW', ammo = 150, components = { 'COMPONENT_AT_AR_FLSH' } },
    { label = 'Pump Shotgun', weapon = 'WEAPON_PUMPSHOTGUN', ammo = 48, components = { 'COMPONENT_AT_AR_FLSH' } },
    { label = 'Sawed-Off Shotgun', weapon = 'WEAPON_SAWNOFFSHOTGUN', ammo = 40 },
    { label = 'Assault Rifle', weapon = 'WEAPON_ASSAULTRIFLE', ammo = 180, components = { 'COMPONENT_AT_AR_FLSH' } },
    { label = 'Carbine Rifle', weapon = 'WEAPON_CARBINERIFLE', ammo = 180, components = { 'COMPONENT_AT_AR_FLSH' } },
    { label = 'Special Carbine', weapon = 'WEAPON_SPECIALCARBINE', ammo = 180, components = { 'COMPONENT_AT_AR_FLSH' } },
    { label = 'Bullpup Rifle', weapon = 'WEAPON_BULLPUPRIFLE', ammo = 180, components = { 'COMPONENT_AT_AR_FLSH' } },
    { label = 'MG', weapon = 'WEAPON_MG', ammo = 200 },
    { label = 'Marksman Rifle', weapon = 'WEAPON_MARKSMANRIFLE', ammo = 90 },
    { label = 'Sniper Rifle', weapon = 'WEAPON_SNIPERRIFLE', ammo = 40 },
    { label = 'Final Knife', weapon = 'WEAPON_KNIFE', ammo = 1 }
}

Config.Arenas = {
    {
        id = 'docks',
        label = 'Los Santos Docks',
        center = { x = 1015.22, y = -2890.78, z = 39.16 },
        radius = 115.0,
        lobby = { x = 1015.22, y = -2890.78, z = 39.16, h = 271.0 },
        spawns = {
            { x = 984.38, y = -2918.96, z = 39.16, h = 315.0 },
            { x = 1041.21, y = -2912.44, z = 39.16, h = 33.0 },
            { x = 1067.26, y = -2867.36, z = 39.16, h = 89.0 },
            { x = 1007.77, y = -2833.88, z = 39.16, h = 183.0 },
            { x = 963.23, y = -2862.74, z = 39.16, h = 238.0 },
            { x = 1026.34, y = -2951.65, z = 39.16, h = 1.0 }
        }
    },
    {
        id = 'sandy',
        label = 'Sandy Airfield',
        center = { x = 1719.45, y = 3254.29, z = 41.15 },
        radius = 130.0,
        lobby = { x = 1719.45, y = 3254.29, z = 41.15, h = 104.0 },
        spawns = {
            { x = 1664.73, y = 3226.58, z = 40.46, h = 278.0 },
            { x = 1728.56, y = 3204.22, z = 41.15, h = 18.0 },
            { x = 1786.31, y = 3255.71, z = 41.29, h = 92.0 },
            { x = 1747.84, y = 3305.11, z = 41.15, h = 171.0 },
            { x = 1686.28, y = 3302.14, z = 41.15, h = 226.0 },
            { x = 1639.93, y = 3263.76, z = 40.53, h = 268.0 }
        }
    },
    {
        id = 'maze',
        label = 'Maze Bank Rooftop',
        center = { x = -75.03, y = -818.91, z = 326.18 },
        radius = 82.0,
        lobby = { x = -75.03, y = -818.91, z = 326.18, h = 340.0 },
        spawns = {
            { x = -84.85, y = -821.68, z = 326.18, h = 319.0 },
            { x = -63.42, y = -824.14, z = 326.18, h = 36.0 },
            { x = -55.57, y = -803.86, z = 326.18, h = 132.0 },
            { x = -81.26, y = -791.39, z = 326.18, h = 207.0 },
            { x = -99.91, y = -809.54, z = 326.18, h = 274.0 }
        }
    }
}

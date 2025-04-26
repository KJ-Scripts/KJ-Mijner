Config = {}

Config.Debug = false

Config.MinerJob = {
    name = "mijner",
    grade = 0
}

Config.AxeRentalPrice = 150

Config.MinerNPC = {
    model = "s_m_y_construct_01",
    coords = vector4(2935.34, 2783.65, 39.11, 308.15),
    scenario = "WORLD_HUMAN_CLIPBOARD",
    blip = {
        sprite = 618,
        color = 5,
        scale = 0.8,
        display = 4
    }
}

Config.AllMiningSpots = {
    {coords = vector3(2926.1357, 2792.2480, 40.2186)},
    {coords = vector3(2937.4141, 2771.8137, 38.9874)},
    {coords = vector3(2953.4624, 2768.1311, 39.2606)},
    {coords = vector3(2920.9631, 2799.5906, 41.4814)},
    {coords = vector3(2969.2690, 2775.7754, 38.8273)},
    {coords = vector3(2977.1277, 2792.3987, 40.2168)},
    {coords = vector3(2972.2817, 2798.9143, 41.9453)},
    {coords = vector3(2938.3025, 2813.0110, 43.3499)},
    {coords = vector3(2921.4026, 2798.3494, 41.7065)},
    {coords = vector3(2926.3721, 2792.2114, 41.4178)},
    {coords = vector3(3000.1797, 2757.2529, 43.9696)}
}

Config.ActiveMiningSpots = 5

Config.MiningSpots = {}

Config.MiningDuration = 10000

Config.MiningItems = {
    {
        name = "steen",
        label = "Steen",
        baseProbability = 40,
        sellPrice = 25
    },
    {
        name = "steenkool",
        label = "Steenkool",
        baseProbability = 25,
        sellPrice = 40
    },
    {
        name = "houtskool",
        label = "Houtskool",
        baseProbability = 20,
        sellPrice = 55
    },
    {
        name = "ijzer",
        label = "IJzer",
        baseProbability = 12,
        sellPrice = 70
    },
    {
        name = "brons",
        label = "Brons",
        baseProbability = 10,
        sellPrice = 90
    },
    {
        name = "zilver",
        label = "Zilver",
        baseProbability = 8,
        sellPrice = 120
    },
    {
        name = "smaragd",
        label = "Smaragd",
        baseProbability = 5,
        sellPrice = 180
    },
    {
        name = "goud",
        label = "Goud",
        baseProbability = 3,
        sellPrice = 250
    },
    {
        name = "diamant",
        label = "Diamant",
        baseProbability = 1,
        sellPrice = 400
    }
}

Config.XP = {
    perMining = 5,
    levelMultiplier = 100,
    probabilityBonus = 2.5,
}

Config.Items = {
    miningAxe = 'pikhouweel'
}

Config.Locales = {
    ['nl'] = {
        ['mining_job_title'] = 'Mijnwerker',
        ['mining_job_desc'] = 'Mijn grondstoffen en verkoop ze voor geld!',
        ['npc_title'] = 'Mijnwerker Baas',
        ['npc_context'] = 'Praat met de Mijnwerker Baas',
        ['rent_axe'] = 'Huur een Pikhouweel ($%s)',
        ['return_axe'] = 'Breng het Pikhouweel terug',
        ['axe_rented'] = 'Je hebt een pikhouweel gehuurd voor $%s',
        ['axe_returned'] = 'Pikhouweel teruggebracht',
        ['axe_deposit_returned'] = 'Pikhouweel teruggebracht. Je krijgt $%s terug als borg.',
        ['already_have_axe'] = 'Je hebt al een pikhouweel',
        ['no_axe_to_return'] = 'Je hebt geen pikhouweel om terug te brengen',
        ['need_axe'] = 'Je hebt een pikhouweel nodig om te graven',
        ['not_enough_money'] = 'Je hebt niet genoeg geld om een pikhouweel te huren',
        ['mine_here'] = 'Mijn Hier',
        ['mining_in_progress'] = 'Mijnen...',
        ['mining_success'] = 'Je hebt %s gevonden',
        ['mining_failed'] = 'Mijnen mislukt',
        ['inventory_full'] = 'Je broekzakken zitten vol',
        ['sell_resources'] = 'Verkoop Grondstoffen',
        ['sell_all'] = 'Verkoop Alle Grondstoffen',
        ['sell_individual'] = 'Verkoop Individuele Grondstoffen',
        ['sell_item'] = 'Verkoop %s (x%s) voor $%s',
        ['sold_item'] = 'Je hebt %s x%s verkocht voor $%s',
        ['nothing_to_sell'] = 'Je hebt niets om te verkopen',
        ['xp_menu_title'] = 'Mijnwerker Ervaring',
        ['xp_menu_desc'] = 'Bekijk je mijnwerker niveau en ervaring',
        ['xp_level'] = 'Level: %s - XP: %s/%s',
        ['xp_gained'] = 'Mijnwerker ervaring verdiend: +%s XP',
        ['xp_level_up'] = 'Level omhoog! Je bent nu level %s',
        ['xp_next_level'] = 'Je hebt nog %s XP nodig om naar de volgende level te gaan',
        ['check_xp'] = 'Bekijk Mijnwerker Ervaring',
        ['close_menu'] = 'Sluit Menu',
        ['rent_axe_desc'] = 'Huur een pikhouweel om mee te mijnen',
        ['return_axe_desc'] = 'Breng je pikhouweel terug',
        ['sell_resources_desc'] = 'Verkoop je grondstoffen voor geld',
        ['cancel'] = 'Annuleren',
        ['press_to_mine'] = 'Druk op ~INPUT_CONTEXT~ om te graven',
        ['wrong_job'] = 'Je bent geen mijnwerker'
    }
}

Config.Locale = 'nl'

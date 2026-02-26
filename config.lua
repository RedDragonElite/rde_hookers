Config = {}

-- ════════════════════════════════════════
--  🌐  Language
-- ════════════════════════════════════════
Config.Locale = 'en'   -- 'en' | 'de'

Config.Locales = {

    en = {
        -- 🚗 Vehicle checks
        no_vehicle          = 'You need to be in a vehicle!',
        not_driver          = 'Only the driver can invite hookers.',
        vehicle_moving      = 'Stop the vehicle first!',

        -- 💋 Invite
        already_busy        = 'You already have a hooker with you!',
        not_available       = 'Not Available',
        shes_coming         = "She's Coming!",
        shes_coming_desc    = '💋 Find a quiet spot to park.',
        shes_in             = "She's In!",
        shes_in_desc        = '💋 Find a quiet spot and park.',
        invite_accepted     = 'Invitation Accepted',

        -- 👋 Dismiss
        hooker_left         = 'Hooker Left',
        hooker_left_desc    = '💋 She left your vehicle.',

        -- 🎭 Service Menu
        menu_title          = '💋 Services',
        menu_enjoying       = '💋 Enjoying the moment…',
        menu_dismiss_hint   = '[X] Dismiss',
        blowjob_title       = '👄 Blowjob',
        blowjob_desc        = 'Quick service',
        sex_title           = '🔥 Full Service',
        sex_desc            = 'Complete experience',
        dismiss_title       = '👋 Dismiss Her',
        dismiss_desc        = 'Send her away',
        cancel_title        = '🚪 Cancel',
        cancel_desc         = 'Maybe later…',

        -- ⏳ Progress
        service_busy        = 'Please wait for the current service to finish.',
        service_in_progress = 'in progress…',
        service_complete    = 'Service Complete',
        service_complete_desc = '💋 That was amazing! Want more?',

        -- 💰 Payment
        service_started     = 'Service Started',
        service_started_desc = '%s You paid **$%d** for %s',
        cannot_start        = 'Cannot Start Service',

        -- ❌ Errors
        session_error       = 'Player session not found. Try again.',
        hooker_invalid      = 'This hooker is not available',
        service_aborted     = 'Service Aborted',

        -- 👑 Admin
        stats_title         = 'Hooker System Stats',
        cleanup_complete    = 'Cleanup Complete',
        cleanup_desc        = 'Cleaned up %d hooker(s)',
        stats_reset         = 'Statistics Reset',
        stats_reset_desc    = 'All statistics have been reset.',

        -- 🖥️ Console
        debug_enabled       = 'DEBUG MODE ENABLED',
        server_ready        = 'Server ready! 💋',
    },

    de = {
        -- 🚗 Fahrzeug-Checks
        no_vehicle          = 'Du musst in einem Fahrzeug sitzen!',
        not_driver          = 'Nur der Fahrer kann Hooker einladen.',
        vehicle_moving      = 'Halte zuerst das Fahrzeug an!',

        -- 💋 Einladen
        already_busy        = 'Du hast bereits eine Begleitung bei dir!',
        not_available       = 'Nicht verfügbar',
        shes_coming         = 'Sie kommt!',
        shes_coming_desc    = '💋 Such dir einen ruhigen Ort zum Parken.',
        shes_in             = 'Sie ist drin!',
        shes_in_desc        = '💋 Such dir einen ruhigen Ort und parke.',
        invite_accepted     = 'Einladung angenommen',

        -- 👋 Entlassen
        hooker_left         = 'Begleitung weg',
        hooker_left_desc    = '💋 Sie hat dein Fahrzeug verlassen.',

        -- 🎭 Service Menu
        menu_title          = '💋 Angebote',
        menu_enjoying       = '💋 Moment genießen…',
        menu_dismiss_hint   = '[X] Entlassen',
        blowjob_title       = '👄 Blowjob',
        blowjob_desc        = 'Kurzer Service',
        sex_title           = '🔥 Vollservice',
        sex_desc            = 'Das komplette Erlebnis',
        dismiss_title       = '👋 Entlassen',
        dismiss_desc        = 'Schick sie weg',
        cancel_title        = '🚪 Abbrechen',
        cancel_desc         = 'Vielleicht später…',

        -- ⏳ Fortschritt
        service_busy        = 'Bitte warte bis der aktuelle Service abgeschlossen ist.',
        service_in_progress = 'läuft…',
        service_complete    = 'Service abgeschlossen',
        service_complete_desc = '💋 Das war fantastisch! Noch mal?',

        -- 💰 Zahlung
        service_started     = 'Service gestartet',
        service_started_desc = '%s Du hast **$%d** für %s bezahlt',
        cannot_start        = 'Service nicht möglich',

        -- ❌ Fehler
        session_error       = 'Spieler-Session nicht gefunden. Versuche es erneut.',
        hooker_invalid      = 'Diese Begleitung ist nicht verfügbar',
        service_aborted     = 'Service abgebrochen',

        -- 👑 Admin
        stats_title         = 'Hooker System Statistiken',
        cleanup_complete    = 'Aufräumen abgeschlossen',
        cleanup_desc        = '%d Begleitung(en) entfernt',
        stats_reset         = 'Statistiken zurückgesetzt',
        stats_reset_desc    = 'Alle Statistiken wurden zurückgesetzt.',

        -- 🖥️ Konsole
        debug_enabled       = 'DEBUG MODUS AKTIV',
        server_ready        = 'Server bereit! 💋',
    },
}

-- ════════════════════════════════════════
--  💰  Economy
-- ════════════════════════════════════════
Config.BlowjobPrice = 250
Config.SexPrice     = 500
Config.Currency     = 'money'

-- ════════════════════════════════════════
--  👄  Service Settings
-- ════════════════════════════════════════
Config.BlowjobDuration    = 45
Config.SexDuration        = 60
Config.MaxServiceSpeed    = 3.0
Config.MinPrivacyDistance = 20.0

-- ════════════════════════════════════════
--  🎭  Hooker Ped Models
-- ════════════════════════════════════════
Config.HookerModels = {
    `s_f_y_hooker_01`,
    `s_f_y_hooker_02`,
    `s_f_y_hooker_03`,
    `a_f_y_clubcust_01`,
    `a_f_y_clubcust_02`,
    `a_f_y_clubcust_03`,
}

-- ════════════════════════════════════════
--  🎬  Animations
-- ════════════════════════════════════════
Config.Animations = {
    blowjob = {
        hooker = { dict = 'oddjobs@towing',              anim = 'f_blow_job_loop',         flag = 1 },
        player = { dict = 'oddjobs@towing',              anim = 'm_blow_job_loop',         flag = 1 },
    },
    sex = {
        hooker = { dict = 'mini@prostitutes@sexlow_veh', anim = 'low_car_sex_loop_female', flag = 1 },
        player = { dict = 'mini@prostitutes@sexlow_veh', anim = 'low_car_sex_loop_player', flag = 1 },
    },
}

-- ════════════════════════════════════════
--  🗣️  Speech Lines
-- ════════════════════════════════════════
Config.Speech = {
    greeting       = { 'Generic_Hows_It_Going', 'GENERIC_HI', 'GENERIC_THANKS' },
    offer          = { 'Hooker_Offer_Service' },
    during_blowjob = { 'Sex_Oral', 'Sex_Oral_Fem', 'Sex_Generic' },
    during_sex     = { 'Sex_Generic', 'Sex_Generic_Fem', 'Sex_Climax', 'Sex_Oral' },
    finished       = { 'Sex_Finished' },
    offer_again    = { 'Hooker_Offer_Again' },
    leaving        = { 'Hooker_Had_Enough', 'GENERIC_BYE', 'GENERIC_THANKS' },
}

-- ════════════════════════════════════════
--  🎨  UI Icons
-- ════════════════════════════════════════
Config.Icons = {
    success = '✅',
    error   = '❌',
    info    = 'ℹ️',
    money   = '💰',
    hooker  = '💋',
    car     = '🚗',
    fire    = '🔥',
    lips    = '👄',
    wave    = '👋',
}

-- ════════════════════════════════════════
--  🛠️  Debug
-- ════════════════════════════════════════
Config.Debug = true

-- ════════════════════════════════════════
--  📊  Advanced
-- ════════════════════════════════════════
Config.Advanced = {
    InteractionDistance     = 3.0,
    VehicleCheckInterval    = 500,
    StateValidationInterval = 2000,
    EntryTimeout            = 10,
    DismissalCooldown       = 10000,
    SpeechVolume            = 1.0,
    AutoMenuDelay           = 2500,
}

return Config
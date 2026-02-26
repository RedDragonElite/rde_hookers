<div align="center">

# 🐉 RDE Hooker System

[![Version](https://img.shields.io/badge/version-1.0.0-red?style=for-the-badge)](https://github.com/RedDragonElite/rde_hookers)
[![License](https://img.shields.io/badge/license-RDE%20Black%20Flag-black?style=for-the-badge)](LICENSE)
[![FiveM](https://img.shields.io/badge/FiveM-Compatible-blue?style=for-the-badge)](https://fivem.net)
[![ox_core](https://img.shields.io/badge/ox__core-Exclusive-purple?style=for-the-badge)](https://github.com/communityox/ox_core)
[![FREE](https://img.shields.io/badge/price-FREE%20FOREVER-green?style=for-the-badge)](https://github.com/RedDragonElite/rde_hookers)

**The most immersive, production-grade hooker system ever built for FiveM.**  
Statebag-synced. Fully animated. Auto-menu. Nostr-logged. Zero compromises.

<img width="1456" height="819" alt="image" src="https://github.com/user-attachments/assets/c9ee7edb-6bf8-4341-ad43-81d298e749dd" />

*Built by [Red Dragon Elite](https://rd-elite.com) | Free Forever | OX Ecosystem Exclusive*

[📖 Installation](#-installation) • [🎮 Features](#-features) • [⚙️ Configuration](#-configuration) • [📡 Nostr Logging](#-nostr-logging) • [💬 Discord](https://discord.gg/rde)

---

</div>

## 🔥 Why This System Changes Everything

Every other hooker script out there is a 200-line spaghetti mess with hardcoded positions and no sync.  
This is what happens when you build with production standards, statebags, and zero shortcuts.

| ❌ Other Scripts | ✅ RDE Hooker System |
|---|---|
| **No sync** – only works for the client who spawned | **Statebag-synced** – server-authoritative, cheat-proof |
| **Hardcoded keys** – conflicts with vehicle controls | **Auto-menu** – opens automatically after parking |
| **Server crashes** on player disconnect | **Zero crashes** – all edge cases handled |
| **Discord-only logging** – rate limited, censored | **Nostr logging** – decentralized, permanent, optional |
| **English only** | **EN / DE** built-in, easily extendable |
| **No validation** – exploitable | **ox_core player guard** on every server event |
| **3000-line god files** | **Modular, clean, documented** |

---

## 🎯 Features

### 🎮 Gameplay
- **Invite hookers to your vehicle** via ox_target interaction
- **Auto service menu** — opens automatically after parking for a few seconds, no key conflicts
- **Blowjob & Full Service** — configurable prices, durations, and animations
- **Ambient speech** — realistic voice lines throughout the entire interaction
- **Auto-dismiss** — hooker leaves if player dies or drives away

### 🏗️ Technical
- **Statebag-first architecture** — server owns all state, no client-side cheating possible
- **ox_core exclusive** — proper player validation on every network event
- **ox_inventory native** — uses `GetItem` with `returnsCount` correctly (not hacks)
- **Cheat-proof** — `withPlayer` statebag prevents multi-player exploitation
- **Timeout handling** — hooker auto-dismissed if she fails to enter the vehicle
- **Resource cleanup** — all entities properly released on resource stop

### 🌐 Quality of Life
- **Multi-language** — EN / DE out of the box, add any language in 5 minutes
- **Fully configurable** — prices, durations, models, animation dicts, speech lines, all in `config.lua`
- **Optional Nostr logging** — integrates with `rde_nostr_log` if installed, silent if not
- **Admin commands** — `/hookerstats`, `/hookercleanup`, `/hookerresetstats`
- **Debug mode** — detailed console output for development

---

## 📸 Screenshots

> *Invite via ox_target → she walks to the car → auto service menu → animations → progress circle*

| She Gets In | Auto Menu | Service Running |
|---|---|---|
| ![invite](https://rd-elite.com/rde_hookers/screenshots/invite.png) | ![menu](https://rd-elite.com/rde_hookers/screenshots/menu.png) | ![service](https://rd-elite.com/rde_hookers/screenshots/service.png) |

---

## 📦 Dependencies

**Required:**
- [ox_core](https://github.com/communityox/ox_core) — Framework
- [ox_lib](https://github.com/communityox/ox_lib) — UI & utilities
- [ox_target](https://github.com/communityox/ox_target) — Interaction targeting
- [ox_inventory](https://github.com/communityox/ox_inventory) — Inventory / currency
- [oxmysql](https://github.com/communityox/oxmysql) — Database connector

**Optional:**
- [rde_nostr_log](https://github.com/RedDragonElite/rde_nostr_log) — Decentralized logging *(script works 100% without it)*

---

## 🚀 Installation

### 1. Download

```bash
cd resources
git clone https://github.com/RedDragonElite/rde_hookers.git
```

Or download the latest [release](https://github.com/RedDragonElite/rde_hookers/releases/latest) and extract to your resources folder.

### 2. Add to server.cfg

Make sure your dependency order is correct:

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_core
ensure ox_target
ensure ox_inventory
ensure rde_nostr_log   # optional
ensure rde_hookers
```

### 3. Configure

Edit `config.lua` to your liking:

```lua
Config.Locale       = 'en'   -- 'en' or 'de'
Config.BlowjobPrice = 250    -- price in your currency item
Config.SexPrice     = 500
Config.Currency     = 'money' -- ox_inventory item name
Config.Debug        = false   -- set true during setup
```

### 4. Done ✅

No database tables needed. No SQL setup. Zero configuration required beyond the config file.  
Start the resource and check your console for the startup banner.

---

## 🎮 How It Works

### Player Flow

```
1. Approach hooker on foot or drive up
2. [ox_target] → "💋 Invite to Car"          (must be driver, seat must be free)
3. She walks to your vehicle and gets in
4. Drive to a quiet spot
5. Park & stop the engine / put in neutral
6. ⏳ After ~2.5 seconds → Service Menu opens automatically
7. Choose Blowjob or Full Service
8. Server charges money via ox_inventory
9. Animations + ambient speech play
10. Progress circle runs for the full duration
11. [X] at any time to dismiss her
```

### Key Controls

| Action | Control |
|---|---|
| Invite hooker | `ox_target` interaction |
| Dismiss hooker | `ox_target` interaction OR `[X]` while parked |
| Open service menu | **Automatic** after parking for `AutoMenuDelay` ms |

> **Why no [E] key?** `[E]` in a vehicle triggers horn/exit — it conflicts. The auto-open approach is cleaner and more immersive.

---

## ⚙️ Configuration

### `config.lua` — Full Reference

```lua
-- Language: 'en' | 'de' (add your own locale in Config.Locales)
Config.Locale = 'en'

-- Economy
Config.BlowjobPrice = 250        -- price charged via ox_inventory
Config.SexPrice     = 500
Config.Currency     = 'money'    -- the ox_inventory item name for your currency

-- Service timing
Config.BlowjobDuration = 45      -- seconds
Config.SexDuration     = 60      -- seconds

-- Vehicle check
Config.MaxServiceSpeed = 3.0     -- km/h — how slow before "stationary"

-- Advanced
Config.Advanced = {
    InteractionDistance     = 3.0,   -- ox_target radius in metres
    AutoMenuDelay           = 2500,  -- ms parked before menu auto-opens (0 = instant)
    StateValidationInterval = 2000,  -- ms between statebag sanity checks
    EntryTimeout            = 10,    -- seconds before hooker entry times out
}
```

### Adding a New Language

Open `config.lua` and add a new block to `Config.Locales`:

```lua
Config.Locales.fr = {
    no_vehicle   = "Vous devez être dans un véhicule !",
    not_driver   = "Seul le conducteur peut inviter.",
    menu_title   = "💋 Services",
    -- ... copy all keys from Config.Locales.en and translate
}
```

Then set `Config.Locale = 'fr'`. That's it.

---

## 👑 Admin Commands

| Command | Description | Permission |
|---|---|---|
| `/hookerstats` | Shows active hookers, in-service count, total revenue & service stats | `group.admin` |
| `/hookercleanup` | Force-dismisses all active hookers across the server | `group.admin` |
| `/hookerresetstats` | Resets all revenue & service statistics | `group.admin` |

---

## 📡 Nostr Logging

If you have [rde_nostr_log](https://github.com/RedDragonElite/rde_nostr_log) installed and started, the hooker system will **automatically** log events to the Nostr network — decentralized, permanent, uncensorable.

**Events logged:**

| Event | Message |
|---|---|
| Player invites hooker | `💋 [HOOKER] PlayerName invited hooker` |
| Service purchased | `👄/🔥 [HOOKER] PlayerName purchased blowjob/sex for $250` |
| Service aborted (e.g. no money) | `❌ [HOOKER] PlayerName – service aborted: reason` |
| Hooker dismissed | `👋 [HOOKER] PlayerName dismissed hooker` |
| Player disconnected with active hooker | `🚪 [HOOKER] PlayerName disconnected with active hooker` |
| Admin command used | `👑 [HOOKER ADMIN] AdminName – hookerstats` |

**No rde_nostr_log installed?** The script checks `GetResourceState('rde_nostr_log')` before every log call. If it's not running, nothing happens — not a single error. Completely silent fallback.

---

## 🔧 Exports

Other resources can use these server-side exports:

```lua
-- Check if a player has enough of the currency
exports['rde_hookers']:HasEnoughMoney(source, amount)

-- Get the configured price for a service type
exports['rde_hookers']:GetServicePrice('blowjob')  -- returns 250
exports['rde_hookers']:GetServicePrice('sex')      -- returns 500

-- Check if a player currently has an active hooker
exports['rde_hookers']:PlayerHasHooker(source)     -- returns true/false

-- Get total active hookers across the server
exports['rde_hookers']:GetActiveHookerCount()      -- returns number

-- Get lifetime statistics table
exports['rde_hookers']:GetStatistics()
-- returns { totalInvites, totalServices, totalRevenue, blowjobs, fullServices }
```

---

## 🐛 Troubleshooting

### Service menu never opens
- Make sure you are the **driver** (not passenger)
- **Stop the vehicle completely** — speed must be below `Config.MaxServiceSpeed` (default 3 km/h)
- Put the vehicle in **neutral (N)** or turn the engine off
- Wait for `AutoMenuDelay` ms (default 2.5 seconds) — the menu opens automatically

### Hooker never enters vehicle
- The front passenger seat (seat 0) must be **free**
- The hooker has a 10-second timeout — if she can't pathfind, she auto-dismisses

### "Not Available" when trying to invite
- Another player may already have this hooker (`withPlayer` statebag is set)
- You may already have a hooker with you (`PlayerHasHooker` check)

### Money not being deducted
- Verify `Config.Currency` matches your actual ox_inventory item name exactly
- Check that the player actually has the item in their inventory
- Enable `Config.Debug = true` and check server console for detailed logs

### Server crashes on player disconnect
- This was a known bug in older versions caused by `GetPlayerName` infinite recursion
- **This is fixed** in the current release — update to the latest version

---

## 🗺️ Roadmap

### v1.1 (Planned)
- [ ] **Privacy check** — refuse service if NPCs are within `MinPrivacyDistance`
- [ ] **Multiple service locations** — outdoor, indoor, custom zones
- [ ] **STD system** — risk/reward mechanic (configurable, off by default)
- [ ] **Wanted level trigger** — optional police attention system

### v2.0 (Future)
- [ ] **Pimp system** — player-owned hooker management
- [ ] **Dynamic pricing** — time of day, location, demand modifiers
- [ ] **Reputation system** — regular customers get discounts
- [ ] **Custom ped outfits** — illenium-appearance integration

---

## 🤝 Contributing

Contributions are welcome!

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/AmazingFeature`
3. Commit your changes: `git commit -m 'Add AmazingFeature'`
4. Push to the branch: `git push origin feature/AmazingFeature`
5. Open a Pull Request

### Bug Reports
Please include:
- FiveM version & build
- ox_core / ox_lib / ox_inventory versions
- Full server console error output
- Steps to reproduce

---

## 📄 License

This project is licensed under the **RDE Black Flag License**.

```
###################################################################################
#                                                                                 #
#      .:: RED DRAGON ELITE (RDE)  -  BLACK FLAG SOURCE LICENSE v6.66 ::.         #
#                                                                                 #
#   PROJECT:    RDE_HOOKERS (The most immersive, production-grade hooker system)  #
#   ARCHITECT:  .:: RDE ⧌ Shin [△ ᛋᛅᚱᛒᛅᚾᛏᛋ ᛒᛁᛏᛅ ▽] ::. | https://rd-elite.com     #
#   ORIGIN:     https://github.com/RedDragonElite                                 #
#                                                                                 #
#   WARNING: THIS CODE IS PROTECTED BY DIGITAL VOODOO AND PURE HATRED FOR LEAKERS #
#                                                                                 #
#   [ THE RULES OF THE GAME ]                                                     #
#                                                                                 #
#   1. // THE "FUCK GREED" PROTOCOL (FREE USE)                                    #
#      You are free to use, edit, and abuse this code on your server.             #
#      Learn from it. Break it. Fix it. That is the hacker way.                   #
#      Cost: 0.00€. If you paid for this, you got scammed by a rat.               #
#                                                                                 #
#   2. // THE TEBEX KILL SWITCH (COMMERCIAL SUICIDE)                              #
#      Listen closely, you parasites:                                             #
#      If I find this script on Tebex, Patreon, or in a paid "Premium Pack":      #
#      > I will DMCA your store into oblivion.                                    #
#      > I will publicly shame your community.                                    #
#      > I hope your server lag spikes to 9999ms every time you blink.            #
#      SELLING FREE WORK IS THEFT. AND I AM THE JUDGE.                            #
#                                                                                 #
#   3. // THE CREDIT OATH                                                         #
#      Keep this header. If you remove my name, you admit you have no skill.      #
#      You can add "Edited by [YourName]", but never erase the original creator.  #
#      Don't be a skid. Respect the architecture.                                 #
#                                                                                 #
#   4. // THE CURSE OF THE COPY-PASTE                                             #
#      This code uses network-synced entities and async bus logic.                #
#      If you just copy-paste without reading, it WILL break.                     #
#      Don't come crying to my DMs. RTFM or learn to code.                        #
#                                                                                 #
#   --------------------------------------------------------------------------    #
#   "We build the future on the graves of paid resources."                        #
#   "REJECT MODERN MEDIOCRITY. EMBRACE RDE SUPERIORITY."                          #
#   --------------------------------------------------------------------------    #
###################################################################################
```

---

## 🙏 Credits

### Built With
- [ox_core](https://github.com/communityox/ox_core) — The only framework worth building on
- [ox_lib](https://github.com/communityox/ox_lib) — UI & utility library
- [ox_target](https://github.com/communityox/ox_target) — Entity interaction system
- [ox_inventory](https://github.com/communityox/ox_inventory) — Inventory management
- [rde_nostr_log](https://github.com/RedDragonElite/rde_nostr_log) — Decentralized logging

### Special Thanks
- Overextended team for the entire OX ecosystem
- The FiveM community for pushing the standard higher
- Everyone who tests, reports bugs, and contributes

---

<div align="center">

**Made with 🔥 by [.:: Red Dragon Elite ::. | SerpentsByte](https://rd-elite.com)**

*Part of the [RDE Arsenal](https://github.com/RedDragonElite) — 55+ next-gen FiveM resources, all FREE.*

[⬆ Back to Top](#-rde-hooker-system)

</div>

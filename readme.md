# jd-carspawner v0.2.1

**A simple car spawner for QBCore jobs and car rentals**

[![jd-carspawner preview](https://img.youtube.com/vi/TkyZzg5bl3Q/maxresdefault.jpg)](https://www.youtube.com/watch?v=TkyZzg5bl3Q)

---

## Table of Contents

- [About](#about)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [How it works](#how-it-works)
- [Files overview](#files-overview)
- [Customization tips](#customization-tips)
- [Contributing](#contributing)
- [License](#license)

---

## About

`jd-carspawner` is a lightweight resource for FiveM running QBCore that provides vehicle spawning functionality for jobs and a simple car rental flow. It keeps logic split between client and server, and all locations / values are configurable in `config.lua`.

## Features

- Job-based vehicle spawns
- Car rental support with configurable pricing
- Configurable spawn locations (vectors) for job spawns and rental peds
- Minimal, easy-to-read Lua code (client + server)

## Requirements

- A QBCore-based FiveM server (make sure `qb-core` is running on the server)
- Tested with common QBCore setups — adapt to your server's exports if necessary

## Installation

1. Copy or clone this repo into your server `resources` folder:

```bash
git clone https://github.com/JadaDev/jd-carspawner.git
```

2. Add the resource to your `server.cfg` (or equivalent) so it loads on start:

```
ensure jd-carspawner
```

3. Restart your server or ensure the resource is started.

## Configuration

All important configuration lives in `config.lua`.

- **Spawn vectors**: Job vehicle spawn locations and rental ped locations are defined in `config.lua` as vectors 4 (or tables with `x`, `y`, `z`, and optionally `heading`). To change where vehicles spawn or where the rental NPC appears, open `config.lua` and look for the sections that define spawn locations — they contain vector entries you can edit to your map coordinates.

Example formats you may find in a config file (read the actual `config.lua` for exact names used):

> **Note:** There are no chat commands for spawning in this resource. Spawns are triggered by the job interactions / rental ped behavior defined in the scripts — check `config.lua` to see how interactions are handled and which config entries are used.

## How it works

- `client.lua` handles player interactions (menus/peds/interaction logic) and requests a spawn from the server when appropriate.
- `server.lua` handles validation (job checks, payments for rentals, etc.) and the final vehicle creation.
- `config.lua` controls which vehicles are available, prices, and all spawn locations.

If you want to integrate the spawner into another script or call it programmatically, inspect `client.lua` and `server.lua` for the events/exports used — they show the exact event names the resource listens to and triggers.

## Files overview

| File                            | Purpose                                                                                |
| ------------------------------- | -------------------------------------------------------------------------------------- |
| `fxmanifest.lua`                | Resource manifest and dependency declarations                                          |
| `config.lua`                    | All configurable values: vehicles, spawn locations (vectors), prices, job restrictions |
| `client.lua`                    | Client-side logic (interactions, menus, requests)                                      |
| `server.lua`                    | Server-side validation and vehicle spawning                                            |
| `client/` `server/` directories | (if present) helper modules / HTML UI / locale files                                   |

## Customization tips

- **Adding vehicles**: add models to the vehicle lists in `config.lua`.
- **Moving spawns**: change the vector entries for job spawns and rental ped locations in `config.lua`. Use an in-game coordinate tool or a map editor to get accurate coordinates.
- **Permissions / jobs**: adjust job names in `config.lua` to match your server's job identifiers.
- **Economy**: update rental prices in `config.lua` to integrate with your server's economy.

## Contributing

Contributions are welcome. Suggested workflow:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-change`)
3. Commit your changes (`git commit -m "Add feature"`)
4. Push and open a Pull Request

If you need help or want changes made to the README itself, open an issue or ping the repo owner.

## License

MIT

---

*If you'd like, I can also:*

- convert this to a one-file `README.md` you can copy into the repo (I already created this here),
- add screenshots or an example `config.lua` snippet taken directly from the repo,
- or prepare a PR that commits the `README.md` for you.


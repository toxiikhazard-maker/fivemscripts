# ZRP Extraction PvE Zombies (QBCore + ox_inventory)

## Requirements
- qb-core
- oxmysql
- ox_lib
- ox_inventory
- baseevents (for death event hooks)
- qb-multicharacter (recommended for multi-character switching)
- One appearance resource (optional but recommended):
  - illenium-appearance **or**
  - fivem-appearance

## Install
1. Copy `resources/[zrp]/*` into your server resources folder.
2. Import SQL file:
   ```sql
   source sql/zrp_schema.sql;
   ```
3. Add resources to `server.cfg` using `server.cfg.zrp.snippet` order.
4. Restart server.

## Controls
- **Radial menu (ox_lib radial, default keybind F1)** for party, raid, skills, customization, and character actions.
- `/zrp_menu` (fallback helper; reminds players to use radial menu).
- `/raid_stash` (open your current raid stash).

## Legacy Admin/Debug Commands (still available)
- `/zrp_skills`
- `/zrp_customize`
- `/zrp_saveappearance`
- `/zrp_switchchar`
- `/party_create`
- `/party_invite <serverId>`
- `/party_leave`
- `/party_kick <serverId>`
- `/raid_solo <zoneId> <contractId>`
- `/raid_party <zoneId> <contractId>`


## txAdmin / FxServer Template

This repository now includes a full-bootstrap template for fast deployment (including dependency download):

- `template/txadmin/recipe.yaml`
  - Import as a txAdmin recipe and deploy directly from this repo.
  - Downloads and installs: `qb-core`, `oxmysql`, `ox_lib`, `ox_inventory`, then copies ZRP resources.
- `template/fxserver/server.cfg.template`
  - Placeholder-based server.cfg template for manual FxServer setups.
- `template/scripts/setup_fxserver.sh`
  - Full bootstrap helper: clones required dependencies, copies ZRP resources + SQL, and renders `server.cfg`.

### Quick manual setup (FxServer)

```bash
bash template/scripts/setup_fxserver.sh /path/to/fxserver "mysql://fivem:password@127.0.0.1/fivem?charset=utf8mb4" "ZRP Extraction PvE" 32
```

Optional dependency refs for manual bootstrap:
- `QB_CORE_REF` (default `main`)
- `OXMYSQL_REF` (default `main`)
- `OX_LIB_REF` (default `master`)
- `OX_INVENTORY_REF` (default `main`)

Then:
1. Import schema: `source /path/to/fxserver/zrp_schema.sql`
2. Edit `/path/to/fxserver/server.cfg` (`sv_licenseKey`, admins, icon, endpoints)
3. Start server.


### txAdmin recipe URL notes (important)

If txAdmin says `invalid yaml`, most often the URL is not the raw file.
Use a **raw file URL** (not the GitHub HTML page).

Recommended (root recipe):
`https://raw.githubusercontent.com/<owner>/<repo>/<branch>/recipe.yaml`

Alternative (same content):
`https://raw.githubusercontent.com/<owner>/<repo>/<branch>/template/txadmin/recipe.yaml`


- Recipe action names were normalized to txAdmin snake_case (`download_github`, `copy_path`, `replace_string`, `query_database`, `remove_path`) for compatibility with builds that reject camelCase actions.

When running the recipe, set:
- `zrpRepoUrl` => `https://github.com/<owner>/<repo>`
- `zrpRepoRef` => your branch/tag (for example `main`)

## Added Systems
- **Hub safezone + vendors**:
  - Configured safezone in hub with weapon disable/invulnerability while inside.
  - Two example vendors (Quartermaster + Medic Supplier) with buy/sell lists via ox_inventory + cash economy.
- **Weapon attachments**: weapon loot can roll random attachment metadata.
- **Ammo types**: ammo loot rolls FMJ/AP/Incendiary/etc metadata with stat multipliers.
- **Armor and clothing perks**: armor/clothing items grant passive buffs (armor, sprint, mitigation).
- **Skill system with multiple trees**:
  - Assault
  - Survival
  - Support
  - Skill points gained on level-up and spent via `/zrp_skills`.
- **Character customization + multi-character support**:
  - Appearance saved per `citizenid` in `zrp_characters`.
  - Saved appearance auto-applies on character load.
  - Character roster query by license for display in ZRP menu.
  - Character switching command (`/zrp_switchchar`) triggers qb-multicharacter selector.

## Gameplay Flow
1. Players in hub bucket 0.
2. Use the **radial menu** to create/invite/leave/kick party, start solo/party raids, open skills, and manage character actions. The hub also contains a safezone and vendor NPCs.
3. Start solo or leader-started party raid.
4. Raid assigns routing bucket = raidId, teleports to insertion, creates per-player stash (`raid:<raidId>:<citizenid>`).
5. Loot from containers goes to raid stash only (Found In Raid), including weapon/ammo metadata.
6. Contract progress is shared per raid.
7. Extraction requires hold timer and may be gated by contract.
8. Successful extract transfers stash to player inventory; death/disconnect clears stash.

## Notes
- PvE only design.
- Zombie pressure scales with threat + party size.
- Threat increases from sprinting, gunfire, and looting.

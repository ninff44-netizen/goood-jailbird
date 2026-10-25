# GOOOD — Jailbird

Client-side menu build for the Roblox FPS **Jailbird** (`placeId 14772802900`).
Luau, single file, no external assets. Menu key: `RIGHT SHIFT`.

```
GOOOD.lua                    the build (execute with a Luau injector)
preview/goood_menu_preview.html   1:1 HTML mockup of the ScreenGui (open in a browser)
```

## Features

| Tab | Option | Notes |
|---|---|---|
| Combat | Aimbot | mouse movement via `mousemoverel`, camera-lerp fallback |
| Combat | Aim mode | `Hold M2` / `Always` |
| Combat | Aim FOV, smoothing, target part | screen-space FOV in pixels |
| Combat | Wall check | local raycast, excludes local + target character |
| Combat | Team check | uses `Player.Team` |
| Combat | Silent aim | `Camera` (render-step hook) or `Remote` (namecall arg rewrite) |
| Combat | Remote name | exact remote name for Remote silent mode |
| Visuals | ESP | box, name, health bar, distance, tracer (Drawing API) |
| Visuals | ESP fallback | `Highlight` when `Drawing` is unavailable |
| Visuals | Fullbright | Lighting override, restored on disable |
| Game | Buff barricades | anchor, collide, transparency, health values → `1e9` |
| Game | No outside detection | blocks matching remotes, hides matching UI, clears matching bools |
| Game | Extra keywords | comma-separated name patterns for the barricade scan |
| Player | Walk speed / jump power | humanoid override, restored on unload |
| Player | Infinite jump | `JumpRequest` → `Jumping` state |
| Player | Hitbox expander | `HumanoidRootPart` scale, restored on disable |
| Setup | Header image | accepts `rbxassetid://…` or a raw id |
| Setup | Save / load config | `GOOOD_jailbird.json` via `writefile` / `readfile` |
| Setup | Unload | disconnects everything and restores every override |

Search box filters the rows of the active tab on every keystroke.

## Requirements

- A Luau injector that exposes `Drawing`, `mousemoverel`, `hookmetamethod`,
  `getnamecallmethod`, `gethui`, and optionally `writefile` / `readfile`.
- The stock Windows client runs Hyperion/Byfron, which blocks common injectors.

The script degrades instead of erroring: no `Drawing` → Highlight fallback;
no `hookmetamethod` → Remote silent mode disabled; no `writefile` → config buttons
are inert. Loading never throws on a missing capability.

## What the game validates

Taken from the game's public changelog:

- **Beta 11.6 (2021-12-06)** — server hit detection + hit feedback only on
  registered hits. `Hitbox expander` is therefore expected to be cosmetic.
- **Beta 11.3 (2021-11-29)** — new bullet raycast synced to reticles and iron
  sights. `Silent aim → Camera` is the mode that matches that path.
- **Beta 13.1 (2021-12-31)** — speed hack patch. `Walk speed` is the riskiest
  option here; leave it near default.
- **Beta 14.1 (2022-01-08)** — named anti-cheat implementation.

Everything that does not need to lie to the server (ESP, mouse aimbot, visuals,
client state spoofs) is the part that survives.

## Known limits

- Not executed against a live client by the author of this repo. The GUI is plain
  Luau with no dependency; the injection-dependent paths are guarded by `if`.
- `Remote` silent aim only rewrites `CFrame`, `Vector3` and `Ray` arguments on a
  remote whose name matches exactly. Other payload shapes are untouched.
- `No outside detection` returns `nil` on matching `InvokeServer` calls, which can
  break a call expecting a value. Disable it if the game misbehaves at spawn.
- Barricade scan walks up to 30,000 descendants with a yield every 400 objects.
- Team checks rely on `Player.Team`. Games that model teams as attributes will
  need both team checks turned off.

## Configuration

Config is written next to the executor's workspace as `GOOOD_jailbird.json`.
Structure is flat: one key per option, names matching the `F` handles in the
script (`Aimbot`, `AimFov`, `EspMax`, `HitboxSize`, …).

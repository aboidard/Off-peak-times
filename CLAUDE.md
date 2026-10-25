# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Garmin Connect IQ **widget** written in Monkey C ("Heures Creuses" = French electricity off-peak hours). It shows whether the current time is in a user-configured off-peak period, the time until the next one, and a 24h timeline bar centered on "now". Targets: every installed touchscreen watch at API 6.0 (Venu 4, Venu X1, vívoactive 6, fēnix 8/8 Pro/8 Solar/E, Enduro 3, Forerunner 70/170/570/970, D2 Mach 2 Pro). Edge bike computers are left out on purpose. Screens range from 260x260 MIP up to 454x454 AMOLED, including the non-round Venu X1. `minApiLevel="6.0.0"`, languages `eng` + `fre`. `manifest.xml` and `monkey.jungle` are authoritative — re-read them rather than trusting these values. `manifest.xml` is generated; edit it through the VS Code Monkey C extension commands.

`.github/agents/garmin-connectiq-widget.agent.md` holds detailed project conventions (written in French); its key points are summarized below.

## Build and run (Windows / PowerShell)

There are no tests or linter; validation means compiling with the Monkey C compiler and running in the simulator. The SDK lives under `%APPDATA%\Garmin\ConnectIQ\Sdks\` (use the one selected by the VS Code extension; last verified with 9.1.0). The developer key path comes from the VS Code setting `monkeyC.developerKeyPath` — never copy the key into the repo.

```powershell
$sdk = '<SDK>'; $key = '<DEVELOPER_KEY>'; $target = 'venu445mm'
java.exe -Xms1g '-Dfile.encoding=UTF-8' -classpath "$sdk\bin\monkeybrains.jar" `
  com.garmin.monkeybrains.Monkeybrains -f "$PWD\monkey.jungle" -d $target `
  -o "$env:TEMP\HeuresCreuses-validation.prg" -w -y $key

# Run: start the simulator first, then push the .prg
& "$sdk\bin\simulator.exe"
java.exe -classpath "$sdk\bin\monkeybrains.jar" com.garmin.monkeybrains.monkeydodeux.MonkeyDoDeux `
  -f "$env:TEMP\HeuresCreuses-validation.prg" -d $target -s "$sdk\bin\shell.exe"
```

- Quote `'-Dfile.encoding=UTF-8'`: unquoted, PowerShell splits it and java fails with `ClassNotFoundException: /encoding=UTF-8`.
- To check every target, loop over the `iq:product` ids in `manifest.xml` and run the build with `-d <id>` for each one.
- Use Windows `java.exe`; the SDK's `bin/monkeyc` script fails under WSL (CRLF), and Linux java reports `Invalid device id`. Don't patch SDK scripts.
- A known, acceptable warning: the launcher icon gets scaled down to 65x65.
- `bin/` is build output (gitignored) — never edit it.
- Be explicit about what was verified: compile vs. simulator launch vs. real device.

## Architecture

- **Entry**: `HeuresCreusesApp` returns `HeuresCreusesView` + `HeuresCreusesDelegate` for the full widget, and `HeuresCreusesGlanceView` from `getGlanceView()`.
- **Glance context**: anything reachable from the glance (`getGlanceView`, `HeuresCreusesGlanceView`, `Settings`) must be annotated `(:glance)`. The error `Class not available to 'Glance'` in the simulator means a missing annotation.
- **`Settings`** (`source/Settings.mc`) is the single storage/model layer over `Application.Storage`. Periods are `[startMinute, endMinute]` pairs (minutes since midnight, 0–1439), up to `MAX_PERIODS = 8`, stored as `period_<i>_start/end` plus `period_count_v2`. If the count key is missing, it migrates from the legacy `p1_*`/`p2_*` keys (or defaults 01:10–06:10 and 14:10–17:10). Period semantics: `start > end` wraps past midnight; `start == end` means all day. Widgets can be killed between activations, so always persist via `Settings` and never rely on in-memory state.
- **Off-peak logic** (`isPeriodActive`, `isHeuresCreuses`, `minutesUntilNextHeuresCreuses`, `formatRemaining`, `minutesToTimeString`) lives in `Settings` and is shared by the main view and the glance. These helpers take the `periods` array as a parameter, so call `getPeriods()` once per `onUpdate`; it reads from storage each time.
- **Precision setting**: `KEY_PRECISION` stores one of `PRECISION_HALF_HOUR` (default), `PRECISION_HOUR` or `PRECISION_MINUTE`. `formatRemaining` rounds the remaining time *up* to that step, then formats it (`49min`, `1h`, `1h05`). The main view and the glance both build their remaining-time text through it. It is edited in `PrecisionView`, a `Menu2` pushed from `SettingsMenuView` and popped once a choice is made.
- **Main view**: custom-drawn status plus a swipe-in side drawer (drag/tap handled in `HeuresCreusesDelegate`, animated with a timer). The menu key pushes `HomeMenuView` (a `Menu2`) → settings or credits.
- **Settings flow** (`SettingsView.mc`, `SettingsDelegate.mc`, `TimePickerView.mc`): `openSettings()` opens `SettingsMenuView`, the root settings `Menu2`. Each of its entries pushes a sub-menu and shows the current state as a sub-label, refreshed in `onShow`; new settings belong there as additional entries. `PeriodsView` lists the periods; selecting one opens `TimePickerView` (start/end editor with check/trash buttons) via `switchToView`. Each time field opens `WheelPickerView` (custom hour/minute wheels) via `pushView`. Deletion goes through the `DeletePeriodView` confirmation menu. Navigation between list ↔ editor ↔ confirm uses `switchToView`, so the view stack stays shallow; keep that pattern.

## Conventions

- Prefer native `WatchUi` components (`Menu2`, `MenuItem`, system pickers/delegates) over hand-drawn controls; use `Dc` drawing only for genuinely custom content (main view, glance). Verify API names and availability against the SDK for the target API level rather than guessing.
- All user-visible text goes in `resources/strings/strings.xml` **and** `resources-fre/strings/strings.xml` (keep the two in sync).
- Don't hardcode screen dimensions; derive layout from `dc.getWidth()/getHeight()`.
- Code comments and identifiers mix French and English; match the surrounding file.

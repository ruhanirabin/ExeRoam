# ExeRoam

ExeRoam is a small Windows launcher for applications stored in portable folders.

Instead of creating hundreds of Windows shortcuts, ExeRoam scans the folders you choose, keeps the application list in a readable `apps.tsv` file, and opens the launcher with one keyboard shortcut. If a drive letter changes, update the configured root folder once (in exeroam.ini) instead of fixing every application entry.

ExeRoam is written for AutoHotkey v2 and intended for x64 Windows.

![Screenshot of ExeRoam](ExeRoam.png?raw=true "ExeRoam Screenshot")

## Files to keep together

- `ExeRoam.exe` or `ExeRoam.ahk`
- `exeroam.ini`
- `apps.tsv`
- `VERSION`

`apps.tsv.example` is an empty example showing the TSV columns.

## Initial setup

Open `exeroam.ini` in a text editor before starting ExeRoam. Its three sections control the launcher.

### Application folders

Add the folders containing your portable applications under `[Roots]` inside `exeroam.ini`. 
For example:

```ini
[Roots]
Root1=D:\Programs
Root2=H:\Programs
```

You may define up to 20 roots using `Root1` through `Root20`. Blank roots are ignored. Each configured folder is scanned recursively for `.exe` files.

The root numbers also make saved paths portable. For example, an executable at `D:\Programs\Notepad++\notepad++.exe` is stored as `{ROOT1}\Notepad++\notepad++.exe`. If the folder later moves to another drive, change only `Root1` in `exeroam.ini`.

### Launcher hotkey

The default global hotkey is Win+Alt+Space:

```ini
[Launcher]
Hotkey=#!Space
CenterOnMouseMonitor=1
```

Set `CenterOnMouseMonitor` to `1` to center the launcher in the work area of
the monitor containing the mouse pointer. Set it to `0` to use the default
Windows/AutoHotkey centering behavior.

AutoHotkey uses these modifier symbols:

| Symbol | Key |
| --- | --- |
| `#` | Windows |
| `!` | Alt |
| `^` | Ctrl |
| `+` | Shift |

For example, `^!Space` means Ctrl+Alt+Space.

### Scanner exclusions

`ExcludedExecutables` is an AutoHotkey regular expression used to skip installers, uninstallers, updaters, helpers, and similar executables during a scan.

```ini
[Scanner]
ExcludedExecutables=i)^(unins.*|setup.*|updater.*)\.exe$
```

The supplied configuration contains a broader default list. Leave the value blank if you do not want filename exclusions:

```ini
ExcludedExecutables=
```

## First run

1. Configure the roots and hotkey in `exeroam.ini`.
2. Start `ExeRoam.exe`, or run `ExeRoam.ahk` with AutoHotkey v2.
3. If `apps.tsv` is missing or contains no application entries, ExeRoam scans the configured roots automatically.
4. Press Win+Alt+Space, or your configured hotkey, to open the launcher.
5. Type part of an application name, alias, path, or argument to filter the list.
6. Select an application and press Enter.

ExeRoam remains available from its notification-area tray icon when the launcher window is hidden.

## Keyboard controls

These keys work while the launcher window is active:

| Key | Action |
| --- | --- |
| Enter | Run the selected application |
| Ctrl+Enter | Run the selected application as administrator |
| Ctrl+F | Add or remove the selected application as a favourite |
| Ctrl+E | Open the selected application's folder |
| Ctrl+C | Copy the expanded executable path |
| F1 | Show the keyboard shortcuts window |
| F2 | Open `apps.tsv` in Notepad |
| F5 | Reload `apps.tsv` after manual edits |
| Down Arrow | Move focus from the search box to the application list |
| Escape | Hide the launcher |

The global hotkey configured in `exeroam.ini` opens or hides ExeRoam.

## Tray menu

Right-click the ExeRoam tray icon to:

- Open the launcher, application list, configuration, or ExeRoam folder.
- Reload `apps.tsv` after editing it.
- Validate whether enabled application paths still exist.
- Force a new scan of all configured roots. WARNING: This will destory your manual entries. So be careful. You should not use this unless you are sure you want to do this.
- Reload or exit ExeRoam.

**Force rescan applications** replaces the current list. It removes manual names, aliases, favourites, arguments, and usage history after asking for confirmation.

## Editing the application list

`apps.tsv` is a tab-separated text file with these columns:

```text
Enabled | Favourite | Name | Aliases | Executable | WorkingDirectory | Arguments | RunCount | LastUsed
```

- Set `Enabled` to `0` to hide an entry without deleting it.
- Set `Favourite` to `1` to keep an entry at the top of the list.
- Put comma-separated alternative search terms in `Aliases`.
- Add command-line parameters in `Arguments`.
- Do not insert literal tabs or line breaks inside a field.
- Press F5 in ExeRoam after saving manual changes.

Paths under configured roots use `{ROOT1}`, `{ROOT2}`, and similar placeholders. Paths inside the ExeRoam folder use `{SCRIPT}`. Other paths remain absolute.

With an empty search, favourites and recently used applications appear first. During a search, favourites appear first and results are then sorted by name.

## Resetting the list

To rebuild the list, remove all application rows from `apps.tsv` while optionally keeping its comment lines. Restart ExeRoam or press F5 to scan the configured roots again.

## Version and license

`VERSION` contains the semantic version shown in the window title and tray tooltip. Release history is recorded in `CHANGELOG.md`.

ExeRoam is created by [Ruhani Rabin](https://www.ruhanirabin.com) and released under the MIT License. See `LICENSE`.

## Building from source

Install AutoHotkey v2 with Ahk2Exe, then run `Compile-ExeRoam.ahk`. The x64 executable and required runtime files are written to `dist`.

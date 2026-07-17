#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; =============================================================================
; ExeRoam - AutoHotkey v2
; Author: Ruhani Rabin
; Website: https://www.ruhanirabin.com
; =============================================================================
;
; PURPOSE
; -------
; A fast, portable launcher for executables stored in configurable folders.
; It does not create Windows shortcuts and does not write anything to AppData.
;
; PORTABLE FILES
; --------------
; Keep these files together. exeroam.ini remains editable even if this script
; is compiled into an .exe:
;
;   ExeRoam.ahk
;   exeroam.ini
;   apps.tsv
;   VERSION
;
; The executable list is stored in apps.tsv. The script scans configured roots
; only when apps.tsv is missing or contains no valid application entries.
;
; PORTABLE PATHS
; --------------
; Scanned paths are stored with root placeholders:
;
;   {ROOT1}\Notepad++\notepad++.exe
;   {ROOT2}\Utilities\Tool.exe
;
; ROOT1, ROOT2, etc. are defined in exeroam.ini. After reinstalling Windows or
; changing drive letters, update exeroam.ini rather than editing every entry.
;
; TSV FORMAT
; ----------
; Enabled | Favourite | Name | Aliases | Executable | WorkingDirectory |
; Arguments | RunCount | LastUsed
;
; Tabs separate fields. Lines beginning with # are comments.
;
; IMPORTANT:
; - Do not put literal tab or newline characters inside a field.
; - Arguments may contain normal spaces and quotes.
; - LastUsed uses yyyyMMddHHmmss so timestamps sort correctly as text.
; - Set Enabled to 0 to keep an entry without showing it in the launcher.
;
; KEYBOARD CONTROLS
; -----------------
; Win+Alt+Space  Open or hide launcher
; Enter          Run selected application
; Ctrl+Enter     Run selected application as administrator
; Ctrl+F         Toggle favourite
; Ctrl+E         Open executable folder
; Ctrl+C         Copy expanded executable path
; F1             Show keyboard shortcuts
; F2             Open apps.tsv
; F5             Reload apps.tsv
; Escape         Hide launcher
;
; SORTING
; -------
; With an empty search:
;   1. Favourites, most recently used first
;   2. Other used applications, most recently used first
;   3. Never-used applications, alphabetically
;
; While searching:
;   1. Favourites first
;   2. Alphabetical by display name
;
; =============================================================================

; -----------------------------------------------------------------------------
; Portable file locations
; -----------------------------------------------------------------------------

global ScriptDirectory := A_ScriptDir
global AppsFile := ScriptDirectory "\apps.tsv"
global ConfigFile := ScriptDirectory "\exeroam.ini"
global VersionFile := ScriptDirectory "\VERSION"
global AppVersion := LoadAppVersion()
global AppTitle := AppVersion != "" ? "ExeRoam v" AppVersion : "ExeRoam"

; -----------------------------------------------------------------------------
; Runtime state
; -----------------------------------------------------------------------------

global Apps := []
global VisibleApps := []
global ProgramRoots := []
global AppsFileModified := ""
global LauncherHotkey := ""
global CenterOnMouseMonitor := false

; Scanner exclusions are loaded from exeroam.ini.
; Keeping them outside the script makes compiled builds easier to maintain.
global ExcludedExecutables := ""

; -----------------------------------------------------------------------------
; Initial setup
; -----------------------------------------------------------------------------

EnsurePortableFiles()
ProgramRoots := LoadProgramRoots()
LauncherHotkey := LoadLauncherHotkey()
CenterOnMouseMonitor := LoadCenterOnMouseMonitor()
ExcludedExecutables := LoadExcludedExecutables()

if AppsFileHasEntries()
    LoadApplications()
else
    ScanApplications()

RememberAppsFileModified()

; -----------------------------------------------------------------------------
; The GUI part
; -----------------------------------------------------------------------------

global LauncherGui := Gui(
    "+AlwaysOnTop -MaximizeBox -MinimizeBox",
    AppTitle
)
LauncherGui.SetFont("s10", "Segoe UI")

global SearchBox := LauncherGui.AddEdit(
    "x12 y12 w756 h30"
)

global AppList := LauncherGui.AddListView(
    "x12 y50 w756 h410 -Multi",
    ["Application", "Location", "Executable", "Used"]
)

global StatusText := LauncherGui.AddText(
    "x12 y468 w632 h22",
    ""
)

global ShortcutButton := LauncherGui.AddButton(
    "x656 y464 w112 h28",
    "? Shortcuts"
)

global ShortcutGui := Gui(
    "+Owner" LauncherGui.Hwnd " +AlwaysOnTop -MaximizeBox -MinimizeBox",
    "ExeRoam Shortcuts"
)
ShortcutGui.SetFont("s10", "Segoe UI")
ShortcutGui.AddText(
    "x18 y16 w130",
    "Enter`n"
    . "Ctrl+Enter`n"
    . "Ctrl+F`n"
    . "Ctrl+E`n"
    . "Ctrl+C`n"
    . "F2`n"
    . "F5`n"
    . "Escape"
)
ShortcutGui.AddText(
    "x148 y16 w220",
    "Open application`n"
    . "Open as administrator`n"
    . "Toggle favourite`n"
    . "Open application folder`n"
    . "Copy executable path`n"
    . "Edit application list`n"
    . "Reload application list`n"
    . "Close launcher"
)
global ShortcutCloseButton := ShortcutGui.AddButton(
    "x268 y172 w100 h28 Default",
    "Close"
)

global AboutGui := Gui(
    "+Owner" LauncherGui.Hwnd " +AlwaysOnTop -MaximizeBox -MinimizeBox",
    "About ExeRoam"
)
AboutGui.SetFont("s10", "Segoe UI")
AboutGui.SetFont("s16 Bold")
AboutGui.AddText("x18 y16 w400", AppTitle)
AboutGui.SetFont("s10 Norm")
AboutGui.AddText(
    "x18 y54 w400",
    "A fast, portable launcher for executables in configurable folders."
)
AboutGui.AddText("x18 y88 w72", "INI file:")
AboutGui.AddEdit(
    "x90 y84 w328 h24 ReadOnly",
    ConfigFile
)
AboutGui.AddText("x18 y122 w72", "Apps file:")
AboutGui.AddEdit(
    "x90 y118 w328 h24 ReadOnly",
    AppsFile
)
AboutGui.AddLink(
    "x18 y156 w400",
    '<a href="https://www.ruhanirabin.com/tools">ruhanirabin.com/tools</a>`n'
    . '<a href="https://github.com/ruhanirabin/ExeRoam">GitHub</a>'
)
AboutGui.AddText(
    "x18 y192 w400 h48",
    "Icon: Soni Sokell / Icon-Icons.com (CC v4)`n"
    . "Scripting library: AutoHotkey v2"
)
AboutGui.AddText(
    "x18 y248 w280",
    "Copyright (c) 2026 Ruhani Rabin`nLicensed under the MIT License."
)
global AboutCloseButton := AboutGui.AddButton(
    "x318 y252 w100 h28 Default",
    "Close"
)

LauncherGui.OnEvent("Close", HideLauncher)
LauncherGui.OnEvent("Escape", HideLauncher)
SearchBox.OnEvent("Change", FilterApplicationList)
AppList.OnEvent("DoubleClick", LaunchSelectedNormal)
ShortcutButton.OnEvent("Click", ShowShortcutHelp)
ShortcutGui.OnEvent("Close", HideShortcutHelp)
ShortcutGui.OnEvent("Escape", HideShortcutHelp)
ShortcutCloseButton.OnEvent("Click", HideShortcutHelp)
OnMessage(0x0006, ShortcutGuiActivationChanged)
AboutGui.OnEvent("Close", HideAbout)
AboutGui.OnEvent("Escape", HideAbout)
AboutCloseButton.OnEvent("Click", HideAbout)

; Hotkeys are active only while the launcher window is active.
HotIfWinActive("ahk_id " LauncherGui.Hwnd)
Hotkey("Enter", LaunchSelectedNormal)
Hotkey("^Enter", LaunchSelectedAsAdmin)
Hotkey("^f", ToggleSelectedFavourite)
Hotkey("^e", OpenSelectedFolder)
Hotkey("^c", CopySelectedPath)
Hotkey("F1", ShowShortcutHelp)
Hotkey("F2", OpenAppsFile)
Hotkey("F5", ReloadApplicationList)
Hotkey("Escape", HideLauncher)
Hotkey("Down", FocusApplicationList)
HotIfWinActive()

HotIfWinActive("ahk_id " ShortcutGui.Hwnd)
Hotkey("Enter", HideShortcutHelp)
Hotkey("Escape", HideShortcutHelp)
HotIfWinActive()

; Global launcher hotkey.
Hotkey(LauncherHotkey, ToggleLauncher)

; -----------------------------------------------------------------------------
; Tray menu part
; -----------------------------------------------------------------------------

A_TrayMenu.Delete()
A_TrayMenu.Add("Open launcher", ShowLauncher)
A_TrayMenu.Default := "Open launcher"

A_TrayMenu.Add()
A_TrayMenu.Add("Open application list", OpenAppsFile)
A_TrayMenu.Add("Open configuration", OpenConfigFile)
A_TrayMenu.Add("Open launcher folder", OpenLauncherFolder)

A_TrayMenu.Add()
A_TrayMenu.Add("Reload application list", ReloadApplicationList)
A_TrayMenu.Add("Validate application paths", ValidateApplicationPaths)
A_TrayMenu.Add("Force rescan applications", ForceRescanApplications)

A_TrayMenu.Add()
A_TrayMenu.Add("Add to Startup", AddToStartup)
A_TrayMenu.Add("About", ShowAbout)

A_TrayMenu.Add()
A_TrayMenu.Add("Reload script", (*) => Reload())
A_TrayMenu.Add("Exit", (*) => ExitApp())

A_IconTip := AppTitle

RenderApplicationList()
return

; =============================================================================
; GUI display part
; =============================================================================

ToggleLauncher(*) {
    global LauncherGui

    if WinExist("ahk_id " LauncherGui.Hwnd)
        HideLauncher()
    else
        ShowLauncher()
}

ShowLauncher(*) {
    global LauncherGui, SearchBox, CenterOnMouseMonitor

    ; Pick up manual TSV edits without reparsing the file on every keypress.
    ReloadIfAppsFileChanged()

    SearchBox.Value := ""
    RenderApplicationList()

    if CenterOnMouseMonitor
        ShowLauncherOnMouseMonitor()
    else
        LauncherGui.Show("w780 h502 Center")

    SearchBox.Focus()
}

ShowLauncherOnMouseMonitor() {
    global LauncherGui

    CoordMode("Mouse", "Screen")
    MouseGetPos(&MouseX, &MouseY)

    Loop MonitorGetCount() {
        MonitorGetWorkArea(A_Index, &Left, &Top, &Right, &Bottom)

        if MouseX >= Left && MouseX < Right
            && MouseY >= Top && MouseY < Bottom {
            WindowX := Left + ((Right - Left - 780) // 2)
            WindowY := Top + ((Bottom - Top - 502) // 2)
            LauncherGui.Show("w780 h502 x" WindowX " y" WindowY)
            return
        }
    }

    ; Fall back safely if Windows does not return a matching monitor.
    LauncherGui.Show("w780 h502 Center")
}

HideLauncher(*) {
    global LauncherGui
    HideShortcutHelp()
    LauncherGui.Hide()
}

ShowShortcutHelp(*) {
    global LauncherGui, ShortcutGui, ShortcutCloseButton

    ShortcutGui.Show("Hide AutoSize")
    LauncherGui.GetPos(&LauncherX, &LauncherY, &LauncherWidth, &LauncherHeight)
    ShortcutGui.GetPos(, , &ShortcutWidth, &ShortcutHeight)

    ShortcutX := LauncherX + ((LauncherWidth - ShortcutWidth) // 2)
    ShortcutY := LauncherY + ((LauncherHeight - ShortcutHeight) // 2)

    ShortcutGui.Show("x" ShortcutX " y" ShortcutY)
    ShortcutCloseButton.Focus()
}

HideShortcutHelp(*) {
    global ShortcutGui
    ShortcutGui.Hide()
}

ShowAbout(*) {
    global AboutGui, AboutCloseButton

    AboutGui.Show("AutoSize Center")
    AboutCloseButton.Focus()
}

HideAbout(*) {
    global AboutGui
    AboutGui.Hide()
}

ShortcutGuiActivationChanged(WParam, LParam, Message, Hwnd) {
    global ShortcutGui

    if Hwnd = ShortcutGui.Hwnd && (WParam & 0xFFFF) = 0
        ShortcutGui.Hide()
}

FocusApplicationList(*) {
    global AppList

    if AppList.GetCount() > 0 {
        AppList.Focus()
        AppList.Modify(1, "Select Focus Vis")
    }
}

; =============================================================================
; File init and configuration
; =============================================================================

EnsurePortableFiles() {
    global AppsFile, ConfigFile

    if !FileExist(ConfigFile) {
        DefaultConfig :=
        (
        "[Launcher]`n"
        "Hotkey=#!Space`n"
        "CenterOnMouseMonitor=1`n"
        "`n"
        "[Scanner]`n"
        "ExcludedExecutables=i)^(unins.*|uninstall.*|setup.*|install.*|update.*|updater.*|crash.*|crashreport.*|report.*|helper.*|service.*|notificationhelper.*|elevate.*)\\.exe$`n"
        "`n"
        "[Roots]`n"
        "Root1=D:\Programs`n"
        "Root2=H:\Programs`n"
        )

        FileAppend(DefaultConfig, ConfigFile, "UTF-8")
    }

    if !FileExist(AppsFile)
        FileAppend("", AppsFile, "UTF-8")
}

LoadAppVersion() {
    global VersionFile

    if !FileExist(VersionFile)
        return ""

    try Version := Trim(FileRead(VersionFile, "UTF-8"))
    catch Error as Err {
        MsgBox(
            "Unable to read VERSION.`n`n" Err.Message,
            "ExeRoam",
            "Iconx"
        )
        ExitApp()
    }

    if !RegExMatch(Version, "^\d+\.\d+\.\d+$") {
        MsgBox(
            "VERSION must contain a semantic version such as 0.1.0.",
            "ExeRoam",
            "Iconx"
        )
        ExitApp()
    }

    return Version
}

LoadProgramRoots() {
    global ConfigFile

    Roots := []

    ; Twenty roots is deliberately generous while keeping the format simple.
    Loop 20 {
        Key := "Root" A_Index
        RootPath := Trim(IniRead(ConfigFile, "Roots", Key, ""))

        if RootPath = ""
            continue

        Roots.Push({
            Token: "{ROOT" A_Index "}",
            Path: RTrim(RootPath, "\")
        })
    }

    if Roots.Length = 0 {
        MsgBox(
            "No program roots are configured in exeroam.ini.",
            "ExeRoam",
            "Iconx"
        )
    }

    return Roots
}

LoadLauncherHotkey() {
    global ConfigFile

    ConfiguredHotkey := Trim(
        IniRead(ConfigFile, "Launcher", "Hotkey", "#!Space")
    )

    ; Fall back to Win+Alt+Space if the setting is blank.
    return ConfiguredHotkey != "" ? ConfiguredHotkey : "#!Space"
}

LoadCenterOnMouseMonitor() {
    global ConfigFile

    ConfiguredValue := Trim(
        IniRead(ConfigFile, "Launcher", "CenterOnMouseMonitor", "0")
    )

    return ConfiguredValue = "1"
}

LoadExcludedExecutables() {
    global ConfigFile

    DefaultPattern :=
        "i)^(unins.*|uninstall.*|setup.*|install.*|update.*|updater.*|"
        . "crash.*|crashreport.*|report.*|helper.*|service.*|"
        . "notificationhelper.*|elevate.*)\.exe$"

    ConfiguredPattern := Trim(
        IniRead(
            ConfigFile,
            "Scanner",
            "ExcludedExecutables",
            DefaultPattern
        )
    )

    ; A blank value deliberately disables executable-name exclusions.
    return ConfiguredPattern
}

; A file containing only blank lines or comments is treated as empty.
; This lets you reset apps.tsv while retaining explanatory comments.
AppsFileHasEntries() {
    global AppsFile

    if !FileExist(AppsFile)
        return false

    try Content := FileRead(AppsFile, "UTF-8")
    catch
        return false

    Loop Parse Content, "`n", "`r" {
        Line := Trim(A_LoopField)

        if Line = "" || SubStr(Line, 1, 1) = "#"
            continue

        return true
    }

    return false
}

; =============================================================================
; Scanning
; =============================================================================

ScanApplications() {
    global Apps, ProgramRoots, ExcludedExecutables

    Apps := []
    SeenPaths := Map()

    for Root in ProgramRoots {
        if !DirExist(Root.Path)
            continue

        Loop Files Root.Path "\*.exe", "FR" {
            if ExcludedExecutables != ""
                && RegExMatch(A_LoopFileName, ExcludedExecutables)
                continue

            NormalizedPath := StrLower(A_LoopFileFullPath)

            if SeenPaths.Has(NormalizedPath)
                continue

            SeenPaths[NormalizedPath] := true

            Apps.Push({
                Enabled: true,
                Favourite: false,
                Name: FormatApplicationName(A_LoopFileName),
                Aliases: "",
                Path: MakePortablePath(A_LoopFileFullPath),
                Folder: MakePortablePath(A_LoopFileDir),
                Arguments: "",
                RunCount: 0,
                LastUsed: ""
            })
        }
    }

    SortAppsAlphabetically(Apps)
    SaveApplications()
}

ForceRescanApplications(*) {
    global AppsFile

    Choice := MsgBox(
        "This will replace every application entry in apps.tsv with a new scan.`n`n"
        . "Manual names, aliases, favourites, arguments and usage history will be lost.`n`n"
        . "Continue?",
        "ExeRoam",
        "YesNo Icon!"
    )

    if Choice != "Yes"
        return

    try {
        if FileExist(AppsFile)
            FileDelete(AppsFile)

        FileAppend("", AppsFile, "UTF-8")
        ScanApplications()
        RememberAppsFileModified()
        RenderApplicationList()

        TrayTip("ExeRoam", "Application list rebuilt.", 2)
    } catch Error as Err {
        ShowError("Unable to rebuild the application list.", Err)
    }
}

; =============================================================================
; TSV loading and saving
; =============================================================================

LoadApplications() {
    global Apps, AppsFile

    LoadedApps := []

    try Content := FileRead(AppsFile, "UTF-8")
    catch Error as Err {
        ShowError("Unable to read apps.tsv.", Err)
        return
    }

    Loop Parse Content, "`n", "`r" {
        RawLine := A_LoopField
        Line := Trim(RawLine)

        if Line = "" || SubStr(Line, 1, 1) = "#"
            continue

        Parts := StrSplit(RawLine, "`t")

        ; Require at least the first six fields:
        ; Enabled, Favourite, Name, Aliases, Executable, WorkingDirectory.
        if Parts.Length < 6
            continue

        EnabledValue := Trim(Parts[1])
        FavouriteValue := Trim(Parts[2])
        AppName := Trim(Parts[3])
        Aliases := Trim(Parts[4])
        ExecutablePath := Trim(Parts[5])
        WorkingDirectory := Trim(Parts[6])
        Arguments := Parts.Length >= 7 ? Trim(Parts[7]) : ""
        RunCountValue := Parts.Length >= 8 ? Trim(Parts[8]) : "0"
        LastUsed := Parts.Length >= 9 ? Trim(Parts[9]) : ""

        if AppName = "" || ExecutablePath = ""
            continue

        RunCount := IsIntegerText(RunCountValue) ? Integer(RunCountValue) : 0

        if WorkingDirectory = "" {
            ExpandedPath := ExpandPortablePath(ExecutablePath)
            SplitPath(ExpandedPath, , &DetectedFolder)
            WorkingDirectory := MakePortablePath(DetectedFolder)
        }

        LoadedApps.Push({
            Enabled: EnabledValue != "0",
            Favourite: FavouriteValue = "1",
            Name: AppName,
            Aliases: Aliases,
            Path: ExecutablePath,
            Folder: WorkingDirectory,
            Arguments: Arguments,
            RunCount: RunCount,
            LastUsed: LastUsed
        })
    }

    Apps := LoadedApps
}

SaveApplications() {
    global Apps, AppsFile

    Header :=
    (
    "# ExeRoam application list`n"
    "#`n"
    "# TAB-SEPARATED COLUMNS:`n"
    "# Enabled | Favourite | Name | Aliases | Executable | WorkingDirectory | Arguments | RunCount | LastUsed`n"
    "#`n"
    "# Enabled/Favourite: 1 = yes, 0 = no`n"
    "# Aliases: comma-separated search terms; aliases are not displayed`n"
    "# LastUsed: yyyyMMddHHmmss; leave empty for never used`n"
    "# Portable paths use {ROOT1}, {ROOT2}, etc. from exeroam.ini`n"
    "# Lines beginning with # are ignored.`n"
    "# Do not insert literal tabs inside fields.`n"
    "#`n"
    )

    Content := Header

    for App in Apps {
        Content .= (App.Enabled ? "1" : "0") "`t"
            . (App.Favourite ? "1" : "0") "`t"
            . SanitizeField(App.Name) "`t"
            . SanitizeField(App.Aliases) "`t"
            . SanitizeField(App.Path) "`t"
            . SanitizeField(App.Folder) "`t"
            . SanitizeField(App.Arguments) "`t"
            . App.RunCount "`t"
            . SanitizeField(App.LastUsed) "`n"
    }

    ; Write to a temporary file first. Replacing the real file only after the
    ; write succeeds reduces the chance of losing the curated list.
    TempFile := AppsFile ".tmp"

    try {
        if FileExist(TempFile)
            FileDelete(TempFile)

        FileAppend(Content, TempFile, "UTF-8")

        if FileExist(AppsFile)
            FileDelete(AppsFile)

        FileMove(TempFile, AppsFile)
        RememberAppsFileModified()
    } catch Error as Err {
        try {
            if FileExist(TempFile)
                FileDelete(TempFile)
        }

        ShowError("Unable to save apps.tsv.", Err)
    }
}

ReloadApplicationList(*) {
    global AppsFile

    if AppsFileHasEntries()
        LoadApplications()
    else
        ScanApplications()

    RememberAppsFileModified()
    RenderApplicationList()
    TrayTip("ExeRoam", "Application list reloaded.", 2)
}

ReloadIfAppsFileChanged() {
    global AppsFile, AppsFileModified

    if !FileExist(AppsFile)
        return

    CurrentModified := FileGetTime(AppsFile, "M")

    if CurrentModified != AppsFileModified {
        if AppsFileHasEntries()
            LoadApplications()
        else
            ScanApplications()

        RememberAppsFileModified()
    }
}

RememberAppsFileModified() {
    global AppsFile, AppsFileModified
    AppsFileModified := FileExist(AppsFile) ? FileGetTime(AppsFile, "M") : ""
}

; =============================================================================
; Filtering, sorting and rendering
; =============================================================================

FilterApplicationList(*) {
    RenderApplicationList()
}

RenderApplicationList() {
    global Apps, VisibleApps, SearchBox, AppList

    SearchTerm := StrLower(Trim(SearchBox.Value))
    Matches := []

    for App in Apps {
        if !App.Enabled
            continue

        SearchableText := StrLower(
            App.Name " "
            . App.Aliases " "
            . App.Path " "
            . App.Arguments
        )

        if SearchTerm != "" && !InStr(SearchableText, SearchTerm)
            continue

        Matches.Push(App)
    }

    if SearchTerm = ""
        SortAppsForDefaultView(Matches)
    else
        SortAppsForSearch(Matches)

    VisibleApps := Matches
    AppList.Delete()

    for App in VisibleApps {
        ExpandedPath := ExpandPortablePath(App.Path)
        Exists := FileExist(ExpandedPath) != ""

        Prefix := ""

        if App.Favourite
            Prefix .= "[FAV] "

        if !Exists
            Prefix .= "[MISSING] "

        SplitPath(ExpandedPath, &ExecutableName)
        Location := GetDisplayLocation(ExpandedPath)
        UsedText := App.LastUsed = "" ? "Never" : FormatUsageTimestamp(App.LastUsed)

        AppList.Add(
            "",
            Prefix App.Name,
            Location,
            ExecutableName,
            UsedText
        )
    }

    AppList.ModifyCol(1, 280)
    AppList.ModifyCol(2, 230)
    AppList.ModifyCol(3, 125)
    AppList.ModifyCol(4, 85)

    if AppList.GetCount() > 0
        AppList.Modify(1, "Select Focus")

    UpdateStatus()
}

UpdateStatus() {
    global Apps, VisibleApps, StatusText

    EnabledCount := 0
    FavouriteCount := 0
    MissingCount := 0

    for App in Apps {
        if !App.Enabled
            continue

        EnabledCount++

        if App.Favourite
            FavouriteCount++

        if !FileExist(ExpandPortablePath(App.Path))
            MissingCount++
    }

    StatusText.Text :=
        VisibleApps.Length " shown - "
        . EnabledCount " enabled - "
        . FavouriteCount " favourites - "
        . MissingCount " missing"
}

; Small collections do not justify a dependency or complicated sort framework.
; Insertion sort is straightforward and performs well for typical launcher lists.
SortAppsForDefaultView(AppArray) {
    InsertionSortApps(AppArray, CompareDefaultApps)
}

SortAppsForSearch(AppArray) {
    InsertionSortApps(AppArray, CompareSearchApps)
}

SortAppsAlphabetically(AppArray) {
    InsertionSortApps(AppArray, CompareAlphabeticalApps)
}

InsertionSortApps(AppArray, CompareFunction) {
    if AppArray.Length < 2
        return

    Loop AppArray.Length - 1 {
        Index := A_Index + 1
        Current := AppArray[Index]
        Position := Index - 1

        while Position >= 1 && CompareFunction.Call(Current, AppArray[Position]) < 0 {
            AppArray[Position + 1] := AppArray[Position]
            Position--
        }

        AppArray[Position + 1] := Current
    }
}

CompareDefaultApps(AppA, AppB) {
    ; Favourites always precede non-favourites.
    if AppA.Favourite != AppB.Favourite
        return AppA.Favourite ? -1 : 1

    AUsed := AppA.LastUsed != ""
    BUsed := AppB.LastUsed != ""

    ; Used applications precede never-used applications.
    if AUsed != BUsed
        return AUsed ? -1 : 1

    ; Newest timestamp first. yyyyMMddHHmmss supports lexical comparison.
    if AUsed && AppA.LastUsed != AppB.LastUsed {
        TimestampA := Integer(AppA.LastUsed)
        TimestampB := Integer(AppB.LastUsed)
        return TimestampA > TimestampB ? -1 : 1
    }

    return CompareNames(AppA.Name, AppB.Name)
}

CompareSearchApps(AppA, AppB) {
    if AppA.Favourite != AppB.Favourite
        return AppA.Favourite ? -1 : 1

    return CompareNames(AppA.Name, AppB.Name)
}

CompareAlphabeticalApps(AppA, AppB) {
    return CompareNames(AppA.Name, AppB.Name)
}

CompareNames(NameA, NameB) {
    return StrCompare(NameA, NameB, false)
}

; =============================================================================
; Selection actions
; =============================================================================

GetSelectedApp() {
    global AppList, VisibleApps

    SelectedRow := AppList.GetNext()

    if SelectedRow = 0 {
        if AppList.GetCount() = 1
            SelectedRow := 1
        else
            return false
    }

    if SelectedRow > VisibleApps.Length
        return false

    return VisibleApps[SelectedRow]
}

LaunchSelectedNormal(*) {
    LaunchSelectedApplication(false)
}

LaunchSelectedAsAdmin(*) {
    LaunchSelectedApplication(true)
}

LaunchSelectedApplication(RunAsAdmin := false) {
    App := GetSelectedApp()

    if !App
        return

    ExecutablePath := ExpandPortablePath(App.Path)
    WorkingDirectory := ExpandPortablePath(App.Folder)

    if !FileExist(ExecutablePath) {
        MsgBox(
            "The executable does not exist:`n`n"
            . ExecutablePath
            . "`n`nUpdate exeroam.ini or apps.tsv.",
            "ExeRoam",
            "Iconx"
        )
        return
    }

    if !DirExist(WorkingDirectory)
        SplitPath(ExecutablePath, , &WorkingDirectory)

    Target := '"' ExecutablePath '"'

    if App.Arguments != ""
        Target .= " " App.Arguments

    if RunAsAdmin
        Target := "*RunAs " Target

    try {
        Run(Target, WorkingDirectory)

        App.RunCount += 1
        App.LastUsed := FormatTime(, "yyyyMMddHHmmss")
        SaveApplications()
        HideLauncher()
    } catch Error as Err {
        ShowError("Unable to start:`n`n" ExecutablePath, Err)
    }
}

ToggleSelectedFavourite(*) {
    App := GetSelectedApp()

    if !App
        return

    App.Favourite := !App.Favourite
    SaveApplications()
    RenderApplicationList()

    Message := App.Favourite
        ? App.Name " added to favourites."
        : App.Name " removed from favourites."

    TrayTip("ExeRoam", Message, 2)
}

OpenSelectedFolder(*) {
    App := GetSelectedApp()

    if !App
        return

    ExecutablePath := ExpandPortablePath(App.Path)
    WorkingDirectory := ExpandPortablePath(App.Folder)

    if DirExist(WorkingDirectory) {
        Run('explorer.exe "' WorkingDirectory '"')
        return
    }

    SplitPath(ExecutablePath, , &DetectedFolder)

    if DirExist(DetectedFolder) {
        Run('explorer.exe "' DetectedFolder '"')
        return
    }

    MsgBox(
        "The application folder does not exist:`n`n" WorkingDirectory,
        "ExeRoam",
        "Iconx"
    )
}

CopySelectedPath(*) {
    App := GetSelectedApp()

    if !App
        return

    A_Clipboard := ExpandPortablePath(App.Path)
    TrayTip("ExeRoam", "Executable path copied.", 1)
}

; =============================================================================
; Validation
; =============================================================================

ValidateApplicationPaths(*) {
    global Apps

    ValidCount := 0
    MissingCount := 0
    DisabledCount := 0
    MissingNames := ""

    for App in Apps {
        if !App.Enabled {
            DisabledCount++
            continue
        }

        ExpandedPath := ExpandPortablePath(App.Path)

        if FileExist(ExpandedPath) {
            ValidCount++
        } else {
            MissingCount++

            if MissingCount <= 15
                MissingNames .= "`n- " App.Name
        }
    }

    if MissingCount > 15
        MissingNames .= "`n- ...and " (MissingCount - 15) " more"

    Message :=
        ValidCount " valid`n"
        . MissingCount " missing`n"
        . DisabledCount " disabled"

    if MissingCount > 0
        Message .= "`n`nMissing applications:" MissingNames

    MsgBox(Message, "Application Path Validation", MissingCount ? "Icon!" : "Iconi")
    RenderApplicationList()
}

; =============================================================================
; Portable path helpers
; =============================================================================

MakePortablePath(Path) {
    global ProgramRoots, ScriptDirectory

    CleanPath := RTrim(Path, "\")

    ; Prefer {SCRIPT} for anything stored inside the launcher directory.
    if IsPathInside(CleanPath, ScriptDirectory) {
        RelativePath := SubStr(CleanPath, StrLen(RTrim(ScriptDirectory, "\")) + 1)
        return "{SCRIPT}" RelativePath
    }

    for Root in ProgramRoots {
        if IsPathInside(CleanPath, Root.Path) {
            RelativePath := SubStr(CleanPath, StrLen(Root.Path) + 1)
            return Root.Token RelativePath
        }
    }

    ; Paths outside configured roots remain absolute.
    return CleanPath
}

ExpandPortablePath(Path) {
    global ProgramRoots, ScriptDirectory

    Expanded := Trim(Path)
    Expanded := StrReplace(Expanded, "{SCRIPT}", RTrim(ScriptDirectory, "\"))

    for Root in ProgramRoots
        Expanded := StrReplace(Expanded, Root.Token, Root.Path)

    return Expanded
}

IsPathInside(Path, RootPath) {
    CleanPath := StrLower(RTrim(Path, "\"))
    CleanRoot := StrLower(RTrim(RootPath, "\"))

    return CleanPath = CleanRoot || InStr(CleanPath, CleanRoot "\") = 1
}

GetDisplayLocation(ExecutablePath) {
    global ProgramRoots

    SplitPath(ExecutablePath, , &ExecutableDirectory)

    for Root in ProgramRoots {
        if IsPathInside(ExecutableDirectory, Root.Path) {
            RelativeFolder := SubStr(
                ExecutableDirectory,
                StrLen(Root.Path) + 1
            )

            RelativeFolder := LTrim(RelativeFolder, "\")

            return RelativeFolder != ""
                ? Root.Token "\" RelativeFolder
                : Root.Token
        }
    }

    return ExecutableDirectory
}

; =============================================================================
; Utility functions
; =============================================================================

FormatApplicationName(FileName) {
    Name := RegExReplace(FileName, "i)\.exe$", "")
    Name := StrReplace(Name, "_", " ")
    Name := StrReplace(Name, "-", " ")
    Name := RegExReplace(Name, "\s+", " ")

    return Trim(Name)
}

FormatUsageTimestamp(Timestamp) {
    if StrLen(Timestamp) != 14
        return Timestamp

    ; Compact display: YYYY-MM-DD. Full precision remains in apps.tsv.
    return SubStr(Timestamp, 1, 4)
        . "-"
        . SubStr(Timestamp, 5, 2)
        . "-"
        . SubStr(Timestamp, 7, 2)
}

SanitizeField(Value) {
    Value := StrReplace(Value, "`t", " ")
    Value := StrReplace(Value, "`r", " ")
    Value := StrReplace(Value, "`n", " ")

    return Trim(Value)
}

IsIntegerText(Value) {
    return RegExMatch(Value, "^\d+$")
}

ShowError(Context, Err) {
    MsgBox(
        Context
        . "`n`n"
        . Err.Message,
        "ExeRoam",
        "Iconx"
    )
}

OpenAppsFile(*) {
    global AppsFile

    if !FileExist(AppsFile)
        FileAppend("", AppsFile, "UTF-8")

    Run('notepad.exe "' AppsFile '"')
}

OpenConfigFile(*) {
    global ConfigFile
    Run('notepad.exe "' ConfigFile '"')
}

OpenLauncherFolder(*) {
    global ScriptDirectory
    Run('explorer.exe "' ScriptDirectory '"')
}

AddToStartup(*) {
    global ScriptDirectory

    ShortcutFile := A_Startup "\ExeRoam.lnk"

    if A_IsCompiled {
        Target := A_ScriptFullPath
        Arguments := ""
    } else {
        Target := A_AhkPath
        Arguments := '"' A_ScriptFullPath '"'
    }

    try {
        if FileExist(ShortcutFile)
            FileDelete(ShortcutFile)

        FileCreateShortcut(
            Target,
            ShortcutFile,
            ScriptDirectory,
            Arguments,
            "Start ExeRoam when signing in to Windows",
            A_ScriptFullPath
        )

        TrayTip("ExeRoam", "Added to Windows Startup.", 2)
    } catch Error as Err {
        ShowError("Unable to add ExeRoam to Windows Startup.", Err)
    }
}

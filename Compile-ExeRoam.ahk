#Requires AutoHotkey v2.0

Compiler := "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
BaseFile := "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
SourceFile := A_ScriptDir "\ExeRoam.ahk"
IconFile := A_ScriptDir "\boost_icon.ico"
OutputDirectory := A_ScriptDir "\dist"
OutputFile := OutputDirectory "\ExeRoam.exe"

DirCreate(OutputDirectory)

RunWait(
    '"' Compiler '"'
    . ' /in "' SourceFile '"'
    . ' /out "' OutputFile '"'
    . ' /icon "' IconFile '"'
    . ' /base "' BaseFile '"'
    . ' /compress 1'
)

FileCopy(A_ScriptDir "\VERSION", OutputDirectory "\VERSION", true)
FileCopy(A_ScriptDir "\exeroam.ini", OutputDirectory "\exeroam.ini", true)

DistAppsFile := OutputDirectory "\apps.tsv"

if !FileExist(DistAppsFile)
    FileCopy(A_ScriptDir "\apps.tsv.example", DistAppsFile)

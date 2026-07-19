#Requires AutoHotkey v2.0

Compiler := "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
BaseFile := "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
SourceFile := A_ScriptDir "\ExeRoam.ahk"
CompileSourceFile := A_ScriptDir "\.ExeRoam.compile.ahk"
IconFile := A_ScriptDir "\boost_icon.ico"
OutputDirectory := A_ScriptDir "\dist"
OutputFile := OutputDirectory "\ExeRoam.exe"
Version := Trim(FileRead(A_ScriptDir "\VERSION", "UTF-8"))

if !RegExMatch(Version, "^\d+\.\d+\.\d+$")
    throw Error("VERSION must contain a semantic version such as 0.1.0.")

DirCreate(OutputDirectory)

CompilerDirectives :=
    ";@Ahk2Exe-SetProductName ExeRoam`n"
    . ";@Ahk2Exe-SetDescription A fast``, portable launcher for executables stored in configurable folders`n"
    . ";@Ahk2Exe-SetCopyright Copyright (c) 2026 Ruhani Rabin. MIT License.`n"
    . ";@Ahk2Exe-SetCompanyName RuhaniRabin.com`n"
    . ";@Ahk2Exe-SetVersion " Version "`n"
    . ";@Ahk2Exe-SetOrigFilename ExeRoam.exe`n`n"

if FileExist(CompileSourceFile)
    FileDelete(CompileSourceFile)

try {
    FileAppend(CompilerDirectives . FileRead(SourceFile, "UTF-8"), CompileSourceFile, "UTF-8")

    ExitCode := RunWait(
        '"' Compiler '"'
        . ' /in "' CompileSourceFile '"'
        . ' /out "' OutputFile '"'
        . ' /icon "' IconFile '"'
        . ' /base "' BaseFile '"'
        . ' /compress 1'
    )

    if ExitCode != 0
        throw Error("Ahk2Exe failed with exit code " ExitCode ".")
} finally {
    if FileExist(CompileSourceFile)
        FileDelete(CompileSourceFile)
}

FileCopy(A_ScriptDir "\exeroam.ini", OutputDirectory "\exeroam.ini", true)
FileCopy(A_ScriptDir "\README.md", OutputDirectory "\README.md", true)
FileCopy(A_ScriptDir "\CHANGELOG.md", OutputDirectory "\CHANGELOG.md", true)
FileCopy(A_ScriptDir "\CREDITS.md", OutputDirectory "\CREDITS.md", true)
FileCopy(A_ScriptDir "\LICENSE", OutputDirectory "\LICENSE.txt", true)

DistAppsFile := OutputDirectory "\apps.tsv"

if !FileExist(DistAppsFile)
    FileCopy(A_ScriptDir "\apps.tsv.example", DistAppsFile)

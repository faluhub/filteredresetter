#NoEnv
#SingleInstance, Force
#Persistent
SetWorkingDir, %A_ScriptDir%
SetKeyDelay, 0

global finder_file = A_ScriptDir . "\finder.exe"
global seed_file = A_ScriptDir . "\seed.txt"

global seed
global instance_pid

WinGet, windows, List
Loop, %windows% {
    WinGet, pid, PID, % "ahk_id " windows%A_Index%
    WinGetTitle, title, ahk_pid %pid%
    if (InStr(title, "Minecraft")) {
        instance_pid := pid
        Break
    }
}

DownloadSeedFinder()
{
    downloadCommand := "curl.exe https://download1073.mediafire.com/s368lb7jbvxg/vge1pgr2dv3bvvo/filter.exe --output " . finder_file
    RunWait, %downloadCommand%,, Hide
}

if (!FileExist(finder_file)) {
    DownloadSeedFinder()
}

RunHide(Command) ; by spec
{
  dhw := A_DetectHiddenWindows
  DetectHiddenWindows, On
  Run, %ComSpec%,, Hide, cPid
  WinWait, ahk_pid %cPid%
  DetectHiddenWindows, %dhw%
  DllCall("AttachConsole", "uint", cPid)

  Shell := ComObjCreate("WScript.Shell")
  Exec := Shell.Exec(Command)
  Result := Exec.StdOut.ReadAll()

  DllCall("FreeConsole")
  Process, Close, %cPid%
  return Result
}

GetMcDir() ; by spec
{
    command := Format("powershell.exe $x = Get-WmiObject Win32_Process -Filter \""ProcessId = {1}\""; $x.CommandLine", instance_pid)
    rawOut := RunHide(command)
    if (InStr(rawOut, "--gameDir")) {
        strStart := RegExMatch(rawOut, "P)--gameDir (?:""(.+?)""|([^\s]+))", strLen, 1)
        return SubStr(rawOut, strStart + 10, strLen - 10) . "\"
    } else {
        strStart := RegExMatch(rawOut, "P)(?:-Djava\.library\.path=(.+?) )|(?:\""-Djava\.library.path=(.+?)\"")", strLen, 1)
        if (SubStr(rawOut, strStart + 20, 1) == "=") {
            strLen -= 1
            strStart += 1
        }
        return StrReplace(SubStr(rawOut, strStart + 20, strLen - 28) . ".minecraft\", "/", "\")
    }
}

GetLineCount(file) ; by spec
{
    lineNum := 0
    Loop, Read, %file%
        lineNum := A_Index
    return lineNum
}

GetSeed()
{
    if (!FileExist(finder_file)) {
        DownloadSeedFinder()
    }

    RunWait, %finder_file%,, Hide
    FileRead, seed, %seed_file%
}

Reset()
{
    WinGetTitle, title, ahk_pid %instance_pid%
    if (InStr(title, "Multiplayer") && !InStr(title, "(LAN)")) {
        return
    }

    if (!FileExist(seed_file)) {
        GetSeed()
    }

    logFile := GetMcDir() . "logs\latest.log"
    lineCount := GetLineCount(logFile)

    if (InStr(title, "Singleplayer") || InStr(title, "(LAN)")) {
        ControlSend,, {Blind}{Tab 6}{Enter}{Tab 13}{Enter}{Esc}{Tab 6}{Enter}{Tab 13}{Enter}, ahk_pid %instance_pid%
        
        Loop,
        {
            Sleep, 40
            lineCount := GetLineCount(logFile)
            Loop, Read, %logFile%
            {
                if (A_Index >= lineCount - 5 && InStr(A_LoopReadLine, "Stopping worker threads")) {
                    Break 2
                }
            }
        }
    }

    Clipboard := seed
    WinActivate, %instance_pid%
    Send, {Blind}{Tab 8}{LShift down}{Enter}{LShift up}{LControl down}av{LControl up}{Tab 5}{Enter}{Tab 8}{Enter}

    GetSeed()
}

DeleteFiles()
{
    if (FileExist(seed_file)) {
        FileDelete, %seed_file%
    }
}

OnExit("DeleteFiles")

#If WinActive("Minecraft* 1.16.1")
{
    *H::Reset()
}

return
#Requires AutoHotkey v2.0
#SingleInstance Force
; claude-ctrl-enter.ahk
; Claude desktop app for Windows:
;   Enter       : newline (sends Shift+Enter)
;                 while the Japanese IME is composing, plain Enter (confirms the conversion)
;   Ctrl+Enter  : send the message
;
; Unofficial. Not affiliated with or endorsed by Anthropic.
; License: MIT (see LICENSE)
;
; How composition is detected
;   Electron apps do not let other processes read the IME composition string, so this
;   script estimates it: it counts character keys typed while the IME is ON since the
;   last Enter / Esc / click.  count > 0 and IME ON  =>  "composing".
;   - Backspace/Delete before conversion subtract 3 (one kana takes at most 3 keys),
;     so the count reaches 0 no later than the composition becomes empty.
;   - After Space-conversion, Backspace/Delete reset the count to 0 (safe side:
;     the worst case is a newline instead of a confirm, never an accidental send).
;   - Space is not counted (with no composition it types a full-width space directly).
;
; Privacy / safety
;   - No network access. Typed text is never stored or sent anywhere.
;   - Optional diagnostic log (off by default) records only key names, counters and
;     the IME ON/OFF state, never the text you type.

; ---------------- settings ----------------
global TARGET_EXE := "Claude.exe"   ; process name of the Claude desktop app
global LOGGING    := false          ; true = write claude-ctrl-enter.log next to this script
; ------------------------------------------

global LogPath := A_ScriptDir "\claude-ctrl-enter.log"
global count := 0
global converted := false

; Stop any other running copy of this script (e.g. a second downloaded copy),
; so that two instances never handle Enter at the same time.
DetectHiddenWindows True
for hwnd in WinGetList("ahk_class AutoHotkey") {
    if (hwnd != A_ScriptHwnd && InStr(WinGetTitle(hwnd), "claude-ctrl-enter")) {
        LogLine("closed other copy")
        PostMessage 0x111, 65307, , , hwnd   ; File > Exit
    }
}
DetectHiddenWindows False

LogLine("=== started  AHK " A_AhkVersion)

; ---- count character keys (only while the target app is active) ----
HotIf((*) => WinActive("ahk_exe " TARGET_EXE))
for vk in CharVKs()
    Hotkey("~*vk" Format("{:02X}", vk), CountKey)
HotIf()

#HotIf WinActive("ahk_exe " TARGET_EXE)

$Enter:: {
    global count, converted
    ime := IME_GET()
    if (count > 0 && ime = 1) {
        LogLine("Enter      count=" count " conv=" converted " ime=" ime " -> CONFIRM")
        Send "{Enter}"
    } else {
        LogLine("Enter      count=" count " conv=" converted " ime=" ime " -> NEWLINE")
        Send "+{Enter}"
    }
    count := 0
    converted := false
}

$^Enter:: {
    global count, converted
    LogLine("Ctrl+Enter count=" count " -> SEND")
    Send "{Enter}"
    count := 0
    converted := false
}

~*Space:: {
    global count, converted
    if (count > 0)
        converted := true
}

~Backspace::Shrink("Backspace")
~Delete::Shrink("Delete")

; reset the counter when the composition state becomes uncertain
~Esc::ResetCount("Esc")
~LButton::ResetCount("Click")
~sc029::ResetCount("Hankaku/Zenkaku")
~vkF3::ResetCount("vkF3")
~vkF4::ResetCount("vkF4")
~vk1C::ResetCount("Henkan")
; Muhenkan (vk1D) is intentionally not handled: during composition it converts to
; katakana (the composition stays), and some users remap it to other keys.

#HotIf

Shrink(name) {
    global count, converted
    if (count = 0)
        return
    before := count
    if converted
        count := 0
    else
        count := Max(0, count - 3)
    if (count = 0)
        converted := false
    LogLine(name " count " before " -> " count)
}

ResetCount(name) {
    global count, converted
    if (count > 0)
        LogLine("reset by " name " (count was " count ")")
    count := 0
    converted := false
}

CountKey(*) {
    global count
    if GetKeyState("Ctrl", "P") || GetKeyState("Alt", "P")
        return
    if (IME_GET() = 1)
        count++
}

CharVKs() {
    list := []
    Loop 10
        list.Push(0x30 + A_Index - 1)   ; 0-9
    Loop 26
        list.Push(0x41 + A_Index - 1)   ; A-Z
    ; vkC0 (@ on JIS keyboards) is NOT counted: with some key remappers every Enter
    ; press also produces a vkC0 event, which would make a quick second Enter send.
    Loop 6
        list.Push(0xBA + A_Index - 1)   ; OEM keys : ; , - . /
    Loop 5
        list.Push(0xDB + A_Index - 1)   ; OEM keys [ \ ] ^ etc.
    list.Push(0xE2)                     ; backslash / underscore on JIS
    return list
}

; IME open status: 1 = IME ON (Japanese input), 0 = OFF
IME_GET() {
    hwnd := 0
    info := Buffer(A_PtrSize = 8 ? 72 : 48, 0)
    NumPut("UInt", info.Size, info, 0)
    if DllCall("GetGUIThreadInfo", "UInt", 0, "Ptr", info)
        hwnd := NumGet(info, A_PtrSize = 8 ? 16 : 12, "Ptr")   ; hwndFocus
    if !hwnd
        hwnd := WinExist("A")
    imeWnd := DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hwnd, "Ptr")
    if !imeWnd
        return 0
    result := 0
    ; WM_IME_CONTROL (0x283), IMC_GETOPENSTATUS (5)
    DllCall("SendMessageTimeoutW", "Ptr", imeWnd, "UInt", 0x283, "Ptr", 5, "Ptr", 0
        , "UInt", 0, "UInt", 200, "Ptr*", &result)
    return result
}

LogLine(msg) {
    global LOGGING, LogPath
    if !LOGGING
        return
    try FileAppend(FormatTime(, "HH:mm:ss") "." A_MSec "  " msg "`n", LogPath, "UTF-8")
}

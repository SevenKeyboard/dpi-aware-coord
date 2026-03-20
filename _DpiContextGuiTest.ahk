#Requires AutoHotkey v2.0
#NoTrayIcon
#SingleInstance Force
#Include .\lib\DpiAwarenessContextUtils.ahk
if (A_Args.Length !== 2)
    ExitApp
callerDpiContext := A_Args[1]
guiDpiContext := A_Args[2]
setThreadDpiAwarenessContext(guiDpiContext)
myGui := Gui("+AlwaysOnTop", "DPI Context GUI Test")
myGui.onEvent("Close", myGuiClose)
myGui.MarginX := 12
myGui.MarginY := 12
myGui.add("Text", "w260", "Caller DPI Context: " callerDpiContext)
myGui.add("Text", "w260", "This GUI DPI Context: " getThreadDpiAwarenessContextIgnoringInfoFlag())
myGui.show("x50 y50 w300 h110")
return
myGuiClose(thisGui)    {
    ExitApp
}
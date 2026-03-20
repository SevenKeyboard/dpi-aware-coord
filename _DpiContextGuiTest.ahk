#Requires AutoHotkey v1.1
#NoTrayIcon
#SingleInstance Force
#Include .\lib\DpiAwarenessContextUtils.ahk
if (A_Args.MaxIndex() !== 2)
    ExitApp
callerDpiContext := A_Args[1]
guiDpiContext := A_Args[2]
setThreadDpiAwarenessContext(guiDpiContext)
gui New
gui +AlwaysOnTop
gui Margin, 12, 12
gui Add, Text, w260, % "Caller DPI Context: " callerDpiContext
gui Add, Text, w260, % "This GUI DPI Context: " getThreadDpiAwarenessContextIgnoringInfoFlag()
gui Show, x50 y50 w300 h110, % "DPI Context GUI Test"
return
GuiClose:
    ExitApp
#Requires AutoHotkey v2.0
#SingleInstance Force
#Include ".\lib\DpiAwarenessContextUtils.ahk"
#Include ".\lib\GdipDpiBitmapUtils.ahk"
#Include ".\lib\winGetWhichMonitor.ahk"
#Include .\vendor\Gdip_All.ahk ;  Tested with https://github.com/buliasz/AHKv2-Gdip/blob/d3ddef1c11c58cac52c73caab8fcbf47a4dca30c/Gdip_All.ahk
/*
  Default is -2. Change it to -1 to -5 if needed to test different DPI awareness contexts.
  DpiAwareCoord is designed to handle all DPI scenarios mathematically.
*/
;  setThreadDpiAwarenessContext(-2)
;----------------------------------------------
callerDpiContext:=getThreadDpiAwarenessContextIgnoringInfoFlag()
guiDpiContext:=-1
run(A_ScriptDir '\_DpiContextGuiTest.ahk "' callerDpiContext '" "' guiDpiContext '"')
pToken:=Gdip_Startup()
onExit(exitFunc)
exitFunc(exitReason, exitCode)   {
    global
    if (pToken)
        Gdip_Shutdown(ptoken)
    if (winExist("DPI Context GUI Test"))
        winClose
}
myGui:=""
;----------------------------------------------
/*
  Launches DpiContextGuiTest with target DPI context -1 to -5,
  passing both the caller and target DPI contexts via A_Args.
*/
F1::
F2::
F3::
F4::
F5::  {
    guiDpiContext:=-subStr(A_ThisHotkey,-1,1)
    run(A_ScriptDir '\_DpiContextGuiTest.ahk "' callerDpiContext '" "' guiDpiContext '"')
}

/*
  Demonstrates an HWND capture helper that adds DPI-aware coordinate
  correction to the usual Gdip_BitmapFromHWND workflow.
*/
F10::  {
    global myGui
    hWnd:=winExist("DPI Context GUI Test")
    if (!hWnd)
        return
    pRaw:=Gdip_DpiBitmapFromHWND(hWnd) ;  DPI-aware replacement for Gdip_BitmapFromHWND.
    if (!pRaw)
        return
    if (myGui)    {
        try myGui.destroy()
        myGui:=""
    }
    try  {
        myGui:=Gui()
        myGui.MarginX:=0
        myGui.MarginY:=0
        myGui.add("Picture",, "hBitmap:" Gdip_createHBITMAPFromBitmap(pRaw))
        myGui.show("NoActivate")
    }  catch  {
        try myGui.destroy()
        myGui:=""
    }  finally  {
        Gdip_disposeImage(pRaw)
    }
}

/*
  Demonstrates a screen capture helper that adds DPI-aware coordinate
  correction to the usual Gdip_BitmapFromScreen workflow.
*/
F11::  {
    global myGui
    hWnd:=winExist("DPI Context GUI Test")
    if (!hWnd)
        return
    winGetPos(&x, &y, &w, &h, hWnd)
    i:=winGetWhichMonitor(hWnd)
    pRaw:=Gdip_DpiBitmapFromScreen(x "|" y "|" w "|" h "|" i) ;  DPI-aware replacement for Gdip_BitmapFromScreen.
    if (!pRaw)
        return
    if (myGui)    {
        try myGui.destroy()
        myGui:=""
    }
    try  {
        myGui:=Gui()
        myGui.MarginX:=0
        myGui.MarginY:=0
        myGui.add("Picture",, "hBitmap:" Gdip_createHBITMAPFromBitmap(pRaw))
        myGui.show("NoActivate")
    }  catch  {
        try myGui.destroy()
        myGui:=""
    }  finally  {
        Gdip_disposeImage(pRaw)
    }
}

F12::  {
    global myGui
    if (myGui)    {
        try myGui.destroy()
        myGui:=""
    }
}
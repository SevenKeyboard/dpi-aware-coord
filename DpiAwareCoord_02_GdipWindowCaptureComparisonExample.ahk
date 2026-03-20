#Requires AutoHotkey v1.1
#SingleInstance Force
#Include .\lib\DpiAwarenessContextUtils.ahk
#Include .\lib\GdipDpiBitmapUtils.ahk
#Include .\lib\winGetWhichMonitor.ahk
#Include .\vendor\Gdip_All.ahk ;  Tested with https://github.com/mmikeww/AHKv2-Gdip/blob/cab5ae291023c790ce4081630b190b5b88409f48/Gdip_All.ahk
/*
  Default is -2. Change it to -1 to -5 if needed to test different DPI awareness contexts.
  DpiAwareCoord is designed to handle all DPI scenarios mathematically.
*/
;  setThreadDpiAwarenessContext(-2)
;----------------------------------------------
callerDpiContext    := getThreadDpiAwarenessContextIgnoringInfoFlag()
guiDpiContext       := -1
run % A_ScriptDir "\_DpiContextGuiTest.ahk """ callerDpiContext """ """ guiDpiContext """"
pToken:=Gdip_Startup()
onExit("exitFunc")
exitFunc(exitReason, exitCode)   {
    global
    if (pToken)
        Gdip_Shutdown(ptoken)
    if (winExist("DPI Context GUI Test"))
        winClose
}
;----------------------------------------------
/*
  Launches DpiContextGuiTest with target DPI context -1 to -5,
  passing both the caller and target DPI contexts via A_Args.
*/
F1::
F2::
F3::
F4::
F5::
    guiDpiContext:=-subStr(A_ThisHotkey,0,1)
    run % A_ScriptDir "\_DpiContextGuiTest.ahk """ callerDpiContext """ """ guiDpiContext """"
    return

/*
  Demonstrates an HWND capture helper that adds DPI-aware coordinate
  correction to the usual Gdip_BitmapFromHWND workflow.
*/
F10::
    hWnd:=winExist("DPI Context GUI Test")
    if (!hWnd)
        return
    pRaw:=Gdip_DpiBitmapFromHWND(hWnd) ;  DPI-aware replacement for Gdip_BitmapFromHWND.
    splashImage % "hBitmap:" Gdip_createHBITMAPFromBitmap(pRaw)
    Gdip_disposeImage(pRaw)
    return

/*
  Demonstrates a screen capture helper that adds DPI-aware coordinate
  correction to the usual Gdip_BitmapFromScreen workflow.
*/
F11::
    hWnd:=winExist("DPI Context GUI Test")
    if (!hWnd)
        return
    winGetPos x, y, w, h, % "ahk_id " hWnd
    i:=winGetWhichMonitor(hWnd)
    pRaw:=Gdip_DpiBitmapFromScreen(x "|" y "|" w "|" h,, i) ;  DPI-aware replacement for Gdip_BitmapFromScreen.
    splashImage % "hBitmap:" Gdip_createHBITMAPFromBitmap(pRaw)
    Gdip_disposeImage(pRaw)
    return

F12::splashImage % "Off"
#Requires AutoHotkey v1.1
#SingleInstance Force
#Include .\lib\DpiAwareCoord.ahk
#Include .\lib\DpiAwarenessContextUtils.ahk
/*
  Default is -2. Change it to -1 to -5 if needed to test different DPI awareness contexts.
  DpiAwareCoord is designed to handle all DPI scenarios mathematically.
*/
;  setThreadDpiAwarenessContext(-2)
;----------------------------------------------
/*
Example Usage:
  F6 — Inspect mouse position across DPI coordinate spaces
       Captures the current mouse position and, based on the thread’s
       DPI awareness context, converts it between Unaware, System, and
       Per-Monitor coordinate spaces.
       The tooltip shows all three (Unw / Sys / Mon) so you can verify
       that your conversion helpers still refer to the same logical point
       in each DPI space.

       For example, on a given setup you might see:
         -1, -5   (-1920,578)   (2194,2674)   (2047,0)
         -2       (-2400,723)   (2742,3342)   (2559,0)
         -3, -4   (-1920,578)   (3839,3599)   (2559,0)
       where each line represents:
         DPI_AWARENESS_CONTEXT    Unw (X,Y)    Sys (X,Y)    Mon (X,Y)
*/
F6::
    prevRelativeTo:=A_CoordModeMouse
    coordMode Mouse, Screen
    mouseGetPos x, y
    coordMode Mouse, % prevRelativeTo
    switch (dpiContext:=getThreadDpiAwarenessContextIgnoringInfoFlag())
    {
        case -1,-5:
            uX:=x, uY:=y
            DpiAwareCoord.convertUnwToSys(sX:=uX, sY:=uY)
            DpiAwareCoord.convertUnwToMon(mX:=uX, mY:=uY)
        case -2:
            sX:=x, sY:=y
            DpiAwareCoord.convertSysToUnw(uX:=sX, uY:=sY)
            DpiAwareCoord.convertSysToMon(mX:=sX, mY:=sY)
        case -3,-4:
            mX:=x, mY:=y
            DpiAwareCoord.convertMonToUnw(uX:=mX, uY:=mY)
            DpiAwareCoord.convertMonToSys(sX:=mX, sY:=mY)
    }
    tooltip % "Unw`t:  (" uX ", " uY ")"
        . "`nSys`t:  (" sX ", " sY ")"
        . "`nMon`t:  (" mX ", " mY ")"
    return
/*
Example Usage:
  F7 — Demonstrate DPI-aware MouseGetPos correction
       On high-DPI / per-monitor setups, using MouseGetPos coordinates directly
       in MouseMove can move the cursor away from its visible position.
       This hotkey converts the raw System coordinates to Per-Monitor coordinates
       so that moving the mouse "to the same position" keeps it visually in place.
*/
F7::
    prevRelativeTo:=A_CoordModeMouse
    coordMode Mouse, Screen
    mouseGetPos x1, y1
    switch (dpiContext:=getThreadDpiAwarenessContextIgnoringInfoFlag())
    {
        
        case -1,-5:     DpiAwareCoord.convertSysToMon(x2:=x1, y2:=y1)
        case -2:        DpiAwareCoord.convertSysToMon(x2:=x1, y2:=y1)
        case -3,-4:     x2:=x1, y2:=y1
    }
    if (getKeyState("F3","P"))
        keyWait % "F3"
    mouseMove % x2, % y2, 0
    coordMode Mouse, % prevRelativeTo
    tooltip % "Raw`t`t:  (" x1 ", " y1 ")"
        . "`nCorrected`t:  (" x2 ", " y2 ")"
    return

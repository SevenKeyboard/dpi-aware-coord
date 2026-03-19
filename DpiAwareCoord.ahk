#Requires AutoHotkey v1.1.36+
#Include %A_ScriptDir%
#Include .\lib\MonitorExGetUtils.ahk
#Include .\lib\pointGetWhichMonitor.ahk
;==============================================================
; DpiAwareCoord — DPI-aware coordinate conversion utilities
;
; GitHub: https://github.com/SevenKeyboard/dpi-aware-coord
; Author: SevenKeyboard Ltd. (2025)
; License: MIT License
;
; Documentation / References:
;   LogicalToPhysicalPointForPerMonitorDPI function (winuser.h)
;     https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-logicaltophysicalpointforpermonitordpi
;   PhysicalToLogicalPointForPerMonitorDPI function (winuser.h)
;     https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-physicaltologicalpointforpermonitordpi
;==============================================================
class VersionManager_DpiAwareCoord
{
    static _ := VersionManager_DpiAwareCoord._init()
    _init()    {
        global
        DPIAWARECOORD_VERSION := "1.1.0"
        if (!this._verCheck(MONITOREXGETUTILS_VERSION, "1.0.0"))
            throw exception("MonitorExGetUtils version 1.x is required (minimum 1.0.0).")
        if (!this._verCheck(POINTGETWHICHMONITOR_VERSION, "1.0.0"))
            throw exception("pointGetWhichMonitor version 1.x is required (minimum 1.0.0).")
        return true
    }
    _verCheck(byRef actual, required)    {
        if !isSet(actual)
            return false
        actualMajor     := strSplit(actual, ".",, 2)[1]
        requiredMajor   := strSplit(required, ".",, 2)[1]
        if (actualMajor !== requiredMajor)
            return false
        return verCompare(actual, ">=" required)
    }
}
;---------------------------------------------
class DpiAwareCoord
{
    MONITOR_DEFAULTTONEAREST    {
        get  {
            return 0x00000002
        }
    }
    ;-----------------------------------------------------
    ;  UNAWARE  =>  SYSTEM
    convertUnwToSys(byRef x, byRef y, i:=0, doRound := true)    {
         uX:=x
        ,uY:=y
        ,i:=(i?i:pointGetWhichMonitor(uX,uY,this.MONITOR_DEFAULTTONEAREST))
        ,obj:=monitorExGetInfo(i)
        if (errorLevel)
            return
        primaryScaleFactor:=monitorExGetScaleFactor()
        ,sLeft  := obj.rcMonitor.left*(primaryScaleFactor/100)
        ,sTop   := obj.rcMonitor.top*(primaryScaleFactor/100)
        ,sRight := sLeft+(obj.rcMonitor.right-obj.rcMonitor.left)/(100/primaryScaleFactor)
        ,sBottom:= sTop+(obj.rcMonitor.bottom-obj.rcMonitor.top)/(100/primaryScaleFactor)
        ,ratioW := (uX-obj.rcMonitor.left)/(obj.rcMonitor.right-obj.rcMonitor.left)
        ,ratioH := (uY-obj.rcMonitor.top)/(obj.rcMonitor.bottom-obj.rcMonitor.top)
        ,sX:=sLeft+(sRight-sLeft)*ratioW
        ,sY:=sTop+(sBottom-sTop)*ratioH
        ,x:=doRound?round(sX):sX
        ,y:=doRound?round(sY):sY
    }
    ;  UNAWARE  =>  PER_MONITOR
    convertUnwToMon(byRef x, byRef y, i:=0, doRound := true)    {
         uX:=x
        ,uY:=y
        ,i:=(i?i:pointGetWhichMonitor(uX,uY,this.MONITOR_DEFAULTTONEAREST))
        ,obj:=monitorExGetInfo(i)
        if (errorLevel)
            return
        ithScaleFactor:=monitorExGetScaleFactor(i)
        ,mX:=obj.rcMonitor.left+(uX-obj.rcMonitor.left)*(ithScaleFactor/100)
        ,mY:=obj.rcMonitor.Top+(uY-obj.rcMonitor.Top)*(ithScaleFactor/100)
        ,x:=doRound?round(mX):mX
        ,y:=doRound?round(mY):mY
    }
    ;-----------------------------------------------------
    ;  SYSTEM  =>  UNAWARE
    convertSysToUnw(byRef x, byRef y, i:=0, doRound := true)   {
         sX:=x
        ,sY:=y
        ,i:=(i?i:pointGetWhichMonitor(sX,sY,this.MONITOR_DEFAULTTONEAREST))
        ,obj:=monitorExGetInfo(i)
        if (errorLevel)
            return
        iX:=obj.rcMonitor.left
        ,iY:=obj.rcMonitor.top
        ,iW:=sX-iX
        ,iH:=sY-iY
        ,ithScaleFactor:=monitorExGetScaleFactor(i)
        ,primaryScaleFactor:=monitorExGetScaleFactor()
        ,uX:=iX/(primaryScaleFactor/100)+iW*(100/primaryScaleFactor)
        ,uY:=iY/(primaryScaleFactor/100)+iH*(100/primaryScaleFactor)
        ,x:=doRound?round(uX):uX
        ,y:=doRound?round(uY):uY
    }
    ;  SYSTEM  =>  PER_MONITOR
    convertSysToMon(byRef x, byRef y, i:=0, doRound := true)   {
         sX:=x
        ,sY:=y
        ,i:=(i?i:pointGetWhichMonitor(sX,sY,this.MONITOR_DEFAULTTONEAREST))
        ,obj:=monitorExGetInfo(i)
        if (errorLevel)
            return
        iX:=obj.rcMonitor.left
        ,iY:=obj.rcMonitor.top
        ,iW:=sX-iX
        ,iH:=sY-iY
        ,ithScaleFactor:=monitorExGetScaleFactor(i)
        ,primaryScaleFactor:=monitorExGetScaleFactor()
        ,mX:=iX/(primaryScaleFactor/100)+iW*(ithScaleFactor/primaryScaleFactor)
        ,mY:=iY/(primaryScaleFactor/100)+iH*(ithScaleFactor/primaryScaleFactor)
        ,x:=doRound?round(mX):mX
        ,y:=doRound?round(mY):mY
    }
    ;-----------------------------------------------------
    ;  PER_MONITOR  =>  UNAWARE
    convertMonToUnw(byRef x, byRef y, i:=0, doRound := true)    {
         mX:=x
        ,mY:=y
        ,i:=(i?i:pointGetWhichMonitor(mX,mY,this.MONITOR_DEFAULTTONEAREST))
        ,obj:=monitorExGetInfo(i)
        if (errorLevel)
            return
        ithScaleFactor:=monitorExGetScaleFactor(i)
        ,sX:=obj.rcMonitor.left+(mX-obj.rcMonitor.left)/(ithScaleFactor/100)
        ,sY:=obj.rcMonitor.Top+(mY-obj.rcMonitor.Top)/(ithScaleFactor/100)
        ,x:=doRound?round(sX):sX
        ,y:=doRound?round(sY):sY
    }
    ;  PER_MONITOR  =>  SYSTEM
    convertMonToSys(byRef x, byRef y, i:=0, doRound := true)    {
         mX:=x
        ,mY:=y
        ,i:=(i?i:pointGetWhichMonitor(mX,mY,this.MONITOR_DEFAULTTONEAREST))
        ,obj:=monitorExGetInfo(i)
        if (errorLevel)
            return
        ithScaleFactor:=monitorExGetScaleFactor(i)
        ,primaryScaleFactor:=monitorExGetScaleFactor()
        ,sLeft  := obj.rcMonitor.left*(primaryScaleFactor/100)
        ,sTop   := obj.rcMonitor.top*(primaryScaleFactor/100)
        ,sRight := sLeft+(obj.rcMonitor.right-obj.rcMonitor.left)/(ithScaleFactor/primaryScaleFactor)
        ,sBottom:= sTop+(obj.rcMonitor.bottom-obj.rcMonitor.top)/(ithScaleFactor/primaryScaleFactor)
        ,ratioW := (mX-obj.rcMonitor.left)/(obj.rcMonitor.right-obj.rcMonitor.left)
        ,ratioH := (mY-obj.rcMonitor.top)/(obj.rcMonitor.bottom-obj.rcMonitor.top)
        ,sX:=round(sLeft+(sRight-sLeft)*ratioW)
        ,sY:=round(sTop+(sBottom-sTop)*ratioH)
        ,x:=doRound?round(sX):sX
        ,y:=doRound?round(sY):sY
    }
}
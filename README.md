# DpiAwareCoord

Mathematical DPI coordinate conversions, preserving the AHK 1.1.0 formulas.

```csharp
using SevenKeyboard;

double x = 120, y = 240;
DpiAwareCoord.ConvertSysToMon(ref x, ref y);
DpiAwareCoord.ConvertMonToSys(ref x, ref y, i: 2, doRound: false);
```

Six methods: `ConvertUnwToSys`, `ConvertUnwToMon`, `ConvertSysToUnw`,
`ConvertSysToMon`, `ConvertMonToUnw`, and `ConvertMonToSys`.
`Unw`, `Sys`, and `Mon` mean unaware, system-aware, and per-monitor coordinates.

Monitor numbers are one-based; zero selects the nearest monitor from the input
point. A missing monitor leaves both coordinates unchanged. Real dependency
errors propagate. Rounding defaults to nearest with midpoint ties away from zero;
disable it to retain fractions. Floating-point rounding follows AHK's operation order.
Zero-divisor arithmetic errors throw; they do not produce an empty numeric value.

The library does not change DPI awareness. Monitor information follows the
existing shared cache: initial enumeration and explicit refresh use their
caller's DPI context. Keep its coordinate basis consistent with the conversion's
calling environment. This port does not introduce context-specific caches.

Dependencies are sibling source projects `monitor-ex-get-utils/main-cs`
(minimum 2.0.0, same major), `point-get-which-monitor/main-cs`
(minimum 1.0.0, same major), and `library-build/main-cs`.
Override `MonitorExGetUtilsProjectPath`, `PointGetWhichMonitorProjectPath`,
and `LibraryBuildTargetsPath` for another layout. Product snapshots include
these sources; originals do not embed each other.

Build: `dotnet build tests/DpiAwareCoord.Tests -c Release`.
Windows 10+, .NET 10; NativeAOT-compatible.
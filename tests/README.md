# DpiAwareCoord tests

Run from the repository root:

```powershell
dotnet run --project tests/DpiAwareCoord.Tests -c Release -- --native
```

Apply any executable signing required by the host before running.
The optional `--native` check reads monitor information and exercises all six
public conversions with explicit and automatic monitor selection under contexts
-1 through -5. It restores the calling thread's context. No input is sent.

`ahk-original.csv` contains 1,728 outputs from the unmodified original class
with controlled monitor rectangles and scale queries. AHK v1.1.37.02 and
v2.0.26 produced identical rows. Cases cover six conversions, negative and
nonzero monitor origins, mixed scale factors, fractional/outside coordinates,
and rounding enabled/disabled. Fixture comparisons use a 1e-12 relative
tolerance; separate exact checks cover rounding boundaries and the sign of zero.

The API follows the LC/CJK AHK v1.1 calling behavior: in-place coordinates,
integer monitor selection, and an absent monitor preserving the input.
C# represents coordinates as doubles. Arithmetic division errors throw rather
than returning AHK v1.1's empty numeric result. Real dependency errors propagate.
AHK v2-only array negative indexing and float bit-operation errors are not added.

Verified 2026-11-10 on Windows 11 x64, SDK 10.0.403:
- Managed x64 and x86: zero build warnings/errors; 3,513 checks passed each.
- NativeAOT x64: publish and the same 3,513 checks passed.
- Each target: 60 native public calls across all five DPI contexts passed.
- Test binaries were Authenticode signed and signatures verified before execution.

This establishes arithmetic compatibility and native-query execution. It is not
a fresh visual alignment test of every physical mixed-DPI monitor arrangement.
Windows 10 execution was not tested in this batch.
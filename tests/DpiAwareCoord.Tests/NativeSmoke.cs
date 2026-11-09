using System.Runtime.InteropServices;
using SevenKeyboard;

internal static class NativeSmoke
{
    private delegate void ConvertPoint(ref double x, ref double y, int i, bool doRound);

    internal static void Run()
    {
        ConvertPoint[] methods = [
            DpiAwareCoord.ConvertUnwToSys, DpiAwareCoord.ConvertUnwToMon,
            DpiAwareCoord.ConvertSysToUnw, DpiAwareCoord.ConvertSysToMon,
            DpiAwareCoord.ConvertMonToUnw, DpiAwareCoord.ConvertMonToSys];
        nint original = GetThreadDpiAwarenessContext();
        int calls = 0, contexts = 0;
        try
        {
            foreach (nint context in new nint[] { -1, -2, -3, -4, -5 })
            {
                if (SetThreadDpiAwarenessContext(context) == 0)
                    continue; // Older Windows versions may not support all context values.
                nint before = GetThreadDpiAwarenessContext();
                var monitors = MonitorExGetUtils.GetInfoList(force: true);
                if (monitors.Count == 0) throw new Exception("No monitors in native smoke.");
                contexts++;
                foreach (var method in methods)
                {
                    double x = monitors[0].Monitor.Left + 37.5;
                    double y = monitors[0].Monitor.Top + 91.25;
                    method(ref x, ref y, 1, false);
                    if (!double.IsFinite(x) || !double.IsFinite(y))
                        throw new Exception("Non-finite native conversion.");
                    if (GetThreadDpiAwarenessContext() != before)
                        throw new Exception("Conversion changed the calling thread DPI context.");
                    calls++;
                    // Exercise the native nearest-monitor selector too.
                    x = monitors[0].Monitor.Left + 37.5; y = monitors[0].Monitor.Top + 91.25;
                    method(ref x, ref y, 0, true);
                    if (!double.IsFinite(x) || !double.IsFinite(y) || GetThreadDpiAwarenessContext() != before)
                        throw new Exception("Automatic monitor conversion failed.");
                    calls++;
                }
            }
        }
        finally
        {
            if (SetThreadDpiAwarenessContext(original) == 0)
                throw new Exception("Could not restore native test thread DPI context.");
        }
        if (contexts == 0) throw new Exception("No supported DPI context was tested.");
        Console.WriteLine($"PASS: {calls} native public conversions in {contexts} DPI contexts; caller contexts preserved.");
    }

    [DllImport("user32.dll", ExactSpelling = true)]
    [DefaultDllImportSearchPaths(DllImportSearchPath.System32)]
    private static extern nint GetThreadDpiAwarenessContext();
    [DllImport("user32.dll", ExactSpelling = true)]
    [DefaultDllImportSearchPaths(DllImportSearchPath.System32)]
    private static extern nint SetThreadDpiAwarenessContext(nint context);
}
// Copyright SevenKeyboard Ltd. (2026). MIT License.
namespace SevenKeyboard;

/// <summary>AHK-compatible mathematical conversions between DPI coordinate spaces.</summary>
/// <remarks>
/// Coordinates are updated in place. A missing monitor leaves both unchanged.
/// The caller's DPI context and the shared monitor cache policy are preserved.
/// </remarks>
public static class DpiAwareCoord
{
    private static readonly CoordinateConverter Converter = new(
        static (x, y) => PointGetWhichMonitor.Get(x, y, 2),
        static i => MonitorExGetUtils.GetInfo(i)?.Monitor,
        static i => MonitorExGetUtils.GetScaleFactor(i));

    public static void ConvertUnwToSys(ref double x, ref double y, int i = 0, bool doRound = true) =>
        Converter.Convert(Conversion.UnwToSys, ref x, ref y, i, doRound);
    public static void ConvertUnwToMon(ref double x, ref double y, int i = 0, bool doRound = true) =>
        Converter.Convert(Conversion.UnwToMon, ref x, ref y, i, doRound);
    public static void ConvertSysToUnw(ref double x, ref double y, int i = 0, bool doRound = true) =>
        Converter.Convert(Conversion.SysToUnw, ref x, ref y, i, doRound);
    public static void ConvertSysToMon(ref double x, ref double y, int i = 0, bool doRound = true) =>
        Converter.Convert(Conversion.SysToMon, ref x, ref y, i, doRound);
    public static void ConvertMonToUnw(ref double x, ref double y, int i = 0, bool doRound = true) =>
        Converter.Convert(Conversion.MonToUnw, ref x, ref y, i, doRound);
    public static void ConvertMonToSys(ref double x, ref double y, int i = 0, bool doRound = true) =>
        Converter.Convert(Conversion.MonToSys, ref x, ref y, i, doRound);
}

internal enum Conversion { UnwToSys, UnwToMon, SysToUnw, SysToMon, MonToUnw, MonToSys }

// Preserve operation order, including monitor selection before information lookup.
internal sealed class CoordinateConverter(
    Func<int, int, int> findMonitor,
    Func<int, MonitorRectangle?> getMonitor,
    Func<int?, int> getScale)
{
    internal void Convert(Conversion conversion, ref double x, ref double y, int i = 0, bool doRound = true)
    {
        if (i == 0)
            i = findMonitor(ToNativeCoordinate(x), ToNativeCoordinate(y));
        if (getMonitor(i) is not { } monitor)
            return;

        double left = monitor.Left, top = monitor.Top;
        double width = (double)monitor.Right - monitor.Left;
        double height = (double)monitor.Bottom - monitor.Top;
        double resultX, resultY, primary, scale;
        switch (conversion)
        {
            case Conversion.UnwToSys:
                primary = getScale(null);
                double sLeft = left * (primary / 100);
                double sTop = top * (primary / 100);
                double sRight = sLeft + Divide(width, Divide(100, primary));
                double sBottom = sTop + Divide(height, Divide(100, primary));
                resultX = sLeft + (sRight - sLeft) * Divide(x - left, width);
                resultY = sTop + (sBottom - sTop) * Divide(y - top, height);
                break;
            case Conversion.UnwToMon:
                scale = getScale(i);
                resultX = left + (x - left) * (scale / 100);
                resultY = top + (y - top) * (scale / 100);
                break;
            case Conversion.SysToUnw:
                _ = getScale(i); // This read is present in the original too.
                primary = getScale(null);
                resultX = Divide(left, primary / 100) + (x - left) * Divide(100, primary);
                resultY = Divide(top, primary / 100) + (y - top) * Divide(100, primary);
                break;
            case Conversion.SysToMon:
                scale = getScale(i);
                primary = getScale(null);
                resultX = Divide(left, primary / 100) + (x - left) * Divide(scale, primary);
                resultY = Divide(top, primary / 100) + (y - top) * Divide(scale, primary);
                break;
            case Conversion.MonToUnw:
                scale = getScale(i);
                resultX = left + Divide(x - left, scale / 100);
                resultY = top + Divide(y - top, scale / 100);
                break;
            case Conversion.MonToSys:
                scale = getScale(i);
                primary = getScale(null);
                double targetLeft = left * (primary / 100);
                double targetTop = top * (primary / 100);
                double targetRight = targetLeft + Divide(width, Divide(scale, primary));
                double targetBottom = targetTop + Divide(height, Divide(scale, primary));
                resultX = targetLeft + (targetRight - targetLeft) * Divide(x - left, width);
                resultY = targetTop + (targetBottom - targetTop) * Divide(y - top, height);
                break;
            default:
                throw new ArgumentOutOfRangeException(nameof(conversion));
        }

        x = doRound ? RoundLikeAhk(resultX) : resultX;
        y = doRound ? RoundLikeAhk(resultY) : resultY;
    }

    // AHK packs the integer portions into signed 32-bit POINT fields.
    private static int ToNativeCoordinate(double value) => unchecked((int)(long)value);
    // Preserve AHK's addition/subtraction before floor/ceiling, including floating-point ties.
    private static double RoundLikeAhk(double value)
    {
        double rounded = value < 0 ? Math.Ceiling(value - 0.5) : Math.Floor(value + 0.5);
        return rounded == 0 ? 0 : rounded; // AHK returns integer zero, without a sign bit.
    }
    private static double Divide(double numerator, double denominator) =>
        denominator != 0 ? numerator / denominator : throw new DivideByZeroException();
}
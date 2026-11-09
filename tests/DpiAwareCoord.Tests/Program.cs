using System.Globalization;
using SevenKeyboard;

int checks = 0;
void Check(bool result, string name) { checks++; if (!result) throw new Exception(name); }
void Near(double actual, double expected, string name) =>
    Check(Math.Abs(actual - expected) <= Math.Max(1, Math.Abs(expected)) * 1e-12, $"{name}: {actual:R} != {expected:R}");

var calls = new List<string>();
var rect = new MonitorRectangle(-1000, 200, 1000, 1200);
var converter = new CoordinateConverter(
    (x, y) => { calls.Add($"find:{x},{y}"); return 2; },
    i => { calls.Add($"info:{i}"); return i == 2 ? rect : null; },
    i => { calls.Add($"scale:{i?.ToString() ?? "primary"}"); return i == null ? 125 : 200; });

(double X, double Y)[] expected = [
    (-1125, 312.5), (-800, 300), (-720, 200),
    (-640, 240), (-950, 225), (-1187.5, 281.25)];
string[] scaleOrder = ["primary", "2", "2,primary", "2,primary", "2", "2,primary"];
foreach (var kind in Enum.GetValues<Conversion>())
{
    double x = -900, y = 250;
    calls.Clear();
    converter.Convert(kind, ref x, ref y, 2, false);
    Near(x, expected[(int)kind].X, $"{kind} X");
    Near(y, expected[(int)kind].Y, $"{kind} Y");
    Check(!calls.Any(c => c.StartsWith("find:")), "explicit monitor skips native selection");
    Check(string.Join(",", calls.Where(c => c.StartsWith("scale:")).Select(c => c[6..])) == scaleOrder[(int)kind],
        "original scale read order");
    x = -900; y = 250;
    converter.Convert(kind, ref x, ref y, 2);
    Near(x, Math.Round(expected[(int)kind].X, MidpointRounding.AwayFromZero), "round X");
    Near(y, Math.Round(expected[(int)kind].Y, MidpointRounding.AwayFromZero), "round Y");

    calls.Clear();
    x = 4.25; y = -5.75;
    converter.Convert(kind, ref x, ref y, 99);
    Check(x == 4.25 && y == -5.75 && calls.SequenceEqual(["info:99"]), "missing monitor preserves coordinates");
}
double autoX = -1.9, autoY = -2.9;
calls.Clear();
converter.Convert(Conversion.UnwToMon, ref autoX, ref autoY);
Check(calls[0] == "find:-1,-2" && calls[1] == "info:2", "AHK truncation and lookup order");

foreach (int i in new[] { 0, -3 })
{
    var missing = new CoordinateConverter((_, _) => 0,
        number => { Check(number == i, "zero/negative monitor is not primary"); return null; },
        _ => throw new Exception("Must not read scale"));
    double x = 1.5, y = -2.5;
    missing.Convert(Conversion.SysToMon, ref x, ref y, i);
    Check(x == 1.5 && y == -2.5, "failed selection leaves input unchanged");
}

var readFailure = new CoordinateConverter((_, _) => 2, _ => throw new IOException("read"), _ => 100);
double errorX = 5, errorY = 6;
try { readFailure.Convert(Conversion.SysToMon, ref errorX, ref errorY); throw new Exception("Expected error"); }
catch (IOException) { Check(errorX == 5 && errorY == 6, "actual dependency error propagates without mutation"); }

var unit = new CoordinateConverter((_, _) => 1, _ => new MonitorRectangle(0, 0, 1920, 1080), _ => 100);
double roundX = 0.5, roundY = -0.5;
unit.Convert(Conversion.UnwToMon, ref roundX, ref roundY);
Check(roundX == 1 && roundY == -1, "midpoints away from zero");

roundX = 0.49999999999999994; roundY = -0.49999999999999994;
unit.Convert(Conversion.UnwToMon, ref roundX, ref roundY);
Check(roundX == 1 && roundY == -1, "AHK floating-point addition at rounding boundary");
roundX = -0.25; roundY = 0.25;
unit.Convert(Conversion.UnwToMon, ref roundX, ref roundY);
Check(BitConverter.DoubleToInt64Bits(roundX) == 0 && BitConverter.DoubleToInt64Bits(roundY) == 0, "AHK integer zero has no negative sign");
var ordered = new CoordinateConverter((_, _) => 1, _ => new MonitorRectangle(-2560, 0, -640, 1080), _ => 125);
double orderedX = -1598, orderedY = 100;
ordered.Convert(Conversion.UnwToSys, ref orderedX, ref orderedY);
Check(orderedX == -1997, "preserve arithmetic sequence before rounding");
foreach (var kind in new[] { Conversion.UnwToSys, Conversion.SysToUnw, Conversion.SysToMon, Conversion.MonToUnw, Conversion.MonToSys })
{
    var zeroScale = new CoordinateConverter((_, _) => 1, _ => new MonitorRectangle(0, 0, 1920, 1080), _ => 0);
    double zx = 3, zy = 4;
    try { zeroScale.Convert(kind, ref zx, ref zy); throw new Exception("Expected division failure"); }
    catch (DivideByZeroException) { Check(zx == 3 && zy == 4, "no partial mutation on invalid divisor"); }
}
string fixtures = args.FirstOrDefault(arg => arg != "--native") ?? Path.Combine(AppContext.BaseDirectory, "ahk-original.csv");
if (!File.Exists(fixtures)) throw new FileNotFoundException("Original AHK fixture is required.", fixtures);
if (File.Exists(fixtures))
{
    // Fixtures are output by the original AHK class with controlled monitor information.
    foreach (string line in File.ReadLines(fixtures).Skip(1))
    {
        if (string.IsNullOrWhiteSpace(line)) continue;
        var v = line.Split(',');
        double D(int n) => double.Parse(v[n], CultureInfo.InvariantCulture);
        int I(int n) => int.Parse(v[n], CultureInfo.InvariantCulture);
        var oracle = new CoordinateConverter((_, _) => 1,
            _ => new MonitorRectangle(I(3), I(4), I(5), I(6)),
            i => i == null ? I(7) : I(8));
        double x = D(1), y = D(2);
        oracle.Convert(Enum.Parse<Conversion>(v[0]), ref x, ref y, 1, I(9) != 0);
        Near(x, D(10), "AHK X");
        Near(y, D(11), "AHK Y");
    }
}
Console.WriteLine($"PASS: {checks} checks");
if (args.Contains("--native")) NativeSmoke.Run();

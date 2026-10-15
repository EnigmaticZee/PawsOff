using System;
using System.Windows;
using Microsoft.Win32;
using System.Windows.Media;

namespace PawsOff
{
    /// Applies the light or dark colour set to the whole app (window and tray pop-up together)
    /// and follows the Windows setting live while the theme is Auto.
    static class ThemeManager
    {
        static Settings settings;
        static bool? forced;

        public static event Action Changed;
        public static bool IsDark { get; private set; } = true;

        public static void Init(Settings appSettings)
        {
            settings = appSettings;
            SystemEvents.UserPreferenceChanged += (s, e) =>
            {
                if (e.Category == UserPreferenceCategory.General)
                    Application.Current.Dispatcher.BeginInvoke(new Action(Reapply));
            };
            Reapply();
        }

        /// Previews render a fixed theme.
        public static void Force(bool dark)
        {
            forced = dark;
            Reapply();
        }

        public static void Reapply()
        {
            IsDark = forced ?? settings?.UsesDarkTheme ?? true;
            Theme.Apply(Application.Current.Resources, IsDark);
            Changed?.Invoke();
        }
    }

    /// Light and dark colour sets. XAML refers to these keys with DynamicResource, so applying a
    /// theme repaints the whole window. Accent colours are shared with the Mac app's Palette.
    static class Theme
    {
        public static readonly Color[] Idle = { Hex("#FA8C78"), Hex("#C266FA") };
        public static readonly Color[] Locked = { Hex("#5CEBC7"), Hex("#3394FA") };

        public static void Apply(ResourceDictionary resources, bool dark)
        {
            var ink = dark ? Colors.White : Hex("#1B1726");
            Set(resources, "TextPrimary", ink);
            Set(resources, "TextBody", WithAlpha(ink, 0xF2));
            Set(resources, "TextSecondary", WithAlpha(ink, dark ? (byte)0x99 : (byte)0xB3));
            Set(resources, "TextMuted", WithAlpha(ink, dark ? (byte)0x8C : (byte)0x99));
            Set(resources, "TextFaint", WithAlpha(ink, dark ? (byte)0x66 : (byte)0x80));
            Set(resources, "Fill1", WithAlpha(ink, dark ? (byte)0x0D : (byte)0x08));
            Set(resources, "Fill2", WithAlpha(ink, dark ? (byte)0x14 : (byte)0x0D));
            Set(resources, "Fill3", WithAlpha(ink, dark ? (byte)0x24 : (byte)0x17));
            Set(resources, "Stroke1", WithAlpha(ink, dark ? (byte)0x1A : (byte)0x14));
            Set(resources, "Stroke2", WithAlpha(ink, dark ? (byte)0x29 : (byte)0x1F));
            // Selected tabs and chips: a lighter pill on dark, a white card on light.
            Set(resources, "SelectedFill", dark ? WithAlpha(Colors.White, 0x29) : Colors.White);
            Set(resources, "SelectedStroke", dark ? WithAlpha(Colors.White, 0x24) : WithAlpha(ink, 0x14));
            Set(resources, "SwitchKnob", Colors.White);
            Set(resources, "CheckInk", dark ? Hex("#0F0F1A") : Colors.White);

            var top = dark ? Hex("#0F0F1A") : Hex("#FBF9FE");
            var bottom = dark ? Hex("#1A1429") : Hex("#F0EBF8");
            resources["WindowBackground"] = Freeze(new LinearGradientBrush(top, bottom, 90));

            // Frosted centre of the big button: tinted dark glass, or bright milky glass.
            resources["GlassFill"] = Freeze(new LinearGradientBrush(
                dark ? Hex("#4D1A1429") : Hex("#33FFFFFF"),
                dark ? Hex("#701A1429") : Hex("#14FFFFFF"), 90));
            resources["GlassHighlight"] = Freeze(new LinearGradientBrush(new GradientStopCollection
            {
                new GradientStop(WithAlpha(Colors.White, dark ? (byte)0x2E : (byte)0x55), 0),
                new GradientStop(WithAlpha(Colors.White, 0), 0.55),
            }, 90));
            resources["GlowStrength"] = dark ? 1.0 : 0.75;
        }

        public static Brush Glow(Color c, double strength) => Freeze(new RadialGradientBrush(new GradientStopCollection
        {
            new GradientStop(WithAlpha(c, (byte)(92 * strength)), 0),
            new GradientStop(WithAlpha(c, (byte)(40 * strength)), 0.45),
            new GradientStop(WithAlpha(c, 0), 1),
        }));

        public static Color Hex(string hex) => (Color)ColorConverter.ConvertFromString(hex);

        static Color WithAlpha(Color c, byte a) => Color.FromArgb(a, c.R, c.G, c.B);

        static void Set(ResourceDictionary resources, string key, Color c) => resources[key] = Freeze(new SolidColorBrush(c));

        static T Freeze<T>(T brush) where T : Freezable
        {
            brush.Freeze();
            return brush;
        }
    }
}

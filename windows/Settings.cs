using System;
using System.Diagnostics;
using Microsoft.Win32;

namespace PawsOff
{
    /// Auto follows the Windows light/dark app setting.
    public enum ThemeChoice { Auto, Light, Dark }

    /// Where Paws Off opens when it starts. The tray icon is always there.
    public enum StartPlace { Tray, Window }

    /// Lifetime totals, kept only on this PC (registry) and never sent anywhere.
    public sealed class PawStats
    {
        public int KeysStopped;   // every key swallowed, any mode
        public int PawKeys;       // keys swallowed in Away mode: the pets' share
        public int PawAmbushes;   // times paw detection locked the keyboard
        public int CleanSessions;
        public int AwaySessions;

        public bool IsEmpty => KeysStopped == 0 && CleanSessions == 0 && AwaySessions == 0;
    }

    /// User settings, stored in HKCU\Software\PawsOff. Preview instances never touch the registry.
    public sealed class Settings
    {
        const string KeyPath = @"Software\PawsOff";
        const string RunKeyPath = @"Software\Microsoft\Windows\CurrentVersion\Run";
        const string RunValueName = "PawsOff";

        readonly bool persists;
        LockMode mode = LockMode.Clean;
        int timerSeconds;
        string unlockPhrase = "unlock";
        bool pawDetection = true;
        ThemeChoice theme = ThemeChoice.Auto;
        StartPlace startIn = StartPlace.Tray;
        int customSeconds = 180;
        bool autoUpdate = true;
        DateTime lastUpdateCheck = DateTime.MinValue;
        string lastAnnouncedVersion = "";

        /// True the very first time Paws Off runs (nothing saved yet).
        public bool IsFirstRun { get; private set; }

        Settings(bool persists) { this.persists = persists; }

        public static Settings InMemory() => new Settings(false);

        public static Settings Load()
        {
            var s = new Settings(true);
            using (var key = Registry.CurrentUser.OpenSubKey(KeyPath))
            {
                if (key == null) { s.IsFirstRun = true; return s; }
                if (Enum.TryParse(key.GetValue("Mode") as string, out LockMode m)) s.mode = m;
                if (key.GetValue("TimerSeconds") is int t) s.timerSeconds = t == 120 ? 120 : 0; // older 30 s / 1 min choices: back to the default
                if (key.GetValue("CustomSeconds") is int cs) s.customSeconds = cs;
                if (key.GetValue("AutoUpdate") is int au) s.autoUpdate = au != 0;
                if (DateTime.TryParse(key.GetValue("LastUpdateCheck") as string, null, System.Globalization.DateTimeStyles.RoundtripKind, out var luc)) s.lastUpdateCheck = luc;
                if (key.GetValue("LastAnnouncedVersion") is string lav) s.lastAnnouncedVersion = lav;
                if (key.GetValue("UnlockPhrase") is string p) s.unlockPhrase = p;
                if (key.GetValue("PawDetection") is int paw) s.pawDetection = paw != 0;
                if (Enum.TryParse(key.GetValue("Theme") as string, out ThemeChoice th)) s.theme = th;
                if (Enum.TryParse(key.GetValue("StartIn") as string, out StartPlace sp)) s.startIn = sp;
            }
            return s;
        }

        public LockMode Mode
        {
            get => mode;
            set { mode = value; Save("Mode", value.ToString()); }
        }

        public int TimerSeconds
        {
            get => timerSeconds;
            set { timerSeconds = value; Save("TimerSeconds", value); }
        }

        public string UnlockPhrase
        {
            get => unlockPhrase;
            set { unlockPhrase = value ?? ""; Save("UnlockPhrase", unlockPhrase); }
        }

        public bool PawDetection
        {
            get => pawDetection;
            set { pawDetection = value; Save("PawDetection", value ? 1 : 0); }
        }

        /// Check GitHub for new versions about once a day.
        public bool AutoUpdate
        {
            get => autoUpdate;
            set { autoUpdate = value; Save("AutoUpdate", value ? 1 : 0); }
        }

        public DateTime LastUpdateCheck
        {
            get => lastUpdateCheck;
            set { lastUpdateCheck = value; Save("LastUpdateCheck", value.ToString("o")); }
        }

        /// The "Paws Off lives in your tray" tip is shown once.
        public bool ShownTrayTip
        {
            get
            {
                using (var key = Registry.CurrentUser.OpenSubKey(KeyPath))
                    return key?.GetValue("ShownTrayTip") is int shown && shown != 0;
            }
            set => Save("ShownTrayTip", value ? 1 : 0);
        }

        /// The version that ran last time, to say "Updated to …" once after an update. Empty before 2.0.2.
        public string LastRunVersion
        {
            get
            {
                using (var key = Registry.CurrentUser.OpenSubKey(KeyPath))
                    return key?.GetValue("LastRunVersion") as string ?? "";
            }
            set => Save("LastRunVersion", value ?? "");
        }

        /// So each new version is announced in the tray only once.
        public string LastAnnouncedVersion
        {
            get => lastAnnouncedVersion;
            set { lastAnnouncedVersion = value ?? ""; Save("LastAnnouncedVersion", lastAnnouncedVersion); }
        }

        /// Last custom auto-unlock length the user entered (seconds).
        public int CustomSeconds
        {
            get => customSeconds;
            set { customSeconds = value; Save("CustomSeconds", value); }
        }

        public PawStats LoadStats()
        {
            var stats = new PawStats();
            if (!persists) return stats;
            using (var key = Registry.CurrentUser.OpenSubKey(KeyPath + @"\Stats"))
            {
                if (key == null) return stats;
                stats.KeysStopped = key.GetValue("KeysStopped") as int? ?? 0;
                stats.PawKeys = key.GetValue("PawKeys") as int? ?? 0;
                stats.PawAmbushes = key.GetValue("PawAmbushes") as int? ?? 0;
                stats.CleanSessions = key.GetValue("CleanSessions") as int? ?? 0;
                stats.AwaySessions = key.GetValue("AwaySessions") as int? ?? 0;
            }
            return stats;
        }

        public void SaveStats(PawStats stats)
        {
            if (!persists) return;
            using (var key = Registry.CurrentUser.CreateSubKey(KeyPath + @"\Stats"))
            {
                key.SetValue("KeysStopped", stats.KeysStopped);
                key.SetValue("PawKeys", stats.PawKeys);
                key.SetValue("PawAmbushes", stats.PawAmbushes);
                key.SetValue("CleanSessions", stats.CleanSessions);
                key.SetValue("AwaySessions", stats.AwaySessions);
            }
        }

        public StartPlace StartIn
        {
            get => startIn;
            set { startIn = value; Save("StartIn", value.ToString()); }
        }

        public ThemeChoice Theme
        {
            get => theme;
            set { theme = value; Save("Theme", value.ToString()); }
        }

        /// True when the app should draw dark: the user's choice, or the Windows setting on Auto.
        public bool UsesDarkTheme
        {
            get
            {
                if (theme != ThemeChoice.Auto) return theme == ThemeChoice.Dark;
                using (var personalize = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"))
                    return personalize?.GetValue("AppsUseLightTheme") is int light && light == 0;
            }
        }

        /// Lowercased phrase with surrounding spaces removed; empty means "click to unlock only".
        public string TrimmedPhrase => unlockPhrase.Trim().ToLowerInvariant();

        /// Starts Paws Off (hidden in the tray) when the user signs in.
        public bool LaunchAtLogin
        {
            get
            {
                using (var run = Registry.CurrentUser.OpenSubKey(RunKeyPath))
                    return run?.GetValue(RunValueName) != null;
            }
            set
            {
                if (!persists) return;
                using (var run = Registry.CurrentUser.CreateSubKey(RunKeyPath))
                {
                    if (value)
                        run.SetValue(RunValueName, $"\"{ExePath}\" --minimized");
                    else
                        run.DeleteValue(RunValueName, false);
                }
            }
        }

        static string ExePath
        {
            get { using (var p = Process.GetCurrentProcess()) return p.MainModule.FileName; }
        }

        void Save(string name, object value)
        {
            if (!persists) return;
            using (var key = Registry.CurrentUser.CreateSubKey(KeyPath))
                key.SetValue(name, value);
        }
    }
}

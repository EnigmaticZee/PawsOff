using System;
using System.ComponentModel;
using System.Linq;
using System.Reflection;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Threading;

namespace PawsOff
{
    public partial class MainWindow : Window
    {
        // Same colours as Palette in the Mac app (Sources/Theme.swift).
        static readonly Color[] Idle = { Hex("#FA8C78"), Hex("#C266FA") };
        static readonly Color[] Locked = { Hex("#5CEBC7"), Hex("#3394FA") };
        const double RingCircumference = Math.PI * 212 / 3; // in stroke-thickness units, for StrokeDashArray

        readonly KeyboardBlocker blocker;
        readonly DispatcherTimer countdown = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(100) };
        bool pulsing;

        /// Closing hides to the tray unless the app is quitting.
        public bool AllowClose { get; set; }

        public MainWindow(KeyboardBlocker blocker)
        {
            InitializeComponent();
            this.blocker = blocker;
            blocker.Changed += Refresh;
            countdown.Tick += (s, e) => UpdateCountdown();
            Refresh();
        }

        static Color Hex(string hex) => (Color)ColorConverter.ConvertFromString(hex);

        static string Spaced(string text) => string.Join(" ", text.ToCharArray());

        // MARK: State → UI

        void Refresh()
        {
            bool locked = blocker.IsActive;
            var mode = locked ? blocker.ActiveMode : blocker.Settings.Mode;
            var accent = locked ? Locked : Idle;
            var gradient = new LinearGradientBrush(accent[0], accent[1], new Point(0, 0), new Point(1, 1));

            Disc.Fill = gradient;
            Halo.Stroke = gradient;
            Ring.Stroke = gradient;
            DiscShadow.Color = accent[1];
            Glow1.Fill = new SolidColorBrush(accent[0]);
            Glow2.Fill = new SolidColorBrush(accent[1]);

            SetTab(CleanTab, mode == LockMode.Clean);
            SetTab(AwayTab, mode == LockMode.Away);
            ModePicker.Opacity = locked ? 0.45 : 1;
            ModePicker.IsEnabled = !locked;
            SettingsButton.Visibility = locked ? Visibility.Hidden : Visibility.Visible;

            StatusLabel.Text = Spaced(locked ? (blocker.PawTriggered ? "PAWS DETECTED" : "KEYBOARD LOCKED") : "KEYBOARD ACTIVE");
            KeyboardGlyph.Visibility = mode == LockMode.Away ? Visibility.Collapsed : Visibility.Visible;
            PawGlyph.Visibility = mode == LockMode.Away ? Visibility.Visible : Visibility.Collapsed;
            ButtonLabel.Text = Spaced(locked ? "UNLOCK" : "LOCK");

            TitleText.Text = TitleFor(locked, mode);
            SubtitleText.Text = SubtitleFor(locked, mode);

            TimerChips.Visibility = Show(!locked && mode == LockMode.Clean);
            PhraseRow.Visibility = Show(!locked && mode == LockMode.Away);
            LockedInfo.Visibility = Show(locked);
            foreach (var chip in TimerChips.Children.OfType<Button>())
                SetChip(chip, int.Parse((string)chip.Tag) == blocker.Settings.TimerSeconds);
            string phrase = blocker.Settings.TrimmedPhrase;
            PhraseText.Text = phrase.Length == 0 ? "off" : phrase;

            var summary = blocker.LastSummary;
            SummaryCard.Visibility = Show(!locked && summary != null);
            HintText.Visibility = Show(locked || summary == null);
            HintText.Text = locked
                ? "Releases by itself if your PC locks or sleeps"
                : $"Press {KeyboardBlocker.ShortcutLabel} to lock from anywhere";
            if (summary != null) FillSummary(summary);

            bool timed = locked && blocker.EndsAt != null;
            Ring.Visibility = Show(timed);
            RingTrack.Visibility = Show(timed);
            SetPulse(locked && !timed);
            if (timed) countdown.Start(); else countdown.Stop();
            UpdateCountdown();
        }

        static Visibility Show(bool visible) => visible ? Visibility.Visible : Visibility.Collapsed;

        string TitleFor(bool locked, LockMode mode)
        {
            if (locked)
            {
                if (blocker.PawTriggered) return "Caught a paw.";
                return mode == LockMode.Clean ? "Wipe away." : "Paws off.";
            }
            return mode == LockMode.Clean ? "Ready to clean?" : "Stepping away?";
        }

        string SubtitleFor(bool locked, LockMode mode)
        {
            string phrase = blocker.Settings.TrimmedPhrase;
            string hint = phrase.Length == 0
                ? "Click the button when you're back."
                : $"Type “{phrase}” or click the button when you're back.";
            if (locked)
            {
                if (blocker.PawTriggered) return "Something walked across your keyboard, so it's locked now. " + hint;
                if (mode == LockMode.Clean)
                    return blocker.EndsAt != null
                        ? "Every key is ignored. It unlocks by itself when the timer runs out."
                        : "Every key is ignored. Click the button with your mouse when you're done.";
                return "Nothing gets typed while you're gone. " + hint;
            }
            return mode == LockMode.Clean
                ? "Lock the keyboard while you wipe it down. Your mouse stays on so you can unlock."
                : "Leave your PC running without curious paws typing into it.";
        }

        void FillSummary(LockSummary s)
        {
            SummaryHeadline.Text = s.PawTriggered ? "🐾  Paws detected while you were away"
                : s.Mode == LockMode.Away ? "Welcome back" : "✓  All clean";
            SummaryDetail.Text = $"{s.Keys} key{(s.Keys == 1 ? "" : "s")} stopped in {Format(s.Duration)}";
            SummaryReason.Text = s.Reason == null ? "" : $"{s.Reason}, so it unlocked by itself";
            SummaryReason.Visibility = Show(s.Reason != null);
        }

        static string Format(TimeSpan t)
        {
            if (t.TotalSeconds < 60) return $"{Math.Max(1, (int)t.TotalSeconds)} sec";
            if (t.TotalHours < 1) return $"{(int)t.TotalMinutes} min";
            return $"{(int)t.TotalHours} hr, {t.Minutes} min";
        }

        void UpdateCountdown()
        {
            int keys = blocker.KeysCaught;
            string caught = $"{keys} key{(keys == 1 ? "" : "s")} caught";
            if (blocker.IsActive && blocker.EndsAt is DateTime end && blocker.LockedAt is DateTime start)
            {
                double total = (end - start).TotalSeconds;
                double left = Math.Max(0, (end - DateTime.Now).TotalSeconds);
                double fraction = total > 0 ? left / total : 0;
                Ring.StrokeDashArray = new DoubleCollection { fraction * RingCircumference, 1000 };
                Ring.Opacity = fraction > 0 ? 1 : 0;
                int secs = (int)Math.Ceiling(left);
                LockedInfoText.Text = $"{caught}  ·  {secs / 60}:{secs % 60:00} left";
            }
            else
            {
                LockedInfoText.Text = caught;
            }
        }

        static void SetTab(Button tab, bool selected)
        {
            tab.Background = new SolidColorBrush(selected ? Color.FromArgb(0x24, 255, 255, 255) : Colors.Transparent);
            tab.BorderBrush = new SolidColorBrush(selected ? Color.FromArgb(0x1F, 255, 255, 255) : Colors.Transparent);
            tab.Foreground = new SolidColorBrush(Color.FromArgb(selected ? (byte)0xF2 : (byte)0x80, 255, 255, 255));
        }

        static void SetChip(Button chip, bool selected)
        {
            chip.Background = new SolidColorBrush(Color.FromArgb(selected ? (byte)0x29 : (byte)0x0D, 255, 255, 255));
            chip.BorderBrush = new SolidColorBrush(Color.FromArgb(selected ? (byte)0x40 : (byte)0x1A, 255, 255, 255));
            chip.Foreground = new SolidColorBrush(Color.FromArgb(selected ? (byte)0xF2 : (byte)0x8C, 255, 255, 255));
        }

        /// Breathing halo while locked without a timer.
        void SetPulse(bool on)
        {
            if (on == pulsing) return;
            pulsing = on;
            if (on)
            {
                var duration = TimeSpan.FromSeconds(1.8);
                var ease = new QuadraticEase { EasingMode = EasingMode.EaseOut };
                var grow = new DoubleAnimation(1, 1.12, duration) { RepeatBehavior = RepeatBehavior.Forever, EasingFunction = ease };
                var fade = new DoubleAnimation(0.8, 0, duration) { RepeatBehavior = RepeatBehavior.Forever, EasingFunction = ease };
                HaloScale.BeginAnimation(ScaleTransform.ScaleXProperty, grow);
                HaloScale.BeginAnimation(ScaleTransform.ScaleYProperty, grow);
                Halo.BeginAnimation(OpacityProperty, fade);
            }
            else
            {
                HaloScale.BeginAnimation(ScaleTransform.ScaleXProperty, null);
                HaloScale.BeginAnimation(ScaleTransform.ScaleYProperty, null);
                Halo.BeginAnimation(OpacityProperty, null);
                Halo.Opacity = 0;
            }
        }

        // MARK: Settings panel

        public void OpenSettings()
        {
            PhraseBox.Text = blocker.Settings.UnlockPhrase;
            PawSwitch.IsChecked = blocker.Settings.PawDetection;
            LoginSwitch.IsChecked = blocker.Settings.LaunchAtLogin;
            ShortcutText.Text = KeyboardBlocker.ShortcutLabel;
            var v = Assembly.GetExecutingAssembly().GetName().Version;
            CreditText.Text = $"Made by Zaid · v{v.Major}.{v.Minor}.{v.Build}";
            SettingsOverlay.Visibility = Visibility.Visible;
        }

        void OnSettings(object sender, RoutedEventArgs e) => OpenSettings();

        void OnSettingsDone(object sender, RoutedEventArgs e)
        {
            SettingsOverlay.Visibility = Visibility.Collapsed;
            Refresh();
        }

        /// The phrase is matched from key codes, so only letters, digits and spaces can be typed.
        void OnPhraseChanged(object sender, TextChangedEventArgs e)
        {
            string clean = new string(PhraseBox.Text.ToLowerInvariant().Where(c => (c >= 'a' && c <= 'z') || char.IsDigit(c) || c == ' ').ToArray());
            if (clean != PhraseBox.Text)
            {
                PhraseBox.Text = clean;
                PhraseBox.CaretIndex = clean.Length;
                return;
            }
            blocker.Settings.UnlockPhrase = clean;
        }

        void OnPawSwitch(object sender, RoutedEventArgs e) => blocker.Settings.PawDetection = PawSwitch.IsChecked == true;

        void OnLoginSwitch(object sender, RoutedEventArgs e)
        {
            try
            {
                blocker.Settings.LaunchAtLogin = LoginSwitch.IsChecked == true;
            }
            catch (Exception)
            {
                LoginSwitch.IsChecked = blocker.Settings.LaunchAtLogin;
            }
        }

        // MARK: Actions

        void OnBigButton(object sender, RoutedEventArgs e) => blocker.Toggle();

        void OnBigButtonHover(object sender, MouseEventArgs e)
        {
            double to = BigButton.IsMouseOver ? 1.03 : 1;
            var spring = new DoubleAnimation(to, TimeSpan.FromMilliseconds(220)) { EasingFunction = new BackEase { Amplitude = 0.4, EasingMode = EasingMode.EaseOut } };
            BigScale.BeginAnimation(ScaleTransform.ScaleXProperty, spring);
            BigScale.BeginAnimation(ScaleTransform.ScaleYProperty, spring);
        }

        void OnCleanTab(object sender, RoutedEventArgs e) => SetMode(LockMode.Clean);
        void OnAwayTab(object sender, RoutedEventArgs e) => SetMode(LockMode.Away);

        void SetMode(LockMode mode)
        {
            blocker.Settings.Mode = mode;
            Refresh();
        }

        void OnChip(object sender, RoutedEventArgs e)
        {
            blocker.Settings.TimerSeconds = int.Parse((string)((Button)sender).Tag);
            Refresh();
        }

        void OnDrag(object sender, MouseButtonEventArgs e)
        {
            if (e.ButtonState == MouseButtonState.Pressed) DragMove();
        }

        void OnMinimize(object sender, RoutedEventArgs e) => WindowState = WindowState.Minimized;

        void OnClose(object sender, RoutedEventArgs e) => Hide();

        protected override void OnClosing(CancelEventArgs e)
        {
            if (!AllowClose)
            {
                e.Cancel = true;
                Hide();
                return;
            }
            countdown.Stop();
            blocker.Changed -= Refresh;
            base.OnClosing(e);
        }
    }
}

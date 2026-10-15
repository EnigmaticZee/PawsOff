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
using Microsoft.Win32;

namespace PawsOff
{
    public partial class MainWindow : Window
    {
        const double RingCircumference = Math.PI * 212 / 3; // in stroke-thickness units, for StrokeDashArray

        readonly KeyboardBlocker blocker;
        readonly bool? forcedDark; // previews render a fixed theme
        readonly DispatcherTimer countdown = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(100) };
        bool pulsing;
        bool dark;

        /// Closing hides to the tray unless the app is quitting.
        public bool AllowClose { get; set; }

        public MainWindow(KeyboardBlocker blocker, bool? forcedDark = null)
        {
            InitializeComponent();
            this.blocker = blocker;
            this.forcedDark = forcedDark;
            blocker.Changed += Refresh;
            countdown.Tick += (s, e) => UpdateCountdown();
            if (forcedDark == null) SystemEvents.UserPreferenceChanged += OnSystemPreferenceChanged;
            ApplyTheme();
        }

        static string Spaced(string text) => string.Join(" ", text.ToCharArray());

        static Visibility Show(bool visible) => visible ? Visibility.Visible : Visibility.Collapsed;

        // MARK: Theme

        void ApplyTheme()
        {
            dark = forcedDark ?? blocker.Settings.UsesDarkTheme;
            Theme.Apply(Resources, dark);
            Refresh();
        }

        /// Follows the Windows light/dark switch live while the theme is Auto.
        void OnSystemPreferenceChanged(object sender, UserPreferenceChangedEventArgs e)
        {
            if (e.Category == UserPreferenceCategory.General)
                Dispatcher.BeginInvoke(new Action(ApplyTheme));
        }

        // MARK: State → UI

        void Refresh()
        {
            bool locked = blocker.IsActive;
            var mode = locked ? blocker.ActiveMode : blocker.Settings.Mode;
            var accent = locked ? Theme.Locked : Theme.Idle;
            var gradient = new LinearGradientBrush(accent[0], accent[1], new Point(0, 0), new Point(1, 1));

            Disc.Fill = gradient;
            Halo.Stroke = gradient;
            Ring.Stroke = gradient;
            DiscShadow.Color = accent[1];
            DiscShadow.Opacity = dark ? 0.55 : 0.4;
            double glow = (double)Resources["GlowStrength"];
            Glow1.Fill = Theme.Glow(accent[0], glow);
            Glow2.Fill = Theme.Glow(accent[1], glow);

            SetSelected(CleanTab, mode == LockMode.Clean, segmented: true);
            SetSelected(AwayTab, mode == LockMode.Away, segmented: true);
            ModePicker.Opacity = locked ? 0.45 : 1;
            ModePicker.IsEnabled = !locked;
            bool settingsOpen = SettingsPage.Visibility == Visibility.Visible;
            SettingsButton.Visibility = locked || settingsOpen ? Visibility.Hidden : Visibility.Visible;

            StatusLabel.Text = Spaced(locked ? (blocker.PawTriggered ? "PAWS DETECTED" : "KEYBOARD LOCKED") : "KEYBOARD ACTIVE");
            KeyboardGlyph.Visibility = Show(mode == LockMode.Clean);
            PawGlyph.Visibility = Show(mode == LockMode.Away);
            ButtonLabel.Text = Spaced(locked ? "UNLOCK" : "LOCK");

            TitleText.Text = TitleFor(locked, mode);
            SubtitleText.Text = SubtitleFor(locked, mode);

            TimerChips.Visibility = Show(!locked && mode == LockMode.Clean);
            PhraseRow.Visibility = Show(!locked && mode == LockMode.Away);
            LockedInfo.Visibility = Show(locked);
            LockedInfoIcon.Data = (Geometry)FindResource(mode == LockMode.Away ? "PawGeometry" : "SparkleGeometry");
            foreach (var chip in TimerChips.Children.OfType<Button>())
                SetSelected(chip, int.Parse((string)chip.Tag) == blocker.Settings.TimerSeconds, segmented: false);
            foreach (var choice in ThemeButtons.Children.OfType<Button>())
                SetSelected(choice, (string)choice.Tag == blocker.Settings.Theme.ToString(), segmented: true);
            string phrase = blocker.Settings.TrimmedPhrase;
            PhraseText.Text = phrase.Length == 0 ? "off" : phrase;

            var summary = blocker.LastSummary;
            SummaryCard.Visibility = Show(!locked && summary != null);
            Hint.Visibility = Show(locked || summary == null);
            HintIcon.Text = locked ? "" : ""; // unlock / keyboard
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
            SummaryPaw.Visibility = Show(s.PawTriggered);
            CheckIcon.Visibility = Show(!s.PawTriggered);
            SummaryHeadline.Text = s.PawTriggered ? "Paws detected while you were away"
                : s.Mode == LockMode.Away ? "Welcome back" : "All clean";
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

        /// Tabs, chips and theme buttons share one selected look, drawn from the theme.
        /// In a segmented pill the unselected options are see-through; chips keep a faint fill.
        static void SetSelected(Button button, bool selected, bool segmented)
        {
            button.SetResourceReference(ForegroundProperty, selected ? "TextBody" : "TextMuted");
            if (!selected && segmented)
            {
                button.Background = Brushes.Transparent;
                button.BorderBrush = Brushes.Transparent;
                return;
            }
            button.SetResourceReference(BackgroundProperty, selected ? "SelectedFill" : "Fill1");
            button.SetResourceReference(BorderBrushProperty, selected ? "SelectedStroke" : "Stroke1");
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

        // MARK: Settings page

        public void OpenSettings(bool animate = true)
        {
            PhraseBox.Text = blocker.Settings.UnlockPhrase;
            PawSwitch.IsChecked = blocker.Settings.PawDetection;
            LoginSwitch.IsChecked = blocker.Settings.LaunchAtLogin;
            ShortcutText.Text = KeyboardBlocker.ShortcutLabel;
            var v = Assembly.GetExecutingAssembly().GetName().Version;
            CreditText.Text = $"Made by Zaid · v{v.Major}.{v.Minor}.{v.Build}";
            SettingsPage.Visibility = Visibility.Visible;
            Slide(0, animate, null);
            Refresh();
        }

        void CloseSettings()
        {
            Slide(380, true, () =>
            {
                SettingsPage.Visibility = Visibility.Collapsed;
                Refresh();
            });
        }

        void Slide(double to, bool animate, Action done)
        {
            if (!animate)
            {
                SettingsSlide.BeginAnimation(TranslateTransform.XProperty, null);
                SettingsSlide.X = to;
                done?.Invoke();
                return;
            }
            var slide = new DoubleAnimation(to, TimeSpan.FromMilliseconds(240)) { EasingFunction = new CubicEase { EasingMode = EasingMode.EaseOut } };
            if (done != null) slide.Completed += (s, e) => done();
            SettingsSlide.BeginAnimation(TranslateTransform.XProperty, slide);
        }

        void OnSettings(object sender, RoutedEventArgs e) => OpenSettings();

        void OnSettingsDone(object sender, RoutedEventArgs e) => CloseSettings();

        void OnThemeChoice(object sender, RoutedEventArgs e)
        {
            blocker.Settings.Theme = (ThemeChoice)Enum.Parse(typeof(ThemeChoice), (string)((Button)sender).Tag);
            ApplyTheme();
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
            if (forcedDark == null) SystemEvents.UserPreferenceChanged -= OnSystemPreferenceChanged;
            base.OnClosing(e);
        }
    }
}

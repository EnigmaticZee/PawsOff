using System;
using System.Linq;
using System.Threading;
using System.Windows;

namespace PawsOff
{
    public partial class App : Application
    {
        const string InstanceName = "PawsOff.SingleInstance";
        const string ShowSignalName = "PawsOff.ShowWindow";

        Mutex instanceMutex;
        EventWaitHandle showSignal;
        KeyboardBlocker blocker;
        TrayIcon tray;
        MainWindow window;
        TrayPanel panel;

        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);
            var args = e.Args;

            // `PawsOff.exe --render-previews <dir>` writes PNGs of every UI state and exits.
            int i = Array.IndexOf(args, "--render-previews");
            if (i >= 0 && i + 1 < args.Length)
            {
                PreviewRenderer.RenderAll(args[i + 1]);
                Shutdown(0);
                return;
            }

            // One copy at a time: a second launch just brings the first window forward.
            instanceMutex = new Mutex(true, InstanceName, out bool firstInstance);
            showSignal = new EventWaitHandle(false, EventResetMode.AutoReset, ShowSignalName);
            if (!firstInstance)
            {
                showSignal.Set();
                Shutdown(0);
                return;
            }
            var listener = new Thread(() =>
            {
                while (showSignal.WaitOne())
                    Dispatcher.BeginInvoke(new Action(ShowWindow));
            }) { IsBackground = true };
            listener.Start();

            var settings = Settings.Load();
            ThemeManager.Init(settings);
            blocker = new KeyboardBlocker(settings, Dispatcher);
            window = new MainWindow(blocker);
            panel = new TrayPanel(blocker);
            window.Card.QuitRequested += Quit;
            panel.Card.QuitRequested += Quit;
            panel.Card.OpenWindowRequested += () => { panel.HidePanel(); ShowWindow(); };
            tray = new TrayIcon(blocker, ShowWindow, panel.Toggle, Quit);

            // Automatic updates: check now (if it's been a day) and every few hours after that, and
            // install a new version straight away unless the keyboard is locked (then on a later check).
            Updater.QuitApp = Quit;
            Updater.Found += version =>
            {
                if (settings.AutoUpdate && !blocker.IsActive) _ = Updater.InstallAsync();
                else tray.Announce($"Paws Off {version} is available",
                    "Open Paws Off's settings to update.", () => { ShowWindow(); window.Card.OpenSettings(); });
            };
            _ = Updater.CheckAsync(settings);

            // The first time Paws Off starts in the tray, say where it lives.
            if (!args.Contains("--minimized") && !settings.IsFirstRun && settings.StartIn == StartPlace.Tray && !settings.ShownTrayTip)
            {
                settings.ShownTrayTip = true;
                tray.Announce("Paws Off lives in your system tray", "Click the paw to lock your keyboard. Right-click for quick actions.");
            }
            var daily = new System.Windows.Threading.DispatcherTimer { Interval = TimeSpan.FromHours(6) };
            daily.Tick += async (s, e) =>
            {
                await Updater.CheckAsync(settings);
                if (Updater.AvailableVersion != null && settings.AutoUpdate && !blocker.IsActive) await Updater.InstallAsync();
            };
            daily.Start();

            // Signing in (--minimized) starts quietly. Otherwise open where the user chose: the window,
            // or the tray pop-up so it's clear where Paws Off lives. The very first run opens the window.
            if (!args.Contains("--minimized"))
            {
                if (settings.IsFirstRun || settings.StartIn == StartPlace.Window) window.Show();
                else panel.ShowNearTray();
                settings.StartIn = settings.StartIn; // saves the key, so later runs aren't "first"
            }
        }

        void ShowWindow()
        {
            window.Show();
            if (window.WindowState == WindowState.Minimized)
                window.WindowState = WindowState.Normal;
            window.Activate();
        }

        void Quit()
        {
            window.AllowClose = true;
            window.Close();
            panel.AllowClose = true;
            panel.Close();
            tray.Dispose();
            blocker.Dispose();
            Shutdown(0);
        }

        protected override void OnExit(ExitEventArgs e)
        {
            tray?.Dispose();
            blocker?.Dispose();
            instanceMutex?.Dispose();
            base.OnExit(e);
        }
    }
}

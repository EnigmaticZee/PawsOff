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

            blocker = new KeyboardBlocker(Settings.Load(), Dispatcher);
            window = new MainWindow(blocker);
            tray = new TrayIcon(blocker, ShowWindow, Quit);

            if (!args.Contains("--minimized"))
                window.Show();
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

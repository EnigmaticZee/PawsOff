using System;
using System.Drawing;
using System.Windows;
using Forms = System.Windows.Forms;

namespace PawsOff
{
    /// The paw in the notification area: lock, unlock, show the window or quit.
    sealed class TrayIcon : IDisposable
    {
        readonly KeyboardBlocker blocker;
        readonly Forms.NotifyIcon icon;
        readonly Forms.ToolStripMenuItem status, lockClean, lockAway, unlock;

        public TrayIcon(KeyboardBlocker blocker, Action showWindow, Action quit)
        {
            this.blocker = blocker;

            var stream = Application.GetResourceStream(new Uri("pack://application:,,,/Assets/PawsOff.ico")).Stream;
            icon = new Forms.NotifyIcon
            {
                Icon = new Icon(stream, Forms.SystemInformation.SmallIconSize),
                Text = "Paws Off",
                Visible = true,
            };

            status = new Forms.ToolStripMenuItem { Enabled = false };
            lockClean = new Forms.ToolStripMenuItem("Lock for Cleaning", null, (s, e) => blocker.Start(LockMode.Clean));
            lockAway = new Forms.ToolStripMenuItem("Lock While Away", null, (s, e) => blocker.Start(LockMode.Away));
            unlock = new Forms.ToolStripMenuItem("Unlock Keyboard", null, (s, e) => blocker.Stop());

            var menu = new Forms.ContextMenuStrip();
            menu.Items.AddRange(new Forms.ToolStripItem[]
            {
                status,
                new Forms.ToolStripSeparator(),
                lockClean,
                lockAway,
                unlock,
                new Forms.ToolStripSeparator(),
                new Forms.ToolStripMenuItem("Show Paws Off", null, (s, e) => showWindow()),
                new Forms.ToolStripMenuItem("Quit Paws Off", null, (s, e) => quit()),
            });
            menu.Opening += (s, e) => Update();
            icon.ContextMenuStrip = menu;
            icon.MouseClick += (s, e) =>
            {
                if (e.Button == Forms.MouseButtons.Left) showWindow();
            };

            blocker.Changed += Update;
            blocker.PawsDetected += () =>
            {
                string phrase = blocker.Settings.TrimmedPhrase;
                icon.ShowBalloonTip(4000, "Paws detected 🐾",
                    phrase.Length > 0 ? $"Keyboard locked. Type “{phrase}” to release it." : "Keyboard locked. Click Unlock to release it.",
                    Forms.ToolTipIcon.None);
            };
            Update();
        }

        void Update()
        {
            bool locked = blocker.IsActive;
            status.Text = locked ? $"Keyboard locked · {blocker.KeysCaught} keys caught" : "Keyboard active";
            lockClean.Visible = !locked;
            lockAway.Visible = !locked;
            unlock.Visible = locked;
            icon.Text = locked ? "Paws Off — keyboard locked" : "Paws Off";
        }

        public void Dispose()
        {
            icon.Visible = false;
            icon.Dispose();
        }
    }
}

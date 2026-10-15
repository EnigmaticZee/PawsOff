using System;
using System.ComponentModel;
using System.Windows;

namespace PawsOff
{
    /// The tray pop-up: the shared card, shown just above the notification area.
    public partial class TrayPanel : Window
    {
        public CardView Card { get; }
        public bool AllowClose { get; set; }
        DateTime hiddenAt = DateTime.MinValue;

        public TrayPanel(KeyboardBlocker blocker)
        {
            InitializeComponent();
            Card = new CardView(blocker, isPanel: true);
            CardHost.Content = Card;
            Deactivated += (s, e) => HidePanel();
        }

        /// Left-click on the tray icon: show, or hide if it's already open.
        public void Toggle()
        {
            // Clicking the tray icon deactivates the pop-up first; don't reopen it straight away.
            if (IsVisible) { HidePanel(); return; }
            if ((DateTime.Now - hiddenAt).TotalMilliseconds < 300) return;
            ShowNearTray();
        }

        void ShowNearTray()
        {
            var area = SystemParameters.WorkArea; // the screen minus the taskbar
            Left = area.Right - Width + 2;
            Top = area.Bottom - Height + 2;
            Show();
            Activate();
        }

        public void HidePanel()
        {
            if (!IsVisible) return;
            hiddenAt = DateTime.Now;
            Hide();
        }

        protected override void OnClosing(CancelEventArgs e)
        {
            if (!AllowClose)
            {
                e.Cancel = true;
                HidePanel();
                return;
            }
            Card.Detach();
            base.OnClosing(e);
        }
    }
}

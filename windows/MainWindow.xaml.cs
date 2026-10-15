using System;
using System.ComponentModel;
using System.Windows;
using System.Windows.Input;

namespace PawsOff
{
    /// The app window: a slim title row above the shared card.
    public partial class MainWindow : Window
    {
        public CardView Card { get; }

        /// Closing hides to the tray unless the app is quitting.
        public bool AllowClose { get; set; }

        public MainWindow(KeyboardBlocker blocker, bool showingSettings = false)
        {
            InitializeComponent();
            Card = new CardView(blocker, isPanel: false, showingSettings: showingSettings);
            CardHost.Content = Card;
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
            Card.Detach();
            base.OnClosing(e);
        }
    }
}

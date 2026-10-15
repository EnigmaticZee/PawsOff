using System.IO;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace PawsOff
{
    /// Off-screen renders of the card in every state, the app window and the tray pop-up, in dark
    /// and light, so the interface can be checked without a screen (CI uploads them as the
    /// windows-previews artifact).
    static class PreviewRenderer
    {
        public static void RenderAll(string dir)
        {
            Directory.CreateDirectory(dir);
            foreach (var dark in new[] { true, false })
            {
                ThemeManager.Force(dark);
                string theme = dark ? "dark" : "light";
                int index = 1;
                foreach (var state in KeyboardBlocker.PreviewStates)
                    RenderCard(new CardView(KeyboardBlocker.Preview(state), isPanel: false), Path.Combine(dir, $"{theme}-{index++}-{state}.png"));
                RenderCard(new CardView(KeyboardBlocker.Preview("cleanReady"), isPanel: false, showingSettings: true),
                           Path.Combine(dir, $"{theme}-{index++}-settings.png"));

                var window = new MainWindow(KeyboardBlocker.Preview("awayReady")) { Left = -10000, Top = -10000, ShowActivated = false, ShowInTaskbar = false };
                window.Show();
                window.UpdateLayout();
                Save(window.RootGrid, Path.Combine(dir, $"{theme}-{index++}-window.png"));
                window.AllowClose = true;
                window.Close();

                var panel = new TrayPanel(KeyboardBlocker.Preview("cleanReady")) { Left = -10000, Top = -10000, ShowActivated = false };
                panel.Show();
                panel.UpdateLayout();
                Save((FrameworkElement)panel.Content, Path.Combine(dir, $"{theme}-{index}-tray-panel.png"), panel.Width, panel.Height);
                panel.AllowClose = true;
                panel.Close();
            }
        }

        static void RenderCard(CardView card, string path)
        {
            card.Measure(new Size(card.Width, card.Height));
            card.Arrange(new Rect(0, 0, card.Width, card.Height));
            card.UpdateLayout();
            Save(card, path);
            card.Detach();
        }

        /// Width/height default to the element's own size; pass the window's size for elements with
        /// an outer margin (the pop-up's shadow), so nothing is cropped.
        static void Save(FrameworkElement element, string path, double width = 0, double height = 0)
        {
            int w = (int)(width > 0 ? width : element.ActualWidth), h = (int)(height > 0 ? height : element.ActualHeight);
            var bitmap = new RenderTargetBitmap(w * 2, h * 2, 192, 192, PixelFormats.Pbgra32);
            bitmap.Render(element);
            var encoder = new PngBitmapEncoder();
            encoder.Frames.Add(BitmapFrame.Create(bitmap));
            using (var file = File.Create(path))
                encoder.Save(file);
        }
    }
}

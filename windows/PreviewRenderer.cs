using System.IO;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;

namespace PawsOff
{
    /// Off-screen renders of each UI state, so the interface can be checked without a screen
    /// (used by CI and for the README art).
    static class PreviewRenderer
    {
        public static void RenderAll(string dir)
        {
            Directory.CreateDirectory(dir);
            int index = 1;
            foreach (var state in KeyboardBlocker.PreviewStates)
                Render(KeyboardBlocker.Preview(state), false, Path.Combine(dir, $"{index++}-{state}.png"));
            Render(KeyboardBlocker.Preview("cleanReady"), true, Path.Combine(dir, $"{index}-settings.png"));
        }

        static void Render(KeyboardBlocker blocker, bool settings, string path)
        {
            var window = new MainWindow(blocker)
            {
                Left = -10000,
                Top = -10000,
                ShowActivated = false,
                ShowInTaskbar = false,
            };
            window.Show();
            if (settings) window.OpenSettings();
            window.UpdateLayout();

            var root = window.RootGrid;
            var bitmap = new RenderTargetBitmap((int)root.ActualWidth * 2, (int)root.ActualHeight * 2, 192, 192, PixelFormats.Pbgra32);
            bitmap.Render(root);
            var encoder = new PngBitmapEncoder();
            encoder.Frames.Add(BitmapFrame.Create(bitmap));
            using (var file = File.Create(path))
                encoder.Save(file);

            window.AllowClose = true;
            window.Close();
        }
    }
}

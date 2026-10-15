using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Reflection;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace PawsOff
{
    /// Automatic updates: asks GitHub for the latest release (about once a day, if the user leaves
    /// that on) and, when there's a newer one, downloads its installer and runs it quietly. Nothing
    /// is sent except the request for the release page.
    public static class Updater
    {
        const string LatestRelease = "https://api.github.com/repos/EnigmaticZee/PawsOff/releases/latest";
        const string InstallerName = "PawsOff-Windows-Setup.exe";

        public static event Action Changed;
        /// Shown once per new version as a tray notification.
        public static event Action<Version> Found;

        public static Version AvailableVersion { get; private set; }
        public static bool Busy { get; private set; }
        static string installerUrl;

        /// Quits the app so the installer can replace it; set by App.
        public static Action QuitApp;

        static readonly HttpClient Http = MakeClient();

        static HttpClient MakeClient()
        {
            ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12;
            var client = new HttpClient { Timeout = TimeSpan.FromSeconds(30) };
            client.DefaultRequestHeaders.UserAgent.ParseAdd("PawsOff-Updater");
            return client;
        }

        public static Version Current
        {
            get
            {
                var v = Assembly.GetExecutingAssembly().GetName().Version;
                return new Version(v.Major, v.Minor, Math.Max(0, v.Build));
            }
        }

        /// Checks if it's been more than a day (or if forced). Failures are silent: offline is fine.
        public static async Task CheckAsync(Settings settings, bool force = false)
        {
            if (Busy) return;
            if (!force && (!settings.AutoUpdate || (DateTime.UtcNow - settings.LastUpdateCheck).TotalHours < 20)) return;
            Busy = true;
            Changed?.Invoke();
            try
            {
                string json = await Http.GetStringAsync(LatestRelease);
                settings.LastUpdateCheck = DateTime.UtcNow;
                var tag = Regex.Match(json, "\"tag_name\"\\s*:\\s*\"v?([0-9.]+)\"").Groups[1].Value;
                var url = Regex.Match(json, "\"browser_download_url\"\\s*:\\s*\"([^\"]*" + Regex.Escape(InstallerName) + ")\"").Groups[1].Value;
                if (Version.TryParse(tag, out var latest) && url.Length > 0 && latest > Current)
                {
                    bool isNew = AvailableVersion == null || latest > AvailableVersion;
                    AvailableVersion = latest;
                    installerUrl = url;
                    if (isNew && settings.LastAnnouncedVersion != latest.ToString())
                    {
                        settings.LastAnnouncedVersion = latest.ToString();
                        Found?.Invoke(latest);
                    }
                }
            }
            catch (Exception)
            {
                // Offline or GitHub unavailable: try again next time.
            }
            finally
            {
                Busy = false;
                Changed?.Invoke();
            }
        }

        /// Downloads the new installer, starts it quietly and quits so it can replace this copy.
        /// The installer relaunches Paws Off when it's done.
        public static async Task InstallAsync()
        {
            if (installerUrl == null || Busy) return;
            Busy = true;
            Changed?.Invoke();
            try
            {
                string path = Path.Combine(Path.GetTempPath(), $"PawsOff-Setup-{AvailableVersion}.exe");
                byte[] bytes = await Http.GetByteArrayAsync(installerUrl);
                File.WriteAllBytes(path, bytes);
                Process.Start(new ProcessStartInfo(path, "/SILENT /NORESTART /CLOSEAPPLICATIONS") { UseShellExecute = true });
                QuitApp?.Invoke();
            }
            catch (Exception)
            {
                Busy = false;
                Changed?.Invoke();
            }
        }
    }
}

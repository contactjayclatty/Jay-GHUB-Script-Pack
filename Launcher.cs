using System;
using System.IO;
using System.IO.Compression;
using System.Diagnostics;
using System.Reflection;
using System.Windows.Forms;
class Launcher {
    [STAThread] static void Main() {
        string temp = Path.Combine(Path.GetTempPath(), "GHUB-Script-Pack-" + Guid.NewGuid().ToString("N"));
        try {
            Directory.CreateDirectory(temp);
            using (Stream source = Assembly.GetExecutingAssembly().GetManifestResourceStream("package.zip"))
            using (FileStream dest = File.Create(Path.Combine(temp, "package.zip"))) { source.CopyTo(dest); }
            ZipFile.ExtractToDirectory(Path.Combine(temp, "package.zip"), temp);
            string shell = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), "WindowsPowerShell", "v1.0", "powershell.exe");
            ProcessStartInfo info = new ProcessStartInfo(shell, "-NoProfile -STA -ExecutionPolicy Bypass -File \"" + Path.Combine(temp, "Installer.ps1") + "\"");
            info.UseShellExecute = false;
            info.CreateNoWindow = true;
            using (Process proc = Process.Start(info)) {
                proc.WaitForExit();
                if (proc.ExitCode != 0) MessageBox.Show("The installer could not finish. No success is confirmed. Use the included source package for diagnostics.", "G HUB Script Pack");
            }
        } catch (Exception ex) { MessageBox.Show(ex.Message, "G HUB Script Pack"); }
        finally {
            try { if (Directory.Exists(temp)) Directory.Delete(temp, true); } catch { }
        }
    }
}

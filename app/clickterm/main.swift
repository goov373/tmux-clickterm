import Cocoa

// App entry point
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Install scripts on first run
        installScriptsIfNeeded()
        
        // Launch iTerm with tmux
        launchiTermWithTmux()
        
        // Keep app running to maintain Dock presence
        NSApp.setActivationPolicy(.regular)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // User clicked Dock icon again - launch/attach to clickterm session
        launchiTermWithTmux()
        return true
    }
    
    // MARK: - Script Installation
    
    private func installScriptsIfNeeded() {
        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/clickterm")
        
        // Check if already installed
        if FileManager.default.fileExists(atPath: configDir.path) {
            return
        }
        
        // Get bundled scripts
        guard let resourcePath = Bundle.main.resourcePath else { return }
        let scriptsPath = URL(fileURLWithPath: resourcePath).appendingPathComponent("scripts")
        
        do {
            try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
            
            let fileManager = FileManager.default
            let scripts = try fileManager.contentsOfDirectory(atPath: scriptsPath.path)
            
            for script in scripts {
                let source = scriptsPath.appendingPathComponent(script)
                let dest = configDir.appendingPathComponent(script)
                try fileManager.copyItem(at: source, to: dest)
                
                // Make executable
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dest.path)
            }
            
            // Install tmux.conf
            let tmuxConf = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".tmux.conf")
            let bundledConf = URL(fileURLWithPath: resourcePath).appendingPathComponent("tmux.conf")
            
            if FileManager.default.fileExists(atPath: bundledConf.path) {
                if FileManager.default.fileExists(atPath: tmuxConf.path) {
                    // Backup existing
                    let backup = tmuxConf.deletingPathExtension().appendingPathExtension("conf.backup")
                    try? fileManager.moveItem(at: tmuxConf, to: backup)
                }
                try fileManager.copyItem(at: bundledConf, to: tmuxConf)
            }
            
        } catch {
            print("Failed to install scripts: \(error)")
        }
    }
    
    // MARK: - iTerm Integration
    
    private func launchiTermWithTmux() {
        // AppleScript to launch iTerm with tmux session
        let appleScript = """
        tell application "iTerm"
            activate
            
            -- Check if we need a new window or can use existing
            if (count of windows) = 0 then
                create window with default profile
            end if
            
            tell current session of current window
                write text "cd ~/Developers/tmux-clickterm && if tmux has-session -t clickterm 2>/dev/null; then tmux attach-session -t clickterm; else tmux new-session -d -s clickterm && tmux send-keys -t clickterm '~/.config/clickterm/clickterm-shell.sh' Enter && tmux attach-session -t clickterm; fi"
            end tell
        end tell
        """
        
        var error: NSDictionary?
        if let script = NSAppleScript(source: appleScript) {
            script.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript error: \(error)")
            }
        }
    }
}

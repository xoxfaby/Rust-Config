[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')       | out-null
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework')      | out-null
[System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')          | out-null
[System.Reflection.Assembly]::LoadWithPartialName('WindowsFormsIntegration') | out-null


$icon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Windows\System32\WorkFolders.exe")    
$Main_Tool_Icon = New-Object System.Windows.Forms.NotifyIcon
$Main_Tool_Icon.Text = "GitFileWatcher $PSScriptRoot"
$Main_Tool_Icon.Icon = $icon
$Main_Tool_Icon.Visible = $true

$Menu_Exit = New-Object System.Windows.Forms.MenuItem
$Menu_Exit.Text = "Exit"

$contextmenu = New-Object System.Windows.Forms.ContextMenu
$Main_Tool_Icon.ContextMenu = $contextmenu
$Main_Tool_Icon.contextMenu.MenuItems.AddRange($Menu_Exit)

# When Exit is clicked, close everything and kill the PowerShell process
$Menu_Exit.add_Click({
    $Main_Tool_Icon.Visible = $false
    $window.Close()
    Stop-Job -Name "keepAwake"
    Stop-Process $pid
 })

 
### HIDE SCRIPT AFTER LAUNCH
$windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
$asyncwindow = Add-Type -MemberDefinition $windowcode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
$null = $asyncwindow::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0)

### SET FOLDER TO WATCH + FILES TO WATCH + SUBFOLDERS YES/NO
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $PSScriptRoot
    $watcher.Filter = "*.*"
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true  

### DEFINE ACTIONS AFTER AN EVENT IS DETECTED
    $action = {
        $name = $Event.SourceEventArgs.Name 
        if(-Not $name.StartsWith(".git"))
        {
            $changeType = $Event.SourceEventArgs.ChangeType
            $commitMessage = "$(Get-Date), File $changeType, $name"
            git add .
            git commit -m $commitMessage
            git push
        }
    }    
### DECIDE WHICH EVENTS SHOULD BE WATCHED 
    Register-ObjectEvent $watcher "Created" -Action $action
    Register-ObjectEvent $watcher "Changed" -Action $action
    Register-ObjectEvent $watcher "Deleted" -Action $action
    Register-ObjectEvent $watcher "Renamed" -Action $action


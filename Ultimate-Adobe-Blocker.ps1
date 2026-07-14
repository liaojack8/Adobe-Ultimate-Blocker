<#
.SYNOPSIS
Ultimate Adobe Blocker
Integrates community-maintained hosts and aggressive firewall rules to block all Adobe telemetry and updates, including Acrobat.
#>

# Ensure Admin Rights
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   Adobe Ultimate Blocker & Optimizer" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

function Update-HostsFile {
    $hostsFilePath = "$env:SystemRoot\System32\drivers\etc\hosts"
    $backupFilePath = "$env:SystemRoot\System32\drivers\etc\hosts.bak"
    
    # URL1: Original Author (Extremely accurate for Adobe/Acrobat) - Synced to your repo
    $url1 = "https://raw.githubusercontent.com/liaojack8/Adobe-Ultimate-Blocker/main/ruddernation-hosts.txt"
    # URL2: Secondary Author (Massive blocklist) - Synced to your repo
    $url2 = "https://raw.githubusercontent.com/liaojack8/Adobe-Ultimate-Blocker/main/list.txt"
    # URL3: Ethanaicode (Highly active alternative) - Synced to your repo
    $url3 = "https://raw.githubusercontent.com/liaojack8/Adobe-Ultimate-Blocker/main/ethanaicode-hosts.txt"

    if (-not (Test-Path -Path $backupFilePath)) {
        Copy-Item -Path $hostsFilePath -Destination $backupFilePath -Force
        Write-Host "[Hosts] Backup created at $backupFilePath" -ForegroundColor Green
    }

    Write-Host "[Hosts] Downloading and merging blocklists..." -ForegroundColor Yellow
    $combinedList = @()
    
    try {
        $web1 = Invoke-WebRequest -Uri $url1 -UseBasicParsing
        $combinedList += $web1.Content -split "`n"
        Write-Host "[Hosts] Fetched list from Ruddernation (Original)" -ForegroundColor Green
    } catch {
        Write-Host "[Hosts] Failed to fetch list 1 from URL, trying local backup..." -ForegroundColor Yellow
        $localBackup1 = Join-Path -Path $PSScriptRoot -ChildPath "ruddernation-hosts.txt"
        if (Test-Path -Path $localBackup1) {
            $combinedList += Get-Content -Path $localBackup1
            Write-Host "[Hosts] Loaded local backup ruddernation-hosts.txt" -ForegroundColor Green
        } else {
            Write-Host "[Hosts] Local backup for list 1 not found." -ForegroundColor Red
        }
    }

    try {
        $web2 = Invoke-WebRequest -Uri $url2 -UseBasicParsing
        $combinedList += $web2.Content -split "`n"
        Write-Host "[Hosts] Fetched list from a.dove.isdumb.one" -ForegroundColor Green
    } catch {
        Write-Host "[Hosts] Failed to fetch list 2 from URL, trying local backup..." -ForegroundColor Yellow
        $localBackup2 = Join-Path -Path $PSScriptRoot -ChildPath "list.txt"
        if (Test-Path -Path $localBackup2) {
            $combinedList += Get-Content -Path $localBackup2
            Write-Host "[Hosts] Loaded local backup list.txt" -ForegroundColor Green
        } else {
            Write-Host "[Hosts] Local backup for list 2 not found." -ForegroundColor Red
        }
    }

    try {
        $web3 = Invoke-WebRequest -Uri $url3 -UseBasicParsing
        $combinedList += $web3.Content -split "`n"
        Write-Host "[Hosts] Fetched list from ethanaicode (Alternative)" -ForegroundColor Green
    } catch {
        Write-Host "[Hosts] Failed to fetch list 3 from URL, trying local backup..." -ForegroundColor Yellow
        $localBackup3 = Join-Path -Path $PSScriptRoot -ChildPath "ethanaicode-hosts.txt"
        if (Test-Path -Path $localBackup3) {
            $combinedList += Get-Content -Path $localBackup3
            Write-Host "[Hosts] Loaded local backup ethanaicode-hosts.txt" -ForegroundColor Green
        } else {
            Write-Host "[Hosts] Local backup for list 3 not found." -ForegroundColor Red
        }
    }

    $existingHosts = Get-Content -Path $hostsFilePath
    $combinedList += $existingHosts

    $uniqueEntries = [ordered]@{}
    $headerLines = [ordered]@{}
    $commentLines = [ordered]@{}
    $seenDomains = @{}

    foreach ($line in $combinedList) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $line = $line.Trim()
        
        if ($line.StartsWith("#")) {
            $commentLines[$line] = $true
            continue
        }
        
        $parts = $line -split '\s+', 2
        if ($parts.Count -ge 2) {
            $ip = $parts[0]
            $domain = $parts[1]
            if ($domain.Contains("#")) {
                $domain = ($domain -split '#')[0].Trim()
            }
            if ($ip -eq "0.0.0.0" -or $ip -eq "127.0.0.1") {
                if (-not $seenDomains.ContainsKey($domain)) {
                    $seenDomains[$domain] = $true
                    $uniqueEntries["0.0.0.0 $domain"] = $true
                }
            } else {
                if (-not $seenDomains.ContainsKey($domain)) {
                    $seenDomains[$domain] = $true
                    $uniqueEntries[$line] = $true
                }
            }
        } else {
            $headerLines[$line] = $true
        }
    }

    $finalContent = @($headerLines.Keys) + @($commentLines.Keys) + @($uniqueEntries.Keys)
    $finalContent | Out-File -FilePath $hostsFilePath -Encoding ASCII
    Write-Host "[Hosts] Hosts file updated successfully and duplicates removed." -ForegroundColor Green
    
    ipconfig /flushdns | Out-Null
    Write-Host "[Hosts] DNS Cache flushed." -ForegroundColor Green
}

function Block-AdobeFirewall {
    $folders = @(
        "C:\Program Files\Adobe",
        "C:\Program Files\Common Files\Adobe",
        "C:\Program Files (x86)\Adobe",
        "C:\Program Files (x86)\Common Files\Adobe"
    )

    Write-Host "[Firewall] Scanning for Adobe executables to block..." -ForegroundColor Yellow
    foreach ($folder in $folders) {
        if (Test-Path -Path $folder) {
            $executables = Get-ChildItem -Path $folder -Recurse -Include *.exe -ErrorAction SilentlyContinue
            foreach ($exe in $executables) {
                $exeName = [System.IO.Path]::GetFileNameWithoutExtension($exe.Name)
                $ruleName = "$exeName Ultimate-Adobe-Block"
                
                try {
                    Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue | Out-Null
                    New-NetFirewallRule -DisplayName $ruleName -Direction Outbound -Program $exe.FullName -Action Block -ErrorAction SilentlyContinue | Out-Null
                    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Program $exe.FullName -Action Block -ErrorAction SilentlyContinue | Out-Null
                    Write-Host "[Firewall] Blocked: $($exe.Name)" -ForegroundColor DarkGray
                } catch {}
            }
        }
    }
    Write-Host "[Firewall] All Adobe executables blocked in Firewall." -ForegroundColor Green
}

function Remove-AdobeServices {
    $services = @(
        "AGSService",
        "AAMUpdater",
        "AdobeARMservice",
        "AdobeUpdateService"
    )

    Write-Host "[Services] Stopping and removing Adobe background services..." -ForegroundColor Yellow
    foreach ($svc in $services) {
        try {
            $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
            if ($service) {
                Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
                Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
                cmd.exe /c "sc delete $svc >nul 2>&1"
                Write-Host "[Services] Removed service: $svc" -ForegroundColor Green
            }
        } catch {}
    }
}

function Remove-AdobeTasks {
    Write-Host "[Tasks] Removing Adobe scheduled tasks..." -ForegroundColor Yellow
    $tasks = @(
        "Adobe Acrobat Update Task",
        "Adobe GC Update",
        "Adobe Updater Startup Utility"
    )
    foreach ($task in $tasks) {
        try {
            Unregister-ScheduledTask -TaskName $task -Confirm:$false -ErrorAction SilentlyContinue
            Write-Host "[Tasks] Removed scheduled task: $task" -ForegroundColor Green
        } catch {}
    }
}

function Clean-AdobeFolders {
    Write-Host "[Cleanup] Deleting Adobe Updater and Genuine Service folders..." -ForegroundColor Yellow
    $paths = @(
        "C:\Program Files (x86)\Common Files\Adobe\AdobeGCClient",
        "C:\Program Files (x86)\Common Files\Adobe\OOBE\PDApp\UWA",
        "C:\Program Files (x86)\Common Files\Adobe\ARM"
    )

    foreach ($p in $paths) {
        if (Test-Path -Path $p) {
            try {
                Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "[Cleanup] Deleted folder: $p" -ForegroundColor Green
            } catch {
                Write-Host "[Cleanup] Failed to delete (might be in use): $p" -ForegroundColor Red
            }
        }
    }
}

Update-HostsFile
Block-AdobeFirewall
Remove-AdobeServices
Remove-AdobeTasks
Clean-AdobeFolders

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   Done! All Adobe updates and telemetry  " -ForegroundColor Cyan
Write-Host "   have been comprehensively blocked.     " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Read-Host "Press Enter to exit..."

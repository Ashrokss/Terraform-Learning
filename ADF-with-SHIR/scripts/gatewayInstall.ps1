# Self-Hosted Integration Runtime installation script
# Ref: https://github.com/loshurik/101-vms-with-selfhost-integration-runtime
# Ref: https://pl.seequality.net/terra-adf-shir/

param(
    [string] $gatewayKey
)

$logLoc = "$env:SystemDrive\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\"
if (!(Test-Path $logLoc)) {
    New-Item -Path $logLoc -ItemType Directory -Force
}
$logPath = "$logLoc\tracelog.log"
"Start to execute gatewayInstall.ps1. `n" | Out-File $logPath

function Now-Value() {
    return (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

function Throw-Error([string] $msg) {
    try { throw $msg } catch {
        $stack = $_.ScriptStackTrace
        Trace-Log "Installation failed: $msg`nStack:`n$stack"
    }
    throw $msg
}

function Trace-Log([string] $msg) {
    $now = Now-Value
    try {
        "${now} $msg`n" | Out-File $logPath -Append
    } catch { }
}

function Run-Process([string] $process, [string] $arguments) {
    $errorFile = "$env:tmp\tmp$pid.err"
    $outFile = "$env:tmp\tmp$pid.out"
    "" | Out-File $outFile
    "" | Out-File $errorFile
    $errVariable = ""

    if ([string]::IsNullOrEmpty($arguments)) {
        $proc = Start-Process -FilePath $process -Wait -Passthru -NoNewWindow `
            -RedirectStandardError $errorFile -RedirectStandardOutput $outFile -ErrorVariable errVariable
    } else {
        $proc = Start-Process -FilePath $process -ArgumentList $arguments -Wait -Passthru -NoNewWindow `
            -RedirectStandardError $errorFile -RedirectStandardOutput $outFile -ErrorVariable errVariable
    }

    $errContent = [string](Get-Content -Path $errorFile -Delimiter "!!!DoesNotExist!!!")
    $outContent = [string](Get-Content -Path $outFile -Delimiter "!!!DoesNotExist!!!")
    Remove-Item $errorFile -ErrorAction SilentlyContinue
    Remove-Item $outFile -ErrorAction SilentlyContinue

    if ($proc.ExitCode -ne 0 -or $errVariable -ne "") {
        Throw-Error "Failed to run process: exitCode=$($proc.ExitCode), errVariable=$errVariable, errContent=$errContent, outContent=$outContent."
    }
    Trace-Log "Run-Process: ExitCode=$($proc.ExitCode), output=$outContent"
    return $outContent.Trim()
}

function Download-Gateway([string] $url, [string] $gwPath) {
    try {
        $ErrorActionPreference = "Stop"
        $client = New-Object System.Net.WebClient
        $client.DownloadFile($url, $gwPath)
        Trace-Log "Download gateway successfully. Gateway loc: $gwPath"
    } catch {
        Trace-Log "Fail to download gateway msi"
        Trace-Log $_.Exception.ToString()
        throw
    }
}

function Install-Gateway([string] $gwPath) {
    if ([string]::IsNullOrEmpty($gwPath)) { Throw-Error "Gateway path is not specified" }
    if (!(Test-Path -Path $gwPath)) { Throw-Error "Invalid gateway path: $gwPath" }

    Trace-Log "Start Gateway installation"
    Run-Process "msiexec.exe" "/i `"$gwPath`" INSTALLTYPE=AzureTemplate /quiet /norestart"
    Start-Sleep -Seconds 30
    Trace-Log "Installation of gateway is successful"
}

function Get-RegistryProperty([string] $keyPath, [string] $property) {
    if (!(Test-Path $keyPath)) {
        Trace-Log "Get-RegistryProperty: $keyPath does not exist"
        return ""
    }
    $keyReg = Get-Item $keyPath
    if (!($keyReg.Property -contains $property)) {
        Trace-Log "Get-RegistryProperty: $property does not exist"
        return ""
    }
    return $keyReg.GetValue($property)
}

function Get-InstalledFilePath() {
    $filePath = Get-RegistryProperty "hklm:\Software\Microsoft\DataTransfer\DataManagementGateway\ConfigurationManager" "DiacmdPath"
    if ([string]::IsNullOrEmpty($filePath)) {
        Throw-Error "Get-InstalledFilePath: Cannot find installed File Path"
    }
    Trace-Log "Gateway installation file: $filePath"
    return $filePath
}

function Register-Gateway([string] $instanceKey) {
    Trace-Log "Register Agent"
    $filePath = Get-InstalledFilePath
    Run-Process $filePath "-era 8060"
    Run-Process $filePath "-k $instanceKey"
    Trace-Log "Agent registration is successful!"
}

Trace-Log "Log file: $logLoc"
$uri = "https://go.microsoft.com/fwlink/?linkid=839822"
Trace-Log "Gateway download fw link: $uri"
$gwPath = "$PWD\gateway.msi"
Trace-Log "Gateway download location: $gwPath"

Download-Gateway $uri $gwPath
Install-Gateway $gwPath
Register-Gateway $gatewayKey
Trace-Log "gatewayInstall.ps1 completed successfully"

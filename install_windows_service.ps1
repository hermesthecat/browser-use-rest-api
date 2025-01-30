# PowerShell script to install Windows Service
# Windows Servisi kurulum scripti
# ===============================
# EN: Run this script as administrator
# TR: Bu scripti yönetici olarak çalıştırın

# EN: Download and install NSSM (Non-Sucking Service Manager)
# TR: NSSM (Non-Sucking Service Manager) indir ve kur
$nssmUrl = "https://nssm.cc/release/nssm-2.24.zip"
$nssmPath = "C:\nssm\nssm.zip"
$nssmExtractPath = "C:\nssm"
$nssmExe = "C:\nssm\nssm-2.24\win64\nssm.exe"

# EN: Create NSSM directory if not exists
# TR: NSSM dizini yoksa oluştur
if (-not (Test-Path "C:\nssm")) {
    New-Item -ItemType Directory -Force -Path "C:\nssm"
}

# EN: Get script directory and set working directory
# TR: Script dizinini al ve çalışma dizinini ayarla
$scriptDir = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
Set-Location $scriptDir

# EN: Download and install NSSM if not exists
# TR: NSSM yüklü değilse indir ve kur
if (-not (Test-Path $nssmExe)) {
    Write-Host "EN: Downloading NSSM..."
    Write-Host "TR: NSSM indiriliyor..."
    Invoke-WebRequest -Uri $nssmUrl -OutFile $nssmPath
    Expand-Archive -Path $nssmPath -DestinationPath $nssmExtractPath -Force
}

# EN: Check Python installation
# TR: Python kurulumunu kontrol et
$pythonCmd = Get-Command python.exe -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    Write-Host "EN: Python is not found in system PATH!"
    Write-Host "TR: Python sistem PATH'inde bulunamadı!"
    exit 1
}

# EN: Install dependencies
# TR: Bağımlılıkları yükle
Write-Host "EN: Installing dependencies..."
Write-Host "TR: Bağımlılıklar yükleniyor..."
& $pythonCmd.Source -m pip install -r "$scriptDir\requirements.txt"

# EN: Service setup
# TR: Servis kurulumu
$serviceName = "AIAssistantAPI"
$pythonPath = $pythonCmd.Source  # Full path to Python executable
$appScript = "$scriptDir\browser_use_rest_api.py"
$logsDir = "$scriptDir\logs"

# EN: Remove existing service if exists
# TR: Eğer servis varsa kaldır
if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
    Write-Host "EN: Removing existing service..."
    Write-Host "TR: Mevcut servis kaldırılıyor..."
    & $nssmExe remove $serviceName confirm
}

# EN: Create logs directory
# TR: Log dizini oluştur
New-Item -ItemType Directory -Force -Path $logsDir

# EN: Install new service
# TR: Yeni servisi kur
Write-Host "EN: Installing service..."
Write-Host "TR: Servis kuruluyor..."
& $nssmExe install $serviceName $pythonPath $appScript

# EN: Configure service settings
# TR: Servis ayarlarını yapılandır
& $nssmExe set $serviceName Description "AI Assistant API Service"
& $nssmExe set $serviceName AppDirectory $scriptDir
& $nssmExe set $serviceName Start SERVICE_AUTO_START
& $nssmExe set $serviceName AppStdout "$logsDir\service.log"
& $nssmExe set $serviceName AppStderr "$logsDir\error.log"
& $nssmExe set $serviceName AppRotateFiles 1
& $nssmExe set $serviceName AppRotateOnline 1
& $nssmExe set $serviceName AppRotateSeconds 86400
& $nssmExe set $serviceName AppRestartDelay 3000
& $nssmExe set $serviceName AppEnvironmentExtra "PATH=$scriptDir;$env:PATH"

# EN: Start service
# TR: Servisi başlat
Write-Host "EN: Starting service..."
Write-Host "TR: Servis başlatılıyor..."
Start-Service -Name $serviceName

Write-Host "EN: AI Assistant API Windows service has been installed and started successfully!"
Write-Host "TR: AI Assistant API Windows servisi başarıyla kuruldu ve başlatıldı!"
Write-Host "EN: To check service status: Get-Service -Name $serviceName"
Write-Host "TR: Servis durumunu kontrol etmek için: Get-Service -Name $serviceName" 
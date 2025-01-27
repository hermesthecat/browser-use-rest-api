# PowerShell script to install Windows Service
# Windows Servisi kurulum scripti
# ===============================
# EN: Run this script as administrator
# TR: Bu scripti yönetici olarak çalıştırın

# EN: Download and install NSSM (Non-Sucking Service Manager)
# TR: NSSM (Non-Sucking Service Manager) indir ve kur
$nssmUrl = "https://nssm.cc/release/nssm-2.24.zip"
$nssmPath = "$env:TEMP\nssm.zip"
$nssmExtractPath = "$env:TEMP\nssm"
$nssmExe = "$nssmExtractPath\nssm-2.24\win64\nssm.exe"

# EN: Navigate to script directory
# TR: Script'in bulunduğu dizine git
$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
Set-Location $scriptPath

# EN: Download and install NSSM if not exists
# TR: NSSM yüklü değilse indir ve kur
if (-not (Test-Path $nssmExe)) {
    Write-Host "EN: Downloading NSSM..."
    Write-Host "TR: NSSM indiriliyor..."
    Invoke-WebRequest -Uri $nssmUrl -OutFile $nssmPath
    Expand-Archive -Path $nssmPath -DestinationPath $nssmExtractPath -Force
}

# EN: Check and create Python virtual environment
# TR: Python sanal ortamını kontrol et ve oluştur
if (-not (Test-Path ".\venv")) {
    Write-Host "EN: Creating virtual environment..."
    Write-Host "TR: Sanal ortam oluşturuluyor..."
    python -m venv venv
    
    # EN: Activate virtual environment and install dependencies
    # TR: Sanal ortamı aktive et ve bağımlılıkları yükle
    .\venv\Scripts\Activate.ps1
    Write-Host "EN: Installing dependencies..."
    Write-Host "TR: Bağımlılıklar yükleniyor..."
    pip install -r requirements.txt
}

# EN: Service setup
# TR: Servis kurulumu
$serviceName = "AIAssistantAPI"
$pythonPath = "$(Get-Location)\venv\Scripts\python.exe"
$scriptPath = "$(Get-Location)\browser_use_rest_api.py"

# EN: Remove existing service if exists
# TR: Eğer servis varsa kaldır
if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
    Write-Host "EN: Removing existing service..."
    Write-Host "TR: Mevcut servis kaldırılıyor..."
    & $nssmExe remove $serviceName confirm
}

# EN: Install new service
# TR: Yeni servisi kur
Write-Host "EN: Installing service..."
Write-Host "TR: Servis kuruluyor..."
& $nssmExe install $serviceName $pythonPath $scriptPath

# EN: Configure service settings
# TR: Servis ayarlarını yapılandır
& $nssmExe set $serviceName Description "AI Assistant API Service"
& $nssmExe set $serviceName AppDirectory "$(Get-Location)"
& $nssmExe set $serviceName Start SERVICE_AUTO_START
& $nssmExe set $serviceName AppStdout "$(Get-Location)\logs\service.log"
& $nssmExe set $serviceName AppStderr "$(Get-Location)\logs\error.log"
& $nssmExe set $serviceName AppRotateFiles 1
& $nssmExe set $serviceName AppRotateOnline 1
& $nssmExe set $serviceName AppRotateSeconds 86400
& $nssmExe set $serviceName AppRestartDelay 3000
& $nssmExe set $serviceName AppEnvironmentExtra "PATH=$(Get-Location)\venv\Scripts;%PATH%"

# EN: Create logs directory
# TR: Log dizini oluştur
New-Item -ItemType Directory -Force -Path ".\logs"

# EN: Start service
# TR: Servisi başlat
Write-Host "EN: Starting service..."
Write-Host "TR: Servis başlatılıyor..."
Start-Service -Name $serviceName

Write-Host "EN: AI Assistant API Windows service has been installed and started successfully!"
Write-Host "TR: AI Assistant API Windows servisi başarıyla kuruldu ve başlatıldı!"
Write-Host "EN: To check service status: Get-Service -Name $serviceName"
Write-Host "TR: Servis durumunu kontrol etmek için: Get-Service -Name $serviceName" 
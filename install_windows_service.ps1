# PowerShell script to install Windows Service
# Bu scripti yönetici olarak çalıştırın

# NSSM (Non-Sucking Service Manager) indirme ve kurma
$nssmUrl = "https://nssm.cc/release/nssm-2.24.zip"
$nssmPath = "$env:TEMP\nssm.zip"
$nssmExtractPath = "$env:TEMP\nssm"
$nssmExe = "$nssmExtractPath\nssm-2.24\win64\nssm.exe"

# Script'in bulunduğu dizine git
$scriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
Set-Location $scriptPath

# NSSM indir ve kur
if (-not (Test-Path $nssmExe)) {
    Write-Host "NSSM indiriliyor..."
    Invoke-WebRequest -Uri $nssmUrl -OutFile $nssmPath
    Expand-Archive -Path $nssmPath -DestinationPath $nssmExtractPath -Force
}

# Python virtual environment kontrolü ve oluşturma
if (-not (Test-Path ".\venv")) {
    Write-Host "Virtual environment oluşturuluyor..."
    python -m venv venv
    
    # Virtual environment'ı aktive et ve bağımlılıkları yükle
    .\venv\Scripts\Activate.ps1
    Write-Host "Bağımlılıklar yükleniyor..."
    pip install -r requirements.txt
}

# Servis kurulumu
$serviceName = "AIAssistantAPI"
$pythonPath = "$(Get-Location)\venv\Scripts\python.exe"
$scriptPath = "$(Get-Location)\test.py"

# Eğer servis varsa kaldır
if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
    Write-Host "Mevcut servis kaldırılıyor..."
    & $nssmExe remove $serviceName confirm
}

# Yeni servisi kur
Write-Host "Servis kuruluyor..."
& $nssmExe install $serviceName $pythonPath $scriptPath

# Servis ayarlarını yapılandır
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

# Log dizini oluştur
New-Item -ItemType Directory -Force -Path ".\logs"

# Servisi başlat
Write-Host "Servis başlatılıyor..."
Start-Service -Name $serviceName

Write-Host "AI Assistant API Windows servisi başarıyla kuruldu ve başlatıldı!"
Write-Host "Servis durumunu kontrol etmek için: Get-Service -Name $serviceName" 
#!/bin/bash

# EN: AI Assistant API Service Installation Script
# TR: AI Assistant API Servis Kurulum Scripti
# ==========================================

# EN: Stop script on any error
# TR: Hata durumunda scripti durdur
set -e

# EN: Root privilege check
# TR: Root yetkisi kontrolü
if [ "$EUID" -ne 0 ]; then 
    echo "EN: This script requires root privileges. Please run with 'sudo'."
    echo "TR: Bu script root yetkisi gerektirir. Lütfen 'sudo' ile çalıştırın."
    exit 1
fi

# EN: Create installation directory
# TR: Kurulum dizini oluştur
INSTALL_DIR="/opt/ai-assistant"
echo "EN: Creating installation directory: $INSTALL_DIR"
echo "TR: Kurulum dizini oluşturuluyor: $INSTALL_DIR"
mkdir -p $INSTALL_DIR

# EN: Copy files
# TR: Dosyaları kopyala
echo "EN: Copying files..."
echo "TR: Dosyalar kopyalanıyor..."
cp -r ./* $INSTALL_DIR/

# EN: Create and activate Python virtual environment
# TR: Python sanal ortamı oluştur ve aktive et
echo "EN: Creating virtual environment..."
echo "TR: Sanal ortam oluşturuluyor..."
cd $INSTALL_DIR
python3 -m venv venv
source venv/bin/activate

# EN: Install dependencies
# TR: Bağımlılıkları yükle
echo "EN: Installing dependencies..."
echo "TR: Bağımlılıklar yükleniyor..."
pip install -r requirements.txt

# EN: Install and activate systemd service
# TR: Systemd servisi kur ve aktive et
echo "EN: Installing systemd service..."
echo "TR: Systemd servisi kuruluyor..."
cp ai-assistant.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable ai-assistant

# EN: Start service
# TR: Servisi başlat
echo "EN: Starting service..."
echo "TR: Servis başlatılıyor..."
systemctl start ai-assistant

echo "EN: AI Assistant API service has been installed and started successfully!"
echo "TR: AI Assistant API servisi başarıyla kuruldu ve başlatıldı!"
echo "EN: To check service status: systemctl status ai-assistant"
echo "TR: Servis durumunu kontrol etmek için: systemctl status ai-assistant"

# EN: Display service status
# TR: Servis durumunu göster
echo -e "\nEN: Current service status:"
echo "TR: Mevcut servis durumu:"
systemctl status ai-assistant 
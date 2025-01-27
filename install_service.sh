#!/bin/bash

# Hata durumunda scripti durdur
set -e

# Root kontrolü
if [ "$EUID" -ne 0 ]; then 
    echo "Bu script root yetkisi gerektirir. Lütfen 'sudo' ile çalıştırın."
    exit 1
fi

# Kurulum dizini oluştur
INSTALL_DIR="/opt/ai-assistant"
mkdir -p $INSTALL_DIR

# Dosyaları kopyala
cp -r ./* $INSTALL_DIR/

# Python virtual environment oluştur
cd $INSTALL_DIR
python3 -m venv venv
source venv/bin/activate

# Bağımlılıkları yükle
pip install -r requirements.txt

# Servis dosyasını kopyala ve aktive et
cp ai-assistant.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable ai-assistant
systemctl start ai-assistant

echo "AI Assistant API servisi başarıyla kuruldu ve başlatıldı!"
echo "Servis durumunu kontrol etmek için: systemctl status ai-assistant" 
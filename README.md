# AI Assistant API

[English](README_EN.md) | [Türkçe](README.md)

## 🚀 Proje Hakkında

AI Assistant API, yapay zeka destekli bir yardım masası asistanıdır. Google arama motorunu kullanarak sorularınızı yanıtlar ve gerektiğinde ilgili web sitelerini ziyaret ederek detaylı bilgi toplar.

## 🔧 Kurulum

### Gereksinimler

- Python 3.8 veya üzeri
- pip (Python paket yöneticisi)
- Windows veya Linux işletim sistemi

### Çevresel Değişkenler

Projeyi çalıştırmadan önce `.env` dosyası oluşturun ve aşağıdaki değişkenleri ayarlayın:

```env
# API Anahtarları
GOOGLE_API_KEY=your_api_key_here

# Model Ayarları
GOOGLE_MODEL_NAME=gemini-2.0-flash-exp

# Browser Ayarları
BROWSER_HEADLESS=True
BROWSER_DISABLE_SECURITY=True

# Server Ayarları
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
```

### Windows'ta Kurulum

1. PowerShell'i yönetici olarak açın
2. Aşağıdaki komutu çalıştırın:

```powershell
.\install_windows_service.ps1
```

Servis yönetimi:

```powershell
# Durum kontrolü
Get-Service -Name AIAssistantAPI

# Servisi durdur
Stop-Service -Name AIAssistantAPI

# Servisi başlat
Start-Service -Name AIAssistantAPI
```

### Linux'ta Kurulum

1. Terminal açın
2. Aşağıdaki komutları çalıştırın:

```bash
# Script'i çalıştırılabilir yap
chmod +x install_service.sh

# Root yetkisiyle çalıştır
sudo ./install_service.sh
```

Servis yönetimi:

```bash
# Durum kontrolü
sudo systemctl status ai-assistant

# Servisi durdur
sudo systemctl stop ai-assistant

# Servisi başlat
sudo systemctl start ai-assistant

# Servisi yeniden başlat
sudo systemctl restart ai-assistant
```

## 📡 API Kullanımı

### Soru Sorma Endpoint'i

**POST** `/ask`

Request body:

```json
{
  "task": "Sorunuz buraya"
}
```

Başarılı yanıt (200):

```json
{
  "answer": "AI'nin cevabı"
}
```

Hata yanıtı (4xx/5xx):

```json
{
  "error": "error_code",
  "message": "Hata mesajı"
}
```

## 🌐 Web Arayüzü

API'yi test etmek için `index.html` dosyasını bir web tarayıcısında açabilirsiniz. Bu arayüz üzerinden:

- Sorularınızı gönderebilir
- Yanıtları görüntüleyebilir
- Hata mesajlarını takip edebilirsiniz

## 📝 Loglar

### Windows

- Servis logları: `logs/service.log`
- Hata logları: `logs/error.log`

### Linux

- Servis logları: `journalctl -u ai-assistant`

## 👥 Katkıda Bulunanlar

- A. Kerem Gök - İlk Geliştirici

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.

# AI Assistant API

[English](README_EN.md) | [Türkçe](README.md)

## 🚀 About The Project

AI Assistant API is an AI-powered help desk assistant. It answers your questions using the Google search engine and gathers detailed information by visiting relevant websites when necessary.

## 🔧 Installation

### Prerequisites

- Python 3.8 or higher
- pip (Python package manager)
- Windows or Linux operating system

### Environment Variables

Create a `.env` file and set the following variables before running the project:

```env
# API Keys
GOOGLE_API_KEY=your_api_key_here

# Model Settings
GOOGLE_MODEL_NAME=gemini-2.0-flash-exp

# Browser Settings
BROWSER_HEADLESS=True
BROWSER_DISABLE_SECURITY=True

# Server Settings
SERVER_HOST=0.0.0.0
SERVER_PORT=8000
```

### Windows Installation

1. Open PowerShell as administrator
2. Run the following command:

```powershell
.\install_windows_service.ps1
```

Service management:

```powershell
# Check status
Get-Service -Name AIAssistantAPI

# Stop service
Stop-Service -Name AIAssistantAPI

# Start service
Start-Service -Name AIAssistantAPI
```

### Linux Installation

1. Open terminal
2. Run the following commands:

```bash
# Make script executable
chmod +x install_service.sh

# Run with root privileges
sudo ./install_service.sh
```

Service management:

```bash
# Check status
sudo systemctl status ai-assistant

# Stop service
sudo systemctl stop ai-assistant

# Start service
sudo systemctl start ai-assistant

# Restart service
sudo systemctl restart ai-assistant
```

## 📡 API Usage

### Ask Question Endpoint

**POST** `/ask`

Request body:

```json
{
  "task": "Your question here"
}
```

Successful response (200):

```json
{
  "answer": "AI's response"
}
```

Error response (4xx/5xx):

```json
{
  "error": "error_code",
  "message": "Error message"
}
```

## 🌐 Web Interface

You can open the `index.html` file in a web browser to test the API. Through this interface, you can:

- Send your questions
- View responses
- Monitor error messages

## 📝 Logs

### Windows

- Service logs: `logs/service.log`
- Error logs: `logs/error.log`

### Linux

- Service logs: `journalctl -u ai-assistant`

## 👥 Contributors

- A. Kerem Gök - Initial Developer

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) file for details.

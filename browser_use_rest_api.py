from langchain_google_genai import ChatGoogleGenerativeAI
from browser_use import Agent, Controller, ActionResult, SystemPrompt, BrowserConfig
from browser_use.browser import browser
from browser_use.browser.context import BrowserContext, BrowserContextConfig
from pydantic import SecretStr, BaseModel
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
import os
from dotenv import load_dotenv
import asyncio
import sys
from typing import Optional

os.environ["ANONYMIZED_TELEMETRY"] = "false"

# .env dosyasını yükle
load_dotenv()

# Environment variable validation
def validate_environment():
    required_env_vars = {
        'GOOGLE_API_KEY': os.getenv('GOOGLE_API_KEY'),
        'GOOGLE_MODEL_NAME': os.getenv('GOOGLE_MODEL_NAME'),
        'SERVER_HOST': os.getenv('SERVER_HOST'),
        'SERVER_PORT': os.getenv('SERVER_PORT')
    }

    for var_name, var_value in required_env_vars.items():
        if not var_value:
            print(f"ERROR: Required environment variable {var_name} is not set")
            sys.exit(1)

    # Port validation
    try:
        port = int(os.getenv('SERVER_PORT'))
        if port < 1 or port > 65535:
            print("ERROR: SERVER_PORT must be between 1 and 65535")
            sys.exit(1)
    except (ValueError, TypeError):
        print("ERROR: SERVER_PORT must be a valid integer")
        sys.exit(1)

# Validate environment variables at startup
validate_environment()

app = FastAPI(
    title="AI Assistant API",
    description="Yapay Zeka Asistanı REST API",
    version="1.0.0",
    contact={
        "name": "A. Kerem Gök"
    }
)

# CORS ayarları
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Güvenlik için production'da spesifik domain belirtilmeli
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize the model
llm = ChatGoogleGenerativeAI(
    model=os.getenv('GOOGLE_MODEL_NAME'),
    api_key=os.getenv('GOOGLE_API_KEY')
)

class Answer(BaseModel):
    answer: str

class Question(BaseModel):
    task: str

controller = Controller(output_model=Answer)

class MySystemPrompt(SystemPrompt):
    def important_rules(self) -> str:
        existing_rules = super().important_rules()
        new_rules = '''
        1- Genel kurallar:
           - Her zaman Türkçe konuş ve profesyonel bir dil kullan. 
           - Sen işinde harika bir Bilgi Teknolojileri Teknik Destek Uzmanısın.
           - Kullanıcının sorduğu soruyu anlamak için önce kullanıcının sorduğu soruyu oku. Ve iletilen sorudan hangi ürün/yazılım/cihaz/hesap ile ilgili olduğunu anlamaya çalış.
           - Google'da arama yaparken öncelikle resmi yardım sayfalarını ve dokümantasyonları tercih et. 
           - Kullanıcıya döneceğimiz cevap Hem Türkçe Hem İngilizce olacak. 
           - Soru çok genel bir soru ise bu muhtemelen kullanıcının kurum tarafından ona verilen bir hesabı ya da cihazı ile ilgilidir.
           - Soruda bir ürün/marka yazılım adı geçmiyor ama cevapta varsa o adı sil.
           - Genel bir soru için cevapta bir ürünün ya da markanın adımlarını verme. Bunun yerine genel bir çözüm ver.
           - Çözüm bulmak için herhangi bir yere login olmaya gerek yok.
           - Son üretilen cevabı biçimlendirmek için HTML kodları kullan. 
           - Türkçe ve İngilizce cevap arasında boş bir satır bırak.
        2- Ürün/Yazılım aramaları için:
           - Öncelikle ürünün resmi web sitesini bul
           - Resmi dokümantasyona git
           - Resmi destek forumlarını kontrol et
           - Güvenilir kaynaklardaki (Stack Overflow, GitHub vb.) çözümleri incele
        3- Cevap analizi yaparken:
           - Çözümün teknik seviyesini belirle (Başlangıç/Orta/İleri)
           - Gerekli yetkileri listele (Normal kullanıcı/Yönetici/Sistem yöneticisi)
        4- Kullanıcı seviyesi çözümler için:
           - Adım adım talimatlar hazırla
           - Olası hata mesajlarını ve çözümlerini belirt
        5- Sistem yönetici seviyesi gerektiren durumlar için:
           - Teknik detayları açıkla
           - Neden sistem yöneticisi gerektiğini belirt
           - Kullanıcının yapabileceği geçici çözümleri öner
        '''
        return f'{existing_rules}\n{new_rules}'


# Browser ve Context konfigürasyonları
browser_config = BrowserConfig(
    headless=os.getenv('BROWSER_HEADLESS', 'true').lower() == 'true',
    disable_security=os.getenv('BROWSER_DISABLE_SECURITY', 'false').lower() == 'true'
)

context_config = BrowserContextConfig(
    wait_for_network_idle_page_load_time=3.0,
    browser_window_size={'width': 1280, 'height': 1100},
    locale='en-US',
    highlight_elements=True,
    viewport_expansion=500
)

@app.post("/ask", response_model=Answer)
async def ask_question(question: Question):
    browser_instance = None
    context = None
    try:
        # Her request için yeni browser instance oluştur
        browser_instance = browser.Browser(config=browser_config)
        context = BrowserContext(browser=browser_instance, config=context_config)
        
        agent = Agent(
            browser_context=context,
            task=question.task,
            llm=llm,
            controller=controller,
            system_prompt_class=MySystemPrompt
        )
        
        # Agent'ı çalıştır ve sonucu bekle (timeout ile)
        history = await asyncio.wait_for(
            agent.run(), 
            timeout=300.0  # 5 dakika timeout
        )
        
        # Sonucu kontrol et
        if not history:
            return JSONResponse(
                status_code=404,
                content={
                    "error": "not_found",
                    "message": "Agent çalışması başarısız oldu"
                }
            )
        
        # Final sonucu al
        result = history.final_result()
        if not result:
            return JSONResponse(
                status_code=404,
                content={
                    "error": "not_found",
                    "message": "Sonuç bulunamadı"
                }
            )
            
        # Sonucu JSON'a çevir
        try:
            answer = Answer.model_validate_json(result)
            return JSONResponse(
                status_code=200,
                content={
                    "answer": answer.answer
                }
            )
        except Exception as e:
            return JSONResponse(
                status_code=500,
                content={
                    "error": "parse_error",
                    "message": f"Sonuç JSON'a çevrilemedi: {str(e)}"
                }
            )
            
    except asyncio.TimeoutError:
        return JSONResponse(
            status_code=408,
            content={
                "error": "timeout",
                "message": "İşlem zaman aşımına uğradı"
            }
        )
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={
                "error": "internal_server_error",
                "message": str(e)
            }
        )
    finally:
        # Kaynakları temizle
        if context:
            try:
                await context.close()
            except Exception as e:
                print(f"Error closing context: {e}")
        if browser_instance:
            try:
                await browser_instance.close()
            except Exception as e:
                print(f"Error closing browser: {e}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host=os.getenv('SERVER_HOST'),
        port=int(os.getenv('SERVER_PORT'))
    )

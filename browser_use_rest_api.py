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
from typing import Optional

# .env dosyasını yükle
load_dotenv()

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
        1- Her zaman Türkçe konuş ve profesyonel bir dil kullan. Google'da arama yaparken öncelikle resmi yardım sayfalarını ve dokümantasyonları tercih et. Kullanıcıya döneceğimiz cevap Hem Türkçe Hem İngilizce olacak.
        2- Ürün/Yazılım aramaları için:
           - Öncelikle ürünün resmi web sitesini bul
           - Resmi dokümantasyona git
           - Resmi destek forumlarını kontrol et
           - Güvenilir kaynaklardaki (Stack Overflow, GitHub vb.) çözümleri incele
        3- Cevap analizi yaparken:
           - Çözümün teknik seviyesini belirle (Başlangıç/Orta/İleri)
           - Gerekli yetkileri listele (Normal kullanıcı/Yönetici/Sistem yöneticisi)
           - Olası riskleri değerlendir
           - Alternatif çözüm yolları varsa belirt
        4- Kullanıcı seviyesi çözümler için:
           - Adım adım talimatlar hazırla
           - Olası hata mesajlarını ve çözümlerini belirt
           - Güvenlik uyarılarını vurgula
        5- Sistem yönetici seviyesi gerektiren durumlar için:
           - Teknik detayları açıkla
           - Neden sistem yöneticisi gerektiğini belirt
           - Kullanıcının yapabileceği geçici çözümleri öner
           - Destek ekibine iletilmesi gereken bilgileri listele
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

# Browser ve Context oluşturma
browser_instance = browser.Browser(config=browser_config)
context = BrowserContext(browser=browser_instance, config=context_config)

@app.post("/ask", response_model=Answer)
async def ask_question(question: Question):
    try:
        agent = Agent(
            browser_context=context,
            task=question.task,
            llm=llm,
            controller=controller,
            system_prompt_class=MySystemPrompt
        )
        
        # Agent'ı çalıştır ve sonucu bekle
        history = await agent.run()
        
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
            
    except Exception as e:
        return JSONResponse(
            status_code=500,
            content={
                "error": "internal_server_error",
                "message": str(e)
            }
        )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host=os.getenv('SERVER_HOST'),
        port=int(os.getenv('SERVER_PORT'))
    )

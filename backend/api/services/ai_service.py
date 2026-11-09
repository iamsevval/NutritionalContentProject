import os
import json
import google.generativeai as genai

GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

def analyze_ingredients_with_ai(text):
    if not GEMINI_API_KEY:
        raise ValueError("Gemini API Key eksik. Lütfen export GEMINI_API_KEY='anahtariniz' ile tanımlayın.")
        
    prompt = f"""
    Sen uzman bir gıda mühendisi ve beslenme uzmanısın.
    Aşağıda bir ürünün ambalajından okunmuş, muhtemelen OCR hataları (yazım yanlışları, eksik harfler vb.) içeren OCR metni bulunmaktadır.
    Lütfen bu metni analiz et, OCR hatalarını mantıksal olarak düzelt ve şunları çıkar:
    1. İçindekiler listesini (düzeltilmiş isimleri ve varsa tahmini yüzdelik/gramajlarıyla birlikte)
    2. Her bir içerik için 'kategori' (Örn: Koruyucu, Renklendirici, Doğal, Tatlandırıcı, Alerjen, Emülgatör vb.) ve 'risk_seviyesi' (Düşük, Orta, Yüksek)
    3. Besin değerlerini
    4. Olası alerjenleri
    5. 100 üzerinden bir "Sağlık Puanı" (Health Score)
    6. Kısa bir sağlık yorumu

    Yanıtını kesinlikle SADECE aşağıdaki JSON formatında döndür:
    
    {{
      "icerikler": [
        {{"isim": "Şeker", "miktar": 10.5, "kategori": "Tatlandırıcı", "risk_seviyesi": "Orta"}},
        {{"isim": "Soya Lesitini", "miktar": null, "kategori": "Emülgatör (Alerjen)", "risk_seviyesi": "Düşük"}}
      ],
      "besinler": {{
        "Enerji (kcal)": "100",
        "Şeker (g)": "5.2"
      }},
      "alerjenler": ["Soya"],
      "saglik_puani": 65,
      "saglik_yorumu": "Yüksek oranda şeker içerdiği için fazla tüketimi önerilmez."
    }}
    
    OCR Metni:
    {text}
    """
    
    model = genai.GenerativeModel('gemini-1.5-flash')
    response = model.generate_content(prompt)
    
    response_text = response.text.strip()
    if response_text.startswith("```json"):
        response_text = response_text[7:-3]
    elif response_text.startswith("```"):
        response_text = response_text[3:-3]
        
    try:
        return json.loads(response_text)
    except json.JSONDecodeError:
        raise ValueError("Yapay zeka geçerli bir JSON formatı döndüremedi.")

def get_product_info_from_ai_by_barcode(barcode):
    if not GEMINI_API_KEY:
        return None
        
    prompt = f"""
    Aşağıdaki barkod numarasına sahip ürünü internetteki güncel veri tabanından (Web Scraping simülasyonu) bul veya tahmin et:
    Barkod: {barcode}
    
    Bu ürünün tahmini markası, ürün adı, içindekiler listesi (kategori ve risk seviyesiyle birlikte) ve besin değerlerini (100g için) oluştur.
    
    Yanıtını kesinlikle SADECE aşağıdaki JSON formatında döndür. Eğer ürünü hiç bulamazsan 'icerikler' listesini boş döndür.
    
    {{
      "icerikler": [
        {{"isim": "Şeker", "miktar": 10.5, "kategori": "Tatlandırıcı", "risk_seviyesi": "Orta"}}
      ],
      "besinler": {{
        "Enerji (kcal)": "250"
      }},
      "alerjenler": ["Süt"],
      "saglik_puani": 50,
      "saglik_yorumu": "Bu ürün AI tarafından internette aranarak bulundu."
    }}
    """
    
    try:
        model = genai.GenerativeModel('gemini-1.5-flash')
        response = model.generate_content(prompt)
        
        response_text = response.text.strip()
        if response_text.startswith("```json"):
            response_text = response_text[7:-3]
        elif response_text.startswith("```"):
            response_text = response_text[3:-3]
            
        data = json.loads(response_text)
        if len(data.get("icerikler", [])) > 0:
            return data
        return None
    except Exception as e:
        print("AI Barkod arama hatası:", e)
        return None

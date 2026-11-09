import os
import sys
import django

sys.path.append(os.path.abspath("."))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "serverSide.settings")
django.setup()

from django.contrib.auth.models import User
from api.models import UserProfile, ScanHistory
from api.views import check_safety_and_save
from api.services.analysis_service import tahmini_icerik_tablosu

print("=== GÜVENLİK VE ALERJİ ANALİZİ TESTİ ===")

# Test kullanıcısı oluştur (Alerjileri: Süt ve Fıstık)
user, created = User.objects.get_or_create(username="test_user_ocr")
profile, _ = UserProfile.objects.get_or_create(user=user)
profile.allergies = "süt, fıstık, gluten"
profile.save()

print(f"Kullanıcı Alerjileri: {profile.allergies}")

# Yapay Zekadan Dönecek Örnek Format (ocr_test.jpeg içeriğine göre)
mock_ai_result = {
  "icerikler": [
    {"isim": "Şeker", "miktar": 50},
    {"isim": "Kakao Yağı", "miktar": 18},
    {"isim": "Antep Fıstığı", "miktar": 15},
    {"isim": "Peyniraltı Suyu Tozu (Süt Ürünü)", "miktar": 5},
    {"isim": "Kakao Kitlesi", "miktar": 5},
    {"isim": "Yağsız Süttozu", "miktar": 5},
    {"isim": "Süt Yağı", "miktar": 1},
    {"isim": "Emülgatör (Ayçiçek Lesitini)", "miktar": 0.5},
    {"isim": "Doğal Aroma Verici", "miktar": 0.5}
  ],
  "besinler": {
    "Enerji (kcal)": "559",
    "Şeker (g)": "50"
  },
  "alerjenler": ["Süt Ürünü", "Antep Fıstığı", "Fındık", "Badem", "Buğday"],
  "saglik_puani": 40,
  "saglik_yorumu": "Yüksek şeker ve alerjen uyarısı."
}

# OCR/Analysis servisindeki gibi tabloya çevir
mock_ai_result["icerikler_tablosu"] = tahmini_icerik_tablosu(mock_ai_result["icerikler"])

full_data = {
    "source": "AI_OCR",
    "data": mock_ai_result
}

print("Analiz Ediliyor...")
check_safety_and_save(user.id, full_data)

print("\n--- SONUÇLAR ---")
print("Hayati Uyarılar (Eşleşen Alerjenler):", full_data["data"].get("hayati_uyari"))
print("Kullanıcı için Güvenli mi (is_safe):", full_data["data"].get("is_safe"))

# Geçmiş tablosundan kontrol et
history = ScanHistory.objects.filter(user=user).last()
print(f"\nVeritabanına Kaydedilen Geçmiş:")
print(f"Ürün: {history.product_name}")
print(f"Bulunan Alerjenler: {history.allergens_found}")
print(f"Güvenli mi?: {history.is_safe}")


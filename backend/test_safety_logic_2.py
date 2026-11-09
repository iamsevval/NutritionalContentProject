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

# Test kullanıcısı oluştur (Alerjileri: Süt)
user, created = User.objects.get_or_create(username="test_user_ocr_2")
profile, _ = UserProfile.objects.get_or_create(user=user)
profile.allergies = "süt"
profile.save()

# Yapay Zekadan Dönecek Örnek Format (ocr_test2.jpeg içeriğine göre)
mock_ai_result_2 = {
  "icerikler": [
    {"isim": "Nohut Unu", "miktar": 59},
    {"isim": "Pirinç Unu", "miktar": 10},
    {"isim": "Pirinç İrmiği", "miktar": 10},
    {"isim": "Ayçiçek Yağı", "miktar": 10},
    {"isim": "Chili Çeşni", "miktar": 6},
    {"isim": "Zeytinyağı", "miktar": 2.5},
    {"isim": "Tuz", "miktar": 2.5}
  ],
  "besinler": {
    "Enerji (kcal)": "400"
  },
  "alerjenler": ["Hardal (Eser miktarda)"],
  "saglik_puani": 75,
  "saglik_yorumu": "Sağlıklı bir atıştırmalık, ancak eser miktarda hardal içeriyor."
}

mock_ai_result_2["icerikler_tablosu"] = tahmini_icerik_tablosu(mock_ai_result_2["icerikler"])

full_data_2 = {
    "source": "AI_OCR",
    "data": mock_ai_result_2
}

print(f"Kullanıcı Alerjileri: {profile.allergies}")
check_safety_and_save(user.id, full_data_2)
print("Hayati Uyarılar:", full_data_2["data"].get("hayati_uyari"))
print("Güvenli mi?:", full_data_2["data"].get("is_safe"))


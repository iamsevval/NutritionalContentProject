import os
import sys
import django

sys.path.append(os.path.abspath("."))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "serverSide.settings")
django.setup()

from django.contrib.auth.models import User
from api.models import UserProfile
from api.views import check_safety_and_save
from api.services.analysis_service import analyze_barcode

user, created = User.objects.get_or_create(username="test_user_barcode_2")
profile, _ = UserProfile.objects.get_or_create(user=user)
profile.allergies = "aspartame"
profile.save()
print(f"Kullanıcı Alerjileri: {profile.allergies}\n")

result_cola = analyze_barcode("5449000131805")
check_safety_and_save(user.id, result_cola)
print("İçerikler:", [i.get("isim") for i in result_cola["data"]["icerikler"]][:5], "...")
print("Hayati Uyarılar:", result_cola["data"].get("hayati_uyari"))
print("Güvenli mi?:", result_cola["data"].get("is_safe"))


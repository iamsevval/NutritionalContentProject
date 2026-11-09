from django.db import models
from django.contrib.auth.models import User

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    # Alerjileri virgülle ayrılmış string olarak tutalım (Örn: "Gluten,Süt,Yer Fıstığı")
    allergies = models.TextField(blank=True, null=True)
    # Hastalıkları virgülle ayrılmış string olarak tutalım (Örn: "Diyabet,Tansiyon")
    diseases = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} Profili"

    def get_allergy_list(self):
        if not self.allergies:
            return []
        return [x.strip().lower() for x in self.allergies.split(",") if x.strip()]
        
    def get_disease_list(self):
        if not self.diseases:
            return []
        return [x.strip() for x in self.diseases.split(",") if x.strip()]

class ScanHistory(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='scan_history')
    date_scanned = models.DateTimeField(auto_now_add=True)
    product_name = models.CharField(max_length=255, blank=True, null=True)
    health_score = models.CharField(max_length=50, blank=True, null=True)
    allergens_found = models.TextField(blank=True, null=True)
    is_safe = models.BooleanField(default=True)
    raw_response = models.TextField(blank=True, null=True) # JSON response yedeği

    def __str__(self):
        return f"{self.user.username} - {self.product_name} ({self.date_scanned.strftime('%Y-%m-%d')})"

from django.contrib import admin
from django.urls import path
from api.views import GoruntuIslemeAPI, BarkodAPI, RegisterAPI, LoginAPI, ProfileAPI, HistoryAPI, PopularProductsAPI

urlpatterns = [
    path('admin/', admin.site.urls),
    path('upload/', GoruntuIslemeAPI.as_view()),
    path('barcode/', BarkodAPI.as_view()),
    path('register/', RegisterAPI.as_view()),
    path('login/', LoginAPI.as_view()),
    path('profile/<int:user_id>/', ProfileAPI.as_view()),
    path('history/<int:user_id>/', HistoryAPI.as_view()),
    path('products/popular/', PopularProductsAPI.as_view()),
]
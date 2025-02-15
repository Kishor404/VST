from django.urls import path
from .views import (
    CheckAvailabilityView,
    NextServiceView, 
    UpcomingServiceView, 
    CurrentServiceView, 
    CompletedServiceView,
    GetUserByID,
    RoleCountView,
    HeadEdit,
    AssignAvailableStaffView,
    )

urlpatterns = [
    # User authentication endpoints
    path('checkstaffavailability/', CheckAvailabilityView.as_view(), name='checker'),
    path('next-service/', NextServiceView.as_view(), name='next-service-info'),
    path('upcomingservice/', UpcomingServiceView.as_view(), name='upcoming-service-info'),
    path('currentservice/', CurrentServiceView.as_view(), name='current-service-info'),
    path('completedservice/', CompletedServiceView.as_view(), name='completed-service-info'),
    path('getuserbyid/<int:id>', GetUserByID.as_view(), name='get-user-by-id'),
    path('headeditreq/<int:id>', HeadEdit.as_view(), name='head-edit-by-id'),
    path('role-count/', RoleCountView.as_view(), name='role-count'),
    path('reassingstaff/<int:id>', AssignAvailableStaffView.as_view(), name='reassign-staff'),
]

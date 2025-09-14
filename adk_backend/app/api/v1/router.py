"""
API router for ADK Meal Planning API v1
"""

from fastapi import APIRouter
from app.api.v1.endpoints import meal_planning, agents

# Create main API router
api_router = APIRouter()

# Include endpoint routers
api_router.include_router(
    meal_planning.router,
    prefix="/meal-planning",
    tags=["meal-planning"]
)

api_router.include_router(
    agents.router,
    prefix="/agents",
    tags=["agents"]
)

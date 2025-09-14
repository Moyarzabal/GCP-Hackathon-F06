"""
Meal planning API endpoints
"""

from fastapi import APIRouter, HTTPException, Depends
import structlog
import time
from typing import List

from app.models.schemas import (
    MealPlanningRequest, MealPlanningResponse, MealPlan, ShoppingItem
)
from app.services.meal_planning_service import MealPlanningService
from app.core.exceptions import MealPlanningException

logger = structlog.get_logger(__name__)
router = APIRouter()

# Dependency injection for meal planning service
async def get_meal_planning_service() -> MealPlanningService:
    """Get meal planning service instance"""
    return MealPlanningService()

@router.post("/suggest", response_model=MealPlanningResponse)
async def suggest_meal_plan(
    request: MealPlanningRequest,
    service: MealPlanningService = Depends(get_meal_planning_service)
) -> MealPlanningResponse:
    """
    Suggest a meal plan using ADK agents
    
    This endpoint coordinates multiple ADK agents to:
    1. Analyze refrigerator ingredients
    2. Calculate nutrition balance
    3. Suggest recipes
    4. Optimize cooking process
    5. Determine meal theme
    6. Generate menu images
    """
    start_time = time.time()
    
    try:
        logger.info(
            "Processing meal planning request",
            household_id=request.household_id,
            product_count=len(request.refrigerator_items),
            max_cooking_time=request.user_preferences.max_cooking_time
        )
        
        # Process meal planning using ADK agents
        meal_plan = await service.suggest_meal_plan(request)
        
        # Generate shopping list
        shopping_list = await service.generate_shopping_list(meal_plan, request.refrigerator_items)
        
        processing_time = time.time() - start_time
        
        logger.info(
            "Meal planning completed",
            household_id=request.household_id,
            processing_time=processing_time,
            confidence=meal_plan.confidence
        )
        
        return MealPlanningResponse(
            meal_plan=meal_plan,
            shopping_list=shopping_list,
            processing_time=processing_time,
            agents_used=[
                "ingredient_analysis",
                "nutrition_balance", 
                "recipe_suggestion",
                "cooking_optimization",
                "meal_theme",
                "image_generation"
            ]
        )
        
    except MealPlanningException as e:
        logger.error(
            "Meal planning error",
            error=str(e),
            household_id=request.household_id
        )
        raise HTTPException(status_code=e.status_code, detail=e.message)
        
    except Exception as e:
        logger.error(
            "Unexpected error in meal planning",
            error=str(e),
            household_id=request.household_id,
            exc_info=True
        )
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/alternatives", response_model=List[MealPlan])
async def suggest_alternatives(
    original_meal_plan: MealPlan,
    request: MealPlanningRequest,
    reason: str,
    service: MealPlanningService = Depends(get_meal_planning_service)
) -> List[MealPlan]:
    """
    Suggest alternative meal plans based on feedback
    """
    try:
        logger.info(
            "Processing alternative meal plans request",
            household_id=request.household_id,
            reason=reason
        )
        
        alternatives = await service.suggest_alternatives(
            original_meal_plan, 
            request, 
            reason
        )
        
        logger.info(
            "Alternative meal plans generated",
            household_id=request.household_id,
            alternative_count=len(alternatives)
        )
        
        return alternatives
        
    except MealPlanningException as e:
        logger.error(
            "Alternative meal planning error",
            error=str(e),
            household_id=request.household_id
        )
        raise HTTPException(status_code=e.status_code, detail=e.message)
        
    except Exception as e:
        logger.error(
            "Unexpected error in alternative meal planning",
            error=str(e),
            household_id=request.household_id,
            exc_info=True
        )
        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/health")
async def health_check():
    """Health check for meal planning service"""
    return {"status": "healthy", "service": "meal-planning"}

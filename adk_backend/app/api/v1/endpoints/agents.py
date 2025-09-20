"""
Individual agent API endpoints
"""

from fastapi import APIRouter, HTTPException, Depends
import structlog

from app.models.schemas import (
    IngredientAnalysisRequest, IngredientAnalysisResult,
    NutritionAnalysisRequest, NutritionAnalysisResult,
    RecipeSuggestionRequest, RecipeSuggestionResult,
    CookingOptimizationRequest, CookingOptimizationResult,
    MealThemeRequest, MealThemeResult,
    ImageGenerationRequest, ImageGenerationResult,
    UserPreferenceRequest, UserPreferenceResult
)
from app.agents.ingredient_analysis_agent import IngredientAnalysisAgent
from app.agents.nutrition_balance_agent import NutritionBalanceAgent
from app.agents.recipe_suggestion_agent import RecipeSuggestionAgent
from app.agents.cooking_optimization_agent import CookingOptimizationAgent
from app.agents.meal_theme_agent import MealThemeAgent
from app.agents.image_generation_agent import ImageGenerationAgent
from app.agents.user_preference_conversation_agent import UserPreferenceConversationAgent
from app.core.exceptions import AgentException

logger = structlog.get_logger(__name__)
router = APIRouter()

# Agent instances
ingredient_agent = IngredientAnalysisAgent()
nutrition_agent = NutritionBalanceAgent()
recipe_agent = RecipeSuggestionAgent()
cooking_agent = CookingOptimizationAgent()
theme_agent = MealThemeAgent()
image_agent = ImageGenerationAgent()
preference_agent = UserPreferenceConversationAgent()

@router.post("/ingredient-analysis", response_model=IngredientAnalysisResult)
async def analyze_ingredients(request: IngredientAnalysisRequest):
    """Analyze refrigerator ingredients and determine priorities"""
    try:
        logger.info("Processing ingredient analysis request")
        result = await ingredient_agent.process(request)
        logger.info("Ingredient analysis completed")
        return result
    except AgentException as e:
        logger.error("Ingredient analysis error", error=str(e))
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        logger.error("Unexpected error in ingredient analysis", error=str(e), exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/nutrition-balance", response_model=NutritionAnalysisResult)
async def analyze_nutrition(request: NutritionAnalysisRequest):
    """Analyze nutrition balance and provide recommendations"""
    try:
        logger.info("Processing nutrition analysis request")
        result = await nutrition_agent.process(request)
        logger.info("Nutrition analysis completed")
        return result
    except AgentException as e:
        logger.error("Nutrition analysis error", error=str(e))
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        logger.error("Unexpected error in nutrition analysis", error=str(e), exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/recipe-suggestion", response_model=RecipeSuggestionResult)
async def suggest_recipes(request: RecipeSuggestionRequest):
    """Suggest recipes based on ingredients and nutrition requirements"""
    try:
        logger.info("Processing recipe suggestion request")
        result = await recipe_agent.process(request)
        logger.info("Recipe suggestion completed")
        return result
    except AgentException as e:
        logger.error("Recipe suggestion error", error=str(e))
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        logger.error("Unexpected error in recipe suggestion", error=str(e), exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/cooking-optimization", response_model=CookingOptimizationResult)
async def optimize_cooking(request: CookingOptimizationRequest):
    """Optimize cooking process and timing"""
    try:
        logger.info("Processing cooking optimization request")
        result = await cooking_agent.process(request)
        logger.info("Cooking optimization completed")
        return result
    except AgentException as e:
        logger.error("Cooking optimization error", error=str(e))
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        logger.error("Unexpected error in cooking optimization", error=str(e), exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/meal-theme", response_model=MealThemeResult)
async def determine_meal_theme(request: MealThemeRequest):
    """Determine meal theme and create unified meal plan"""
    try:
        logger.info("Processing meal theme request")
        result = await theme_agent.process(request)
        logger.info("Meal theme determination completed")
        return result
    except AgentException as e:
        logger.error("Meal theme error", error=str(e))
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        logger.error("Unexpected error in meal theme", error=str(e), exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/image-generation", response_model=ImageGenerationResult)
async def generate_menu_images(request: ImageGenerationRequest):
    """Generate images for menu items"""
    try:
        logger.info("Processing image generation request")
        result = await image_agent.process(request)
        logger.info("Image generation completed")
        return result
    except AgentException as e:
        logger.error("Image generation error", error=str(e))
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        logger.error("Unexpected error in image generation", error=str(e), exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/user-preferences", response_model=UserPreferenceResult)
async def collect_user_preferences(request: UserPreferenceRequest):
    """Collect and structure user preferences through conversation"""
    try:
        logger.info("Processing user preference collection request")
        result = await preference_agent.process(request)
        logger.info("User preference collection completed")
        return result
    except AgentException as e:
        logger.error("User preference collection error", error=str(e))
        raise HTTPException(status_code=e.status_code, detail=e.message)
    except Exception as e:
        logger.error("Unexpected error in user preference collection", error=str(e), exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/health")
async def agents_health_check():
    """Health check for all agents"""
    return {
        "status": "healthy",
        "service": "agents",
        "available_agents": [
            "ingredient_analysis",
            "nutrition_balance",
            "recipe_suggestion",
            "cooking_optimization",
            "meal_theme",
            "image_generation",
            "user_preference_conversation"
        ]
    }

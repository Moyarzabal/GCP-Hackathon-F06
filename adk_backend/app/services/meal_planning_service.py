"""
Meal planning service that coordinates ADK agents
"""

import structlog
from typing import List
from datetime import datetime

from app.models.schemas import (
    MealPlanningRequest, MealPlan, ShoppingItem, Product,
    IngredientAnalysisRequest, NutritionAnalysisRequest,
    RecipeSuggestionRequest, CookingOptimizationRequest,
    MealThemeRequest, ImageGenerationRequest
)
from app.agents.ingredient_analysis_agent import IngredientAnalysisAgent
from app.agents.nutrition_balance_agent import NutritionBalanceAgent
from app.agents.recipe_suggestion_agent import RecipeSuggestionAgent
from app.agents.cooking_optimization_agent import CookingOptimizationAgent
from app.agents.meal_theme_agent import MealThemeAgent
from app.agents.image_generation_agent import ImageGenerationAgent
from app.core.exceptions import MealPlanningException

logger = structlog.get_logger(__name__)

class MealPlanningService:
    """Service that coordinates multiple ADK agents for meal planning"""
    
    def __init__(self):
        self.ingredient_agent = IngredientAnalysisAgent()
        self.nutrition_agent = NutritionBalanceAgent()
        self.recipe_agent = RecipeSuggestionAgent()
        self.cooking_agent = CookingOptimizationAgent()
        self.theme_agent = MealThemeAgent()
        self.image_agent = ImageGenerationAgent()
    
    async def suggest_meal_plan(self, request: MealPlanningRequest) -> MealPlan:
        """Suggest a meal plan using coordinated ADK agents"""
        try:
            logger.info(
                "Starting meal planning process",
                household_id=request.household_id,
                product_count=len(request.refrigerator_items)
            )
            
            # Step 1: Analyze ingredients
            logger.info("Step 1: Analyzing ingredients")
            ingredient_analysis_request = IngredientAnalysisRequest(
                products=request.refrigerator_items,
                current_date=datetime.now()
            )
            ingredient_analysis = await self.ingredient_agent.process(ingredient_analysis_request)
            
            # Step 2: Analyze nutrition balance
            logger.info("Step 2: Analyzing nutrition balance")
            nutrition_analysis_request = NutritionAnalysisRequest(
                ingredients=ingredient_analysis.analyzed_ingredients,
                user_preferences=request.user_preferences
            )
            nutrition_analysis = await self.nutrition_agent.process(nutrition_analysis_request)
            
            # Step 3: Suggest recipes
            logger.info("Step 3: Suggesting recipes")
            recipe_suggestion_request = RecipeSuggestionRequest(
                ingredient_analysis=ingredient_analysis,
                nutrition_analysis=nutrition_analysis,
                user_preferences=request.user_preferences
            )
            recipe_suggestion = await self.recipe_agent.process(recipe_suggestion_request)
            
            # Step 4: Optimize cooking
            logger.info("Step 4: Optimizing cooking process")
            cooking_optimization_request = CookingOptimizationRequest(
                recipes=[
                    recipe_suggestion.main_dish,
                    recipe_suggestion.side_dish,
                    recipe_suggestion.soup,
                    recipe_suggestion.rice
                ],
                constraints={
                    "max_cooking_time": request.user_preferences.max_cooking_time,
                    "difficulty": request.user_preferences.preferred_difficulty
                }
            )
            cooking_optimization = await self.cooking_agent.process(cooking_optimization_request)
            
            # Step 5: Determine meal theme
            logger.info("Step 5: Determining meal theme")
            meal_theme_request = MealThemeRequest(
                recipes=[
                    recipe_suggestion.main_dish,
                    recipe_suggestion.side_dish,
                    recipe_suggestion.soup,
                    recipe_suggestion.rice
                ],
                user_preferences=request.user_preferences,
                current_date=datetime.now()
            )
            meal_theme = await self.theme_agent.process(meal_theme_request)
            
            # Step 6: Generate images (optional, can be done asynchronously)
            logger.info("Step 6: Generating menu images")
            try:
                image_generation_request = ImageGenerationRequest(
                    recipes=[
                        recipe_suggestion.main_dish,
                        recipe_suggestion.side_dish,
                        recipe_suggestion.soup,
                        recipe_suggestion.rice
                    ],
                    meal_theme=meal_theme,
                    image_style={
                        "style": "appetizing",
                        "lighting": "natural",
                        "composition": "professional"
                    }
                )
                image_generation = await self.image_agent.process(image_generation_request)
                
                # Update meal items with generated images
                recipe_suggestion.main_dish.image_url = image_generation.image_urls[0] if len(image_generation.image_urls) > 0 else None
                recipe_suggestion.side_dish.image_url = image_generation.image_urls[1] if len(image_generation.image_urls) > 1 else None
                recipe_suggestion.soup.image_url = image_generation.image_urls[2] if len(image_generation.image_urls) > 2 else None
                recipe_suggestion.rice.image_url = image_generation.image_urls[3] if len(image_generation.image_urls) > 3 else None
                
            except Exception as e:
                logger.warning(f"Image generation failed, continuing without images: {e}")
            
            # Create final meal plan
            meal_plan = MealPlan(
                household_id=request.household_id,
                date=datetime.now(),
                status="suggested",
                main_dish=recipe_suggestion.main_dish,
                side_dish=recipe_suggestion.side_dish,
                soup=recipe_suggestion.soup,
                rice=recipe_suggestion.rice,
                total_cooking_time=cooking_optimization.total_time,
                difficulty=recipe_suggestion.difficulty,
                nutrition_score=nutrition_analysis.nutrition_score,
                confidence=recipe_suggestion.confidence,
                created_at=datetime.now(),
                created_by="adk_agent"
            )
            
            logger.info(
                "Meal planning completed successfully",
                household_id=request.household_id,
                confidence=meal_plan.confidence,
                nutrition_score=meal_plan.nutrition_score
            )
            
            return meal_plan
            
        except Exception as e:
            logger.error(
                "Meal planning failed",
                household_id=request.household_id,
                error=str(e),
                exc_info=True
            )
            raise MealPlanningException(
                f"Failed to generate meal plan: {str(e)}",
                error_code="MEAL_PLANNING_FAILED",
                status_code=500
            )
    
    async def suggest_alternatives(
        self, 
        original_meal_plan: MealPlan, 
        request: MealPlanningRequest, 
        reason: str
    ) -> List[MealPlan]:
        """Suggest alternative meal plans based on feedback"""
        try:
            logger.info(
                "Generating alternative meal plans",
                household_id=request.household_id,
                reason=reason
            )
            
            # Modify user preferences based on feedback
            modified_preferences = self._modify_preferences_from_feedback(
                request.user_preferences, 
                reason
            )
            
            # Generate alternatives with modified preferences
            alternatives = []
            for i in range(3):  # Generate 3 alternatives
                alternative_request = MealPlanningRequest(
                    refrigerator_items=request.refrigerator_items,
                    household_id=request.household_id,
                    user_preferences=modified_preferences
                )
                
                alternative_meal_plan = await self.suggest_meal_plan(alternative_request)
                alternatives.append(alternative_meal_plan)
            
            logger.info(
                "Alternative meal plans generated",
                household_id=request.household_id,
                alternative_count=len(alternatives)
            )
            
            return alternatives
            
        except Exception as e:
            logger.error(
                "Alternative meal planning failed",
                household_id=request.household_id,
                error=str(e),
                exc_info=True
            )
            raise MealPlanningException(
                f"Failed to generate alternatives: {str(e)}",
                error_code="ALTERNATIVE_PLANNING_FAILED",
                status_code=500
            )
    
    async def generate_shopping_list(
        self, 
        meal_plan: MealPlan, 
        available_products: List[Product]
    ) -> List[ShoppingItem]:
        """Generate shopping list for missing ingredients"""
        try:
            shopping_items = []
            available_product_names = {product.name.lower() for product in available_products}
            
            # Collect all ingredients from meal plan
            all_ingredients = [
                *meal_plan.main_dish.ingredients,
                *meal_plan.side_dish.ingredients,
                *meal_plan.soup.ingredients,
                *meal_plan.rice.ingredients,
            ]
            
            # Find missing ingredients
            for ingredient in all_ingredients:
                if ingredient.shopping_required or ingredient.name.lower() not in available_product_names:
                    shopping_item = ShoppingItem(
                        name=ingredient.name,
                        quantity=ingredient.quantity,
                        unit=ingredient.unit,
                        category=ingredient.category,
                        is_custom=False,
                        added_by="adk_agent",
                        added_at=datetime.now(),
                        notes=ingredient.notes
                    )
                    shopping_items.append(shopping_item)
            
            logger.info(
                "Shopping list generated",
                item_count=len(shopping_items)
            )
            
            return shopping_items
            
        except Exception as e:
            logger.error(
                "Shopping list generation failed",
                error=str(e),
                exc_info=True
            )
            raise MealPlanningException(
                f"Failed to generate shopping list: {str(e)}",
                error_code="SHOPPING_LIST_FAILED",
                status_code=500
            )
    
    def _modify_preferences_from_feedback(
        self, 
        preferences, 
        reason: str
    ):
        """Modify user preferences based on feedback"""
        # This is a simplified implementation
        # In a real system, you might use NLP to parse the reason
        # and make more sophisticated modifications
        
        modified_preferences = preferences.copy()
        
        if "辛い" in reason or "辛すぎ" in reason:
            modified_preferences.dietary_restrictions.append("spicy_food")
        
        if "時間" in reason or "長い" in reason:
            modified_preferences.max_cooking_time = max(10, modified_preferences.max_cooking_time - 10)
        
        if "簡単" in reason or "簡単に" in reason:
            modified_preferences.preferred_difficulty = "easy"
        
        return modified_preferences

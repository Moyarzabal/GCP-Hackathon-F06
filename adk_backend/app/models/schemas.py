"""
Pydantic models for ADK Meal Planning API
"""

from pydantic import BaseModel, Field, validator
from typing import List, Optional, Dict, Any, Union
from datetime import datetime
from enum import Enum

# Enums
class DifficultyLevel(str, Enum):
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"
    EXPERT = "expert"

class ExpiryPriority(str, Enum):
    URGENT = "urgent"
    SOON = "soon"
    FRESH = "fresh"
    LONG_TERM = "long_term"

class MealPlanStatus(str, Enum):
    SUGGESTED = "suggested"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    COMPLETED = "completed"

class MealCategory(str, Enum):
    MAIN = "main"
    SIDE = "side"
    SOUP = "soup"
    RICE = "rice"

# Base models
class Product(BaseModel):
    """Product model from Flutter app"""
    id: str
    name: str
    category: str
    quantity: float
    unit: str
    expiry_date: datetime
    days_until_expiry: int
    current_image_url: Optional[str] = None

class UserPreferences(BaseModel):
    """User preferences for meal planning"""
    max_cooking_time: int = Field(default=60, ge=10, le=300)
    preferred_difficulty: DifficultyLevel = DifficultyLevel.EASY
    dietary_restrictions: List[str] = Field(default_factory=list)
    allergies: List[str] = Field(default_factory=list)
    disliked_ingredients: List[str] = Field(default_factory=list)
    preferred_cuisines: List[str] = Field(default_factory=list)

# Ingredient models
class Ingredient(BaseModel):
    """Ingredient model"""
    name: str
    quantity: str
    unit: str
    available: bool = True
    expiry_date: Optional[datetime] = None
    shopping_required: bool = False
    product_id: Optional[str] = None
    priority: ExpiryPriority = ExpiryPriority.FRESH
    category: str = "その他"
    image_url: Optional[str] = None
    notes: Optional[str] = None
    
    @property
    def priority_score(self) -> int:
        """Calculate priority score for sorting"""
        priority_scores = {
            ExpiryPriority.URGENT: 1,
            ExpiryPriority.SOON: 2,
            ExpiryPriority.FRESH: 3,
            ExpiryPriority.LONG_TERM: 4,
        }
        return priority_scores.get(self.priority, 3)

# Nutrition models
class NutritionInfo(BaseModel):
    """Nutrition information model"""
    calories: float = Field(ge=0)
    protein: float = Field(ge=0)
    carbohydrates: float = Field(ge=0)
    fat: float = Field(ge=0)
    fiber: float = Field(default=0, ge=0)
    sugar: float = Field(default=0, ge=0)
    sodium: float = Field(default=0, ge=0)

# Recipe models
class RecipeStep(BaseModel):
    """Recipe step model"""
    step_number: int = Field(ge=1)
    description: str

class Recipe(BaseModel):
    """Recipe model"""
    steps: List[RecipeStep]
    cooking_time: int = Field(ge=1)
    prep_time: int = Field(default=10, ge=0)
    difficulty: DifficultyLevel
    tips: List[str] = Field(default_factory=list)
    serving_size: int = Field(default=4, ge=1)
    nutrition_info: NutritionInfo

class MealItem(BaseModel):
    """Individual meal item model"""
    name: str
    category: MealCategory
    description: str
    ingredients: List[Ingredient]
    recipe: Recipe
    cooking_time: int = Field(ge=1)
    difficulty: DifficultyLevel
    nutrition_info: NutritionInfo
    created_at: datetime = Field(default_factory=datetime.now)

# Meal plan models
class MealPlan(BaseModel):
    """Complete meal plan model"""
    household_id: str
    date: datetime
    status: MealPlanStatus
    main_dish: MealItem
    side_dish: MealItem
    soup: MealItem
    rice: MealItem
    total_cooking_time: int = Field(ge=1)
    difficulty: DifficultyLevel
    nutrition_score: float = Field(ge=0, le=100)
    confidence: float = Field(ge=0, le=1)
    created_at: datetime = Field(default_factory=datetime.now)
    created_by: str = "adk_agent"

# Shopping models
class ShoppingItem(BaseModel):
    """Shopping item model"""
    name: str
    quantity: str
    unit: str
    category: str
    is_custom: bool = False
    added_by: str = "adk_agent"
    added_at: datetime = Field(default_factory=datetime.now)
    notes: Optional[str] = None

# API Request/Response models
class MealPlanningRequest(BaseModel):
    """Request model for meal planning"""
    refrigerator_items: List[Product]
    household_id: str
    user_preferences: UserPreferences
    
    @validator('refrigerator_items')
    def validate_refrigerator_items(cls, v):
        if not v:
            raise ValueError('Refrigerator items cannot be empty')
        return v

class MealPlanningResponse(BaseModel):
    """Response model for meal planning"""
    meal_plan: MealPlan
    shopping_list: List[ShoppingItem]
    processing_time: float
    agents_used: List[str]

# Agent-specific models
class IngredientAnalysisRequest(BaseModel):
    """Request for ingredient analysis agent"""
    products: List[Product]
    current_date: datetime = Field(default_factory=datetime.now)

class IngredientAnalysisResult(BaseModel):
    """Result from ingredient analysis agent"""
    analyzed_ingredients: List[Ingredient]
    priority_ingredients: List[Ingredient]
    expiring_soon: List[Ingredient]
    recommendations: List[str]

class NutritionAnalysisRequest(BaseModel):
    """Request for nutrition balance agent"""
    ingredients: List[Ingredient]
    user_preferences: UserPreferences

class NutritionAnalysisResult(BaseModel):
    """Result from nutrition balance agent"""
    nutrition_score: float = Field(ge=0, le=100)
    recommended_nutrients: Dict[str, float]
    warnings: List[str]
    suggestions: List[str]

class RecipeSuggestionRequest(BaseModel):
    """Request for recipe suggestion agent"""
    ingredient_analysis: IngredientAnalysisResult
    nutrition_analysis: NutritionAnalysisResult
    user_preferences: UserPreferences

class RecipeSuggestionResult(BaseModel):
    """Result from recipe suggestion agent"""
    main_dish: MealItem
    side_dish: MealItem
    soup: MealItem
    rice: MealItem
    total_cooking_time: int
    difficulty: DifficultyLevel
    nutrition_score: float
    confidence: float

class CookingOptimizationRequest(BaseModel):
    """Request for cooking optimization agent"""
    recipes: List[MealItem]
    constraints: Dict[str, Any]

class CookingOptimizationResult(BaseModel):
    """Result from cooking optimization agent"""
    optimized_recipes: List[MealItem]
    cooking_schedule: List[Dict[str, Any]]
    total_time: int
    efficiency_score: float

class MealThemeRequest(BaseModel):
    """Request for meal theme agent"""
    recipes: List[MealItem]
    user_preferences: UserPreferences
    current_date: datetime

class MealThemeResult(BaseModel):
    """Result from meal theme agent"""
    theme_name: str
    theme_description: str
    unified_meal_plan: MealPlan
    visual_style: Dict[str, Any]

class ImageGenerationRequest(BaseModel):
    """Request for image generation agent"""
    recipes: List[MealItem]
    meal_theme: MealThemeResult
    image_style: Dict[str, Any]

class ImageGenerationResult(BaseModel):
    """Result from image generation agent"""
    image_urls: List[str]
    image_metadata: List[Dict[str, Any]]
    generation_time: float

class UserPreferenceRequest(BaseModel):
    """Request for user preference conversation agent"""
    user_input: str
    existing_profile: Optional[Dict[str, Any]] = None
    available_ingredients: List[Ingredient]

class UserPreferenceResult(BaseModel):
    """Result from user preference conversation agent"""
    structured_preferences: UserPreferences
    confidence_score: float
    next_questions: List[str]
    updated_profile: Dict[str, Any]

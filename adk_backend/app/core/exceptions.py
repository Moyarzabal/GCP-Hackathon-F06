"""
Custom exceptions for ADK Meal Planning API
"""

from typing import Optional, Dict, Any

class MealPlanningException(Exception):
    """Base exception for meal planning operations"""
    
    def __init__(
        self,
        message: str,
        error_code: str = "MEAL_PLANNING_ERROR",
        status_code: int = 500,
        details: Optional[Dict[str, Any]] = None
    ):
        self.message = message
        self.error_code = error_code
        self.status_code = status_code
        self.details = details or {}
        super().__init__(self.message)

class AgentException(MealPlanningException):
    """Exception raised by ADK agents"""
    
    def __init__(
        self,
        message: str,
        agent_name: str,
        error_code: str = "AGENT_ERROR",
        status_code: int = 500,
        details: Optional[Dict[str, Any]] = None
    ):
        self.agent_name = agent_name
        super().__init__(
            message=f"Agent '{agent_name}' error: {message}",
            error_code=error_code,
            status_code=status_code,
            details=details
        )

class IngredientAnalysisError(AgentException):
    """Exception for ingredient analysis agent"""
    
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(
            message=message,
            agent_name="ingredient_analysis",
            error_code="INGREDIENT_ANALYSIS_ERROR",
            status_code=400,
            details=details
        )

class NutritionBalanceError(AgentException):
    """Exception for nutrition balance agent"""
    
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(
            message=message,
            agent_name="nutrition_balance",
            error_code="NUTRITION_BALANCE_ERROR",
            status_code=400,
            details=details
        )

class RecipeSuggestionError(AgentException):
    """Exception for recipe suggestion agent"""
    
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(
            message=message,
            agent_name="recipe_suggestion",
            error_code="RECIPE_SUGGESTION_ERROR",
            status_code=400,
            details=details
        )

class CookingOptimizationError(AgentException):
    """Exception for cooking optimization agent"""
    
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(
            message=message,
            agent_name="cooking_optimization",
            error_code="COOKING_OPTIMIZATION_ERROR",
            status_code=400,
            details=details
        )

class MealThemeError(AgentException):
    """Exception for meal theme agent"""
    
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(
            message=message,
            agent_name="meal_theme",
            error_code="MEAL_THEME_ERROR",
            status_code=400,
            details=details
        )

class ImageGenerationError(AgentException):
    """Exception for image generation agent"""
    
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(
            message=message,
            agent_name="image_generation",
            error_code="IMAGE_GENERATION_ERROR",
            status_code=400,
            details=details
        )

class UserPreferenceError(AgentException):
    """Exception for user preference conversation agent"""
    
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(
            message=message,
            agent_name="user_preference_conversation",
            error_code="USER_PREFERENCE_ERROR",
            status_code=400,
            details=details
        )

class APIValidationError(MealPlanningException):
    """Exception for API validation errors"""
    
    def __init__(self, message: str, field: Optional[str] = None, details: Optional[Dict[str, Any]] = None):
        super().__init__(
            message=message,
            error_code="VALIDATION_ERROR",
            status_code=400,
            details={"field": field, **(details or {})}
        )

class ExternalAPIError(MealPlanningException):
    """Exception for external API errors"""
    
    def __init__(self, message: str, api_name: str, details: Optional[Dict[str, Any]] = None):
        super().__init__(
            message=f"External API '{api_name}' error: {message}",
            error_code="EXTERNAL_API_ERROR",
            status_code=502,
            details=details
        )

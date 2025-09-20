"""
Configuration management for ADK Meal Planning API
"""

from pydantic_settings import BaseSettings
from typing import Optional
import os

class Settings(BaseSettings):
    """Application settings"""
    
    # API Configuration
    api_title: str = "ADK Meal Planning API"
    api_version: str = "1.0.0"
    debug: bool = False
    
    # ADK Configuration
    gemini_api_key: Optional[str] = None
    # OpenAI API key is no longer needed - using Google Imagen instead
    
    # Agent Configuration
    default_model: str = "gemini-1.5-pro"
    default_temperature: float = 0.7
    default_max_tokens: int = 2048
    
    # Agent-specific settings
    ingredient_analysis_model: str = "gemini-1.5-pro"
    ingredient_analysis_temperature: float = 0.3
    ingredient_analysis_max_tokens: int = 2000
    
    nutrition_balance_model: str = "gemini-1.5-pro"
    nutrition_balance_temperature: float = 0.2
    nutrition_balance_max_tokens: int = 1500
    
    recipe_suggestion_model: str = "gemini-1.5-pro"
    recipe_suggestion_temperature: float = 0.7
    recipe_suggestion_max_tokens: int = 3000
    
    cooking_optimization_model: str = "gemini-1.5-pro"
    cooking_optimization_temperature: float = 0.4
    cooking_optimization_max_tokens: int = 2000
    
    meal_theme_model: str = "gemini-1.5-pro"
    meal_theme_temperature: float = 0.8
    meal_theme_max_tokens: int = 1000
    
    image_generation_model: str = "imagen-3"
    image_generation_temperature: float = 0.9
    image_generation_max_tokens: int = 500
    
    user_preference_model: str = "gemini-1.5-pro"
    user_preference_temperature: float = 0.6
    user_preference_max_tokens: int = 2000
    
    # Redis Configuration (for caching)
    redis_url: str = "redis://localhost:6379"
    cache_ttl: int = 3600  # 1 hour
    
    # Rate limiting
    rate_limit_requests: int = 100
    rate_limit_window: int = 60  # seconds
    
    model_config = {
        "env_file": ".env",
        "case_sensitive": False,
        "extra": "ignore"
    }

# Global settings instance
settings = Settings()

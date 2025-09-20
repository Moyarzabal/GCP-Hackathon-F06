"""
Recipe Suggestion Agent using Google ADK
Suggests recipes based on ingredients and nutrition requirements
"""

import google.generativeai as genai
from typing import List, Dict, Any
import json
import structlog
from datetime import datetime

from app.agents.base_agent import BaseAgent
from app.models.schemas import (
    IngredientAnalysisResult, NutritionAnalysisResult, UserPreferences,
    RecipeSuggestionRequest, RecipeSuggestionResult, MealItem, MealCategory,
    Ingredient, Recipe, RecipeStep, NutritionInfo, DifficultyLevel
)
from app.core.exceptions import RecipeSuggestionError
from app.core.config import settings

logger = structlog.get_logger(__name__)

class RecipeSuggestionAgent(BaseAgent[RecipeSuggestionRequest, RecipeSuggestionResult]):
    """Agent for suggesting recipes based on ingredients and nutrition"""
    
    def __init__(self):
        super().__init__(
            name="recipe_suggestion",
            model=settings.recipe_suggestion_model,
            temperature=settings.recipe_suggestion_temperature,
            max_tokens=settings.recipe_suggestion_max_tokens
        )
        
        # Initialize Gemini
        if settings.gemini_api_key:
            genai.configure(api_key=settings.gemini_api_key)
        else:
            logger.warning("Gemini API key not configured, using mock responses")
    
    def get_system_prompt(self) -> str:
        """Get system prompt for recipe suggestion"""
        return """
あなたは料理の専門家です。
以下の責任を持ってレシピを提案してください：

1. 利用可能な食材を最大限活用した料理提案
2. 栄養バランスを考慮した献立構成
3. 調理時間と難易度を考慮した実用的な提案
4. 主菜・副菜・汁物・主食の4品構成

提案結果は以下の形式でJSON出力してください：
{
  "main_dish": {
    "name": "料理名",
    "description": "料理の説明",
    "cooking_time": 調理時間(分),
    "difficulty": "easy|medium|hard|expert",
    "ingredients": [
      {
        "name": "材料名",
        "quantity": "分量",
        "unit": "単位",
        "available": true,
        "priority": "urgent|soon|fresh|long_term"
      }
    ],
    "recipe": {
      "steps": ["手順1", "手順2", "手順3"],
      "tips": ["コツ1", "コツ2"]
    },
    "nutrition_info": {
      "calories": カロリー,
      "protein": タンパク質(g),
      "carbohydrates": 炭水化物(g),
      "fat": 脂質(g)
    }
  },
  "side_dish": { /* 同様の構造 */ },
  "soup": { /* 同様の構造 */ },
  "rice": { /* 同様の構造 */ },
  "total_cooking_time": 合計調理時間(分),
  "difficulty": "easy|medium|hard|expert",
  "nutrition_score": 栄養スコア(0-100),
  "confidence": 信頼度(0-1)
}

すべてのテキストは日本語で出力してください。
"""
    
    async def process(self, request: RecipeSuggestionRequest) -> RecipeSuggestionResult:
        """Process recipe suggestion request"""
        try:
            await self.validate_request(request)
            processed_request = await self.preprocess_request(request)
            
            logger.info(
                "Processing recipe suggestion",
                ingredient_count=len(processed_request.ingredient_analysis.analyzed_ingredients),
                nutrition_score=processed_request.nutrition_analysis.nutrition_score
            )
            
            # Generate AI recipe suggestions
            if settings.gemini_api_key:
                ai_suggestion = await self._generate_ai_recipes(processed_request)
            else:
                ai_suggestion = self._get_mock_recipes(processed_request)
            
            # Parse and create meal items
            main_dish = self._create_meal_item(ai_suggestion['main_dish'], MealCategory.main, processed_request.ingredient_analysis.analyzed_ingredients)
            side_dish = self._create_meal_item(ai_suggestion['side_dish'], MealCategory.side, processed_request.ingredient_analysis.analyzed_ingredients)
            soup = self._create_meal_item(ai_suggestion['soup'], MealCategory.soup, processed_request.ingredient_analysis.analyzed_ingredients)
            rice = self._create_meal_item(ai_suggestion['rice'], MealCategory.rice, processed_request.ingredient_analysis.analyzed_ingredients)
            
            # Create result
            result = RecipeSuggestionResult(
                main_dish=main_dish,
                side_dish=side_dish,
                soup=soup,
                rice=rice,
                total_cooking_time=ai_suggestion['total_cooking_time'],
                difficulty=DifficultyLevel(ai_suggestion['difficulty']),
                nutrition_score=ai_suggestion['nutrition_score'],
                confidence=ai_suggestion['confidence']
            )
            
            return await self.postprocess_response(result)
            
        except Exception as e:
            await self.handle_error(e, request)
            raise RecipeSuggestionError(f"Failed to suggest recipes: {str(e)}")
    
    async def _generate_ai_recipes(self, request: RecipeSuggestionRequest) -> Dict[str, Any]:
        """Generate AI recipe suggestions"""
        try:
            # Create ingredients summary
            ingredients_summary = []
            for ingredient in request.ingredient_analysis.analyzed_ingredients:
                priority_text = ""
                if ingredient.priority.name == "urgent":
                    priority_text = "[緊急]"
                elif ingredient.priority.name == "soon":
                    priority_text = "[期限間近]"
                
                ingredients_summary.append(
                    f"{priority_text}{ingredient.name} {ingredient.quantity}{ingredient.unit} ({ingredient.category})"
                )
            
            # Create user preferences summary
            restrictions_text = ""
            if request.user_preferences.dietary_restrictions:
                restrictions_text = f"Restrictions: {', '.join(request.user_preferences.dietary_restrictions)}"
            
            allergies_text = ""
            if request.user_preferences.allergies:
                allergies_text = f"Allergies: {', '.join(request.user_preferences.allergies)}"
            
            prompt = f"""
You are a cooking expert. Please suggest a meal plan following these principles:

[Principles]
1. Prioritize ingredients with close expiry dates ([緊急] and [期限間近] marked ingredients have highest priority)
2. Good nutritional balance
3. Consider cooking time and difficulty
4. Consider seasonality and timing
5. Consist of main dish, side dish, soup, and staple food (4 items)

[Available Ingredients]
{chr(10).join(ingredients_summary)}

[User Settings]
- Max cooking time: {request.user_preferences.max_cooking_time} minutes
- Difficulty: {request.user_preferences.preferred_difficulty.name}
{restrictions_text}
{allergies_text}

[Nutrition Requirements]
- Current nutrition score: {request.nutrition_analysis.nutrition_score}
- Recommended nutrients: {request.nutrition_analysis.recommended_nutrients}

[Output Format]
Please suggest a meal plan in the following JSON format:

{{
  "main_dish": {{
    "name": "Menu name in Japanese",
    "description": "Brief description in Japanese",
    "cooking_time": cooking_time_in_minutes,
    "difficulty": "easy/medium/hard/expert",
    "ingredients": [
      {{
        "name": "玉ねぎ",
        "quantity": "1個",
        "unit": "個",
        "available": true,
        "priority": "urgent"
      }}
    ],
    "recipe": {{
      "steps": ["Step 1 in Japanese", "Step 2 in Japanese", "Step 3 in Japanese"],
      "tips": ["Tip 1 in Japanese", "Tip 2 in Japanese"]
    }},
    "nutrition_info": {{
      "calories": calories_number,
      "protein": protein_grams,
      "carbohydrates": carbs_grams,
      "fat": fat_grams
    }}
  }},
  "side_dish": {{ /* Same structure */ }},
  "soup": {{ /* Same structure */ }},
  "rice": {{ /* Same structure */ }},
  "total_cooking_time": total_cooking_time_in_minutes,
  "difficulty": "easy/medium/hard/expert",
  "nutrition_score": nutrition_score_0_to_100,
  "confidence": confidence_0_to_1
}}

CRITICAL REQUIREMENTS:
- All text content should be in Japanese
- String fields (name, description, quantity, unit, steps, tips) MUST be quoted with double quotes
- Numeric fields (cookingTime, calories, protein, carbohydrates, fat, totalCookingTime, nutritionScore, confidence) MUST be numbers without quotes
- Boolean fields (available) MUST be true/false without quotes
- For quantity field: use format like "1個", "2本", "大さじ1", "小さじ2", "100g" (number + unit)
- For unit field: use simple units like "個", "本", "枚", "g", "ml" (unit only)
- Return ONLY valid JSON format
- Do NOT include any text outside the JSON
"""
            
            model = genai.GenerativeModel(self.model)
            response = model.generate_content(
                prompt,
                generation_config=genai.types.GenerationConfig(
                    temperature=self.temperature,
                    max_output_tokens=self.max_tokens,
                )
            )
            
            if response.text:
                # Parse JSON response
                json_start = response.text.find('{')
                json_end = response.text.rfind('}') + 1
                
                if json_start != -1 and json_end > json_start:
                    json_str = response.text[json_start:json_end]
                    data = json.loads(json_str)
                    return data
            
            return self._get_mock_recipes(request)
            
        except Exception as e:
            logger.warning(f"Failed to generate AI recipes: {e}")
            return self._get_mock_recipes(request)
    
    def _get_mock_recipes(self, request: RecipeSuggestionRequest) -> Dict[str, Any]:
        """Get mock recipes when AI is not available"""
        # Use priority ingredients for mock recipes
        priority_ingredients = [
            ing for ing in request.ingredient_analysis.analyzed_ingredients 
            if ing.priority.name in ['urgent', 'soon']
        ]
        
        if not priority_ingredients:
            priority_ingredients = request.ingredient_analysis.analyzed_ingredients[:3]
        
        # Create mock recipes based on available ingredients
        main_ingredient = priority_ingredients[0] if priority_ingredients else None
        
        if main_ingredient:
            main_dish_name = f"{main_ingredient.name}の炒め物"
            main_dish_desc = f"{main_ingredient.name}を使った栄養満点の炒め物"
        else:
            main_dish_name = "野菜炒め"
            main_dish_desc = "色とりどりの野菜を使った炒め物"
        
        return {
            "main_dish": {
                "name": main_dish_name,
                "description": main_dish_desc,
                "cooking_time": 15,
                "difficulty": "easy",
                "ingredients": [
                    {
                        "name": main_ingredient.name if main_ingredient else "野菜",
                        "quantity": "適量",
                        "unit": "g",
                        "available": True,
                        "priority": main_ingredient.priority.name if main_ingredient else "fresh"
                    }
                ],
                "recipe": {
                    "steps": [
                        "材料を切る",
                        "フライパンで炒める",
                        "調味料で味付けする"
                    ],
                    "tips": [
                        "強火で短時間で炒める",
                        "最後に醤油を加える"
                    ]
                },
                "nutrition_info": {
                    "calories": 200,
                    "protein": 15,
                    "carbohydrates": 10,
                    "fat": 8
                }
            },
            "side_dish": {
                "name": "サラダ",
                "description": "新鮮な野菜のサラダ",
                "cooking_time": 5,
                "difficulty": "easy",
                "ingredients": [
                    {
                        "name": "レタス",
                        "quantity": "1玉",
                        "unit": "玉",
                        "available": True,
                        "priority": "fresh"
                    }
                ],
                "recipe": {
                    "steps": [
                        "野菜を洗う",
                        "適当な大きさに切る",
                        "ドレッシングをかける"
                    ],
                    "tips": [
                        "水気をよく切る",
                        "食べる直前にドレッシングをかける"
                    ]
                },
                "nutrition_info": {
                    "calories": 50,
                    "protein": 2,
                    "carbohydrates": 8,
                    "fat": 1
                }
            },
            "soup": {
                "name": "味噌汁",
                "description": "具沢山の味噌汁",
                "cooking_time": 10,
                "difficulty": "easy",
                "ingredients": [
                    {
                        "name": "豆腐",
                        "quantity": "1/2丁",
                        "unit": "丁",
                        "available": True,
                        "priority": "fresh"
                    }
                ],
                "recipe": {
                    "steps": [
                        "出汁を取る",
                        "具材を入れる",
                        "味噌を溶かす"
                    ],
                    "tips": [
                        "味噌は最後に入れる",
                        "沸騰させない"
                    ]
                },
                "nutrition_info": {
                    "calories": 80,
                    "protein": 5,
                    "carbohydrates": 6,
                    "fat": 3
                }
            },
            "rice": {
                "name": "白米",
                "description": "ふっくらとした白米",
                "cooking_time": 30,
                "difficulty": "easy",
                "ingredients": [
                    {
                        "name": "米",
                        "quantity": "2合",
                        "unit": "合",
                        "available": True,
                        "priority": "long_term"
                    }
                ],
                "recipe": {
                    "steps": [
                        "米を洗う",
                        "水加減を調整する",
                        "炊飯器で炊く"
                    ],
                    "tips": [
                        "しっかりと研ぐ",
                        "水加減を正確に"
                    ]
                },
                "nutrition_info": {
                    "calories": 300,
                    "protein": 6,
                    "carbohydrates": 65,
                    "fat": 1
                }
            },
            "total_cooking_time": 30,
            "difficulty": "easy",
            "nutrition_score": 80,
            "confidence": 0.8
        }
    
    def _create_meal_item(
        self, 
        dish_data: Dict[str, Any], 
        category: MealCategory,
        available_ingredients: List[Ingredient]
    ) -> MealItem:
        """Create a MealItem from dish data"""
        
        # Parse ingredients
        ingredients = []
        for ing_data in dish_data.get('ingredients', []):
            # Find matching available ingredient
            available_ingredient = next(
                (ing for ing in available_ingredients if ing.name == ing_data['name']),
                None
            )
            
            if available_ingredient:
                ingredient = available_ingredient.copyWith(
                    quantity=ing_data.get('quantity', available_ingredient.quantity),
                    unit=ing_data.get('unit', available_ingredient.unit),
                    available=ing_data.get('available', True),
                )
            else:
                # Create new ingredient if not found in available ingredients
                from app.models.schemas import ExpiryPriority
                ingredient = Ingredient(
                    name=ing_data['name'],
                    quantity=ing_data.get('quantity', '適量'),
                    unit=ing_data.get('unit', 'g'),
                    available=ing_data.get('available', False),
                    shoppingRequired=not ing_data.get('available', False),
                    priority=ExpiryPriority(ing_data.get('priority', 'fresh')),
                    category='その他',
                )
            
            ingredients.append(ingredient)
        
        # Create recipe
        recipe_data = dish_data.get('recipe', {})
        recipe = Recipe(
            steps=[
                RecipeStep(stepNumber=i+1, description=step)
                for i, step in enumerate(recipe_data.get('steps', []))
            ],
            cookingTime=dish_data.get('cooking_time', 30),
            prepTime=10,
            difficulty=DifficultyLevel(dish_data.get('difficulty', 'easy')),
            tips=recipe_data.get('tips', []),
            servingSize=4,
            nutritionInfo=NutritionInfo(
                calories=float(dish_data.get('nutrition_info', {}).get('calories', 0)),
                protein=float(dish_data.get('nutrition_info', {}).get('protein', 0)),
                carbohydrates=float(dish_data.get('nutrition_info', {}).get('carbohydrates', 0)),
                fat=float(dish_data.get('nutrition_info', {}).get('fat', 0)),
            )
        )
        
        # Create meal item
        return MealItem(
            name=dish_data.get('name', ''),
            category=category,
            description=dish_data.get('description', ''),
            ingredients=ingredients,
            recipe=recipe,
            cookingTime=dish_data.get('cooking_time', 30),
            difficulty=DifficultyLevel(dish_data.get('difficulty', 'easy')),
            nutritionInfo=recipe.nutritionInfo,
            createdAt=datetime.now()
        )

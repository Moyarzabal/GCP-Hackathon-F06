"""
Meal Theme Agent using Google ADK
Determines meal theme and creates unified meal plan
"""

import google.generativeai as genai
from typing import List, Dict, Any
import json
import structlog
from datetime import datetime

from app.agents.base_agent import BaseAgent
from app.models.schemas import (
    MealItem, UserPreferences, MealThemeRequest, MealThemeResult,
    MealPlan, MealPlanStatus, DifficultyLevel
)
from app.core.exceptions import MealThemeError
from app.core.config import settings

logger = structlog.get_logger(__name__)

class MealThemeAgent(BaseAgent[MealThemeRequest, MealThemeResult]):
    """Agent for determining meal theme and creating unified meal plan"""
    
    def __init__(self):
        super().__init__(
            name="meal_theme",
            model=settings.meal_theme_model,
            temperature=settings.meal_theme_temperature,
            max_tokens=settings.meal_theme_max_tokens
        )
        
        # Initialize Gemini
        if settings.gemini_api_key:
            genai.configure(api_key=settings.gemini_api_key)
        else:
            logger.warning("Gemini API key not configured, using mock responses")
    
    def get_system_prompt(self) -> str:
        """Get system prompt for meal theme determination"""
        return """
あなたは献立のテーマとコンセプトの専門家です。
以下の責任を持って献立テーマを決定してください：

1. 献立全体のテーマ・コンセプトの決定
2. 料理の統一感の確保
3. 季節感・イベント感の演出
4. ユーザーの好みに基づくテーマ選択
5. 統一感のある献立の調整提案

テーマ決定結果は以下の形式でJSON出力してください：
{
  "theme_name": "テーマ名",
  "theme_description": "テーマの詳細説明",
  "unified_meal_plan": {
    "household_id": "世帯ID",
    "date": "日付",
    "status": "suggested",
    "main_dish": { /* 調整された主菜 */ },
    "side_dish": { /* 調整された副菜 */ },
    "soup": { /* 調整された汁物 */ },
    "rice": { /* 調整された主食 */ },
    "total_cooking_time": 合計調理時間(分),
    "difficulty": "easy|medium|hard|expert",
    "nutrition_score": 栄養スコア(0-100),
    "confidence": 信頼度(0-1)
  },
  "visual_style": {
    "color_palette": ["色1", "色2", "色3"],
    "mood": "雰囲気の説明",
    "presentation_style": "盛り付けスタイル"
  }
}

テーマの例：
- 和風家庭料理テーマ
- 中華風炒め物テーマ
- イタリアン家庭料理テーマ
- ヘルシー野菜中心テーマ
- 簡単時短料理テーマ

すべてのテキストは日本語で出力してください。
"""
    
    async def process(self, request: MealThemeRequest) -> MealThemeResult:
        """Process meal theme determination request"""
        try:
            await self.validate_request(request)
            processed_request = await self.preprocess_request(request)
            
            logger.info(
                "Processing meal theme determination",
                recipe_count=len(processed_request.recipes)
            )
            
            # Generate AI theme determination
            if settings.gemini_api_key:
                ai_theme = await self._generate_ai_theme(processed_request)
            else:
                ai_theme = self._get_mock_theme(processed_request)
            
            # Create unified meal plan
            unified_meal_plan = self._create_unified_meal_plan(
                processed_request.recipes,
                ai_theme['unified_meal_plan']
            )
            
            # Create result
            result = MealThemeResult(
                theme_name=ai_theme['theme_name'],
                theme_description=ai_theme['theme_description'],
                unified_meal_plan=unified_meal_plan,
                visual_style=ai_theme['visual_style']
            )
            
            return await self.postprocess_response(result)
            
        except Exception as e:
            await self.handle_error(e, request)
            raise MealThemeError(f"Failed to determine meal theme: {str(e)}")
    
    async def _generate_ai_theme(self, request: MealThemeRequest) -> Dict[str, Any]:
        """Generate AI meal theme determination"""
        try:
            # Create recipes summary
            recipes_summary = []
            for recipe in request.recipes:
                recipes_summary.append(
                    f"- {recipe.name}: {recipe.description} ({recipe.cookingTime}分)"
                )
            
            # Create user preferences summary
            preferences_text = f"""
- 最大調理時間: {request.user_preferences.max_cooking_time}分
- 難易度: {request.user_preferences.preferred_difficulty.name}
- 好みの料理ジャンル: {', '.join(request.user_preferences.preferred_cuisines)}
- 食事制限: {', '.join(request.user_preferences.dietary_restrictions)}
"""
            
            current_date = request.current_date
            season = self._determine_season(current_date)
            
            prompt = f"""
以下の料理リストを分析して、統一感のある献立テーマを決定してください：

【料理リスト】
{chr(10).join(recipes_summary)}

【ユーザー設定】
{preferences_text}

【現在の情報】
- 日付: {current_date.strftime('%Y年%m月%d日')}
- 季節: {season}

【テーマ決定のポイント】
1. 料理の味付けや調理法の統一感
2. 季節感や旬の食材の活用
3. ユーザーの好みとの一致
4. 視覚的な統一感
5. 栄養バランスの維持

以下の形式でJSON出力してください：
{{
  "theme_name": "テーマ名",
  "theme_description": "テーマの詳細説明とコンセプト",
  "unified_meal_plan": {{
    "household_id": "household_123",
    "date": "{current_date.isoformat()}",
    "status": "suggested",
    "main_dish": {{
      "name": "調整された主菜名",
      "description": "調整された説明",
      "cooking_time": 調理時間(分),
      "difficulty": "easy|medium|hard|expert"
    }},
    "side_dish": {{
      "name": "調整された副菜名",
      "description": "調整された説明",
      "cooking_time": 調理時間(分),
      "difficulty": "easy|medium|hard|expert"
    }},
    "soup": {{
      "name": "調整された汁物名",
      "description": "調整された説明",
      "cooking_time": 調理時間(分),
      "difficulty": "easy|medium|hard|expert"
    }},
    "rice": {{
      "name": "調整された主食名",
      "description": "調整された説明",
      "cooking_time": 調理時間(分),
      "difficulty": "easy|medium|hard|expert"
    }},
    "total_cooking_time": 合計調理時間(分),
    "difficulty": "easy|medium|hard|expert",
    "nutrition_score": 栄養スコア(0-100),
    "confidence": 信頼度(0-1)
  }},
  "visual_style": {{
    "color_palette": ["色1", "色2", "色3"],
    "mood": "雰囲気の説明",
    "presentation_style": "盛り付けスタイルの説明"
  }}
}}

テーマの例：
- 「和風家庭料理テーマ」: 醤油ベースの味付けで統一
- 「中華風炒め物テーマ」: オイスターソースや豆板醤で統一
- 「ヘルシー野菜中心テーマ」: 野菜を主役にした軽やかな味付け
- 「簡単時短料理テーマ」: 15分以内で完成する手軽な料理

すべてのテキストは日本語で出力してください。
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
                    
                    # Validate and clean data
                    return {
                        'theme_name': data.get('theme_name', '統一献立テーマ'),
                        'theme_description': data.get('theme_description', 'バランスの取れた献立'),
                        'unified_meal_plan': data.get('unified_meal_plan', {}),
                        'visual_style': data.get('visual_style', {
                            'color_palette': ['緑', '白', '茶'],
                            'mood': '家庭的な雰囲気',
                            'presentation_style': 'シンプルで温かみのある盛り付け'
                        })
                    }
            
            return self._get_mock_theme(request)
            
        except Exception as e:
            logger.warning(f"Failed to generate AI meal theme: {e}")
            return self._get_mock_theme(request)
    
    def _get_mock_theme(self, request: MealThemeRequest) -> Dict[str, Any]:
        """Get mock theme when AI is not available"""
        recipes = request.recipes
        season = self._determine_season(request.current_date)
        
        # Determine theme based on recipes
        if any('和' in recipe.name or '味噌' in recipe.name for recipe in recipes):
            theme_name = "和風家庭料理テーマ"
            theme_description = "醤油と味噌をベースにした和風の味付けで統一した家庭料理"
        elif any('中華' in recipe.name or '炒め' in recipe.name for recipe in recipes):
            theme_name = "中華風炒め物テーマ"
            theme_description = "オイスターソースや豆板醤を使った中華風の炒め物中心の献立"
        elif any('野菜' in recipe.name or 'サラダ' in recipe.name for recipe in recipes):
            theme_name = "ヘルシー野菜中心テーマ"
            theme_description = "野菜を主役にしたヘルシーで軽やかな味付けの献立"
        else:
            theme_name = f"{season}の家庭料理テーマ"
            theme_description = f"{season}の食材を活かした温かみのある家庭料理"
        
        # Calculate total cooking time and difficulty
        total_time = sum(recipe.cookingTime for recipe in recipes)
        avg_difficulty = sum(self._difficulty_to_score(recipe.difficulty) for recipe in recipes) / len(recipes)
        overall_difficulty = self._score_to_difficulty(avg_difficulty)
        
        # Create unified meal plan data
        unified_meal_plan = {
            "household_id": "household_123",
            "date": request.current_date.isoformat(),
            "status": "suggested",
            "main_dish": {
                "name": recipes[0].name if len(recipes) > 0 else "主菜",
                "description": f"{theme_name}に合わせて調整された{recipes[0].description if len(recipes) > 0 else '主菜'}",
                "cooking_time": recipes[0].cookingTime if len(recipes) > 0 else 20,
                "difficulty": overall_difficulty.name
            },
            "side_dish": {
                "name": recipes[1].name if len(recipes) > 1 else "副菜",
                "description": f"{theme_name}に合わせて調整された{recipes[1].description if len(recipes) > 1 else '副菜'}",
                "cooking_time": recipes[1].cookingTime if len(recipes) > 1 else 15,
                "difficulty": overall_difficulty.name
            },
            "soup": {
                "name": recipes[2].name if len(recipes) > 2 else "汁物",
                "description": f"{theme_name}に合わせて調整された{recipes[2].description if len(recipes) > 2 else '汁物'}",
                "cooking_time": recipes[2].cookingTime if len(recipes) > 2 else 10,
                "difficulty": overall_difficulty.name
            },
            "rice": {
                "name": recipes[3].name if len(recipes) > 3 else "主食",
                "description": f"{theme_name}に合わせて調整された{recipes[3].description if len(recipes) > 3 else '主食'}",
                "cooking_time": recipes[3].cookingTime if len(recipes) > 3 else 30,
                "difficulty": overall_difficulty.name
            },
            "total_cooking_time": total_time,
            "difficulty": overall_difficulty.name,
            "nutrition_score": 85,
            "confidence": 0.8
        }
        
        return {
            'theme_name': theme_name,
            'theme_description': theme_description,
            'unified_meal_plan': unified_meal_plan,
            'visual_style': {
                'color_palette': ['緑', '白', '茶'],
                'mood': '家庭的な温かみのある雰囲気',
                'presentation_style': 'シンプルで美しい盛り付け'
            }
        }
    
    def _determine_season(self, date: datetime) -> str:
        """Determine season from date"""
        month = date.month
        if month in [12, 1, 2]:
            return "冬"
        elif month in [3, 4, 5]:
            return "春"
        elif month in [6, 7, 8]:
            return "夏"
        else:
            return "秋"
    
    def _difficulty_to_score(self, difficulty: DifficultyLevel) -> int:
        """Convert difficulty level to score"""
        difficulty_scores = {
            DifficultyLevel.EASY: 1,
            DifficultyLevel.MEDIUM: 2,
            DifficultyLevel.HARD: 3,
            DifficultyLevel.EXPERT: 4,
        }
        return difficulty_scores.get(difficulty, 1)
    
    def _score_to_difficulty(self, score: float) -> DifficultyLevel:
        """Convert score to difficulty level"""
        if score <= 1.5:
            return DifficultyLevel.EASY
        elif score <= 2.5:
            return DifficultyLevel.MEDIUM
        elif score <= 3.5:
            return DifficultyLevel.HARD
        else:
            return DifficultyLevel.EXPERT
    
    def _create_unified_meal_plan(
        self, 
        original_recipes: List[MealItem], 
        unified_data: Dict[str, Any]
    ) -> MealPlan:
        """Create unified meal plan from original recipes and theme data"""
        # This is a simplified implementation
        # In a real system, you would create new MealItem instances based on the unified data
        
        return MealPlan(
            householdId=unified_data.get('household_id', 'household_123'),
            date=datetime.fromisoformat(unified_data.get('date', datetime.now().isoformat())),
            status=MealPlanStatus.SUGGESTED,
            mainDish=original_recipes[0] if len(original_recipes) > 0 else self._create_default_meal_item("主菜"),
            sideDish=original_recipes[1] if len(original_recipes) > 1 else self._create_default_meal_item("副菜"),
            soup=original_recipes[2] if len(original_recipes) > 2 else self._create_default_meal_item("汁物"),
            rice=original_recipes[3] if len(original_recipes) > 3 else self._create_default_meal_item("主食"),
            totalCookingTime=unified_data.get('total_cooking_time', 60),
            difficulty=DifficultyLevel(unified_data.get('difficulty', 'easy')),
            nutritionScore=float(unified_data.get('nutrition_score', 80)),
            confidence=float(unified_data.get('confidence', 0.8)),
            createdAt=datetime.now(),
            createdBy='adk_agent'
        )
    
    def _create_default_meal_item(self, name: str) -> MealItem:
        """Create a default meal item"""
        from app.models.schemas import MealCategory, Ingredient, Recipe, RecipeStep, NutritionInfo, DifficultyLevel
        
        return MealItem(
            name=name,
            category=MealCategory.MAIN,
            description=f"デフォルトの{name}",
            ingredients=[],
            recipe=Recipe(
                steps=[RecipeStep(stepNumber=1, description=f"{name}を作る")],
                cookingTime=20,
                prepTime=10,
                difficulty=DifficultyLevel.EASY,
                tips=[],
                servingSize=4,
                nutritionInfo=NutritionInfo(calories=200, protein=10, carbohydrates=20, fat=5)
            ),
            cookingTime=20,
            difficulty=DifficultyLevel.EASY,
            nutritionInfo=NutritionInfo(calories=200, protein=10, carbohydrates=20, fat=5),
            createdAt=datetime.now()
        )

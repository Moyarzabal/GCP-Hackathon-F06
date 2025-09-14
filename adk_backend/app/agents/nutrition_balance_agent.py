"""
Nutrition Balance Agent using Google ADK
Analyzes nutrition balance and provides recommendations
"""

import google.generativeai as genai
from typing import List, Dict, Any
import json
import structlog

from app.agents.base_agent import BaseAgent
from app.models.schemas import (
    Ingredient, UserPreferences, NutritionAnalysisRequest, 
    NutritionAnalysisResult
)
from app.core.exceptions import NutritionBalanceError
from app.core.config import settings

logger = structlog.get_logger(__name__)

class NutritionBalanceAgent(BaseAgent[NutritionAnalysisRequest, NutritionAnalysisResult]):
    """Agent for analyzing nutrition balance"""
    
    def __init__(self):
        super().__init__(
            name="nutrition_balance",
            model=settings.nutrition_balance_model,
            temperature=settings.nutrition_balance_temperature,
            max_tokens=settings.nutrition_balance_max_tokens
        )
        
        # Initialize Gemini
        if settings.gemini_api_key:
            genai.configure(api_key=settings.gemini_api_key)
        else:
            logger.warning("Gemini API key not configured, using mock responses")
    
    def get_system_prompt(self) -> str:
        """Get system prompt for nutrition balance analysis"""
        return """
あなたは栄養学の専門家です。
以下の責任を持って栄養バランスを分析してください：

1. 食材の栄養成分を分析
2. 栄養バランスの評価
3. 不足している栄養素の特定
4. 健康的な献立のための推奨事項

分析結果は以下の形式でJSON出力してください：
{
  "nutrition_score": 0-100の数値,
  "recommended_nutrients": {
    "protein": 推奨タンパク質量(g),
    "carbohydrates": 推奨炭水化物量(g),
    "fat": 推奨脂質量(g),
    "fiber": 推奨食物繊維量(g),
    "vitamins": 推奨ビタミン量,
    "minerals": 推奨ミネラル量
  },
  "warnings": ["警告事項リスト"],
  "suggestions": ["改善提案リスト"]
}

栄養スコアの基準：
- 90-100: 優秀な栄養バランス
- 80-89: 良好な栄養バランス
- 70-79: 普通の栄養バランス
- 60-69: 改善が必要
- 60未満: 大幅な改善が必要

すべてのテキストは日本語で出力してください。
"""
    
    async def process(self, request: NutritionAnalysisRequest) -> NutritionAnalysisResult:
        """Process nutrition balance analysis request"""
        try:
            await self.validate_request(request)
            processed_request = await self.preprocess_request(request)
            
            logger.info(
                "Processing nutrition balance analysis",
                ingredient_count=len(processed_request.ingredients)
            )
            
            # Calculate basic nutrition analysis
            basic_analysis = self._calculate_basic_nutrition(processed_request.ingredients)
            
            # Generate AI recommendations
            ai_recommendations = await self._generate_ai_recommendations(
                processed_request.ingredients,
                processed_request.user_preferences,
                basic_analysis
            )
            
            # Create result
            result = NutritionAnalysisResult(
                nutrition_score=ai_recommendations['nutrition_score'],
                recommended_nutrients=ai_recommendations['recommended_nutrients'],
                warnings=ai_recommendations['warnings'],
                suggestions=ai_recommendations['suggestions']
            )
            
            return await self.postprocess_response(result)
            
        except Exception as e:
            await self.handle_error(e, request)
            raise NutritionBalanceError(f"Failed to analyze nutrition balance: {str(e)}")
    
    def _calculate_basic_nutrition(self, ingredients: List[Ingredient]) -> Dict[str, Any]:
        """Calculate basic nutrition information from ingredients"""
        total_calories = 0.0
        total_protein = 0.0
        total_carbs = 0.0
        total_fat = 0.0
        
        # Simple nutrition estimation based on ingredient categories
        for ingredient in ingredients:
            category = ingredient.category.lower()
            
            # Basic nutrition values per 100g (rough estimates)
            if '野菜' in category or '果物' in category:
                total_calories += 25
                total_carbs += 5
            elif '肉' in category or '魚' in category:
                total_calories += 200
                total_protein += 20
                total_fat += 10
            elif '乳製品' in category:
                total_calories += 150
                total_protein += 8
                total_fat += 8
            elif '主食' in category or '米' in category:
                total_calories += 350
                total_carbs += 75
            else:
                # Default estimation
                total_calories += 100
                total_carbs += 15
        
        return {
            'calories': total_calories,
            'protein': total_protein,
            'carbohydrates': total_carbs,
            'fat': total_fat
        }
    
    async def _generate_ai_recommendations(
        self, 
        ingredients: List[Ingredient], 
        user_preferences: UserPreferences,
        basic_analysis: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Generate AI recommendations for nutrition balance"""
        if not settings.gemini_api_key:
            return self._get_mock_recommendations(ingredients, basic_analysis)
        
        try:
            # Create ingredients summary
            ingredients_summary = []
            for ingredient in ingredients:
                ingredients_summary.append(
                    f"- {ingredient.name} ({ingredient.category})"
                )
            
            # Create user preferences summary
            restrictions_text = ""
            if user_preferences.dietary_restrictions:
                restrictions_text = f"食事制限: {', '.join(user_preferences.dietary_restrictions)}"
            
            allergies_text = ""
            if user_preferences.allergies:
                allergies_text = f"アレルギー: {', '.join(user_preferences.allergies)}"
            
            prompt = f"""
以下の食材とユーザー設定を基に、栄養バランスを分析してください：

【食材リスト】
{chr(10).join(ingredients_summary)}

【現在の栄養素（推定）】
- カロリー: {basic_analysis['calories']:.1f}kcal
- タンパク質: {basic_analysis['protein']:.1f}g
- 炭水化物: {basic_analysis['carbohydrates']:.1f}g
- 脂質: {basic_analysis['fat']:.1f}g

【ユーザー設定】
- 最大調理時間: {user_preferences.max_cooking_time}分
- 難易度: {user_preferences.preferred_difficulty}
{restrictions_text}
{allergies_text}

以下の形式でJSON出力してください：
{{
  "nutrition_score": 0-100の数値,
  "recommended_nutrients": {{
    "protein": 推奨タンパク質量(g),
    "carbohydrates": 推奨炭水化物量(g),
    "fat": 推奨脂質量(g),
    "fiber": 推奨食物繊維量(g)
  }},
  "warnings": ["警告事項リスト"],
  "suggestions": ["改善提案リスト"]
}}

栄養スコアは、現在の食材で達成可能な栄養バランスを0-100で評価してください。
推奨事項は具体的で実用的なアドバイスを日本語で提供してください。
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
                    nutrition_score = max(0, min(100, data.get('nutrition_score', 75)))
                    recommended_nutrients = data.get('recommended_nutrients', {})
                    warnings = data.get('warnings', [])
                    suggestions = data.get('suggestions', [])
                    
                    return {
                        'nutrition_score': nutrition_score,
                        'recommended_nutrients': recommended_nutrients,
                        'warnings': warnings if isinstance(warnings, list) else [],
                        'suggestions': suggestions if isinstance(suggestions, list) else []
                    }
            
            return self._get_mock_recommendations(ingredients, basic_analysis)
            
        except Exception as e:
            logger.warning(f"Failed to generate AI nutrition recommendations: {e}")
            return self._get_mock_recommendations(ingredients, basic_analysis)
    
    def _get_mock_recommendations(
        self, 
        ingredients: List[Ingredient], 
        basic_analysis: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Get mock recommendations when AI is not available"""
        # Calculate nutrition score based on ingredient diversity
        categories = set(ingredient.category for ingredient in ingredients)
        diversity_score = min(len(categories) * 15, 100)
        
        # Adjust score based on basic nutrition
        protein_score = min(basic_analysis['protein'] * 2, 30)
        carb_score = min(basic_analysis['carbohydrates'] / 5, 30)
        fat_score = min(basic_analysis['fat'] * 3, 30)
        
        nutrition_score = min(diversity_score + protein_score + carb_score + fat_score, 100)
        
        recommendations = {
            'nutrition_score': nutrition_score,
            'recommended_nutrients': {
                'protein': 60.0,
                'carbohydrates': 200.0,
                'fat': 50.0,
                'fiber': 25.0
            },
            'warnings': [],
            'suggestions': []
        }
        
        # Add warnings based on analysis
        if basic_analysis['protein'] < 30:
            recommendations['warnings'].append('タンパク質が不足しています')
            recommendations['suggestions'].append('肉類や魚類を追加してください')
        
        if basic_analysis['carbohydrates'] < 100:
            recommendations['warnings'].append('炭水化物が不足しています')
            recommendations['suggestions'].append('主食を追加してください')
        
        if len(categories) < 4:
            recommendations['warnings'].append('食材の種類が少ないです')
            recommendations['suggestions'].append('野菜や果物を追加してください')
        
        if not recommendations['warnings']:
            recommendations['suggestions'].append('バランスの良い献立です')
        
        return recommendations

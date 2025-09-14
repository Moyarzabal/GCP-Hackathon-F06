"""
Cooking Optimization Agent using Google ADK
Optimizes cooking process and timing
"""

import google.generativeai as genai
from typing import List, Dict, Any
import json
import structlog

from app.agents.base_agent import BaseAgent
from app.models.schemas import (
    MealItem, CookingOptimizationRequest, CookingOptimizationResult,
    DifficultyLevel
)
from app.core.exceptions import CookingOptimizationError
from app.core.config import settings

logger = structlog.get_logger(__name__)

class CookingOptimizationAgent(BaseAgent[CookingOptimizationRequest, CookingOptimizationResult]):
    """Agent for optimizing cooking process and timing"""
    
    def __init__(self):
        super().__init__(
            name="cooking_optimization",
            model=settings.cooking_optimization_model,
            temperature=settings.cooking_optimization_temperature,
            max_tokens=settings.cooking_optimization_max_tokens
        )
        
        # Initialize Gemini
        if settings.gemini_api_key:
            genai.configure(api_key=settings.gemini_api_key)
        else:
            logger.warning("Gemini API key not configured, using mock responses")
    
    def get_system_prompt(self) -> str:
        """Get system prompt for cooking optimization"""
        return """
あなたは調理の効率化の専門家です。
以下の責任を持って調理プロセスを最適化してください：

1. 調理時間の最適化
2. 調理順序の提案
3. 効率的な調理手順の提案
4. 同時調理の提案
5. 調理器具の効率的な使用

最適化結果は以下の形式でJSON出力してください：
{
  "optimized_recipes": [
    {
      "name": "料理名",
      "optimized_cooking_time": 最適化後の調理時間(分),
      "preparation_order": 準備順序,
      "cooking_tips": ["調理のコツ1", "調理のコツ2"]
    }
  ],
  "cooking_schedule": [
    {
      "time": 時刻,
      "action": "アクション",
      "duration": 所要時間(分),
      "parallel": 並行可能フラグ
    }
  ],
  "total_time": 合計調理時間(分),
  "efficiency_score": 効率スコア(0-100)
}

効率スコアの基準：
- 90-100: 非常に効率的
- 80-89: 効率的
- 70-79: 普通
- 60-69: 改善余地あり
- 60未満: 非効率

すべてのテキストは日本語で出力してください。
"""
    
    async def process(self, request: CookingOptimizationRequest) -> CookingOptimizationResult:
        """Process cooking optimization request"""
        try:
            await self.validate_request(request)
            processed_request = await self.preprocess_request(request)
            
            logger.info(
                "Processing cooking optimization",
                recipe_count=len(processed_request.recipes),
                max_cooking_time=processed_request.constraints.get('max_cooking_time', 60)
            )
            
            # Generate AI optimization
            if settings.gemini_api_key:
                ai_optimization = await self._generate_ai_optimization(processed_request)
            else:
                ai_optimization = self._get_mock_optimization(processed_request)
            
            # Create optimized recipes
            optimized_recipes = self._create_optimized_recipes(
                processed_request.recipes, 
                ai_optimization['optimized_recipes']
            )
            
            # Create result
            result = CookingOptimizationResult(
                optimized_recipes=optimized_recipes,
                cooking_schedule=ai_optimization['cooking_schedule'],
                total_time=ai_optimization['total_time'],
                efficiency_score=ai_optimization['efficiency_score']
            )
            
            return await self.postprocess_response(result)
            
        except Exception as e:
            await self.handle_error(e, request)
            raise CookingOptimizationError(f"Failed to optimize cooking: {str(e)}")
    
    async def _generate_ai_optimization(self, request: CookingOptimizationRequest) -> Dict[str, Any]:
        """Generate AI cooking optimization"""
        try:
            # Create recipes summary
            recipes_summary = []
            for recipe in request.recipes:
                recipes_summary.append(
                    f"- {recipe.name}: {recipe.cookingTime}分 ({recipe.difficulty.name})"
                )
            
            max_time = request.constraints.get('max_cooking_time', 60)
            difficulty = request.constraints.get('difficulty', 'easy')
            
            prompt = f"""
以下の料理の調理プロセスを最適化してください：

【料理リスト】
{chr(10).join(recipes_summary)}

【制約条件】
- 最大調理時間: {max_time}分
- 難易度: {difficulty}

【最適化のポイント】
1. 準備作業の並行化
2. 調理器具の効率的な使用
3. 調理順序の最適化
4. 時間短縮のコツ

以下の形式でJSON出力してください：
{{
  "optimized_recipes": [
    {{
      "name": "料理名",
      "optimized_cooking_time": 最適化後の調理時間(分),
      "preparation_order": "準備順序の説明",
      "cooking_tips": ["調理のコツ1", "調理のコツ2"]
    }}
  ],
  "cooking_schedule": [
    {{
      "time": "00:00",
      "action": "アクション説明",
      "duration": 所要時間(分),
      "parallel": true
    }}
  ],
  "total_time": 合計調理時間(分),
  "efficiency_score": 効率スコア(0-100)
}}

効率化のポイント：
- 同時にできる作業を特定する
- 準備作業を並行して行う
- 調理器具を効率的に使い回す
- 時間のかかる作業を最初に開始する

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
                        'optimized_recipes': data.get('optimized_recipes', []),
                        'cooking_schedule': data.get('cooking_schedule', []),
                        'total_time': max(1, data.get('total_time', 30)),
                        'efficiency_score': max(0, min(100, data.get('efficiency_score', 75)))
                    }
            
            return self._get_mock_optimization(request)
            
        except Exception as e:
            logger.warning(f"Failed to generate AI cooking optimization: {e}")
            return self._get_mock_optimization(request)
    
    def _get_mock_optimization(self, request: CookingOptimizationRequest) -> Dict[str, Any]:
        """Get mock optimization when AI is not available"""
        recipes = request.recipes
        max_time = request.constraints.get('max_cooking_time', 60)
        
        # Simple optimization logic
        optimized_recipes = []
        cooking_schedule = []
        current_time = 0
        
        # Sort recipes by cooking time (longest first)
        sorted_recipes = sorted(recipes, key=lambda r: r.cookingTime, reverse=True)
        
        for i, recipe in enumerate(sorted_recipes):
            # Reduce cooking time by 10-20%
            optimized_time = max(5, int(recipe.cookingTime * 0.8))
            
            optimized_recipes.append({
                "name": recipe.name,
                "optimized_cooking_time": optimized_time,
                "preparation_order": f"{i+1}番目に準備",
                "cooking_tips": [
                    "事前に材料を準備しておく",
                    "強火で短時間調理する"
                ]
            })
            
            # Add to cooking schedule
            cooking_schedule.append({
                "time": f"{current_time:02d}:00",
                "action": f"{recipe.name}の準備開始",
                "duration": optimized_time,
                "parallel": i > 0  # Allow parallel cooking for multiple recipes
            })
            
            current_time += optimized_time
        
        # Calculate total time (considering parallel cooking)
        total_time = max(recipe['optimized_cooking_time'] for recipe in optimized_recipes)
        
        # Calculate efficiency score
        original_time = sum(recipe.cookingTime for recipe in recipes)
        efficiency_score = min(100, int((original_time - total_time) / original_time * 100 + 70))
        
        return {
            'optimized_recipes': optimized_recipes,
            'cooking_schedule': cooking_schedule,
            'total_time': total_time,
            'efficiency_score': efficiency_score
        }
    
    def _create_optimized_recipes(
        self, 
        original_recipes: List[MealItem], 
        optimized_data: List[Dict[str, Any]]
    ) -> List[MealItem]:
        """Create optimized recipes from original recipes and optimization data"""
        optimized_recipes = []
        
        for original_recipe, opt_data in zip(original_recipes, optimized_data):
            # Create optimized recipe
            optimized_recipe = original_recipe.copyWith(
                cookingTime=opt_data.get('optimized_cooking_time', original_recipe.cookingTime),
                recipe=original_recipe.recipe.copyWith(
                    cookingTime=opt_data.get('optimized_cooking_time', original_recipe.cookingTime),
                    tips=original_recipe.recipe.tips + opt_data.get('cooking_tips', [])
                )
            )
            
            optimized_recipes.append(optimized_recipe)
        
        return optimized_recipes

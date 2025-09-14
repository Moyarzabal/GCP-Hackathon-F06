"""
Ingredient Analysis Agent using Google ADK
Analyzes refrigerator ingredients and determines priorities
"""

import google.generativeai as genai
from typing import List, Dict, Any
import json
import structlog
from datetime import datetime

from app.agents.base_agent import BaseAgent
from app.models.schemas import (
    Product, Ingredient, IngredientAnalysisRequest, 
    IngredientAnalysisResult, ExpiryPriority
)
from app.core.exceptions import IngredientAnalysisError
from app.core.config import settings

logger = structlog.get_logger(__name__)

class IngredientAnalysisAgent(BaseAgent[IngredientAnalysisRequest, IngredientAnalysisResult]):
    """Agent for analyzing refrigerator ingredients"""
    
    def __init__(self):
        super().__init__(
            name="ingredient_analysis",
            model=settings.ingredient_analysis_model,
            temperature=settings.ingredient_analysis_temperature,
            max_tokens=settings.ingredient_analysis_max_tokens
        )
        
        # Initialize Gemini
        if settings.gemini_api_key:
            genai.configure(api_key=settings.gemini_api_key)
        else:
            logger.warning("Gemini API key not configured, using mock responses")
    
    def get_system_prompt(self) -> str:
        """Get system prompt for ingredient analysis"""
        return """
あなたは冷蔵庫管理と食材分析の専門家です。
以下の責任を持って食材を分析してください：

1. 食材の賞味期限を考慮した優先度付け
2. 食材の鮮度と状態の評価
3. 利用可能食材の分類と整理
4. 推奨使用順序の提案

分析結果は以下の形式でJSON出力してください：
{
  "analyzed_ingredients": [
    {
      "name": "食材名",
      "quantity": "数量",
      "unit": "単位",
      "available": true,
      "expiry_date": "YYYY-MM-DD",
      "shopping_required": false,
      "priority": "urgent|soon|fresh|long_term",
      "category": "カテゴリ",
      "notes": "備考"
    }
  ],
  "priority_ingredients": ["優先度の高い食材名リスト"],
  "expiring_soon": ["期限切れが近い食材名リスト"],
  "recommendations": ["推奨事項リスト"]
}

優先度の基準：
- urgent: 期限切れまたは1日以内
- soon: 2-3日以内
- fresh: 4-7日以内
- long_term: 8日以上

すべてのテキストは日本語で出力してください。
"""
    
    async def process(self, request: IngredientAnalysisRequest) -> IngredientAnalysisResult:
        """Process ingredient analysis request"""
        try:
            await self.validate_request(request)
            processed_request = await self.preprocess_request(request)
            
            logger.info(
                "Processing ingredient analysis",
                product_count=len(processed_request.products)
            )
            
            # Convert products to ingredients with priority analysis
            analyzed_ingredients = await self._analyze_ingredients(processed_request.products)
            
            # Generate AI recommendations
            ai_recommendations = await self._generate_ai_recommendations(analyzed_ingredients)
            
            # Create result
            result = IngredientAnalysisResult(
                analyzed_ingredients=analyzed_ingredients,
                priority_ingredients=[ing for ing in analyzed_ingredients if ing.priority in [ExpiryPriority.URGENT, ExpiryPriority.SOON]],
                expiring_soon=[ing for ing in analyzed_ingredients if ing.priority == ExpiryPriority.URGENT],
                recommendations=ai_recommendations
            )
            
            return await self.postprocess_response(result)
            
        except Exception as e:
            await self.handle_error(e, request)
            raise IngredientAnalysisError(f"Failed to analyze ingredients: {str(e)}")
    
    async def _analyze_ingredients(self, products: List[Product]) -> List[Ingredient]:
        """Analyze products and convert to ingredients with priorities"""
        ingredients = []
        
        for product in products:
            # Determine expiry priority
            priority = self._determine_expiry_priority(product.days_until_expiry)
            
            # Translate category to Japanese
            category = self._translate_category(product.category)
            
            ingredient = Ingredient(
                name=product.name,
                quantity=str(product.quantity),
                unit=product.unit,
                available=True,
                expiry_date=product.expiry_date,
                shopping_required=False,
                product_id=product.id,
                priority=priority,
                category=category,
                image_url=product.current_image_url,
                notes=f"賞味期限まで{product.days_until_expiry}日"
            )
            
            ingredients.append(ingredient)
        
        # Sort by priority
        ingredients.sort(key=lambda x: x.priority_score)
        
        return ingredients
    
    def _determine_expiry_priority(self, days_until_expiry: int) -> ExpiryPriority:
        """Determine expiry priority based on days until expiry"""
        if days_until_expiry <= 0:
            return ExpiryPriority.URGENT
        elif days_until_expiry <= 1:
            return ExpiryPriority.URGENT
        elif days_until_expiry <= 3:
            return ExpiryPriority.SOON
        elif days_until_expiry <= 7:
            return ExpiryPriority.FRESH
        else:
            return ExpiryPriority.LONG_TERM
    
    def _translate_category(self, category: str) -> str:
        """Translate category to Japanese"""
        category_map = {
            'vegetables': '野菜',
            'fruits': '果物',
            'meat': '肉',
            'fish': '魚',
            'dairy': '乳製品',
            'grains': '主食',
            'seasonings': '調味料',
            'beverages': '飲み物',
            'snacks': 'お菓子',
            'frozen': '冷凍食品',
        }
        
        return category_map.get(category.lower(), category)
    
    async def _generate_ai_recommendations(self, ingredients: List[Ingredient]) -> List[str]:
        """Generate AI recommendations for ingredient usage"""
        if not settings.gemini_api_key:
            return self._get_mock_recommendations(ingredients)
        
        try:
            # Create ingredients summary
            ingredients_summary = []
            for ingredient in ingredients:
                priority_text = ""
                if ingredient.priority == ExpiryPriority.URGENT:
                    priority_text = "[緊急]"
                elif ingredient.priority == ExpiryPriority.SOON:
                    priority_text = "[期限間近]"
                
                ingredients_summary.append(
                    f"{priority_text}{ingredient.name} {ingredient.quantity}{ingredient.unit} "
                    f"(賞味期限まで{ingredient.notes.split('まで')[1].split('日')[0]}日)"
                )
            
            prompt = f"""
以下の冷蔵庫の食材を分析して、使用推奨事項を3つ提案してください：

食材リスト：
{chr(10).join(ingredients_summary)}

以下の形式でJSON出力してください：
{{
  "recommendations": [
    "推奨事項1",
    "推奨事項2", 
    "推奨事項3"
  ]
}}

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
                    return data.get('recommendations', [])
            
            return self._get_mock_recommendations(ingredients)
            
        except Exception as e:
            logger.warning(f"Failed to generate AI recommendations: {e}")
            return self._get_mock_recommendations(ingredients)
    
    def _get_mock_recommendations(self, ingredients: List[Ingredient]) -> List[str]:
        """Get mock recommendations when AI is not available"""
        urgent_count = len([ing for ing in ingredients if ing.priority == ExpiryPriority.URGENT])
        soon_count = len([ing for ing in ingredients if ing.priority == ExpiryPriority.SOON])
        
        recommendations = []
        
        if urgent_count > 0:
            recommendations.append(f"期限切れ間近の食材{urgent_count}個を最優先で使用してください")
        
        if soon_count > 0:
            recommendations.append(f"2-3日以内に期限切れの食材{soon_count}個の調理を計画してください")
        
        recommendations.append("栄養バランスを考慮して野菜とタンパク質を組み合わせた献立を提案します")
        
        return recommendations

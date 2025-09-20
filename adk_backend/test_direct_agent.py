#!/usr/bin/env python3
"""
画像生成エージェントの直接テスト
"""

import asyncio
import sys
import os

# パスを追加
sys.path.append('.')

from app.agents.image_generation_agent import ImageGenerationAgent
from app.models.schemas import ImageGenerationRequest, MealItem, MealThemeResult, Ingredient, Recipe, NutritionInfo, RecipeStep

async def test_image_generation_agent():
    """画像生成エージェントの直接テスト"""
    
    print("🚀 画像生成エージェントの直接テスト開始...")
    
    try:
        # エージェントの初期化
        agent = ImageGenerationAgent()
        print("✅ エージェント初期化完了")
        print(f"📋 モデル: {agent.model}")
        print(f"🌡️  温度: {agent.temperature}")
        
        # テスト用の簡単なデータを作成
        test_recipe = MealItem(
            name="オムライス",
            category="main",
            description="美味しいオムライス",
            ingredients=[
                Ingredient(name="卵", quantity="2", unit="個"),
                Ingredient(name="ご飯", quantity="1", unit="杯"),
                Ingredient(name="ケチャップ", quantity="2", unit="大さじ")
            ],
            cooking_time=15,
            difficulty="easy",
            nutrition_info=NutritionInfo(
                calories=400,
                protein=15,
                carbohydrates=60,
                fat=10
            ),
            recipe=Recipe(
                steps=[
                    RecipeStep(step_number=1, description="玉ねぎを炒める", time=5),
                    RecipeStep(step_number=2, description="ご飯を炒める", time=5),
                    RecipeStep(step_number=3, description="卵で包む", time=5)
                ],
                tips=["卵は半熟にすると美味しい"],
                cooking_time=15,
                difficulty="easy",
                nutrition_info=NutritionInfo(
                    calories=400,
                    protein=15,
                    carbohydrates=60,
                    fat=10
                )
            )
        )
        
        # テスト用のメールテーマ
        test_meal_theme = MealThemeResult(
            theme_name="和食",
            theme_description="温かい家庭料理",
            unified_meal_plan={
                "household_id": "test_household",
                "date": "2025-09-14",
                "status": "suggested",
                "main_dish": {"name": "オムライス"},
                "side_dish": {"name": "味噌汁"},
                "soup": {"name": "味噌汁"},
                "rice": {"name": "白米"},
                "total_cooking_time": 30,
                "difficulty": "easy",
                "nutrition_score": 85,
                "confidence": 0.9
            },
            visual_style={
                "style": "natural",
                "color": "warm"
            }
        )
        
        # リクエストの作成
        request = ImageGenerationRequest(
            recipes=[test_recipe],
            meal_theme=test_meal_theme,
            image_style={
                "style": "natural",
                "lighting": "warm",
                "background": "simple"
            }
        )
        
        print("📝 リクエスト作成完了")
        print(f"🍽️  レシピ: {request.recipes[0].name}")
        print(f"🎨 テーマ: {request.meal_theme.theme_name}")
        print(f"🖼️  スタイル: {request.image_style}")
        
        # エージェントの実行
        print("⚡ 画像生成開始...")
        result = await agent.process(request)
        
        print("✅ 画像生成完了!")
        print(f"🖼️  生成された画像URL数: {len(result.image_urls)}")
        for i, url in enumerate(result.image_urls):
            print(f"   {i+1}. {url}")
        
        print(f"⏱️  生成時間: {result.generation_time:.2f}秒")
        print(f"📋 メタデータ:")
        for i, metadata in enumerate(result.image_metadata):
            print(f"   {i+1}. {metadata}")
            
    except Exception as e:
        print(f"❌ エラー: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_image_generation_agent())

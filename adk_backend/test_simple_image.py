#!/usr/bin/env python3
"""
簡単な画像生成テストスクリプト
"""

import requests
import json
import time

def test_image_generation():
    """画像生成APIのテスト"""
    
    # テスト用のシンプルなデータ
    test_data = {
        "recipes": [
            {
                "name": "オムライス",
                "category": "main",
                "description": "美味しいオムライス",
                "ingredients": [
                    {"name": "卵", "quantity": "2", "unit": "個"},
                    {"name": "ご飯", "quantity": "1", "unit": "杯"},
                    {"name": "ケチャップ", "quantity": "2", "unit": "大さじ"}
                ],
                "cooking_time": 15,
                "difficulty": "easy",
                "nutrition_info": {
                    "calories": 400,
                    "protein": 15,
                    "carbohydrates": 60,
                    "fat": 10
                },
                "recipe": {
                    "steps": [
                        {
                            "step_number": 1,
                            "description": "玉ねぎを炒める",
                            "time": 5
                        },
                        {
                            "step_number": 2,
                            "description": "ご飯を炒める",
                            "time": 5
                        },
                        {
                            "step_number": 3,
                            "description": "卵で包む",
                            "time": 5
                        }
                    ],
                    "tips": ["卵は半熟にすると美味しい"],
                    "cooking_time": 15,
                    "difficulty": "easy",
                    "nutrition_info": {
                        "calories": 400,
                        "protein": 15,
                        "carbohydrates": 60,
                        "fat": 10
                    }
                }
            }
        ],
        "meal_theme": {
            "theme_name": "和食",
            "theme_description": "温かい家庭料理",
            "unified_meal_plan": {
                "household_id": "test_household",
                "date": "2025-09-14",
                "status": "suggested",
                "main_dish": "オムライス",
                "side_dish": "味噌汁",
                "soup": "味噌汁",
                "rice": "白米",
                "total_cooking_time": 30,
                "difficulty": "easy",
                "nutrition_score": 85,
                "confidence": 0.9
            },
            "visual_style": {
                "style": "natural",
                "color": "warm"
            }
        },
        "image_style": {
            "style": "natural",
            "lighting": "warm",
            "background": "simple"
        }
    }
    
    print("🚀 画像生成APIテスト開始...")
    print(f"📝 テストデータ: {json.dumps(test_data, indent=2, ensure_ascii=False)}")
    
    try:
        # APIリクエスト
        response = requests.post(
            "http://localhost:8000/api/v1/agents/image-generation",
            json=test_data,
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        
        print(f"📊 レスポンスステータス: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ 画像生成成功!")
            print(f"🖼️  生成された画像URL: {result.get('image_urls', [])}")
            print(f"⏱️  生成時間: {result.get('generation_time', 0):.2f}秒")
            print(f"📋 メタデータ: {json.dumps(result.get('image_metadata', []), indent=2, ensure_ascii=False)}")
        else:
            print(f"❌ エラー: {response.status_code}")
            print(f"📄 エラー詳細: {response.text}")
            
    except requests.exceptions.RequestException as e:
        print(f"❌ リクエストエラー: {e}")
    except Exception as e:
        print(f"❌ 予期しないエラー: {e}")

if __name__ == "__main__":
    test_image_generation()

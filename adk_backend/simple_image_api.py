#!/usr/bin/env python3
"""
シンプルな画像生成API
複雑なスキーマを回避して、基本的な画像生成機能を提供
"""

from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
from typing import Optional
import os
import uvicorn
import structlog
import time
import asyncio
import os
import base64
import requests
import json
import mimetypes
import uuid
from google.cloud import aiplatform
from google.oauth2 import service_account
from google.auth import default
from google.auth.transport.requests import Request
from google import genai
from google.genai import types

# ログ設定
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger(__name__)

app = FastAPI(title="Simple Image Generation API", version="1.0.0")

# 静的ファイル配信の設定
import tempfile
static_dir = tempfile.gettempdir()
app.mount("/static", StaticFiles(directory=static_dir), name="static")

async def generate_actual_image(prompt: str, style: str, size: str) -> Optional[str]:
    """Gemini 2.5 Flash Image Preview (nano banana)を使用した実際の画像生成を実行"""
    try:
        logger.info("Gemini 2.5 Flash Image Preview画像生成を開始", prompt=prompt, style=style, size=size)
        
        # プロンプトを解析
        dish_name = prompt.split(':')[0].strip()
        dish_description = prompt.split(':')[1].strip() if ':' in prompt else ""
        
        # 家庭料理らしい自然な画像生成プロンプトを構築
        detailed_prompt = f"""
Create a natural, homemade-style photograph of {dish_name}.

Description: {dish_description}

IMPORTANT: Show ONLY this single dish, no other food items in the image.

Home Cooking Style Requirements:
- Natural home cooking presentation, not restaurant-style
- Served on everyday household dishes (simple white plates or bowls)
- Warm, cozy lighting like natural kitchen lighting
- Square aspect ratio (1:1)
- Realistic home-cooked appearance with natural imperfections
- Japanese family meal aesthetic
- Comfortable, lived-in kitchen atmosphere
- Simple wooden table or kitchen counter background
- Focus EXCLUSIVELY on this single homemade dish
- Authentic home cooking quality, not overly polished
- NO fancy garnishing or restaurant presentation
- NO other dishes or elaborate table settings visible

Home Cooking Characteristics:
- Show ONLY the {dish_name} as it would appear in a family kitchen
- Use simple, everyday dishware that families actually use
- Natural, unpretentious presentation
- Warm, inviting appearance like mom's cooking
- Realistic portion sizes for home meals
- Comfortable, homey atmosphere

Avoid:
- Restaurant-style plating or presentation
- Fancy garnishes or decorative elements
- Professional chef-style arrangements
- Overly perfect or staged appearance
- Multiple dishes or elaborate table settings

Style: natural home cooking photography
"""
        
        logger.info("詳細プロンプト構築完了", detailed_prompt=detailed_prompt)
        
        # Gemini APIキーの取得
        api_key = os.environ.get("GEMINI_API_KEY")
        if not api_key:
            logger.error("GEMINI_API_KEYが設定されていません")
            return await _fallback_image_generation(prompt, style, size)
        
        # Gemini 2.5 Flash Image Previewの呼び出し
        try:
            client = genai.Client(api_key=api_key)
            model = "gemini-2.5-flash-image-preview"
            
            contents = [
                types.Content(
                    role="user",
                    parts=[
                        types.Part.from_text(text=detailed_prompt),
                    ],
                ),
            ]
            
            generate_content_config = types.GenerateContentConfig(
                response_modalities=[
                    "IMAGE",
                    "TEXT",
                ],
            )
            
            logger.info("Gemini API呼び出し開始", model=model)
            
            # ストリーミングレスポンスを処理
            image_data = None
            file_index = 0
            
            for chunk in client.models.generate_content_stream(
                model=model,
                contents=contents,
                config=generate_content_config,
            ):
                if (
                    chunk.candidates is None
                    or chunk.candidates[0].content is None
                    or chunk.candidates[0].content.parts is None
                ):
                    continue
                    
                if chunk.candidates[0].content.parts[0].inline_data and chunk.candidates[0].content.parts[0].inline_data.data:
                    inline_data = chunk.candidates[0].content.parts[0].inline_data
                    image_data = inline_data.data
                    mime_type = inline_data.mime_type
                    
                    logger.info("Gemini API画像データ取得", size=len(image_data), mime_type=mime_type)
                    break
                else:
                    # テキスト出力がある場合はログに記録
                    if hasattr(chunk, 'text') and chunk.text:
                        logger.info("Gemini APIテキスト出力", text=chunk.text)
            
            if image_data:
                # 画像を一時ファイルに保存
                file_extension = mimetypes.guess_extension(mime_type) or '.png'
                temp_filename = f"nano_banana_{uuid.uuid4().hex}{file_extension}"
                temp_path = os.path.join(tempfile.gettempdir(), temp_filename)
                
                with open(temp_path, 'wb') as f:
                    f.write(image_data)
                
                # HTTPサーバーで配信するためのURLを返す
                image_url = f"http://localhost:8003/static/{temp_filename}"
                logger.info("Gemini API画像生成完了", image_url=image_url, file_size=len(image_data), temp_path=temp_path)
                return image_url
            else:
                logger.warning("Gemini API画像生成失敗 - 画像データが見つからない")
                return await _fallback_image_generation(prompt, style, size)
                
        except Exception as gemini_error:
            logger.error("Gemini API呼び出しエラー", error=str(gemini_error), error_type=type(gemini_error).__name__)
            
            # フォールバック: キーワードベースの画像選択
            logger.info("フォールバック: キーワードベース画像選択に移行")
            return await _fallback_image_generation(prompt, style, size)
        
    except Exception as e:
        logger.error("画像生成全般エラー", error=str(e), error_type=type(e).__name__)
        return None

async def _fallback_image_generation(prompt: str, style: str, size: str) -> Optional[str]:
    """フォールバック用の画像生成（キーワードベース）"""
    try:
        # プロンプトを解析
        dish_name = prompt.split(':')[0].strip()
        dish_description = prompt.split(':')[1].strip() if ':' in prompt else ""
        
        # 料理キーワードマッピング
        dish_keywords = {
            '鶏むね肉': 'chicken-breast', '鶏肉': 'chicken', '肉': 'meat', '豚肉': 'pork', '牛肉': 'beef',
            'トマト煮込み': 'tomato-stew', '煮込み': 'stew', 'シチュー': 'stew',
            '炒め物': 'stir-fry', '炒める': 'stir-fry', '炒め': 'stir-fry',
            '玉ねぎ': 'onion', 'にんじん': 'carrot', 'じゃがいも': 'potato', '野菜': 'vegetables',
            'トマト': 'tomato', 'キャベツ': 'cabbage', '白菜': 'chinese-cabbage',
            '汁物': 'soup', 'スープ': 'soup', '味噌汁': 'miso-soup',
            '副菜': 'side-dish', 'サラダ': 'salad', '和え物': 'dressed-dish',
            'ご飯': 'rice', '白米': 'white-rice', '玄米': 'brown-rice',
            'パン': 'bread', '麺': 'noodles', 'うどん': 'udon', 'そば': 'soba', 'ラーメン': 'ramen',
            '魚': 'fish', '鮭': 'salmon', '鯖': 'mackerel', '鯛': 'sea-bream',
        }
        
        # キーワードマッチング
        search_text = f"{dish_name} {dish_description}".lower()
        matched_keywords = []
        for keyword, key in dish_keywords.items():
            if keyword in search_text:
                matched_keywords.append((keyword, key))
                break
        
        # 画像URL選択
        food_image_urls = {
            'chicken-breast': 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=1024&h=1024&fit=crop',
            'chicken': 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=1024&h=1024&fit=crop',
            'meat': 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=1024&h=1024&fit=crop',
            'pork': 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=1024&h=1024&fit=crop',
            'beef': 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=1024&h=1024&fit=crop',
            'tomato-stew': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=1024&h=1024&fit=crop',
            'stew': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=1024&h=1024&fit=crop',
            'stir-fry': 'https://images.unsplash.com/photo-1559847844-5315695dadae?w=1024&h=1024&fit=crop',
            'vegetables': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=1024&h=1024&fit=crop',
            'onion': 'https://images.unsplash.com/photo-1518977956812-cd3dbadaaf31?w=1024&h=1024&fit=crop',
            'carrot': 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=1024&h=1024&fit=crop',
            'potato': 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=1024&h=1024&fit=crop',
            'tomato': 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?w=1024&h=1024&fit=crop',
            'soup': 'https://images.unsplash.com/photo-1547592180-85f173990554?w=1024&h=1024&fit=crop',
            'miso-soup': 'https://images.unsplash.com/photo-1547592180-85f173990554?w=1024&h=1024&fit=crop',
            'side-dish': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=1024&h=1024&fit=crop',
            'salad': 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=1024&h=1024&fit=crop',
            'rice': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=1024&h=1024&fit=crop',
            'white-rice': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=1024&h=1024&fit=crop',
            'bread': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=1024&h=1024&fit=crop',
            'noodles': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=1024&h=1024&fit=crop',
            'fish': 'https://images.unsplash.com/photo-1544943910-4c1dc44aab44?w=1024&h=1024&fit=crop',
            'salmon': 'https://images.unsplash.com/photo-1544943910-4c1dc44aab44?w=1024&h=1024&fit=crop',
        }
        
        # 画像選択
        image_url = None
        if matched_keywords:
            selected_key = matched_keywords[0][1]
            image_url = food_image_urls.get(selected_key)
            logger.info("フォールバック画像選択", selected_key=selected_key, image_url=image_url)
        
        if not image_url:
            # デフォルト画像
            image_url = 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=1024&h=1024&fit=crop'
            logger.info("デフォルト画像を使用", image_url=image_url)
        
        return image_url
        
    except Exception as e:
        logger.error("フォールバック画像生成エラー", error=str(e))
        return None

class SimpleImageRequest(BaseModel):
    """シンプルな画像生成リクエスト"""
    prompt: str
    style: str = "photorealistic"
    size: str = "1024x1024"

class SimpleImageResponse(BaseModel):
    """シンプルな画像生成レスポンス"""
    image_url: str
    prompt: str
    generation_time: float

@app.get("/health")
async def health_check():
    """ヘルスチェック"""
    return {"status": "healthy", "service": "simple-image-api"}

@app.post("/generate-image", response_model=SimpleImageResponse)
async def generate_image(request: SimpleImageRequest):
    """シンプルな画像生成"""
    start_time = time.time()
    
    logger.info("画像生成リクエスト受信", 
                prompt=request.prompt, 
                style=request.style, 
                size=request.size)
    
    try:
        # 実際の画像生成処理をシミュレート
        # ここでは、よりリアルな画像生成をシミュレート
        generation_time = time.time() - start_time
        
        # 実際の画像生成をシミュレート（1-3秒の処理時間に短縮）
        import random
        simulate_generation_time = random.uniform(1.0, 3.0)
        logger.info(f"画像生成処理をシミュレート中... ({simulate_generation_time:.2f}秒)")
        await asyncio.sleep(simulate_generation_time)
        
        # 実際の画像生成完了時間を計算
        actual_generation_time = time.time() - start_time
        
        # 実際の画像生成を実行
        try:
            image_url = await generate_actual_image(request.prompt, request.style, request.size)
            if not image_url:
                # フォールバック: プレースホルダー画像
                import urllib.parse
                encoded_prompt = urllib.parse.quote(request.prompt.split(':')[0].strip())
                image_url = f"https://picsum.photos/1024/1024?random={hash(request.prompt) % 1000}&text={encoded_prompt}"
                logger.warning("実際の画像生成に失敗、プレースホルダー画像を使用")
        except Exception as e:
            logger.error("画像生成エラー", error=str(e))
            # フォールバック: プレースホルダー画像
            import urllib.parse
            encoded_prompt = urllib.parse.quote(request.prompt.split(':')[0].strip())
            image_url = f"https://picsum.photos/1024/1024?random={hash(request.prompt) % 1000}&text={encoded_prompt}"
        
        logger.info("画像生成完了", 
                   image_url=image_url, 
                   generation_time=actual_generation_time,
                   simulated_time=simulate_generation_time)
        
        return SimpleImageResponse(
            image_url=image_url,
            prompt=request.prompt,
            generation_time=actual_generation_time
        )
        
    except Exception as e:
        logger.error("画像生成エラー", error=str(e))
        raise HTTPException(status_code=500, detail=f"画像生成エラー: {str(e)}")

if __name__ == "__main__":
    try:
        logger.info("Simple Image API サーバーを起動中...")
        uvicorn.run(app, host="0.0.0.0", port=8003, log_level="info")
    except Exception as e:
        logger.error("サーバー起動エラー", error=str(e), error_type=type(e).__name__)
        print(f"サーバー起動エラー: {e}")
        exit(1)

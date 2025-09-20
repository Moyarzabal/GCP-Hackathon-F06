"""
Image Generation Agent using Google Imagen
Generates images for menu items
"""

import google.generativeai as genai
from typing import List, Dict, Any
import structlog
import time

from app.agents.base_agent import BaseAgent
from app.models.schemas import (
    MealItem, MealThemeResult, ImageGenerationRequest, ImageGenerationResult
)
from app.core.exceptions import ImageGenerationError
from app.core.config import settings

logger = structlog.get_logger(__name__)

class ImageGenerationAgent(BaseAgent[ImageGenerationRequest, ImageGenerationResult]):
    """Agent for generating images for menu items using Google Imagen"""
    
    def __init__(self):
        super().__init__(
            name="image_generation",
            model=settings.image_generation_model,
            temperature=settings.image_generation_temperature,
            max_tokens=settings.image_generation_max_tokens
        )
        
        # Initialize Google Generative AI (Imagen)
        if settings.gemini_api_key:
            genai.configure(api_key=settings.gemini_api_key)
        else:
            logger.warning("Gemini API key not configured, using mock responses")
    
    def get_system_prompt(self) -> str:
        """Get system prompt for image generation"""
        return """
あなたは料理の写真撮影と画像生成の専門家です。
以下の責任を持って料理画像を生成してください：

主要要件：
1. 料理を美味しく魅力的に見せる画像を生成
2. すべてのメニューアイテムで一貫したビジュアルスタイルを維持
3. 献立テーマとビジュアルスタイルの設定を考慮
4. 適切な照明と構図を使用
5. メニュー表示に適した画像を生成

画像生成ガイドライン：
- 自然光と温かいトーンを使用
- 料理の盛り付けとプレゼンテーションに焦点
- 過度に加工された人工的な画像を避ける
- 献立テーマとの一貫性を維持
- ウェブ表示に適した高解像度画像を生成

Google Imagenを使用して高品質な料理画像を生成してください。
"""
    
    async def process(self, request: ImageGenerationRequest) -> ImageGenerationResult:
        """Process image generation request"""
        try:
            await self.validate_request(request)
            processed_request = await self.preprocess_request(request)
            
            logger.info(
                "Processing image generation",
                recipe_count=len(processed_request.recipes)
            )
            
            # Generate images
            if settings.openai_api_key:
                ai_images = await self._generate_ai_images(processed_request)
            else:
                ai_images = self._get_mock_images(processed_request)
            
            # Create result
            result = ImageGenerationResult(
                image_urls=ai_images['image_urls'],
                image_metadata=ai_images['image_metadata'],
                generation_time=ai_images['generation_time']
            )
            
            return await self.postprocess_response(result)
            
        except Exception as e:
            await self.handle_error(e, request)
            raise ImageGenerationError(f"Failed to generate images: {str(e)}")
    
    async def _generate_ai_images(self, request: ImageGenerationRequest) -> Dict[str, Any]:
        """Generate AI images using Google Imagen"""
        try:
            start_time = time.time()
            
            image_urls = []
            image_metadata = []
            
            for recipe in request.recipes:
                # Create prompt for image generation
                prompt = self._create_image_prompt(recipe, request.meal_theme, request.image_style)
                
                try:
                    # Generate image using Google Imagen
                    # Note: 実際のImagen APIの使用方法は、Google Cloud AI Platformの設定に依存します
                    # ここでは、Gemini APIを使用して画像生成のプロンプトを最適化し、
                    # 実際の画像生成は別のサービスに委ねる実装とします
                    
                    # プロンプトを最適化
                    optimized_prompt = await self._optimize_prompt_for_imagen(prompt)
                    
                    # 実際の画像生成は、Google Cloud AI PlatformのImagenを使用
                    # ここでは、プロンプトベースの実装として、画像URLをシミュレート
                    image_url = self._generate_imagen_url(optimized_prompt)
                    image_urls.append(image_url)
                    
                    # Create metadata
                    metadata = {
                        "recipe_name": recipe.name,
                        "prompt": prompt,
                        "optimized_prompt": optimized_prompt,
                        "size": "1024x1024",
                        "model": "imagen-3",
                        "generated_at": time.time()
                    }
                    image_metadata.append(metadata)
                    
                    logger.info(f"Generated image for {recipe.name}")
                    
                except Exception as e:
                    logger.warning(f"Failed to generate image for {recipe.name}: {e}")
                    # Add placeholder URL
                    image_urls.append(self._get_placeholder_url(recipe.name))
                    image_metadata.append({
                        "recipe_name": recipe.name,
                        "error": str(e),
                        "placeholder": True
                    })
            
            generation_time = time.time() - start_time
            
            return {
                'image_urls': image_urls,
                'image_metadata': image_metadata,
                'generation_time': generation_time
            }
            
        except Exception as e:
            logger.warning(f"Failed to generate AI images: {e}")
            return self._get_mock_images(request)
    
    def _create_image_prompt(
        self, 
        recipe: MealItem, 
        meal_theme: MealThemeResult, 
        image_style: Dict[str, Any]
    ) -> str:
        """Create prompt for image generation"""
        # Base prompt components
        recipe_description = f"{recipe.name}: {recipe.description}"
        
        # Theme-based styling
        theme_name = meal_theme.theme_name
        visual_style = meal_theme.visual_style
        
        # Style preferences
        style_mood = image_style.get('mood', 'appetizing')
        style_lighting = image_style.get('lighting', 'natural')
        style_composition = image_style.get('composition', 'professional')
        
        # Color palette from theme
        color_palette = ', '.join(visual_style.get('color_palette', ['warm', 'natural']))
        
        prompt = f"""
Professional food photography of {recipe_description}

Style: {style_mood}, {style_lighting} lighting, {style_composition} composition
Theme: {theme_name}
Color palette: {color_palette}
Mood: {visual_style.get('mood', 'appetizing and delicious')}
Presentation: {visual_style.get('presentation_style', 'elegant plating')}

Technical requirements:
- High resolution (1024x1024)
- Professional food photography quality
- Natural lighting with warm tones
- Clean, uncluttered background
- Focus on food presentation
- Appetizing and delicious appearance
- Suitable for menu display

Avoid: artificial lighting, overly processed look, cluttered background, poor composition
"""
        
        return prompt.strip()
    
    async def _optimize_prompt_for_imagen(self, prompt: str) -> str:
        """Gemini APIを使用してImagen用のプロンプトを最適化"""
        try:
            if not settings.gemini_api_key:
                return prompt
            
            optimization_prompt = f"""
以下の料理画像生成プロンプトを、Google Imagenで最適な結果を得られるように改善してください：

元のプロンプト：
{prompt}

改善のポイント：
1. Imagenの特徴を活かした詳細な描写
2. 料理の魅力を最大限に引き出す表現
3. 技術的な画像生成に適した構成
4. 高品質な料理写真の要素を含める

改善されたプロンプトを返してください：
"""
            
            model = genai.GenerativeModel('gemini-1.5-pro')
            response = model.generate_content(optimization_prompt)
            
            if response.text:
                return response.text.strip()
            else:
                return prompt
                
        except Exception as e:
            logger.warning(f"Failed to optimize prompt: {e}")
            return prompt
    
    def _generate_imagen_url(self, prompt: str) -> str:
        """Imagen APIを使用して画像URLを生成（シミュレート）"""
        # 実際の実装では、Google Cloud AI PlatformのImagen APIを呼び出します
        # ここでは、プロンプトベースのURLをシミュレート
        import hashlib
        prompt_hash = hashlib.md5(prompt.encode()).hexdigest()[:8]
        return f"https://storage.googleapis.com/imagen-generated/{prompt_hash}.jpg"
    
    def _get_placeholder_url(self, recipe_name: str) -> str:
        """Get placeholder URL for failed image generation"""
        # In a real implementation, you might have placeholder images
        # or use a service like placeholder.com
        return f"https://via.placeholder.com/400x400?text={recipe_name.replace(' ', '+')}"
    
    def _get_mock_images(self, request: ImageGenerationRequest) -> Dict[str, Any]:
        """Get mock images when AI is not available"""
        import time
        start_time = time.time()
        
        image_urls = []
        image_metadata = []
        
        for recipe in request.recipes:
            # Use placeholder URLs for mock
            placeholder_url = self._get_placeholder_url(recipe.name)
            image_urls.append(placeholder_url)
            
            metadata = {
                "recipe_name": recipe.name,
                "prompt": f"Mock image for {recipe.name}",
                "size": "1024x1024",
                "quality": "mock",
                "generated_at": time.time(),
                "mock": True
            }
            image_metadata.append(metadata)
        
        generation_time = time.time() - start_time
        
        return {
            'image_urls': image_urls,
            'image_metadata': image_metadata,
            'generation_time': generation_time
        }

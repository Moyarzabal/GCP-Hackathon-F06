"""
User Preference Conversation Agent using Google ADK
Collects and structures user preferences through conversation
"""

import google.generativeai as genai
from typing import List, Dict, Any, Optional
import json
import structlog

from app.agents.base_agent import BaseAgent
from app.models.schemas import (
    Ingredient, UserPreferences, UserPreferenceRequest, UserPreferenceResult,
    DifficultyLevel
)
from app.core.exceptions import UserPreferenceError
from app.core.config import settings

logger = structlog.get_logger(__name__)

class UserPreferenceConversationAgent(BaseAgent[UserPreferenceRequest, UserPreferenceResult]):
    """Agent for collecting user preferences through conversation"""
    
    def __init__(self):
        super().__init__(
            name="user_preference_conversation",
            model=settings.user_preference_model,
            temperature=settings.user_preference_temperature,
            max_tokens=settings.user_preference_max_tokens
        )
        
        # Initialize Gemini
        if settings.gemini_api_key:
            genai.configure(api_key=settings.gemini_api_key)
        else:
            logger.warning("Gemini API key not configured, using mock responses")
    
    def get_system_prompt(self) -> str:
        """Get system prompt for user preference conversation"""
        return """
あなたはユーザーの好みと設定を自然な対話で収集する専門家です。
以下の責任を持ってユーザー設定を収集してください：

1. ユーザーとの自然な対話による設定収集
2. 好み・制約事項の段階的な聞き取り
3. 設定の妥当性チェック・提案
4. ユーザー体験の最適化

収集結果は以下の形式でJSON出力してください：
{
  "structured_preferences": {
    "max_cooking_time": 最大調理時間(分),
    "preferred_difficulty": "easy|medium|hard|expert",
    "dietary_restrictions": ["制限1", "制限2"],
    "allergies": ["アレルギー1", "アレルギー2"],
    "disliked_ingredients": ["苦手食材1", "苦手食材2"],
    "preferred_cuisines": ["好みジャンル1", "好みジャンル2"]
  },
  "confidence_score": 信頼度(0-1),
  "next_questions": ["次の質問1", "次の質問2"],
  "updated_profile": {
    "user_id": "ユーザーID",
    "preferences": { /* 構造化された設定 */ },
    "conversation_history": ["対話履歴"],
    "last_updated": "更新日時"
  }
}

対話のポイント：
- 自然で親しみやすい口調
- 段階的に情報を収集
- 曖昧な回答を明確にする
- ユーザーの状況に合わせた質問
- 既存設定の確認と更新

すべてのテキストは日本語で出力してください。
"""
    
    async def process(self, request: UserPreferenceRequest) -> UserPreferenceResult:
        """Process user preference conversation request"""
        try:
            await self.validate_request(request)
            processed_request = await self.preprocess_request(request)
            
            logger.info(
                "Processing user preference conversation",
                user_input_length=len(processed_request.user_input)
            )
            
            # Generate AI conversation response
            if settings.gemini_api_key:
                ai_response = await self._generate_ai_conversation(processed_request)
            else:
                ai_response = self._get_mock_conversation(processed_request)
            
            # Parse and create structured preferences
            structured_preferences = self._parse_preferences(ai_response['structured_preferences'])
            
            # Create result
            result = UserPreferenceResult(
                structured_preferences=structured_preferences,
                confidence_score=ai_response['confidence_score'],
                next_questions=ai_response['next_questions'],
                updated_profile=ai_response['updated_profile']
            )
            
            return await self.postprocess_response(result)
            
        except Exception as e:
            await self.handle_error(e, request)
            raise UserPreferenceError(f"Failed to process user preference conversation: {str(e)}")
    
    async def _generate_ai_conversation(self, request: UserPreferenceRequest) -> Dict[str, Any]:
        """Generate AI conversation response"""
        try:
            # Create available ingredients summary
            ingredients_summary = []
            for ingredient in request.available_ingredients:
                ingredients_summary.append(f"- {ingredient.name} ({ingredient.category})")
            
            # Create existing profile summary
            existing_profile_text = ""
            if request.existing_profile:
                existing_profile_text = f"""
【既存の設定】
- 最大調理時間: {request.existing_profile.get('max_cooking_time', '未設定')}分
- 難易度: {request.existing_profile.get('preferred_difficulty', '未設定')}
- 食事制限: {', '.join(request.existing_profile.get('dietary_restrictions', []))}
- アレルギー: {', '.join(request.existing_profile.get('allergies', []))}
- 苦手食材: {', '.join(request.existing_profile.get('disliked_ingredients', []))}
- 好みジャンル: {', '.join(request.existing_profile.get('preferred_cuisines', []))}
"""
            
            prompt = f"""
ユーザーからの入力: "{request.user_input}"

【利用可能な食材】
{chr(10).join(ingredients_summary) if ingredients_summary else "食材情報なし"}
{existing_profile_text}

上記のユーザー入力から、献立提案に必要な設定を抽出・更新してください。

以下の形式でJSON出力してください：
{{
  "structured_preferences": {{
    "max_cooking_time": 最大調理時間(分、10-300の範囲),
    "preferred_difficulty": "easy|medium|hard|expert",
    "dietary_restrictions": ["制限1", "制限2"],
    "allergies": ["アレルギー1", "アレルギー2"],
    "disliked_ingredients": ["苦手食材1", "苦手食材2"],
    "preferred_cuisines": ["好みジャンル1", "好みジャンル2"]
  }},
  "confidence_score": 抽出した設定の信頼度(0-1),
  "next_questions": ["次の質問1", "次の質問2"],
  "updated_profile": {{
    "user_id": "user_123",
    "preferences": {{
      "max_cooking_time": 最大調理時間(分),
      "preferred_difficulty": "easy|medium|hard|expert",
      "dietary_restrictions": ["制限1", "制限2"],
      "allergies": ["アレルギー1", "アレルギー2"],
      "disliked_ingredients": ["苦手食材1", "苦手食材2"],
      "preferred_cuisines": ["好みジャンル1", "好みジャンル2"]
    }},
    "conversation_history": ["{request.user_input}"],
    "last_updated": "{json.dumps(datetime.now().isoformat())}"
  }}
}}

設定抽出のガイドライン：
- 調理時間: 「30分以内」「1時間くらい」「早い方がいい」などの表現から数値に変換
- 難易度: 「簡単」「普通」「難しい」などの表現から選択
- 食事制限: 「ベジタリアン」「糖質制限」「塩分控えめ」など
- アレルギー: 「エビアレルギー」「卵アレルギー」など
- 苦手食材: 「にんじんが嫌い」「魚が苦手」など
- 好みジャンル: 「和食」「イタリアン」「中華」など

信頼度の基準：
- 0.9-1.0: 明確で具体的な情報
- 0.7-0.8: 比較的明確な情報
- 0.5-0.6: 推測が必要な情報
- 0.3-0.4: 曖昧な情報
- 0.0-0.2: 不明確な情報

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
                        'structured_preferences': data.get('structured_preferences', {}),
                        'confidence_score': max(0.0, min(1.0, data.get('confidence_score', 0.5))),
                        'next_questions': data.get('next_questions', []),
                        'updated_profile': data.get('updated_profile', {})
                    }
            
            return self._get_mock_conversation(request)
            
        except Exception as e:
            logger.warning(f"Failed to generate AI conversation: {e}")
            return self._get_mock_conversation(request)
    
    def _get_mock_conversation(self, request: UserPreferenceRequest) -> Dict[str, Any]:
        """Get mock conversation when AI is not available"""
        from datetime import datetime
        
        # Simple mock parsing based on keywords
        user_input = request.user_input.lower()
        
        # Extract cooking time
        max_cooking_time = 60  # default
        if '30分' in user_input or '30分以内' in user_input:
            max_cooking_time = 30
        elif '1時間' in user_input or '60分' in user_input:
            max_cooking_time = 60
        elif '15分' in user_input:
            max_cooking_time = 15
        
        # Extract difficulty
        preferred_difficulty = "easy"
        if '難しい' in user_input or '上級' in user_input:
            preferred_difficulty = "hard"
        elif '普通' in user_input or '中級' in user_input:
            preferred_difficulty = "medium"
        
        # Extract allergies
        allergies = []
        if 'エビ' in user_input and 'アレルギー' in user_input:
            allergies.append('エビ')
        if '卵' in user_input and 'アレルギー' in user_input:
            allergies.append('卵')
        
        # Extract disliked ingredients
        disliked_ingredients = []
        if 'にんじん' in user_input and ('嫌い' in user_input or '苦手' in user_input):
            disliked_ingredients.append('にんじん')
        if '魚' in user_input and ('嫌い' in user_input or '苦手' in user_input):
            disliked_ingredients.append('魚')
        
        # Extract preferred cuisines
        preferred_cuisines = []
        if '和食' in user_input or '日本料理' in user_input:
            preferred_cuisines.append('和食')
        if 'イタリアン' in user_input or 'パスタ' in user_input:
            preferred_cuisines.append('イタリアン')
        if '中華' in user_input or '中国料理' in user_input:
            preferred_cuisines.append('中華')
        
        structured_preferences = {
            "max_cooking_time": max_cooking_time,
            "preferred_difficulty": preferred_difficulty,
            "dietary_restrictions": [],
            "allergies": allergies,
            "disliked_ingredients": disliked_ingredients,
            "preferred_cuisines": preferred_cuisines
        }
        
        # Generate next questions based on missing information
        next_questions = []
        if not allergies:
            next_questions.append("アレルギーはありますか？")
        if not disliked_ingredients:
            next_questions.append("苦手な食材はありますか？")
        if not preferred_cuisines:
            next_questions.append("好みの料理ジャンルはありますか？")
        
        if not next_questions:
            next_questions.append("他にご希望はありますか？")
        
        updated_profile = {
            "user_id": "user_123",
            "preferences": structured_preferences,
            "conversation_history": [request.user_input],
            "last_updated": datetime.now().isoformat()
        }
        
        return {
            'structured_preferences': structured_preferences,
            'confidence_score': 0.7,
            'next_questions': next_questions,
            'updated_profile': updated_profile
        }
    
    def _parse_preferences(self, preferences_data: Dict[str, Any]) -> UserPreferences:
        """Parse preferences data into UserPreferences object"""
        return UserPreferences(
            max_cooking_time=preferences_data.get('max_cooking_time', 60),
            preferred_difficulty=DifficultyLevel(preferences_data.get('preferred_difficulty', 'easy')),
            dietary_restrictions=preferences_data.get('dietary_restrictions', []),
            allergies=preferences_data.get('allergies', []),
            disliked_ingredients=preferences_data.get('disliked_ingredients', []),
            preferred_cuisines=preferences_data.get('preferred_cuisines', [])
        )

#!/usr/bin/env python3
"""
ADK Backend Configuration Test Script
環境変数とAPIキーの設定をテストします
"""

import os
import sys
from dotenv import load_dotenv

def test_environment_variables():
    """環境変数の設定をテスト"""
    print("🔍 環境変数の設定をテスト中...")
    
    # .envファイルを読み込み
    load_dotenv()
    
    # 必須環境変数のチェック
    required_vars = [
        'GEMINI_API_KEY',
        # 'OPENAI_API_KEY',  # No longer needed - using Google Imagen instead
    ]
    
    missing_vars = []
    for var in required_vars:
        value = os.getenv(var)
        if not value or value == f'your_actual_{var.lower()}_here':
            missing_vars.append(var)
        else:
            # APIキーの一部をマスクして表示
            masked_value = value[:8] + '...' + value[-4:] if len(value) > 12 else '***'
            print(f"✅ {var}: {masked_value}")
    
    if missing_vars:
        print(f"❌ 以下の環境変数が設定されていません: {', '.join(missing_vars)}")
        return False
    
    print("✅ すべての必須環境変数が設定されています")
    return True

def test_api_connectivity():
    """API接続をテスト"""
    print("\n🌐 API接続をテスト中...")
    
    try:
        import google.generativeai as genai
        # import openai  # No longer needed - using Google Imagen instead
        
        # Gemini API接続テスト
        gemini_api_key = os.getenv('GEMINI_API_KEY')
        if gemini_api_key:
            genai.configure(api_key=gemini_api_key)
            print("✅ Gemini API設定完了")
        else:
            print("❌ Gemini APIキーが設定されていません")
            return False
        
        # Google Imagen API接続テスト（Gemini APIと同じキーを使用）
        if gemini_api_key:
            print("✅ Google Imagen API設定完了（Gemini APIと同じキーを使用）")
        else:
            print("❌ Google Imagen APIキーが設定されていません")
            return False
        
        print("✅ すべてのAPI接続設定が完了しています")
        return True
        
    except ImportError as e:
        print(f"❌ 必要なライブラリがインストールされていません: {e}")
        print("pip install -r requirements.txt を実行してください")
        return False
    except Exception as e:
        print(f"❌ API接続テストでエラーが発生しました: {e}")
        return False

def test_fastapi_setup():
    """FastAPI設定をテスト"""
    print("\n🚀 FastAPI設定をテスト中...")
    
    try:
        from fastapi import FastAPI
        from app.core.config import settings
        
        print(f"✅ FastAPI設定読み込み完了")
        print(f"   - APIタイトル: {settings.api_title}")
        print(f"   - APIバージョン: {settings.api_version}")
        print(f"   - デバッグモード: {settings.debug}")
        print(f"   - デフォルトモデル: {settings.default_model}")
        
        return True
        
    except ImportError as e:
        print(f"❌ FastAPI関連のライブラリがインストールされていません: {e}")
        return False
    except Exception as e:
        print(f"❌ FastAPI設定テストでエラーが発生しました: {e}")
        return False

def main():
    """メイン関数"""
    print("🧪 ADK Backend Configuration Test")
    print("=" * 50)
    
    # テスト実行
    tests = [
        test_environment_variables,
        test_api_connectivity,
        test_fastapi_setup,
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        try:
            if test():
                passed += 1
        except Exception as e:
            print(f"❌ テスト実行中にエラーが発生しました: {e}")
    
    print("\n" + "=" * 50)
    print(f"📊 テスト結果: {passed}/{total} 通過")
    
    if passed == total:
        print("🎉 すべてのテストが通過しました！ADK Backendの設定は完了です。")
        print("\n次のステップ:")
        print("1. python main.py でサーバーを起動")
        print("2. http://localhost:8000/docs でAPI ドキュメントを確認")
        return True
    else:
        print("⚠️  一部のテストが失敗しました。設定を確認してください。")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)

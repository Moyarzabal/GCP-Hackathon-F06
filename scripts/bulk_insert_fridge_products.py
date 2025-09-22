#!/usr/bin/env python3
"""
冷蔵庫画面用食材データ大量挿入スクリプト
冷蔵庫画面で表示される'products'コレクションに直接データを挿入します
"""

import json
import random
import uuid
from datetime import datetime, timedelta
from typing import Dict, List, Any
import firebase_admin
from firebase_admin import credentials, firestore
import os

# Firebase初期化
def initialize_firebase():
    """Firebase Admin SDKを初期化"""
    if not firebase_admin._apps:
        service_account_path = os.path.join(os.path.dirname(__file__), '..', 'firebase-service-account.json')
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
    
    return firestore.client()

# 食材カテゴリとサンプルデータ
FOOD_CATEGORIES = {
    "野菜": [
        "トマト", "きゅうり", "にんじん", "じゃがいも", "たまねぎ", "キャベツ", "レタス", "ほうれん草",
        "ブロッコリー", "なす", "ピーマン", "もやし", "大根", "白菜", "小松菜", "ねぎ", "しめじ",
        "えのき", "しいたけ", "まいたけ", "エリンギ", "アスパラガス", "とうもろこし", "かぼちゃ",
        "さつまいも", "里芋", "ごぼう", "れんこん", "オクラ", "いんげん", "枝豆", "そら豆"
    ],
    "肉類": [
        "牛もも肉", "牛バラ肉", "牛ひき肉", "豚ロース", "豚バラ肉", "豚ひき肉", "鶏もも肉", 
        "鶏むね肉", "鶏ひき肉", "手羽先", "手羽元", "ささみ", "豚こま切れ", "牛切り落とし",
        "ソーセージ", "ベーコン", "ハム", "サラミ", "鶏レバー", "豚レバー", "牛タン"
    ],
    "魚介類": [
        "鮭", "まぐろ", "さば", "あじ", "いわし", "さんま", "ぶり", "たい", "ひらめ", "かれい",
        "えび", "いか", "たこ", "ほたて", "あさり", "しじみ", "牡蠣", "かに", "うに", "いくら",
        "ちくわ", "かまぼこ", "はんぺん", "さつま揚げ"
    ],
    "乳製品": [
        "牛乳", "豆乳", "ヨーグルト", "チーズ", "バター", "生クリーム", "カッテージチーズ",
        "モッツァレラチーズ", "クリームチーズ", "パルメザンチーズ", "カマンベールチーズ"
    ],
    "卵・大豆製品": [
        "卵", "豆腐", "厚揚げ", "油揚げ", "がんもどき", "納豆", "豆乳", "きなこ", "味噌",
        "醤油", "枝豆"
    ],
    "穀物・パン": [
        "米", "パン", "食パン", "フランスパン", "クロワッサン", "ベーグル", "パスタ", "うどん",
        "そば", "そうめん", "ラーメン", "焼きそば", "小麦粉", "片栗粉", "パン粉"
    ],
    "果物": [
        "りんご", "みかん", "バナナ", "いちご", "ぶどう", "桃", "梨", "柿", "キウイ", "パイナップル",
        "メロン", "スイカ", "さくらんぼ", "プラム", "アボカド", "レモン", "ライム", "グレープフルーツ",
        "オレンジ", "マンゴー", "パパイヤ", "ブルーベリー", "イチジク"
    ],
    "調味料": [
        "塩", "砂糖", "醤油", "味噌", "酢", "みりん", "料理酒", "サラダ油", "ごま油", "オリーブオイル",
        "マヨネーズ", "ケチャップ", "ソース", "からし", "わさび", "しょうが", "にんにく", "こしょう",
        "七味唐辛子", "カレー粉", "コンソメ", "だしの素", "めんつゆ"
    ],
    "冷凍食品": [
        "冷凍餃子", "冷凍シュウマイ", "冷凍チャーハン", "冷凍うどん", "冷凍パスタ", "冷凍野菜ミックス",
        "冷凍ブロッコリー", "冷凍コーン", "冷凍エビフライ", "冷凍唐揚げ", "冷凍ハンバーグ",
        "アイスクリーム", "冷凍フルーツ"
    ],
    "飲み物": [
        "水", "お茶", "コーヒー", "紅茶", "ジュース", "炭酸水", "スポーツドリンク", "野菜ジュース",
        "牛乳", "豆乳", "ビール", "ワイン", "日本酒", "焼酎"
    ]
}

# 単位のリスト
UNITS = ["個", "本", "袋", "パック", "kg", "g", "L", "ml", "束", "枚", "切れ", "尾", "匹"]

# メーカー名のリスト
MANUFACTURERS = [
    "明治", "森永", "グリコ", "カルビー", "日清", "味の素", "キッコーマン", "ヤマサ", "マルコメ",
    "カゴメ", "ハウス食品", "エスビー食品", "永谷園", "丸美屋", "オタフクソース", "ブルドック",
    "キューピー", "ミツカン", "タカラ", "白鶴", "月桂冠", "サントリー", "アサヒ", "キリン"
]

def generate_jan_code() -> str:
    """JANコードを生成（13桁）"""
    return f"49{random.randint(10000000000, 99999999999)}"

def generate_barcode() -> str:
    """バーコードを生成"""
    return f"{random.randint(1000000000000, 9999999999999)}"

def generate_expiry_date() -> datetime:
    """賞味期限を生成（現在から1日〜30日後）"""
    days_ahead = random.randint(1, 30)
    return datetime.now() + timedelta(days=days_ahead)

def create_fridge_product(category: str, product_name: str) -> Dict[str, Any]:
    """冷蔵庫画面用の食材データを作成（productsコレクション用）"""
    jan_code = generate_jan_code()
    expiry_date = generate_expiry_date()
    
    # Productモデルに合わせたデータ構造
    return {
        'janCode': jan_code,
        'name': product_name,
        'scannedAt': None,
        'addedDate': firestore.SERVER_TIMESTAMP,
        'expiryDate': int(expiry_date.timestamp() * 1000),  # millisecondsSinceEpoch
        'category': category,
        'imageUrl': None,  # 画像は後で設定可能
        'imageUrls': None,  # 複数段階画像
        'barcode': generate_barcode(),
        'manufacturer': random.choice(MANUFACTURERS),
        'quantity': random.randint(1, 5),
        'unit': random.choice(UNITS),
        'deletedAt': None
    }

def bulk_insert_fridge_products(db, num_products: int = 100):
    """大量の食材データをFirestoreの'products'コレクションに挿入"""
    print(f"🚀 冷蔵庫画面用に{num_products}個の食材データを挿入開始...")
    print(f"📍 対象コレクション: 'products'")
    
    batch = db.batch()
    products_created = 0
    batch_size = 500  # Firestoreのバッチ制限
    
    try:
        for i in range(num_products):
            # ランダムなカテゴリと商品を選択
            category = random.choice(list(FOOD_CATEGORIES.keys()))
            product_name = random.choice(FOOD_CATEGORIES[category])
            
            # 商品データを作成
            product_data = create_fridge_product(category, product_name)
            
            # バッチに追加（自動IDを使用）
            doc_ref = db.collection('products').document()
            batch.set(doc_ref, product_data)
            
            products_created += 1
            
            # バッチサイズに達したらコミット
            if products_created % batch_size == 0:
                batch.commit()
                print(f"  📦 {products_created}/{num_products} 個の商品を挿入完了")
                batch = db.batch()  # 新しいバッチを作成
        
        # 残りのバッチをコミット
        if products_created % batch_size != 0:
            batch.commit()
        
        print(f"✅ 合計 {products_created} 個の食材データを'products'コレクションに挿入完了!")
        
        # 挿入されたデータの統計を表示
        show_fridge_statistics(db)
        
    except Exception as e:
        print(f"❌ データ挿入エラー: {e}")
        raise

def show_fridge_statistics(db):
    """挿入されたデータの統計情報を表示"""
    try:
        # カテゴリ別の統計
        print("\n📊 挿入されたデータの統計:")
        for category in FOOD_CATEGORIES.keys():
            count = db.collection('products').where('category', '==', category).where('deletedAt', '==', None).get()
            print(f"  {category}: {len(count)} 個")
        
        # 全体の統計
        all_products = db.collection('products').where('deletedAt', '==', None).get()
        print(f"\n📈 合計: {len(all_products)} 個の食材")
        
        # 賞味期限別の統計
        now = datetime.now()
        fresh_count = 0
        warning_count = 0
        urgent_count = 0
        
        for product in all_products:
            data = product.to_dict()
            expiry_timestamp = data.get('expiryDate')
            if expiry_timestamp:
                expiry_date = datetime.fromtimestamp(expiry_timestamp / 1000)
                days_until_expiry = (expiry_date - now).days
                
                if days_until_expiry > 7:
                    fresh_count += 1
                elif days_until_expiry > 3:
                    warning_count += 1
                else:
                    urgent_count += 1
        
        print(f"  新鮮 (7日以上): {fresh_count} 個")
        print(f"  注意 (3-7日): {warning_count} 個") 
        print(f"  緊急 (3日未満): {urgent_count} 個")
        
    except Exception as e:
        print(f"⚠️ 統計表示エラー: {e}")

def clear_existing_products(db):
    """既存のproductsコレクションのデータをクリア（デバッグ用）"""
    print("🧹 既存のproductsコレクションをクリア中...")
    
    try:
        # 既存の商品を取得
        products = db.collection('products').get()
        
        if not products:
            print("  ℹ️ クリアする商品がありません")
            return
        
        # バッチで削除
        batch = db.batch()
        count = 0
        
        for product in products:
            batch.delete(product.reference)
            count += 1
            
            # バッチサイズ制限対応
            if count % 500 == 0:
                batch.commit()
                batch = db.batch()
        
        # 残りのバッチをコミット
        if count % 500 != 0:
            batch.commit()
        
        print(f"✅ {count} 個の商品をクリアしました")
        
    except Exception as e:
        print(f"❌ クリアエラー: {e}")
        raise

def main():
    """メイン処理"""
    print("🔥 Firebase冷蔵庫画面用食材データ大量挿入スクリプト開始")
    print("📍 対象コレクション: 'products' (冷蔵庫画面で表示される)")
    
    try:
        # Firebase初期化
        db = initialize_firebase()
        print("✅ Firebase接続完了")
        
        # 既存データのクリア確認
        clear_existing = input("\n既存のproductsコレクションをクリアしますか？ (y/N): ")
        if clear_existing.lower() == 'y':
            clear_existing_products(db)
        
        # 挿入する商品数を設定（デフォルト100個）
        num_products = int(input("挿入する食材の数を入力してください (デフォルト: 100): ") or "100")
        
        # 確認
        print(f"\n📝 挿入設定:")
        print(f"  対象コレクション: 'products'")
        print(f"  挿入予定数: {num_products} 個")
        print(f"  ℹ️ これらの食材は冷蔵庫画面に表示されます")
        
        confirm = input("\n実行しますか？ (y/N): ")
        if confirm.lower() != 'y':
            print("❌ 実行をキャンセルしました")
            return
        
        # 大量データ挿入実行
        bulk_insert_fridge_products(db, num_products)
        
        print(f"\n🎉 冷蔵庫画面用食材データの挿入が完了しました!")
        print(f"   アプリの冷蔵庫画面をリロードして確認してください。")
        
    except Exception as e:
        print(f"💥 エラーが発生しました: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()

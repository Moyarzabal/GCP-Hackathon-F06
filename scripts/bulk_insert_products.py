#!/usr/bin/env python3
"""
デバッグ用食材データ大量挿入スクリプト
Firebase Firestoreに大量の食材データを挿入します
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
        # サービスアカウントキーのパスを設定
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

def create_sample_product(category: str, product_name: str, household_id: str, user_id: str) -> Dict[str, Any]:
    """サンプル食材データを作成"""
    item_id = str(uuid.uuid4())
    jan_code = generate_jan_code()
    expiry_date = generate_expiry_date()
    
    # 賞味期限から感情状態を計算
    days_until_expiry = (expiry_date - datetime.now()).days
    if days_until_expiry > 7:
        emotion_state = "😊"
    elif days_until_expiry > 3:
        emotion_state = "😐"
    elif days_until_expiry > 1:
        emotion_state = "😟"
    elif days_until_expiry >= 1:
        emotion_state = "😰"
    else:
        emotion_state = "💀"
    
    return {
        'itemId': item_id,
        'householdId': household_id,
        'productName': product_name,
        'janCode': jan_code,
        'category': category,
        'quantity': random.randint(1, 5),
        'unit': random.choice(UNITS),
        'expiryDate': expiry_date,
        'status': emotion_state,
        'barcode': generate_barcode(),
        'price': random.randint(100, 2000),
        'manufacturer': random.choice(MANUFACTURERS),
        'imageUrl': None,  # 画像は後で設定可能
        'addedBy': user_id,
        'addedDate': firestore.SERVER_TIMESTAMP,
        'deletedAt': None
    }

def create_household_and_user(db) -> tuple[str, str]:
    """テスト用の世帯とユーザーを作成"""
    household_id = str(uuid.uuid4())
    user_id = str(uuid.uuid4())
    
    # 世帯を作成
    household_data = {
        'householdId': household_id,
        'name': 'デバッグ用テスト世帯',
        'members': [user_id],
        'createdAt': firestore.SERVER_TIMESTAMP,
        'settings': {
            'notificationEnabled': True,
            'expiryWarningDays': 3
        }
    }
    
    # ユーザーを作成
    user_data = {
        'userId': user_id,
        'displayName': 'デバッグユーザー',
        'email': 'debug@test.com',
        'householdId': household_id,
        'role': 'owner',
        'joinedAt': firestore.SERVER_TIMESTAMP
    }
    
    try:
        db.collection('households').document(household_id).set(household_data)
        db.collection('users').document(user_id).set(user_data)
        print(f"✅ 世帯とユーザーを作成しました: {household_id}, {user_id}")
        return household_id, user_id
    except Exception as e:
        print(f"❌ 世帯・ユーザー作成エラー: {e}")
        raise

def bulk_insert_products(db, household_id: str, user_id: str, num_products: int = 100):
    """大量の食材データをFirestoreに挿入"""
    print(f"🚀 {num_products}個の食材データを挿入開始...")
    
    batch = db.batch()
    products_created = 0
    batch_size = 500  # Firestoreのバッチ制限
    
    try:
        for i in range(num_products):
            # ランダムなカテゴリと商品を選択
            category = random.choice(list(FOOD_CATEGORIES.keys()))
            product_name = random.choice(FOOD_CATEGORIES[category])
            
            # 商品データを作成
            product_data = create_sample_product(category, product_name, household_id, user_id)
            
            # バッチに追加
            doc_ref = db.collection('items').document(product_data['itemId'])
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
        
        print(f"✅ 合計 {products_created} 個の食材データを挿入完了!")
        
        # 挿入されたデータの統計を表示
        show_statistics(db, household_id)
        
    except Exception as e:
        print(f"❌ データ挿入エラー: {e}")
        raise

def show_statistics(db, household_id: str):
    """挿入されたデータの統計情報を表示"""
    try:
        # カテゴリ別の統計
        print("\n📊 挿入されたデータの統計:")
        for category in FOOD_CATEGORIES.keys():
            count = db.collection('items').where('householdId', '==', household_id).where('category', '==', category).get()
            print(f"  {category}: {len(count)} 個")
        
        # 全体の統計
        all_items = db.collection('items').where('householdId', '==', household_id).get()
        print(f"\n📈 合計: {len(all_items)} 個の食材")
        
        # 賞味期限別の統計
        fresh_count = sum(1 for item in all_items if item.to_dict().get('status') == '😊')
        warning_count = sum(1 for item in all_items if item.to_dict().get('status') in ['😐', '😟'])
        urgent_count = sum(1 for item in all_items if item.to_dict().get('status') in ['😰', '💀'])
        
        print(f"  新鮮 (😊): {fresh_count} 個")
        print(f"  注意 (😐😟): {warning_count} 個") 
        print(f"  緊急 (😰💀): {urgent_count} 個")
        
    except Exception as e:
        print(f"⚠️ 統計表示エラー: {e}")

def main():
    """メイン処理"""
    print("🔥 Firebase食材データ大量挿入スクリプト開始")
    
    try:
        # Firebase初期化
        db = initialize_firebase()
        print("✅ Firebase接続完了")
        
        # 既存の世帯・ユーザーを確認、なければ作成
        print("👥 テスト用世帯・ユーザーを作成中...")
        household_id, user_id = create_household_and_user(db)
        
        # 挿入する商品数を設定（デフォルト100個）
        num_products = int(input("挿入する食材の数を入力してください (デフォルト: 100): ") or "100")
        
        # 確認
        print(f"\n📝 挿入設定:")
        print(f"  世帯ID: {household_id}")
        print(f"  ユーザーID: {user_id}")
        print(f"  挿入予定数: {num_products} 個")
        
        confirm = input("\n実行しますか？ (y/N): ")
        if confirm.lower() != 'y':
            print("❌ 実行をキャンセルしました")
            return
        
        # 大量データ挿入実行
        bulk_insert_products(db, household_id, user_id, num_products)
        
        print(f"\n🎉 デバッグ用食材データの挿入が完了しました!")
        print(f"   世帯ID: {household_id}")
        print(f"   ユーザーID: {user_id}")
        print(f"   アプリでログインして確認してください。")
        
    except Exception as e:
        print(f"💥 エラーが発生しました: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()

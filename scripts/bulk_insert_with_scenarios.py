#!/usr/bin/env python3
"""
シナリオ別食材データ大量挿入スクリプト
異なるシナリオ（期限切れ間近、大量在庫など）に特化したデータを挿入します
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

# シナリオ別データ生成
def create_expiry_scenario_data(household_id: str, user_id: str, count: int = 20) -> List[Dict[str, Any]]:
    """期限切れ間近の食材データを生成"""
    products = []
    urgent_foods = [
        ("牛乳", "乳製品"), ("パン", "穀物・パン"), ("ヨーグルト", "乳製品"),
        ("豆腐", "卵・大豆製品"), ("もやし", "野菜"), ("レタス", "野菜"),
        ("バナナ", "果物"), ("いちご", "果物"), ("鶏もも肉", "肉類"), ("鮭", "魚介類")
    ]
    
    for i in range(count):
        product_name, category = random.choice(urgent_foods)
        item_id = str(uuid.uuid4())
        
        # 0-3日後に期限切れ
        days_ahead = random.randint(0, 3)
        expiry_date = datetime.now() + timedelta(days=days_ahead)
        
        if days_ahead == 0:
            emotion_state = "💀"
        elif days_ahead <= 1:
            emotion_state = "😰"
        else:
            emotion_state = "😟"
        
        products.append({
            'itemId': item_id,
            'householdId': household_id,
            'productName': f"{product_name}_{i+1}",
            'janCode': f"49{random.randint(10000000000, 99999999999)}",
            'category': category,
            'quantity': random.randint(1, 3),
            'unit': random.choice(["個", "パック", "本", "袋"]),
            'expiryDate': expiry_date,
            'status': emotion_state,
            'barcode': f"{random.randint(1000000000000, 9999999999999)}",
            'price': random.randint(100, 800),
            'manufacturer': random.choice(["明治", "森永", "カルビー", "日清", "味の素"]),
            'addedBy': user_id,
            'addedDate': firestore.SERVER_TIMESTAMP,
            'deletedAt': None
        })
    
    return products

def create_bulk_scenario_data(household_id: str, user_id: str, count: int = 30) -> List[Dict[str, Any]]:
    """大量在庫の食材データを生成"""
    products = []
    bulk_foods = [
        ("米", "穀物・パン", "kg"), ("じゃがいも", "野菜", "kg"),
        ("たまねぎ", "野菜", "個"), ("にんじん", "野菜", "本"),
        ("冷凍餃子", "冷凍食品", "袋"), ("パスタ", "穀物・パン", "袋"),
        ("調味料セット", "調味料", "セット"), ("お米", "穀物・パン", "kg")
    ]
    
    for i in range(count):
        product_name, category, unit = random.choice(bulk_foods)
        item_id = str(uuid.uuid4())
        
        # 7-30日後に期限切れ
        days_ahead = random.randint(7, 30)
        expiry_date = datetime.now() + timedelta(days=days_ahead)
        emotion_state = "😊"
        
        products.append({
            'itemId': item_id,
            'householdId': household_id,
            'productName': f"{product_name}_{i+1}",
            'janCode': f"49{random.randint(10000000000, 99999999999)}",
            'category': category,
            'quantity': random.randint(5, 20),  # 大量在庫
            'unit': unit,
            'expiryDate': expiry_date,
            'status': emotion_state,
            'barcode': f"{random.randint(1000000000000, 9999999999999)}",
            'price': random.randint(300, 2000),
            'manufacturer': random.choice(["コストコ", "業務スーパー", "イオン", "全農"]),
            'addedBy': user_id,
            'addedDate': firestore.SERVER_TIMESTAMP,
            'deletedAt': None
        })
    
    return products

def create_mixed_scenario_data(household_id: str, user_id: str, count: int = 50) -> List[Dict[str, Any]]:
    """バランスの取れた食材データを生成"""
    products = []
    
    # 期限切れ間近 20%
    products.extend(create_expiry_scenario_data(household_id, user_id, int(count * 0.2)))
    
    # 大量在庫 30%
    products.extend(create_bulk_scenario_data(household_id, user_id, int(count * 0.3)))
    
    # 通常の食材 50%
    normal_foods = [
        ("トマト", "野菜"), ("きゅうり", "野菜"), ("鶏むね肉", "肉類"),
        ("豚バラ肉", "肉類"), ("さば", "魚介類"), ("チーズ", "乳製品"),
        ("りんご", "果物"), ("みかん", "果物"), ("食パン", "穀物・パン")
    ]
    
    remaining_count = count - len(products)
    for i in range(remaining_count):
        product_name, category = random.choice(normal_foods)
        item_id = str(uuid.uuid4())
        
        # 3-14日後に期限切れ
        days_ahead = random.randint(3, 14)
        expiry_date = datetime.now() + timedelta(days=days_ahead)
        
        if days_ahead > 7:
            emotion_state = "😊"
        elif days_ahead > 3:
            emotion_state = "😐"
        else:
            emotion_state = "😟"
        
        products.append({
            'itemId': item_id,
            'householdId': household_id,
            'productName': f"{product_name}_{i+1}",
            'janCode': f"49{random.randint(10000000000, 99999999999)}",
            'category': category,
            'quantity': random.randint(1, 4),
            'unit': random.choice(["個", "パック", "本", "袋"]),
            'expiryDate': expiry_date,
            'status': emotion_state,
            'barcode': f"{random.randint(1000000000000, 9999999999999)}",
            'price': random.randint(150, 1500),
            'manufacturer': random.choice(["地元農家", "スーパー", "コンビニ"]),
            'addedBy': user_id,
            'addedDate': firestore.SERVER_TIMESTAMP,
            'deletedAt': None
        })
    
    return products

def bulk_insert_scenario_products(db, household_id: str, user_id: str, scenario: str, count: int):
    """シナリオ別データを挿入"""
    print(f"🚀 シナリオ「{scenario}」で{count}個の食材データを挿入開始...")
    
    # シナリオ別データ生成
    if scenario == "expiry":
        products = create_expiry_scenario_data(household_id, user_id, count)
    elif scenario == "bulk":
        products = create_bulk_scenario_data(household_id, user_id, count)
    elif scenario == "mixed":
        products = create_mixed_scenario_data(household_id, user_id, count)
    else:
        print("❌ 無効なシナリオです")
        return
    
    # バッチ挿入
    batch = db.batch()
    batch_size = 500
    
    try:
        for i, product_data in enumerate(products):
            doc_ref = db.collection('items').document(product_data['itemId'])
            batch.set(doc_ref, product_data)
            
            if (i + 1) % batch_size == 0:
                batch.commit()
                print(f"  📦 {i+1}/{len(products)} 個の商品を挿入完了")
                batch = db.batch()
        
        # 残りのバッチをコミット
        if len(products) % batch_size != 0:
            batch.commit()
        
        print(f"✅ 合計 {len(products)} 個の食材データを挿入完了!")
        
        # 統計表示
        show_scenario_statistics(db, household_id, scenario)
        
    except Exception as e:
        print(f"❌ データ挿入エラー: {e}")
        raise

def show_scenario_statistics(db, household_id: str, scenario: str):
    """シナリオ別統計を表示"""
    try:
        all_items = db.collection('items').where('householdId', '==', household_id).get()
        
        print(f"\n📊 シナリオ「{scenario}」の統計:")
        print(f"📈 合計: {len(all_items)} 個の食材")
        
        # 感情状態別統計
        status_counts = {}
        quantity_total = 0
        price_total = 0
        
        for item in all_items:
            data = item.to_dict()
            status = data.get('status', '😊')
            status_counts[status] = status_counts.get(status, 0) + 1
            quantity_total += data.get('quantity', 1)
            price_total += data.get('price', 0)
        
        print(f"  新鮮 (😊): {status_counts.get('😊', 0)} 個")
        print(f"  普通 (😐): {status_counts.get('😐', 0)} 個")
        print(f"  注意 (😟): {status_counts.get('😟', 0)} 個")
        print(f"  緊急 (😰): {status_counts.get('😰', 0)} 個")
        print(f"  期限切れ (💀): {status_counts.get('💀', 0)} 個")
        print(f"  総数量: {quantity_total} 個")
        print(f"  総金額: ¥{price_total:,}")
        
    except Exception as e:
        print(f"⚠️ 統計表示エラー: {e}")

def main():
    """メイン処理"""
    print("🔥 Firebase食材データシナリオ別大量挿入スクリプト開始")
    
    try:
        # Firebase初期化
        db = initialize_firebase()
        print("✅ Firebase接続完了")
        
        # シナリオ選択
        print("\n📋 利用可能なシナリオ:")
        print("  1. expiry  - 期限切れ間近の食材中心")
        print("  2. bulk    - 大量在庫の食材中心")
        print("  3. mixed   - バランスの取れた食材")
        
        scenario = input("\nシナリオを選択してください (expiry/bulk/mixed): ").strip()
        if scenario not in ['expiry', 'bulk', 'mixed']:
            print("❌ 無効なシナリオです")
            return
        
        # 既存の世帯IDとユーザーIDを入力
        household_id = input("世帯ID (空白の場合は新規作成): ").strip()
        user_id = input("ユーザーID (空白の場合は新規作成): ").strip()
        
        if not household_id or not user_id:
            print("🆕 新しい世帯・ユーザーを作成します...")
            household_id = str(uuid.uuid4())
            user_id = str(uuid.uuid4())
            
            # 世帯とユーザーを作成
            household_data = {
                'householdId': household_id,
                'name': f'デバッグ用{scenario}シナリオ世帯',
                'members': [user_id],
                'createdAt': firestore.SERVER_TIMESTAMP,
                'settings': {'notificationEnabled': True, 'expiryWarningDays': 3}
            }
            
            user_data = {
                'userId': user_id,
                'displayName': f'{scenario}シナリオユーザー',
                'email': f'debug_{scenario}@test.com',
                'householdId': household_id,
                'role': 'owner',
                'joinedAt': firestore.SERVER_TIMESTAMP
            }
            
            db.collection('households').document(household_id).set(household_data)
            db.collection('users').document(user_id).set(user_data)
            print(f"✅ 世帯とユーザーを作成: {household_id}, {user_id}")
        
        # 挿入する商品数を設定
        if scenario == "expiry":
            default_count = 20
        elif scenario == "bulk":
            default_count = 30
        else:
            default_count = 50
        
        count = int(input(f"挿入する食材の数を入力してください (デフォルト: {default_count}): ") or str(default_count))
        
        # 確認
        print(f"\n📝 挿入設定:")
        print(f"  シナリオ: {scenario}")
        print(f"  世帯ID: {household_id}")
        print(f"  ユーザーID: {user_id}")
        print(f"  挿入予定数: {count} 個")
        
        confirm = input("\n実行しますか？ (y/N): ")
        if confirm.lower() != 'y':
            print("❌ 実行をキャンセルしました")
            return
        
        # シナリオ別データ挿入実行
        bulk_insert_scenario_products(db, household_id, user_id, scenario, count)
        
        print(f"\n🎉 シナリオ「{scenario}」のデータ挿入が完了しました!")
        print(f"   世帯ID: {household_id}")
        print(f"   ユーザーID: {user_id}")
        print(f"   アプリでログインして確認してください。")
        
    except Exception as e:
        print(f"💥 エラーが発生しました: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()

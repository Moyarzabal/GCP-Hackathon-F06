import 'package:flutter/material.dart';

class Recipe {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String cookingTime;
  final List<String> ingredients;
  final List<String> steps;
  final String category;

  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.cookingTime,
    required this.ingredients,
    required this.steps,
    required this.category,
  });
}

class RecipeService {
  static const Map<String, List<Recipe>> _recipesByCategory = {
    '飲料': [
      Recipe(
        id: 'drink_1',
        title: 'フルーツスムージー',
        description: '新鮮なフルーツを使ったヘルシーなスムージー',
        imageUrl: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=400',
        cookingTime: '5分',
        ingredients: ['バナナ', 'イチゴ', 'ヨーグルト', '牛乳', 'ハチミツ'],
        steps: [
          'フルーツを適当な大きさに切る',
          'ミキサーに材料を入れる',
          '滑らかになるまで攪拌する',
          'グラスに注いで完成'
        ],
        category: '飲料',
      ),
      Recipe(
        id: 'drink_2',
        title: 'レモネード',
        description: 'さわやかなレモネードでリフレッシュ',
        imageUrl: 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400',
        cookingTime: '10分',
        ingredients: ['レモン', '砂糖', '水', 'ミント'],
        steps: [
          'レモンを絞ってジュースを作る',
          '砂糖を水に溶かしてシロップを作る',
          'レモンジュースとシロップを混ぜる',
          '氷を入れてミントで飾る'
        ],
        category: '飲料',
      ),
      Recipe(
        id: 'drink_3',
        title: 'ホットココア',
        description: '心も温まる美味しいホットココア',
        imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        cookingTime: '8分',
        ingredients: ['ココアパウダー', '牛乳', '砂糖', 'バニラエッセンス'],
        steps: [
          '鍋に牛乳を温める',
          'ココアパウダーと砂糖を混ぜる',
          '温めた牛乳に加えて混ぜる',
          'バニラエッセンスを加えて完成'
        ],
        category: '飲料',
      ),
    ],
    '食品': [
      Recipe(
        id: 'food_1',
        title: '野菜炒め',
        description: 'シャキシャキ食感の美味しい野菜炒め',
        imageUrl: 'https://images.unsplash.com/photo-1563379091339-03246963d4b0?w=400',
        cookingTime: '15分',
        ingredients: ['キャベツ', '人参', 'ピーマン', 'もやし', '醤油', 'ごま油'],
        steps: [
          '野菜を食べやすい大きさに切る',
          'フライパンに油を熱する',
          '野菜を炒める',
          '調味料で味付けして完成'
        ],
        category: '食品',
      ),
      Recipe(
        id: 'food_2',
        title: 'オムライス',
        description: 'ふわふわ卵の美味しいオムライス',
        imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
        cookingTime: '20分',
        ingredients: ['ご飯', '卵', '玉ねぎ', 'ピーマン', 'ケチャップ', 'バター'],
        steps: [
          '野菜をみじん切りにする',
          'フライパンで野菜を炒める',
          'ご飯を加えてケチャップで味付け',
          '別のフライパンで卵を焼いて包む'
        ],
        category: '食品',
      ),
      Recipe(
        id: 'food_3',
        title: 'サラダボウル',
        description: '彩り豊かなヘルシーサラダ',
        imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
        cookingTime: '10分',
        ingredients: ['レタス', 'トマト', 'キュウリ', '人参', 'ドレッシング'],
        steps: [
          '野菜を洗って適当な大きさに切る',
          'ボウルに野菜を盛り付ける',
          'ドレッシングをかける',
          'よく混ぜて完成'
        ],
        category: '食品',
      ),
    ],
    '調味料': [
      Recipe(
        id: 'seasoning_1',
        title: '手作りドレッシング',
        description: 'オリーブオイルベースの美味しいドレッシング',
        imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        cookingTime: '5分',
        ingredients: ['オリーブオイル', '酢', '醤油', 'ハチミツ', '塩', 'コショウ'],
        steps: [
          'ボウルに酢と醤油を入れる',
          'ハチミツを加えて混ぜる',
          'オリーブオイルを少しずつ加える',
          '塩コショウで味を整える'
        ],
        category: '調味料',
      ),
      Recipe(
        id: 'seasoning_2',
        title: '手作りソース',
        description: 'トマトベースの美味しいソース',
        imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
        cookingTime: '30分',
        ingredients: ['トマト', '玉ねぎ', 'にんにく', 'オリーブオイル', '塩', '砂糖'],
        steps: [
          '野菜をみじん切りにする',
          'フライパンで野菜を炒める',
          'トマトを加えて煮込む',
          '調味料で味を整える'
        ],
        category: '調味料',
      ),
      Recipe(
        id: 'seasoning_3',
        title: '手作りマリネ液',
        description: '魚や肉を美味しくするマリネ液',
        imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
        cookingTime: '10分',
        ingredients: ['醤油', 'みりん', '酒', '砂糖', 'にんにく', '生姜'],
        steps: [
          '調味料を混ぜ合わせる',
          'にんにくと生姜をすりおろす',
          'すべてを混ぜ合わせる',
          '冷蔵庫で冷やして完成'
        ],
        category: '調味料',
      ),
    ],
    '冷凍食品': [
      Recipe(
        id: 'frozen_1',
        title: '冷凍野菜炒め',
        description: '冷凍野菜を使った簡単炒め物',
        imageUrl: 'https://images.unsplash.com/photo-1563379091339-03246963d4b0?w=400',
        cookingTime: '10分',
        ingredients: ['冷凍野菜ミックス', '醤油', 'ごま油', 'にんにく'],
        steps: [
          'フライパンを熱する',
          '冷凍野菜をそのまま炒める',
          '調味料を加える',
          '火が通ったら完成'
        ],
        category: '冷凍食品',
      ),
      Recipe(
        id: 'frozen_2',
        title: '冷凍餃子の焼き方',
        description: 'パリパリ食感の美味しい焼き餃子',
        imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
        cookingTime: '15分',
        ingredients: ['冷凍餃子', '油', '水', '醤油', '酢'],
        steps: [
          'フライパンに油をひく',
          '餃子を並べて焼く',
          '水を加えて蒸し焼きにする',
          'パリパリになるまで焼く'
        ],
        category: '冷凍食品',
      ),
      Recipe(
        id: 'frozen_3',
        title: '冷凍ピザのアレンジ',
        description: '冷凍ピザを美味しくアレンジ',
        imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
        cookingTime: '20分',
        ingredients: ['冷凍ピザ', 'チーズ', 'ハム', 'ピーマン', 'トマト'],
        steps: [
          '冷凍ピザを解凍する',
          '追加の具材をトッピング',
          'オーブンで焼く',
          'チーズが溶けたら完成'
        ],
        category: '冷凍食品',
      ),
    ],
    'その他': [
      Recipe(
        id: 'other_1',
        title: '簡単おにぎり',
        description: '具材を入れた美味しいおにぎり',
        imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
        cookingTime: '15分',
        ingredients: ['ご飯', '海苔', '具材（お好み）', '塩'],
        steps: [
          'ご飯を適温にする',
          '手に塩をつける',
          'ご飯を握る',
          '海苔を巻いて完成'
        ],
        category: 'その他',
      ),
      Recipe(
        id: 'other_2',
        title: '手作りお菓子',
        description: '簡単に作れる美味しいお菓子',
        imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400',
        cookingTime: '30分',
        ingredients: ['小麦粉', '砂糖', 'バター', '卵', 'バニラエッセンス'],
        steps: [
          '材料を混ぜ合わせる',
          '生地を作る',
          'オーブンで焼く',
          '冷まして完成'
        ],
        category: 'その他',
      ),
      Recipe(
        id: 'other_3',
        title: '簡単スープ',
        description: '体が温まる美味しいスープ',
        imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
        cookingTime: '20分',
        ingredients: ['野菜', 'コンソメ', '水', '塩', 'コショウ'],
        steps: [
          '野菜を切る',
          '鍋に水を入れて煮る',
          'コンソメを加える',
          '調味料で味を整える'
        ],
        category: 'その他',
      ),
    ],
  };

  /// 商品カテゴリに基づいてレシピを取得
  static List<Recipe> getRecipesByCategory(String category) {
    return _recipesByCategory[category] ?? _recipesByCategory['その他']!;
  }

  /// ランダムにレシピを取得（最大3つ）
  static List<Recipe> getRandomRecipes(String category, {int maxCount = 3}) {
    final recipes = getRecipesByCategory(category);
    final mutableRecipes = List<Recipe>.from(recipes);
    mutableRecipes.shuffle();
    return mutableRecipes.take(maxCount).toList();
  }
}

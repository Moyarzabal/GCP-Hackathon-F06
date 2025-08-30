import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class ImagenService {
  static const String _projectId = 'gcp-f06-barcode';
  static const String _location = 'asia-northeast1';
  static const String _apiEndpoint = 'https://asia-northeast1-aiplatform.googleapis.com';
  
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> generateCharacterImage({
    required String productName,
    required String emotionState,
    required String category,
  }) async {
    try {
      // Get access token (in production, use proper authentication)
      final accessToken = await _getAccessToken();
      
      // Create prompt based on emotion state
      final prompt = _createPrompt(productName, emotionState, category);
      
      // Call Vertex AI Imagen API
      final response = await http.post(
        Uri.parse('$_apiEndpoint/v1/projects/$_projectId/locations/$_location/publishers/google/models/imagen-3.0-generate-001:predict'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'instances': [
            {
              'prompt': prompt,
              'parameters': {
                'sampleCount': 1,
                'aspectRatio': '1:1',
                'addWatermark': false,
                'safetyFilterLevel': 'block_none',
                'personGeneration': 'dont_allow',
              }
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['predictions'] != null && data['predictions'].isNotEmpty) {
          final imageBase64 = data['predictions'][0]['bytesBase64Encoded'];
          
          // Upload to Firebase Storage
          final imageUrl = await _uploadToStorage(imageBase64, productName, emotionState);
          return imageUrl;
        }
      }
      
      return null;
    } catch (e) {
      print('Error generating character image: $e');
      return _getFallbackImage(emotionState);
    }
  }

  String _createPrompt(String productName, String emotionState, String category) {
    final basePrompt = 'Cute kawaii Japanese mascot character representing $productName ($category food item), ';
    
    switch (emotionState) {
      case '😊':
        return basePrompt + 'happy and fresh, bright colors, smiling face, sparkles around, chibi style, simple design';
      case '😐':
        return basePrompt + 'neutral expression, slightly concerned, pastel colors, chibi style, simple design';
      case '😟':
        return basePrompt + 'worried expression, sweat drops, muted colors, looking anxious, chibi style, simple design';
      case '😰':
        return basePrompt + 'very worried and panicking, dark shadows, urgent expression, chibi style, simple design';
      case '💀':
        return basePrompt + 'zombie-like appearance, expired and spooky, dark colors, ghost-like, chibi style, simple design';
      default:
        return basePrompt + 'neutral kawaii expression, chibi style, simple design';
    }
  }

  Future<String> _uploadToStorage(String base64Image, String productName, String emotionState) async {
    try {
      final bytes = base64Decode(base64Image);
      final fileName = '${productName}_${emotionState}_${DateTime.now().millisecondsSinceEpoch}.png';
      final ref = _storage.ref().child('character_images/$fileName');
      
      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/png'),
      );
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image to storage: $e');
      throw e;
    }
  }

  Future<String> _getAccessToken() async {
    // In production, implement proper authentication
    // For now, this is a placeholder
    // You should use Application Default Credentials or Service Account
    return 'YOUR_ACCESS_TOKEN';
  }

  String _getFallbackImage(String emotionState) {
    // Return default emoji as fallback
    switch (emotionState) {
      case '😊':
        return 'assets/images/happy_food.png';
      case '😐':
        return 'assets/images/neutral_food.png';
      case '😟':
        return 'assets/images/worried_food.png';
      case '😰':
        return 'assets/images/panicking_food.png';
      case '💀':
        return 'assets/images/expired_food.png';
      default:
        return 'assets/images/default_food.png';
    }
  }

  // Cache management for generated images
  static final Map<String, String> _imageCache = {};

  Future<String?> getCachedOrGenerateImage({
    required String productName,
    required String emotionState,
    required String category,
  }) async {
    final cacheKey = '${productName}_$emotionState';
    
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey];
    }
    
    final imageUrl = await generateCharacterImage(
      productName: productName,
      emotionState: emotionState,
      category: category,
    );
    
    if (imageUrl != null) {
      _imageCache[cacheKey] = imageUrl;
    }
    
    return imageUrl;
  }

  void clearCache() {
    _imageCache.clear();
  }
}
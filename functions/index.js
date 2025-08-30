const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { PredictionServiceClient } = require('@google-cloud/aiplatform');
const fetch = require('node-fetch');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// Scheduled function to check expiring products
exports.checkExpiringProducts = functions
  .region('asia-northeast1')
  .pubsub.schedule('every day 09:00')
  .timeZone('Asia/Tokyo')
  .onRun(async (context) => {
    try {
      const households = await db.collection('households').get();
      
      for (const householdDoc of households.docs) {
        const householdData = householdDoc.data();
        const householdId = householdDoc.id;
        
        if (!householdData.settings?.enableNotifications) continue;
        
        const notificationDays = householdData.settings?.notificationDays || 3;
        const futureDate = new Date();
        futureDate.setDate(futureDate.getDate() + notificationDays);
        
        const expiringItems = await db.collection('items')
          .where('householdId', '==', householdId)
          .where('expiryDate', '<=', admin.firestore.Timestamp.fromDate(futureDate))
          .where('expiryDate', '>=', admin.firestore.Timestamp.now())
          .get();
        
        for (const itemDoc of expiringItems.docs) {
          const item = itemDoc.data();
          const daysUntilExpiry = Math.ceil(
            (item.expiryDate.toDate() - new Date()) / (1000 * 60 * 60 * 24)
          );
          
          await sendExpiryNotification(householdId, item, daysUntilExpiry);
        }
      }
      
      return null;
    } catch (error) {
      console.error('Error checking expiring products:', error);
      return null;
    }
  });

// Function to send expiry notification
async function sendExpiryNotification(householdId, item, daysUntilExpiry) {
  const message = {
    notification: {
      title: `${item.productName}の賞味期限が近づいています`,
      body: daysUntilExpiry === 0 
        ? '今日が賞味期限です！' 
        : `あと${daysUntilExpiry}日で賞味期限です`,
    },
    data: {
      type: 'expiry_warning',
      productId: item.itemId,
      householdId: householdId,
    },
    topic: `household_${householdId}`,
  };
  
  try {
    await messaging.send(message);
    console.log('Notification sent for:', item.productName);
  } catch (error) {
    console.error('Error sending notification:', error);
  }
}

// HTTP function to generate character image using Vertex AI
exports.generateCharacterImage = functions
  .region('asia-northeast1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }
    
    const { productName, emotionState, category } = data;
    
    if (!productName || !emotionState) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Product name and emotion state are required'
      );
    }
    
    try {
      const imageUrl = await generateImageWithVertexAI(productName, emotionState, category);
      return { imageUrl };
    } catch (error) {
      console.error('Error generating image:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to generate character image'
      );
    }
  });

// Helper function for Vertex AI Imagen
async function generateImageWithVertexAI(productName, emotionState, category) {
  const projectId = 'gcp-f06-barcode';
  const location = 'asia-northeast1';
  const model = 'imagen-3.0-generate-001';
  
  const client = new PredictionServiceClient({
    apiEndpoint: `${location}-aiplatform.googleapis.com`,
  });
  
  const prompt = createPrompt(productName, emotionState, category);
  
  const parameters = {
    sampleCount: 1,
    aspectRatio: '1:1',
    addWatermark: false,
    safetyFilterLevel: 'block_none',
  };
  
  const instance = {
    prompt: prompt,
    parameters: parameters,
  };
  
  const request = {
    endpoint: `projects/${projectId}/locations/${location}/publishers/google/models/${model}`,
    instances: [instance],
  };
  
  const [response] = await client.predict(request);
  
  if (response.predictions && response.predictions.length > 0) {
    const imageBase64 = response.predictions[0].bytesBase64Encoded;
    
    // Upload to Firebase Storage
    const bucket = admin.storage().bucket();
    const fileName = `character_images/${productName}_${emotionState}_${Date.now()}.png`;
    const file = bucket.file(fileName);
    
    const buffer = Buffer.from(imageBase64, 'base64');
    await file.save(buffer, {
      metadata: {
        contentType: 'image/png',
      },
    });
    
    // Make the file public and get URL
    await file.makePublic();
    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;
    
    return publicUrl;
  }
  
  throw new Error('No image generated');
}

function createPrompt(productName, emotionState, category) {
  const basePrompt = `Cute kawaii Japanese mascot character representing ${productName} (${category} food item), `;
  
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

// HTTP function to get recipe suggestions using Gemini
exports.getRecipeSuggestions = functions
  .region('asia-northeast1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }
    
    const { ingredients } = data;
    
    if (!ingredients || !Array.isArray(ingredients)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Ingredients array is required'
      );
    }
    
    try {
      const recipes = await getRecipesFromGemini(ingredients);
      return { recipes };
    } catch (error) {
      console.error('Error getting recipes:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to get recipe suggestions'
      );
    }
  });

// Helper function for Gemini API
async function getRecipesFromGemini(ingredients) {
  // This would call the Gemini API
  // For now, returning mock data
  return [
    {
      name: '野菜炒め',
      cookingTime: '15分',
      difficulty: '簡単',
      ingredients: ingredients.map(i => `${i}: 適量`),
      instructions: ['材料を切る', 'フライパンで炒める', '調味料を加える'],
      calories: '約200kcal',
    },
  ];
}

// Firestore trigger to update product status based on expiry date
exports.updateProductStatus = functions
  .region('asia-northeast1')
  .firestore
  .document('items/{itemId}')
  .onWrite(async (change, context) => {
    const newData = change.after.exists ? change.after.data() : null;
    
    if (!newData) return null;
    
    const expiryDate = newData.expiryDate.toDate();
    const today = new Date();
    const daysUntilExpiry = Math.ceil((expiryDate - today) / (1000 * 60 * 60 * 24));
    
    let status;
    if (daysUntilExpiry < 0) {
      status = '💀';
    } else if (daysUntilExpiry <= 1) {
      status = '😰';
    } else if (daysUntilExpiry <= 3) {
      status = '😟';
    } else if (daysUntilExpiry <= 7) {
      status = '😐';
    } else {
      status = '😊';
    }
    
    if (newData.status !== status) {
      await change.after.ref.update({ status });
    }
    
    return null;
  });

// HTTP function to fetch product info from Open Food Facts
exports.getProductInfo = functions
  .region('asia-northeast1')
  .https.onCall(async (data, context) => {
    const { barcode } = data;
    
    if (!barcode) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Barcode is required'
      );
    }
    
    try {
      // Check cache first
      const cachedProduct = await db.collection('products').doc(barcode).get();
      if (cachedProduct.exists) {
        return cachedProduct.data();
      }
      
      // Fetch from Open Food Facts
      const response = await fetch(
        `https://world.openfoodfacts.org/api/v2/product/${barcode}.json`,
        {
          headers: { 'User-Agent': 'FridgeManager/1.0' },
        }
      );
      
      if (response.ok) {
        const data = await response.json();
        
        if (data.status === 1 && data.product) {
          const productInfo = {
            janCode: barcode,
            productName: data.product.product_name || 'Unknown Product',
            manufacturer: data.product.brands || '',
            category: data.product.categories || '',
            imageUrl: data.product.image_url || null,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          };
          
          // Cache the result
          await db.collection('products').doc(barcode).set(productInfo);
          
          return productInfo;
        }
      }
      
      return null;
    } catch (error) {
      console.error('Error fetching product info:', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to fetch product information'
      );
    }
  });

module.exports = {
  checkExpiringProducts: exports.checkExpiringProducts,
  generateCharacterImage: exports.generateCharacterImage,
  getRecipeSuggestions: exports.getRecipeSuggestions,
  updateProductStatus: exports.updateProductStatus,
  getProductInfo: exports.getProductInfo,
};
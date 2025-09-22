const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const admin = require('firebase-admin');
const fetch = require('node-fetch');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// Scheduled function to check expiring products
exports.checkExpiringProducts = onSchedule({
  schedule: 'every day 09:00',
  timeZone: 'Asia/Tokyo',
  region: 'asia-northeast1'
}, async (event) => {
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

// HTTP function to generate character image (placeholder)
exports.generateCharacterImage = onCall({
  region: 'asia-northeast1',
  cors: true
}, async (request) => {
  const { productName, emotionState, category } = request.data;
  
  if (!productName || !emotionState) {
    throw new Error('Product name and emotion state are required');
  }
  
  try {
    // Placeholder implementation - replace with actual Vertex AI call
    const imageUrl = `https://via.placeholder.com/300x300.png?text=${encodeURIComponent(productName + ' ' + emotionState)}`;
    return { imageUrl };
  } catch (error) {
    console.error('Error generating image:', error);
    throw new Error('Failed to generate character image');
  }
});

// HTTP function to get recipe suggestions
exports.getRecipeSuggestions = onCall({
  region: 'asia-northeast1',
  cors: true
}, async (request) => {
  const { ingredients } = request.data;
  
  if (!ingredients || !Array.isArray(ingredients)) {
    throw new Error('Ingredients array is required');
  }
  
  try {
    // Placeholder implementation
    const recipes = [
      {
        name: '野菜炒め',
        cookingTime: '15分',
        difficulty: '簡単',
        ingredients: ingredients.map(i => `${i}: 適量`),
        instructions: ['材料を切る', 'フライパンで炒める', '調味料を加える'],
        calories: '約200kcal',
      },
    ];
    return { recipes };
  } catch (error) {
    console.error('Error getting recipes:', error);
    throw new Error('Failed to get recipe suggestions');
  }
});

// Firestore trigger to update product status
exports.updateProductStatus = onDocumentWritten({
  document: 'items/{itemId}',
  region: 'asia-northeast1'
}, async (event) => {
  const newData = event.data?.after.data();
  
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
    await event.data.after.ref.update({ status });
  }
  
  return null;
});

// HTTP function to fetch product info from Open Food Facts
exports.getProductInfo = onCall({
  region: 'asia-northeast1',
  cors: true
}, async (request) => {
  const { barcode } = request.data;
  
  if (!barcode) {
    throw new Error('Barcode is required');
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
    throw new Error('Failed to fetch product information');
  }
});
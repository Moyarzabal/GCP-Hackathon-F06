#!/bin/bash

# Auto-setup script for environment variables
# This script fetches configuration from gcloud and Firebase CLI

echo "🔧 Setting up environment variables from gcloud CLI..."

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI is not installed. Please install it first."
    exit 1
fi

# Check if firebase is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Please install it first."
    exit 1
fi

# Get GCP project info
PROJECT_ID=$(gcloud config get-value project)
if [ -z "$PROJECT_ID" ]; then
    echo "❌ No GCP project configured. Run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
REGION="asia-northeast1"

echo "✅ GCP Project: $PROJECT_ID"
echo "✅ Project Number: $PROJECT_NUMBER"

# Get Firebase configuration
echo "📱 Fetching Firebase configuration..."

# Check if web app exists
WEB_APP_ID=$(firebase apps:list | grep WEB | awk '{print $2}' | head -1)
if [ -z "$WEB_APP_ID" ]; then
    echo "Creating Firebase Web app..."
    firebase apps:create web "FridgeManager Web"
    WEB_APP_ID=$(firebase apps:list | grep WEB | awk '{print $2}' | head -1)
fi

# Get web config
FIREBASE_CONFIG=$(firebase apps:sdkconfig web $WEB_APP_ID 2>/dev/null)

# Parse JSON values
API_KEY=$(echo "$FIREBASE_CONFIG" | grep '"apiKey"' | cut -d'"' -f4)
AUTH_DOMAIN=$(echo "$FIREBASE_CONFIG" | grep '"authDomain"' | cut -d'"' -f4)
STORAGE_BUCKET=$(echo "$FIREBASE_CONFIG" | grep '"storageBucket"' | cut -d'"' -f4)
MESSAGING_SENDER_ID=$(echo "$FIREBASE_CONFIG" | grep '"messagingSenderId"' | cut -d'"' -f4)
APP_ID=$(echo "$FIREBASE_CONFIG" | grep '"appId"' | cut -d'"' -f4)

# Create .env file
cat > .env << EOF
# Firebase/GCP Configuration
# Auto-generated from gcloud CLI
# Generated at: $(date)

# GCP Configuration
GCP_PROJECT_ID=$PROJECT_ID
GCP_PROJECT_NUMBER=$PROJECT_NUMBER
GCP_REGION=$REGION

# Firebase Configuration (from Firebase SDK)
FIREBASE_API_KEY=$API_KEY
FIREBASE_AUTH_DOMAIN=$AUTH_DOMAIN
FIREBASE_PROJECT_ID=$PROJECT_ID
FIREBASE_STORAGE_BUCKET=$STORAGE_BUCKET
FIREBASE_MESSAGING_SENDER_ID=$MESSAGING_SENDER_ID
FIREBASE_APP_ID=$APP_ID

# Vertex AI Configuration
VERTEX_AI_PROJECT=$PROJECT_ID
VERTEX_AI_LOCATION=$REGION
VERTEX_AI_ENDPOINT=$REGION-aiplatform.googleapis.com

# API Keys (需要手動で設定)
# Gemini API Key - Get from: https://makersuite.google.com/app/apikey
GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE

# FCM Web Push (需要手動で設定)
# Get from Firebase Console > Project Settings > Cloud Messaging
VAPID_KEY=YOUR_VAPID_KEY_HERE

# Application Default Credentials (optional)
# Run: gcloud auth application-default login
# GOOGLE_APPLICATION_CREDENTIALS=/path/to/credentials.json

# Environment
ENVIRONMENT=development

# Open Food Facts API
OPEN_FOOD_FACTS_USER_AGENT=FridgeManager/1.0
EOF

echo "✅ .env file created successfully!"

# Create iOS and Android apps if they don't exist
echo "📱 Setting up iOS and Android apps..."

# Check iOS app
IOS_APP_ID=$(firebase apps:list | grep IOS | awk '{print $2}' | head -1)
if [ -z "$IOS_APP_ID" ]; then
    echo "Creating Firebase iOS app..."
    firebase apps:create ios "FridgeManager iOS" --bundle-id com.f06team.fridgemanager
    IOS_APP_ID=$(firebase apps:list | grep IOS | awk '{print $2}' | head -1)
fi

# Check Android app
ANDROID_APP_ID=$(firebase apps:list | grep ANDROID | awk '{print $2}' | head -1)
if [ -z "$ANDROID_APP_ID" ]; then
    echo "Creating Firebase Android app..."
    firebase apps:create android "FridgeManager Android" --package-name com.f06team.fridgemanager
    ANDROID_APP_ID=$(firebase apps:list | grep ANDROID | awk '{print $2}' | head -1)
fi

# Download configuration files
if [ ! -z "$IOS_APP_ID" ]; then
    echo "📱 Downloading iOS configuration..."
    mkdir -p ios/Runner
    firebase apps:sdkconfig ios $IOS_APP_ID > ios/Runner/GoogleService-Info.plist
    echo "✅ iOS configuration saved to ios/Runner/GoogleService-Info.plist"
fi

if [ ! -z "$ANDROID_APP_ID" ]; then
    echo "🤖 Downloading Android configuration..."
    mkdir -p android/app
    firebase apps:sdkconfig android $ANDROID_APP_ID > android/app/google-services.json
    echo "✅ Android configuration saved to android/app/google-services.json"
fi

echo ""
echo "🎉 Environment setup complete!"
echo ""
echo "⚠️  Manual steps required:"
echo "1. Get Gemini API Key from: https://makersuite.google.com/app/apikey"
echo "2. Get VAPID Key from Firebase Console > Project Settings > Cloud Messaging"
echo "3. Update these values in the .env file"
echo ""
echo "📱 To add iOS/Android platforms to your Flutter project:"
echo "   flutter create --platforms=ios,android ."
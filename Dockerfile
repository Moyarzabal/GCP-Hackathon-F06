# Flutter Webアプリ用の軽量なnginxイメージ
FROM nginx:alpine

# nginxの設定ファイルをコピー
COPY nginx.conf /etc/nginx/nginx.conf

# ビルド済みのFlutter Webアプリをコピー
COPY build/web /usr/share/nginx/html

# Cloud Runはポート8080を使用
EXPOSE 8080

# nginxを起動
CMD ["nginx", "-g", "daemon off;"]
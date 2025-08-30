# Flutter Webアプリ用の軽量なnginxイメージ
FROM nginx:alpine

# Cloud Run用にnginxユーザーの権限を設定
RUN sed -i 's/user  nginx;/user  nginx;/g' /etc/nginx/nginx.conf

# デフォルトのnginx設定を削除
RUN rm /etc/nginx/conf.d/default.conf

# カスタムnginx設定ファイルをコピー
COPY nginx.conf /etc/nginx/nginx.conf

# ビルド済みのFlutter Webアプリをコピー
COPY build/web /usr/share/nginx/html

# 権限を設定
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chmod -R 755 /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

# Cloud Runはポート8080を使用
EXPOSE 8080

# nginxユーザーで実行
USER nginx

# nginxを起動
CMD ["nginx", "-g", "daemon off;"]
# Multi-stage Dockerfile for building Flutter web and serving with nginx
FROM cirrusci/flutter:stable AS builder

WORKDIR /app

# Copy project
COPY . .

# Ensure dependencies and build web release
RUN flutter pub get
RUN flutter build web --release

# Serve with nginx in a small image
FROM nginx:alpine

# Remove default site
RUN rm -rf /usr/share/nginx/html/*

# Copy built web app
COPY --from=builder /app/build/web /usr/share/nginx/html

# Optional: provide small custom nginx config if you need SPA fallback.
# (If you want SPA routing support uncomment and copy an nginx.conf file.)
# COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

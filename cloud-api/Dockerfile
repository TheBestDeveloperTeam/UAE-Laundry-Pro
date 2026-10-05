# Multi-Stage Production Build for LaundryPro UAE Cloud Hub API
# Stage 1: Build & Dependency Preparation
FROM php:8.2-fpm-alpine AS builder

RUN apk update && apk add --no-cache \
    curl \
    unzip \
    libzip-dev \
    oniguruma-dev

RUN docker-php-ext-install pdo_mysql mbstring zip bcmath opcache

# Stage 2: Final Minimal Runtime Image
FROM php:8.2-fpm-alpine

# Install minimal runtime dependencies (no compiler/build tools)
RUN apk update && apk add --no-cache \
    nginx \
    supervisor \
    mariadb-client \
    libzip \
    oniguruma \
    && rm -rf /var/cache/apk/*

# Copy compiled PHP extensions from builder
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# Setup Nginx configuration
RUN rm /etc/nginx/conf.d/default.conf 2>/dev/null || true
RUN echo -e "server {\n\
    listen 80;\n\
    server_name _;\n\
    root /var/www/html/public;\n\
    index index.php index.html;\n\
\n\
    location / {\n\
        try_files \$uri \$uri/ /index.php?\$query_string;\n\
    }\n\
\n\
    location ~ \.php$ {\n\
        include fastcgi_params;\n\
        fastcgi_pass 127.0.0.1:9000;\n\
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;\n\
        fastcgi_index index.php;\n\
    }\n\
\n\
    location ~ /\.ht {\n\
        deny all;\n\
    }\n\
}" > /etc/nginx/http.d/default.conf

# Setup Supervisor configuration
RUN mkdir -p /etc/supervisor/conf.d/
RUN echo -e "[supervisord]\n\
nodaemon=true\n\
\n\
[program:php-fpm]\n\
command=php-fpm\n\
autostart=true\n\
autorestart=true\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n\
\n\
[program:nginx]\n\
command=nginx -g 'daemon off;'\n\
autostart=true\n\
autorestart=true\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0" > /etc/supervisor/conf.d/supervisord.conf

# Set working directory
WORKDIR /var/www/html

# Copy application files (filtered via .dockerignore)
COPY . .

# Remove unnecessary documentation & tests from runtime if copied
RUN rm -rf tests docs README.md \
    && mkdir -p storage/logs \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

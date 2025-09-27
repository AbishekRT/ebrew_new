#!/bin/sh
set -e

: "${PORT:=8080}"

# Minimal default nginx config
cat > /etc/nginx/conf.d/default.conf <<EOF
server {
    listen ${PORT};
    root /var/www/html/public;

    index index.php index.html;
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include fastcgi_params;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

cd /var/www/html

# ensure composer is optimized
composer dump-autoload --optimize --no-interaction || true

# ensure storage symlink
php artisan storage:link || true

# migrate if requested
if [ "${MIGRATE_ON_DEPLOY:-false}" = "true" ]; then
  echo "Running migrations..."
  php artisan migrate --force || { echo 'Migration failed'; exit 1; }
fi

# start services
php-fpm -D
nginx -g 'daemon off;'

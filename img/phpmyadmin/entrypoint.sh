#!/bin/bash
set -e

# Set up config if not present
if [ ! -f ./config.inc.php ]; then
    echo "[Entrypoint] Generating phpMyAdmin config file..."

    cat > ./config.inc.php <<EOF
<?php
\$cfg['blowfish_secret'] = '$(openssl rand -base64 32)';
\$i = 0;
\$i++;
\$cfg['Servers'][\$i]['auth_type'] = 'cookie';
\$cfg['Servers'][\$i]['host'] = '${DB_CONTAINER_NAME:-dbs}';
\$cfg['Servers'][\$i]['compress'] = false;
\$cfg['Servers'][\$i]['AllowNoPassword'] = true;
EOF
fi

echo "[Entrypoint] Starting Apache..."
exec apachectl -D FOREGROUND

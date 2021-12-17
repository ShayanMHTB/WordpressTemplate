#!/bin/bash
set -e

echo "[Entrypoint] Starting MailHog..."
exec mailhog

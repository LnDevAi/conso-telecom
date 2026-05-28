#!/bin/bash
set -e

# deploy.sh — Initial server setup & deployment for ConsoTélécom back-end
# Target: Ubuntu 22.04 LTS, Hetzner CX11
# Run as root on first deployment: bash deploy.sh

APP_DIR="/opt/consotelecom"
REPO_URL="https://github.com/LnDevAi/conso-telecom.git"
DOMAIN_API="api.consotelecom.edefence.tech"
DOMAIN_ADMIN="admin.consotelecom.edefence.tech"

echo "=========================================="
echo " ConsoTélécom — Déploiement Serveur"
echo "=========================================="

# --- System packages ---
apt-get update -y
apt-get install -y git curl nginx certbot python3-certbot-nginx \
  ca-certificates gnupg lsb-release

# --- Docker ---
if ! command -v docker &>/dev/null; then
  curl -fsSL https://get.docker.com | sh
  systemctl enable docker --now
fi

# --- Project dir ---
mkdir -p "$APP_DIR"
if [ ! -d "$APP_DIR/.git" ]; then
  git clone "$REPO_URL" "$APP_DIR"
else
  cd "$APP_DIR" && git pull origin main
fi

cd "$APP_DIR"

# Copy env if not present
if [ ! -f .env ]; then
  cp .env.example .env
  echo ""
  echo "⚠️  Éditez $APP_DIR/.env avec vos vrais secrets avant de continuer!"
  echo "    nano $APP_DIR/.env"
  exit 0
fi

# --- TLS ---
certbot --nginx -d "$DOMAIN_API" -d "$DOMAIN_ADMIN" --non-interactive --agree-tos -m admin@edefence.tech || true

# --- Docker Compose prod ---
docker compose -f docker-compose.prod.yml pull || true
docker compose -f docker-compose.prod.yml up -d --build

sleep 8
docker compose -f docker-compose.prod.yml exec -T backend alembic upgrade head
docker compose -f docker-compose.prod.yml exec -T backend python -m app.services.seed

# --- Health check ---
sleep 3
curl -sf http://localhost:8000/api/v1/health && echo "✅ Backend OK" || echo "⚠️  Backend KO"

echo ""
echo "✅ Déploiement ConsoTélécom terminé : $(date)"
echo "   API     : https://$DOMAIN_API"
echo "   Back-office: https://$DOMAIN_ADMIN"

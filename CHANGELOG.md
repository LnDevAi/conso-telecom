# Changelog — ConsoTélécom

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2026-05-28

### Added

#### Backend API (FastAPI)
- Architecture complète FastAPI 0.111 + SQLAlchemy 2.0 async + asyncpg + PostgreSQL 16
- Modèles : Country, Operator, TariffPlan, UnitTariff, AiProvider, AiModel, ExchangeRate, AdminUser
- Endpoints publics (pas d'auth) pour l'app mobile :
  - `GET /api/v1/tariffs/countries` — pays actifs
  - `GET /api/v1/tariffs/operators/{country_code}` — opérateurs avec forfaits et tarifs unitaires
  - `GET /api/v1/tariffs/ai-providers` — fournisseurs IA avec modèles et tarifs
  - `GET /api/v1/tariffs/exchange-rates` — taux de change
  - `GET /api/v1/tariffs/updates?since=<timestamp>` — delta sync incrémental
- Endpoints admin protégés JWT : CRUD complet pour tous les modèles
- Auto-refresh des taux de change via open.er-api.com (endpoint `/admin/exchange-rates/refresh`)
- Seed automatique au démarrage :
  - Opérateurs BF : Orange, Moov Africa, Telecel (codes USSD réels)
  - Forfaits avec tarifs réalistes en FCFA
  - Tarifs unitaires data/voix/SMS on-net/off-net/international
  - Fournisseurs IA : Anthropic, OpenAI, Google, Mistral (10 modèles, tarifs USD/MTok réels 2026)
  - Taux de change USD/XOF ~600, EUR/XOF 655.957 (taux CFA fixe)
- Migrations Alembic (001_initial)
- Tests pytest : 15+ tests couvrant tariffs API et admin auth
- Dockerfile multi-stage (Python 3.12 slim)

#### Back-office Flutter Web
- Authentification JWT avec stockage sécurisé (flutter_secure_storage)
- GoRouter avec redirection auth automatique
- Pages complètes : Dashboard, Pays, Opérateurs, Tarifs, Fournisseurs IA, Modèles IA, Taux de change
- DataTable2 avec CRUD complet, dialogs d'édition, confirmation de suppression
- Thème admin (sidebar #1E3A5F, accent #2979FF)
- Synchronisation automatique des taux de change avec feedback utilisateur
- Dockerfile multi-stage (Flutter build web → nginx:alpine)

#### Infra partagée
- `docker-compose.yml` : db (postgres:16-alpine) + backend (port 8000) + backoffice (port 3000)
- CI GitHub Actions : backend (Python 3.11 + 3.12) + mobile + backoffice (Flutter stable)
- CD GitHub Actions : déploiement SSH via appleboy/ssh-action
- `.gitignore` : Python + Flutter + Docker + IDE

## [0.1.0] - 2025-01-01

### Added
- Application mobile Flutter Android-first
- Mesure locale consommation voix/SMS/data via MethodChannel (NetworkStats + CallLog)
- Calcul de coûts en FCFA (Burkina Faso)
- Gestionnaire de tokens IA (Claude, OpenAI, Gemini, Mistral) avec clés chiffrées AES-256
- Alertes seuil de consommation
- Comparateur d'offres opérateurs
- Back-office Flutter Web (prototype)
- API FastAPI légère (tarifs + admin, version initiale)
- Docker Compose
- CI GitHub Actions

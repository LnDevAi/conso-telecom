# ConsoTélécom v2.0

> Mesure locale de consommation télécom et tokens IA — Burkina Faso / E-DEFENCE

ConsoTélécom est une plateforme **local-first** de suivi de consommation télécom et d'IA.
L'application mobile tourne entièrement sur l'appareil : aucune donnée de consommation n'est
envoyée aux serveurs. L'API backend ne sert qu'à distribuer les **grilles tarifaires** (opérateurs
télécom BF + fournisseurs IA) à l'application.

---

## Fonctionnalités

### Application mobile (Flutter Android)
- Mesure automatique de la consommation data, voix, SMS via MethodChannel
- Calcul de coûts en FCFA selon les tarifs opérateur (Orange, Moov, Telecel)
- Suivi des tokens IA (Claude, GPT, Gemini, Mistral) et estimation des coûts en USD/XOF
- Clés API IA chiffrées localement (AES-256) — jamais transmises
- Alertes sur seuil de consommation
- Comparateur d'offres

### Back-office admin (Flutter Web)
- Authentification JWT sécurisée
- Gestion des pays et opérateurs (CRUD)
- Gestion des forfaits et tarifs unitaires par opérateur
- Gestion des fournisseurs IA et de leurs modèles avec tarification en USD/MTok
- Taux de change avec synchronisation automatique (open.er-api.com)
- Tableau de bord avec statistiques globales

### API backend (FastAPI + PostgreSQL)
- Endpoints publics pour l'app mobile (tarifs, opérateurs, modèles IA, taux de change)
- Delta sync (`/tariffs/updates?since=<timestamp>`) pour synchronisation incrémentale
- Endpoints admin protégés par JWT

---

## Architecture

```
conso-telecom/
├── mobile/           # App Android Flutter (local-first)
├── backoffice/       # Admin Flutter Web
├── backend/          # API FastAPI + PostgreSQL
├── .github/
│   └── workflows/   # CI (pytest + flutter) + CD (SSH deploy)
├── docker-compose.yml
└── README.md
```

### Stack technique

| Couche       | Technologie                                  |
|--------------|----------------------------------------------|
| Mobile       | Flutter, Isar, WorkManager, MethodChannel    |
| Back-office  | Flutter Web, Riverpod, GoRouter, DataTable2  |
| API          | FastAPI 0.111, SQLAlchemy 2.0 async          |
| Base données | PostgreSQL 16                                |
| Auth         | JWT (HS256), bcrypt                          |
| Infra        | Docker Compose, nginx                        |

---

## Démarrage rapide

### Prérequis
- Docker et Docker Compose
- (Optionnel) Python 3.12 + Flutter SDK pour le développement local

### Lancement avec Docker

```bash
# 1. Cloner le dépôt
git clone https://github.com/LnDevAi/conso-telecom.git
cd conso-telecom

# 2. Configurer l'environnement
cp backend/.env.example backend/.env
# Editer backend/.env avec vos vraies valeurs

# 3. Démarrer les services
docker compose up -d

# 4. Accès
#   Back-office : http://localhost:3000
#   API docs    : http://localhost:8000/api/docs
#   API health  : http://localhost:8000/api/health
```

### Développement backend

```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # ou .venv\Scripts\activate sur Windows
pip install -r requirements.txt
cp .env.example .env
alembic upgrade head
uvicorn app.main:app --reload
```

### Développement back-office

```bash
cd backoffice
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

### Tests backend

```bash
cd backend
pip install aiosqlite pytest-asyncio
pytest tests/ -v
```

---

## Déploiement production

Configurer les secrets GitHub :
- `PROD_HOST` — IP du serveur
- `PROD_USER` — Utilisateur SSH
- `PROD_SSH_KEY` — Clé privée SSH

Le workflow CD déploie automatiquement sur push vers `main`.

---

## Données initiales (seed)

Au démarrage, l'API insère automatiquement :

**Opérateurs Burkina Faso :**
- Orange BF (`#124#` / `*150*1#`)
- Moov Africa BF (`#111#` / `*111#`)
- Telecel Faso (`#123#`)

**Fournisseurs IA :** Anthropic, OpenAI, Google, Mistral (tarifs réels USD/MTok)

**Taux de change :** USD/XOF ~600, EUR/XOF 655.957 (taux CFA fixe)

---

## Conformité & Sécurité

- Données de consommation 100% locales (loi n°010-2004/AN, CIL BF)
- Clés IA chiffrées AES-256 sur l'appareil
- API backend sans stockage de données personnelles
- HTTPS / TLS 1.3 en production

---

## Contribution

1. Fork le dépôt
2. Créer une branche (`git checkout -b feature/ma-feature`)
3. Committer (`git commit -m 'feat: ma feature'`)
4. Pousser (`git push origin feature/ma-feature`)
5. Ouvrir une Pull Request vers `dev`

---

© 2026 E-DEFENCE — Burkina Faso — Licence MIT

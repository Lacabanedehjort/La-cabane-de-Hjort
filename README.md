# La Cabane de Hjort — Documentation complète

> Boutique artisanale viking/médiéval — créations en bois gravé (porte-clefs, plateaux, dessous de verre, marque-pages)

---

## Sommaire

1. [État actuel (V1) — ce qui existe](#1-état-actuel-v1)
2. [Les 15 problèmes identifiés dans le code V1](#2-les-15-problèmes-identifiés)
3. [Vision V2 — la vraie boutique](#3-vision-v2)
4. [Stack technique choisie](#4-stack-technique)
5. [Architecture V2](#5-architecture-v2)
6. [Plan de migration — étape par étape](#6-plan-de-migration--étape-par-étape)
7. [Comment lancer le projet en local](#7-lancer-en-local)
8. [Déploiement avec Docker](#8-déploiement-docker)
9. [Variables d'environnement](#9-variables-denvironnement)

---

## 1. État actuel (V1)

La V1 est un site statique en HTML/CSS/JS pur :

- ~70 fichiers HTML (une page par produit)
- 1 fichier `style.css` global
- 1 fichier `script.js` global
- Aucun backend, aucune base de données
- Les données (panier, utilisateurs, avis) sont stockées dans le `localStorage` du navigateur

**Ce qui fonctionne :**

- Navigation entre les pages produit
- Ajout au panier (côté navigateur uniquement)
- Envoi de commande par email via EmailJS
- Formulaire de contact

**Ce qui ne fonctionne pas correctement :**

- Voir la section suivante

---

## 2. Les 15 problèmes identifiés

Voici les 15 bugs et problèmes structurels trouvés dans le code V1, du plus critique au plus mineur.

---

### 🔴 Problème 1 — Mots de passe stockés en clair dans le navigateur

**Fichier :** `inscription.html`, `login.html`

```js
// ❌ Ce que fait le code actuel
users.push({ username, password }); // password = "monmotdepasse" en clair
localStorage.setItem("users", JSON.stringify(users));
```

N'importe qui peut ouvrir les DevTools du navigateur (F12 → Application → localStorage) et voir tous les mots de passe. C'est une faille de sécurité critique.

**Solution V2 :** authentification côté serveur avec mots de passe hachés (bcrypt), sessions sécurisées via JWT ou cookies httpOnly.

---

### 🔴 Problème 2 — Pas de vrai backend : les commandes peuvent être falsifiées

**Fichier :** `commande.html`

Le prix total est calculé **dans le navigateur** depuis le `localStorage`. N'importe qui peut modifier sa commande dans les DevTools avant de l'envoyer. Le vendeur ne peut pas vérifier que le montant reçu par email est correct.

**Solution V2 :** recalcul du total côté serveur depuis une base de données de produits avec prix fixes.

---

### 🔴 Problème 3 — Les avis ne sont stockés que sur l'ordinateur du visiteur

**Fichier :** `avis.html`

```js
// ❌ Stocké dans localStorage = visible uniquement par la personne qui l'a écrit
localStorage.setItem("reviews", JSON.stringify(reviews));
```

Chaque visiteur voit **ses propres avis uniquement**. Les avis ne sont jamais partagés entre les utilisateurs.

**Solution V2 :** base de données partagée (PostgreSQL ou SQLite).

---

### 🔴 Problème 4 — Le panier est perdu si on change de navigateur ou d'appareil

**Fichier :** toutes les pages produit

Le panier est dans le `localStorage`, donc lié à un navigateur précis. Si le client commence ses achats sur mobile et veut finir sur ordinateur, son panier est vide.

**Solution V2 :** panier persisté en base de données, lié au compte utilisateur.

---

### 🔴 Problème 5 — Placeholders EmailJS non remplacés

**Fichiers :** `index.html`, `panier.html` et d'autres

```js
// ❌ Valeurs de test jamais remplacées
emailjs.sendForm("TON_SERVICE_ID", "TON_TEMPLATE_ID", this)
```

Les formulaires de ces pages ne fonctionnent pas du tout — EmailJS renvoie une erreur silencieuse ou une alerte cryptique.

**Solution V2 :** variables d'environnement centralisées (`.env`), plus de duplication.

---

### 🟠 Problème 6 — Scripts placés avant `<body>` : le DOM n'est pas encore chargé

**Fichiers :** `login.html`, `inscription.html`, `avis.html`, `panier.html`, etc.

```html
<!-- ❌ Structure incorrecte -->
<head>...</head>
<script>
  document.getElementById("user-info").innerText = "..."; // 💥 null : le <p> n'existe pas encore
</script>
<body>
  <p id="user-info"></p> <!-- trop tard -->
</body>
```

Certains scripts s'exécutent avant que les éléments HTML qu'ils ciblent existent, provoquant des erreurs `null` silencieuses. C'est pourquoi du code défensif `DOMContentLoaded` a été ajouté en patchwork.

**Solution V2 :** framework (Next.js) qui gère le cycle de vie des composants proprement.

---

### 🟠 Problème 7 — EmailJS importé en double sur plusieurs pages

**Fichiers :** `commande.html`, `panier.html`

```html
<!-- ❌ Deux fois le même CDN sur la même page -->
<script src="https://cdn.jsdelivr.net/npm/emailjs-com@3/dist/email.min.js"></script>
...
<script src="https://cdn.jsdelivr.net/npm/emailjs-com@3/dist/email.min.js"></script>
```

Charge la librairie deux fois, ralentit le chargement, peut provoquer des comportements inattendus.

---

### 🟠 Problème 8 — 70 fichiers HTML avec le même header/footer copié-collé

Il y a environ 70 fichiers HTML. Chaque page contient exactement le même bloc `<header>` avec la navigation. Si on veut ajouter un lien dans le menu, il faut modifier **70 fichiers** à la main.

**Solution V2 :** composant `<Navbar>` unique réutilisé dans chaque page.

---

### 🟠 Problème 9 — Aucune page produit n'a de vrai SEO

Les pages produit ont toutes `<title>La cabane de Hjort</title>` — le même titre générique pour tous les articles. Google ne peut pas distinguer "Porte-clef Mjolnir" de "Plateau Vegvisir".

**Solution V2 :** Next.js avec `generateMetadata()` par produit — titre, description, image Open Graph générés dynamiquement.

---

### 🟠 Problème 10 — Pas de gestion du stock réelle

**Fichier :** `script.js`

```js
// Le "stock" est lu dans le texte de la description HTML
if (description.includes("hors stock")) {
    bouton.disabled = true;
}
```

Le stock est géré en **écrivant "hors stock" dans le texte** de la description produit. C'est fragile : une faute d'orthographe et le produit restera disponible à l'achat même épuisé.

**Solution V2 :** champ `stock: number` en base de données.

---

### 🟡 Problème 11 — Pas de confirmation de commande pour le client

Quand une commande est passée, un email est envoyé **au vendeur** via EmailJS, mais le client ne reçoit aucune confirmation. Il doit croire sur parole que la commande a bien été reçue.

**Solution V2 :** envoi d'un email de confirmation automatique au client + page de confirmation dédiée.

---

### 🟡 Problème 12 — Pas de protection des routes

N'importe qui peut aller directement sur `commande.html` ou `paiement.html` sans être connecté ni avoir de produits dans le panier. Il n'y a aucune redirection.

**Solution V2 :** middleware Next.js vérifiant la session et le panier avant d'accéder aux pages de checkout.

---

### 🟡 Problème 13 — Pas de responsive mobile fiable

Le CSS n'a aucune media query. La navigation horizontale avec 8 liens dépasse sur mobile. Aucun test d'affichage sur petits écrans n'est documenté.

**Solution V2 :** Tailwind CSS avec breakpoints mobile-first.

---

### 🟡 Problème 14 — Images non optimisées

Les photos produit (`.jpg`) sont des photos brutes sans compression ni redimensionnement. Elles sont chargées en taille maximale même sur mobile.

**Solution V2 :** composant `<Image>` de Next.js avec optimisation automatique (WebP, lazy loading, tailles adaptatives).

---

### 🟡 Problème 15 — Pas de paiement réel intégré

La page `paiement.html` existe mais ne contient aucune intégration de paiement fonctionnelle. La commande est envoyée par email, le paiement se fait "à l'ancienne" (virement, chèque, en main propre ?).

**Solution V2 :** intégration Stripe (solution la plus simple pour un artisan français — Stripe Checkout, sans serveur complexe).

---

## 3. Vision V2

La V2 transforme le site statique en une vraie boutique avec :

| Fonctionnalité | V1 | V2 |
|---|---|---|
| Données produits | Fichiers HTML | Base de données |
| Panier | localStorage | Base de données (persistant) |
| Authentification | localStorage (mots de passe clairs) | Serveur sécurisé (NextAuth) |
| Avis clients | localStorage (privés) | Base de données (partagés) |
| Commandes | Email manuel | Système de commandes + email automatique |
| Paiement | Aucun | Stripe Checkout |
| Stock | Texte dans HTML | Champ numérique en base |
| SEO | Titre générique | Métadonnées par produit |
| Maintenance | 70 fichiers à éditer | 1 composant à modifier |
| Déploiement | Fichiers statiques | Docker + serveur |

---

## 4. Stack technique

**Pourquoi Next.js plutôt que Svelte ?**

Next.js est recommandé ici pour plusieurs raisons :

- **SEO natif** avec Server Side Rendering — crucial pour une boutique (Google indexe les fiches produit)
- **Écosystème e-commerce** mature : NextAuth pour l'auth, intégrations Stripe documentées
- **Plus de ressources** pour apprendre (tutos, exemples, communauté française)
- **App Router** (Next.js 14+) simplifie les layouts partagés — exactement ce dont on a besoin pour le header/footer commun

| Couche | Techno | Pourquoi |
|---|---|---|
| Frontend | Next.js 14 (App Router) | SSR, SEO, composants réutilisables |
| Style | Tailwind CSS | Responsive rapide, pas de CSS à la main |
| Base de données | SQLite (dev) / PostgreSQL (prod) | Simple pour commencer, scalable |
| ORM | Prisma | Schéma typé, migrations automatiques |
| Auth | NextAuth.js | Google OAuth ou email/password sécurisé |
| Paiement | Stripe Checkout | Le plus simple pour un artisan |
| Emails | Resend ou Nodemailer | Remplacement propre d'EmailJS |
| Conteneur | Docker + Docker Compose | Déploiement reproductible |
| Hébergement | VPS (Coolify ou manuel) | Contrôle total, coût maîtrisé |

---

## 5. Architecture V2

```text
la-cabane-de-hjort/
├── src/
│   ├── app/                        # Next.js App Router
│   │   ├── layout.tsx              # Layout global (Navbar + Footer communs)
│   │   ├── page.tsx                # Page d'accueil
│   │   ├── produits/
│   │   │   ├── page.tsx            # Catalogue
│   │   │   └── [slug]/page.tsx     # Fiche produit dynamique (remplace les 70 HTML)
│   │   ├── panier/page.tsx
│   │   ├── commande/page.tsx
│   │   ├── paiement/
│   │   │   ├── page.tsx
│   │   │   └── succes/page.tsx
│   │   ├── auth/
│   │   │   ├── login/page.tsx
│   │   │   └── inscription/page.tsx
│   │   ├── avis/page.tsx
│   │   ├── contact/page.tsx
│   │   └── api/                    # API Routes Next.js
│   │       ├── auth/[...nextauth]/ # NextAuth
│   │       ├── produits/           # CRUD produits
│   │       ├── commandes/          # Créer une commande
│   │       ├── avis/               # CRUD avis
│   │       └── webhooks/stripe/    # Confirmation paiement Stripe
│   ├── components/
│   │   ├── Navbar.tsx              # Navigation unique
│   │   ├── Footer.tsx
│   │   ├── ProduitCard.tsx         # Carte produit réutilisable
│   │   ├── PanierItem.tsx
│   │   └── AvisForm.tsx
│   ├── lib/
│   │   ├── prisma.ts               # Client Prisma singleton
│   │   ├── stripe.ts               # Client Stripe
│   │   └── email.ts                # Envoi d'emails
│   └── types/
│       └── index.ts                # Types TypeScript partagés
├── prisma/
│   ├── schema.prisma               # Schéma base de données
│   └── seed.ts                     # Données initiales (produits actuels)
├── public/
│   └── images/                     # Photos produits optimisées
├── Dockerfile
├── docker-compose.yml
├── docker-compose.dev.yml
├── .env.example
└── package.json
```

**Schéma base de données (Prisma) :**

```prisma
model Produit {
  id          String   @id @default(cuid())
  slug        String   @unique        // "porte-clef-mjolnir-corbeau"
  nom         String
  description String
  prix        Float
  stock       Int      @default(0)
  categorie   String                  // "porte-clefs", "plateaux", etc.
  images      String[]
  createdAt   DateTime @default(now())
  panierItems PanierItem[]
  commandeItems CommandeItem[]
}

model Utilisateur {
  id        String   @id @default(cuid())
  email     String   @unique
  username  String   @unique
  password  String                    // bcrypt hash
  createdAt DateTime @default(now())
  commandes Commande[]
  avis      Avis[]
}

model Commande {
  id          String         @id @default(cuid())
  userId      String?
  user        Utilisateur?   @relation(fields: [userId], references: [id])
  nom         String
  email       String
  adresse     String
  total       Float
  fraisPort   Float
  statut      String         @default("en_attente")
  stripeId    String?
  items       CommandeItem[]
  createdAt   DateTime       @default(now())
}

model CommandeItem {
  id        String   @id @default(cuid())
  commandeId String
  commande  Commande @relation(fields: [commandeId], references: [id])
  produitId String
  produit   Produit  @relation(fields: [produitId], references: [id])
  prix      Float
  quantite  Int
}

model Avis {
  id        String      @id @default(cuid())
  userId    String?
  user      Utilisateur? @relation(fields: [userId], references: [id])
  nom       String
  note      Int                       // 1-5
  commentaire String
  valide    Boolean     @default(false) // modération avant publication
  createdAt DateTime    @default(now())
}
```

---

## 6. Plan de migration — étape par étape

### Étape 1 — Initialiser le projet Next.js

```bash
npx create-next-app@latest la-cabane-de-hjort-v2 \
  --typescript \
  --tailwind \
  --app \
  --src-dir \
  --import-alias "@/*"

cd la-cabane-de-hjort-v2
```

### Étape 2 — Installer les dépendances

```bash
npm install prisma @prisma/client
npm install next-auth @auth/prisma-adapter
npm install stripe @stripe/stripe-js
npm install bcryptjs
npm install resend                    # ou nodemailer
npm install -D @types/bcryptjs
npx prisma init
```

### Étape 3 — Configurer la base de données

Éditer `prisma/schema.prisma` avec le schéma ci-dessus, puis :

```bash
npx prisma migrate dev --name init
npx prisma generate
```

### Étape 4 — Créer le fichier `.env`

```bash
cp .env.example .env
# Remplir les valeurs (voir section Variables d'environnement)
```

### Étape 5 — Migrer les produits dans la base de données

Créer `prisma/seed.ts` avec tous les produits actuels (nom, prix, slug, catégorie, image). Lancer :

```bash
npx prisma db seed
```

Les 70 fichiers HTML produit deviennent **0 fichier** — une seule page dynamique `src/app/produits/[slug]/page.tsx`.

### Étape 6 — Créer le layout global (Navbar + Footer)

`src/app/layout.tsx` — remplace le header/footer copié-collé dans les 70 fichiers. Modifier la navigation = 1 fichier.

### Étape 7 — Configurer NextAuth (authentification sécurisée)

`src/app/api/auth/[...nextauth]/route.ts` — remplace le système `localStorage` avec mots de passe en clair. Les mots de passe sont hachés avec bcrypt avant d'être stockés.

### Étape 8 — Créer les pages catalogue et fiche produit

- `src/app/produits/page.tsx` — liste tous les produits depuis la base de données
- `src/app/produits/[slug]/page.tsx` — fiche produit avec `generateMetadata()` pour le SEO

### Étape 9 — Créer l'API panier

`src/app/api/panier/route.ts` — le panier est maintenant en base de données (lié au compte utilisateur si connecté, sinon cookie de session temporaire).

### Étape 10 — Intégrer Stripe Checkout

`src/app/api/commandes/route.ts` — crée une session Stripe, redirige vers le paiement hébergé par Stripe. Le webhook `src/app/api/webhooks/stripe/route.ts` confirme la commande après paiement réel.

### Étape 11 — Créer le système d'emails

`src/lib/email.ts` — remplace EmailJS. Envoie :

- Un email au vendeur avec le détail de la commande
- Un email de confirmation au client

### Étape 12 — Migrer les avis

`src/app/avis/page.tsx` — les avis sont en base de données, visibles par tous. Ajouter un champ `valide` pour que le vendeur puisse modérer avant publication.

### Étape 13 — Ajouter la gestion du stock

Le champ `stock` en base de données est décrémenté automatiquement à chaque commande confirmée (webhook Stripe). Le bouton "Ajouter au panier" est désactivé si `stock === 0`.

### Étape 14 — Dockeriser l'application

```dockerfile
# Dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npx prisma generate
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
EXPOSE 3000
CMD ["node", "server.js"]
```

```yaml
# docker-compose.yml
services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=${DATABASE_URL}
      - NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
      - STRIPE_SECRET_KEY=${STRIPE_SECRET_KEY}
    depends_on:
      - db

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: cabane_hjort
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

### Étape 15 — Déployer sur le VPS

```bash
# Sur le VPS
git clone <repo>
cp .env.example .env
# Remplir .env avec les vraies valeurs
docker compose up -d
docker compose exec app npx prisma migrate deploy
docker compose exec app npx prisma db seed
```

Pointer le domaine vers le VPS via Cloudflare, configurer Traefik ou Nginx comme reverse proxy avec HTTPS.

---

## 7. Lancer en local

### Prérequis

- Node.js 20+
- Docker Desktop (pour la base de données en dev)

### Installation

```bash
git clone <repo>
cd la-cabane-de-hjort-v2
npm install
cp .env.example .env
# Remplir .env (voir section suivante)
```

### Démarrer la base de données de développement

```bash
docker compose -f docker-compose.dev.yml up -d
```

### Initialiser la base de données

```bash
npx prisma migrate dev
npx prisma db seed
```

### Lancer le serveur de développement

```bash
npm run dev
# Ouvrir http://localhost:3000
```

---

## 8. Déploiement Docker

### Lancer automatiquement (script tout-en-un)

Le script `scripts/build-deploy.sh` fait tout : installe Docker si absent, build, lance les conteneurs, applique les migrations et seed.

```bash
# Premier lancement
bash scripts/build-deploy.sh

# Repartir de zéro (efface la base de données)
bash scripts/build-deploy.sh --reset
```

**Ce que fait le script, étape par étape :**

1. Détecte l'OS (Windows / Mac / Linux)
2. Vérifie si Docker est installé — sinon donne les instructions d'installation
3. Vérifie que `.env` existe — sinon le crée depuis `.env.example` et attend que tu le remplisses
4. Build l'image Next.js
5. Lance les conteneurs (`app` + `db` PostgreSQL)
6. Applique les migrations Prisma
7. Charge les produits en base de données (seed)
8. Affiche l'URL d'accès

**Commandes utiles après le lancement :**

```bash
docker compose logs -f app                       # Logs en direct
docker compose down                              # Arrêter
docker compose exec app npx prisma studio        # Interface graphique base de données
docker compose exec app npx prisma migrate dev   # Après modification du schéma
```

---

## 9. Exposer le site sur Internet avec Pangolin

> **Pangolin** est un reverse proxy qui permet d'exposer une application qui tourne sur ton PC ou un VPS derrière un nom de domaine HTTPS, sans ouvrir de port sur ta box Internet.

### Schéma

```text
Visiteur → https://lacabanedehjort.fr
              ↓
         Cloudflare (DNS)
              ↓
         VPS (Pangolin + Traefik)
              ↓  tunnel sécurisé
         Ton PC / serveur → localhost:3000 (Next.js)
```

### Option A — Déploiement direct sur un VPS (recommandé pour la production)

Le site tourne directement sur le VPS, pas sur ton PC.

**Prérequis :** un VPS Ubuntu 22.04+ (OVH, Hostinger, Hetzner — ~5€/mois) et un domaine (ex: `lacabanedehjort.fr`).

```bash
# 1. Connecte-toi au VPS
ssh root@<IP_DU_VPS>

# 2. Clone le projet
git clone https://github.com/<ton-compte>/la-cabane-de-hjort.git
cd la-cabane-de-hjort

# 3. Lance le script (installe Docker automatiquement sur Linux)
bash scripts/build-deploy.sh

# 4. Installe Traefik comme reverse proxy HTTPS
# (voir section Traefik ci-dessous)
```

**Configurer Traefik pour HTTPS automatique :**

Ajoute dans `docker-compose.yml` :

```yaml
services:
  traefik:
    image: traefik:v3
    command:
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencrypt.acme.email=lacabanedehjort@gmail.com"
      - "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
      - "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "letsencrypt:/letsencrypt"

  app:
    # ... (config existante)
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.app.rule=Host(`lacabanedehjort.fr`)"
      - "traefik.http.routers.app.entrypoints=websecure"
      - "traefik.http.routers.app.tls.certresolver=letsencrypt"

volumes:
  letsencrypt:
```

**Pointer le domaine vers le VPS (Cloudflare) :**

Dans le dashboard Cloudflare :

- Type : `A`
- Nom : `@` (et `www`)
- Valeur : `<IP_DU_VPS>`
- Proxy : ✅ Activé (nuage orange)

### Option B — Tunnel Pangolin depuis ton PC (sans VPS)

Si tu veux exposer le site depuis ton PC sans VPS, utilise **Cloudflare Tunnel** (gratuit) :

```bash
# 1. Installe cloudflared
# Windows : https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/
# Mac :
brew install cloudflare/cloudflare/cloudflared
# Linux :
curl -L https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg > /dev/null

# 2. Connecte ton compte Cloudflare
cloudflared tunnel login

# 3. Crée un tunnel
cloudflared tunnel create cabane-hjort

# 4. Configure le tunnel (crée config.yml)
# ~/.cloudflared/config.yml
tunnel: <ID_DU_TUNNEL>
credentials-file: ~/.cloudflared/<ID_DU_TUNNEL>.json
ingress:
  - hostname: lacabanedehjort.fr
    service: http://localhost:3000
  - service: http_status:404

# 5. Lance le tunnel
cloudflared tunnel run cabane-hjort
```

Le site est alors accessible sur `https://lacabanedehjort.fr` depuis n'importe où, tant que ton PC est allumé et que Docker tourne.

---

## 9. Variables d'environnement

Créer un fichier `.env` à la racine (ne jamais le committer) :

```env
# Base de données
DATABASE_URL="postgresql://user:password@localhost:5432/cabane_hjort"

# NextAuth — générer avec : openssl rand -base64 32
NEXTAUTH_SECRET="..."
NEXTAUTH_URL="https://lacabanedehjort.fr"

# Stripe
STRIPE_SECRET_KEY="sk_live_..."
STRIPE_WEBHOOK_SECRET="whsec_..."
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY="pk_live_..."

# Emails (Resend)
RESEND_API_KEY="re_..."
EMAIL_FROM="commandes@lacabanedehjort.fr"

# EmailJS (garde pendant la transition, supprime après)
NEXT_PUBLIC_EMAILJS_SERVICE_ID="service_wsueymf"
NEXT_PUBLIC_EMAILJS_TEMPLATE_ID="template_lgkejta"
NEXT_PUBLIC_EMAILJS_PUBLIC_KEY="FHFf7MN9Fhd6TisH_"
```

Créer un fichier `.env.example` (commité, sans valeurs sensibles) :

```env
DATABASE_URL="postgresql://user:password@localhost:5432/cabane_hjort"
NEXTAUTH_SECRET=""
NEXTAUTH_URL="http://localhost:3000"
STRIPE_SECRET_KEY=""
STRIPE_WEBHOOK_SECRET=""
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=""
RESEND_API_KEY=""
EMAIL_FROM=""
```

---

## À propos

La Cabane de Hjort — créations artisanales gravées à thème viking et médiéval.
Contact : <lacabanedehjort@gmail.com>

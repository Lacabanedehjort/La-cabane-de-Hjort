# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

**La Cabane de Hjort** — site e-commerce statique en HTML/CSS/JS pur, sans framework, sans bundler. Vente de créations artisanales à thème viking/médiéval (porte-clefs, plateaux, dessous de verre, marque-pages).

Il n'y a pas de build, pas de dépendances npm, pas de serveur. Le site s'ouvre directement dans un navigateur.

## Développement

Ouvrir `index.html` dans le navigateur (double-clic ou Live Server VSCode). Aucune commande à lancer.

## Architecture

Tout est dans la racine du repo : un fichier HTML par page, un seul `style.css` global, un seul `script.js` global.

**Pages principales :**
- `index.html` — accueil (hero, services, à propos, avis, contact)
- `produit.html` — catalogue produits
- `panier.html` — panier d'achat
- `commande.html` — formulaire de finalisation de commande
- `paiement.html` — page de paiement
- `login.html` / `inscription.html` — authentification

**Pages produit individuelles :** une par article (`porte-clefs_mjolnir_corbeau.html`, `plateau_runique.html`, etc.) — chacune décrit le produit et contient un bouton "Ajouter au panier".

**Pages légales/info :** `cgv.html`, `mentions_légales.html`, `avis.html`, `contact.html`

## Persistence des données

Tout est dans `localStorage` — aucun backend :
- `panier` — tableau JSON `[{nom, prix}]`
- `users` — tableau JSON `[{username, password}]` (mots de passe en clair)
- `currentUser` — string (username connecté)
- `reviews` — tableau JSON des avis

## Envoi d'emails (EmailJS)

Les pages `commande.html` et `contact.html` utilisent EmailJS (CDN) pour envoyer des emails sans backend.

- Service ID configuré : `service_wsueymf`
- Template commande : `template_lgkejta`
- Clé publique EmailJS : `FHFf7MN9Fhd6TisH_`

**Attention :** plusieurs pages (notamment `index.html`, `panier.html`) contiennent des placeholders non remplacés `"TON_SERVICE_ID"` / `"TON_TEMPLATE_ID"` — bug connu à corriger si les formulaires contact/avis de ces pages doivent fonctionner.

## Bugs structurels connus

- Les `<script>` sont souvent placés avant `<body>` (hors `<head>`) — certains scripts s'exécutent avant que le DOM soit prêt, d'où les `DOMContentLoaded` défensifs.
- EmailJS est importé en double sur certaines pages (`commande.html`, `panier.html`).
- L'authentification stocke les mots de passe en clair dans `localStorage`.
- `script.js` (stock/indisponible) est global mais ne s'applique qu'aux pages produit qui ont la classe `.produit` avec `.description` et `.btn-acheter`.

## Frais de port

Logique dans `commande.html` : gratuit si total ≥ 50 €, sinon 5 €.

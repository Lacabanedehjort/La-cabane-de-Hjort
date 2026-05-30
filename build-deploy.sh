#!/usr/bin/env bash
# =============================================================================
# build-deploy.sh — La Cabane de Hjort V2
# Lance le site Next.js en local avec Docker (1 commande)
# Usage : bash scripts/build-deploy.sh
# =============================================================================

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo -e "${BLUE}[DEPLOY]${NC} $1"; }
ok()   { echo -e "${GREEN}[OK]${NC}    $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
err()  { echo -e "${RED}[ERREUR]${NC} $1"; exit 1; }

# ─── Étape 1 : Docker ────────────────────────────────────────────────────────
echo -e "\n${BOLD}Étape 1 — Vérification Docker${NC}"

if ! command -v docker &>/dev/null; then
  warn "Docker non installé."

  if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo -e "\n  👉 Installe Docker Desktop pour Windows :"
    echo -e "  ${BOLD}https://www.docker.com/products/docker-desktop/${NC}"
    echo -e "\n  Après installation, redémarre ton PC puis relance ce script."
    exit 1
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v brew &>/dev/null; then
      log "Installation via Homebrew..."; brew install --cask docker
      open /Applications/Docker.app
      echo -e "\n  Attends que Docker Desktop soit prêt (icône baleine), puis relance le script."
      exit 0
    else
      echo -e "  👉 ${BOLD}https://www.docker.com/products/docker-desktop/${NC}"; exit 1
    fi
  else
    log "Installation Docker Engine (Linux)..."
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker "$USER"
    ok "Docker installé. Déconnecte/reconnecte-toi puis relance ce script."; exit 0
  fi
fi

if ! docker info &>/dev/null; then
  err "Docker est installé mais pas démarré. Lance Docker Desktop et réessaie."
fi

ok "Docker $(docker --version | grep -oP '\d+\.\d+\.\d+' | head -1) ✓"

# ─── Étape 2 : .env ──────────────────────────────────────────────────────────
echo -e "\n${BOLD}Étape 2 — Configuration${NC}"

if [[ ! -f ".env" ]]; then
  cp .env.example .env
  warn ".env créé. Remplis les clés EmailJS dans .env avant de continuer :"
  echo ""
  echo "  NEXT_PUBLIC_EMAILJS_PUBLIC_KEY=ta_clé_ici"
  echo ""
  read -rp "  Appuie sur Entrée une fois que c'est fait..." _
fi
ok ".env présent ✓"

# ─── Étape 3 : Build + lancement ─────────────────────────────────────────────
echo -e "\n${BOLD}Étape 3 — Build${NC}"
log "Construction de l'image..."
docker compose build --no-cache
ok "Image construite ✓"

echo -e "\n${BOLD}Étape 4 — Démarrage${NC}"
docker compose up -d
ok "Site démarré ✓"

# ─── Résultat ────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}  ✅  La Cabane de Hjort V2 est en ligne !${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════${NC}"
echo ""
echo -e "  🌐 Site : ${BOLD}http://localhost:3000${NC}"
echo ""
echo -e "  Commandes utiles :"
echo -e "  ${BOLD}docker compose logs -f${NC}   → voir les logs"
echo -e "  ${BOLD}docker compose down${NC}      → arrêter le site"
echo ""

#!/usr/bin/env bash
# ============================================================
#  deploy.sh — sube Eco Celestial a GitHub y publica el sitio
# ============================================================
# Corré este script DESDE ADENTRO de la carpeta "eco-celestial"
# (la que descomprimiste del zip), en tu propia PC:
#
#     bash deploy.sh
#
# Requiere tener "git" instalado. Si además tenés "gh" (GitHub
# CLI) instalado y logueado, el script hace TODO solo: crea el
# repo, sube el código y activa GitHub Pages.
#
# Si no tenés "gh", el script te va a pedir que crees el
# repositorio vacío en github.com (un paso de 30 segundos) y
# después hace el resto (init, commit, push) solo.
# ============================================================

set -e

echo "== Eco Celestial — despliegue =="
echo

# --- 1. Verificar que estamos en la carpeta correcta ---
if [ ! -f "index.html" ] || [ ! -d "scripts" ]; then
  echo "⚠️  No encuentro index.html/scripts acá."
  echo "   Corré este script DESDE ADENTRO de la carpeta eco-celestial."
  exit 1
fi

# --- 2. Verificar git ---
if ! command -v git >/dev/null 2>&1; then
  echo "⚠️  No tenés git instalado."
  echo "   Instalalo desde https://git-scm.com/downloads y volvé a correr este script."
  exit 1
fi

# --- 3. Pedir nombre de usuario y repo ---
read -rp "Tu nombre de usuario de GitHub: " GH_USER
read -rp "Nombre del repositorio (ej: eco-celestial): " REPO_NAME
REPO_NAME=${REPO_NAME:-eco-celestial}

# --- 4. Inicializar git si hace falta ---
if [ ! -d ".git" ]; then
  git init
  git branch -M main
fi
git add .
git commit -m "Sitio Eco Celestial" --allow-empty -q

HAS_GH=false
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    HAS_GH=true
  else
    echo "ℹ️  Tenés 'gh' instalado pero no logueado. Corré 'gh auth login' y volvé a ejecutar este script para el modo automático completo."
  fi
fi

if [ "$HAS_GH" = true ]; then
  # ---------- MODO AUTOMÁTICO COMPLETO (con gh) ----------
  echo
  echo "→ Creando repositorio y subiendo el código con GitHub CLI..."
  if gh repo view "$GH_USER/$REPO_NAME" >/dev/null 2>&1; then
    git remote remove origin 2>/dev/null || true
    git remote add origin "https://github.com/$GH_USER/$REPO_NAME.git"
    git push -u origin main
  else
    gh repo create "$REPO_NAME" --public --source=. --remote=origin --push
  fi

  echo "→ Activando GitHub Pages (publicación vía GitHub Actions)..."
  gh api -X PUT "repos/$GH_USER/$REPO_NAME/pages" -f build_type=workflow >/dev/null 2>&1 || \
  gh api -X POST "repos/$GH_USER/$REPO_NAME/pages" -f "build_type=workflow" >/dev/null 2>&1 || true

  echo "→ Disparando la primera actualización de noticias..."
  gh workflow run "Actualizar noticias y publicar sitio" -R "$GH_USER/$REPO_NAME" 2>/dev/null || \
    echo "   (no se pudo disparar automáticamente — andá a la pestaña Actions y corré el workflow a mano una vez)"

  echo
  echo "✅ Listo. En unos minutos el sitio va a estar en:"
  echo "   https://$GH_USER.github.io/$REPO_NAME/"

else
  # ---------- MODO MANUAL (sin gh) ----------
  echo
  echo "== Paso manual único =="
  echo "1. Andá a https://github.com/new"
  echo "2. Nombre del repositorio: $REPO_NAME"
  echo "3. Dejalo público, NO tildes 'Add a README' (ya tenemos uno)"
  echo "4. Hacé clic en 'Create repository'"
  echo
  read -rp "Cuando lo hayas creado, presioná ENTER para continuar... " _

  git remote remove origin 2>/dev/null || true
  git remote add origin "https://github.com/$GH_USER/$REPO_NAME.git"
  git push -u origin main

  echo
  echo "== Un paso más (30 segundos) =="
  echo "1. Andá a https://github.com/$GH_USER/$REPO_NAME/settings/pages"
  echo "2. En 'Build and deployment' → Source, elegí: GitHub Actions"
  echo "3. Andá a la pestaña 'Actions' del repo y ejecutá el workflow"
  echo "   'Actualizar noticias y publicar sitio' una vez (botón 'Run workflow')"
  echo
  echo "✅ Después de eso, el sitio va a estar en:"
  echo "   https://$GH_USER.github.io/$REPO_NAME/"
fi

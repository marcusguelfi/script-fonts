#!/bin/bash

# ============================================================
# Google Fonts Downloader
# Script para baixar fontes do Google Fonts
# Autor: Marcus Guelfi
# Repositório: https://github.com/marcusguelfi/script-fonts
# ============================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir com cor
print_color() {
    color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Banner
echo ""
print_color "$BLUE" "======================================================"
print_color "$BLUE" "         Google Fonts Downloader v1.0"
print_color "$BLUE" "======================================================"
echo ""

# Configurações
API_KEY="AIzaSyDilHfKDiN9uD4sbCJm8fQ2B_N2C6XNQEE"
FONTS_DIR="${FONTS_DIR:-/opt/photopea-fonts}"

# Criar diretório se não existir
if [ ! -d "$FONTS_DIR" ]; then
    if [ -w "$(dirname "$FONTS_DIR")" ]; then
        mkdir -p "$FONTS_DIR"
    else
        print_color "$YELLOW" "⚠️  Diretório requer permissões elevadas"
        sudo mkdir -p "$FONTS_DIR"
        sudo chown $USER:$USER "$FONTS_DIR"
        print_color "$GREEN" "✓ Diretório criado com sucesso!"
    fi
fi

print_color "$GREEN" "📁 Diretório de destino: $FONTS_DIR"
echo ""

# Verificar dependências
print_color "$YELLOW" "🔍 Verificando dependências..."
DEPS_MISSING=()

command -v jq >/dev/null 2>&1 || DEPS_MISSING+=("jq")
command -v wget >/dev/null 2>&1 || DEPS_MISSING+=("wget")
command -v unzip >/dev/null 2>&1 || DEPS_MISSING+=("unzip")
command -v curl >/dev/null 2>&1 || DEPS_MISSING+=("curl")

if [ ${#DEPS_MISSING[@]} -gt 0 ]; then
    print_color "$RED" "❌ Dependências faltando: ${DEPS_MISSING[*]}"
    echo ""
    read -p "Deseja instalar as dependências? (s/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[SsYy]$ ]]; then
        print_color "$YELLOW" "📦 Instalando dependências..."
        sudo apt-get update -qq
        sudo apt-get install -y "${DEPS_MISSING[@]}"
        print_color "$GREEN" "✓ Dependências instaladas com sucesso!"
    else
        print_color "$RED" "❌ Não é possível continuar sem as dependências."
        exit 1
    fi
else
    print_color "$GREEN" "✓ Todas as dependências instaladas!"
fi

echo ""

# Lista completa de fontes populares (fallback)
POPULAR_FONTS=(
    "Roboto" "Open Sans" "Lato" "Montserrat" "Oswald" "Raleway" "Poppins"
    "Ubuntu" "Nunito" "Playfair Display" "Inter" "Bebas Neue" "Merriweather"
    "PT Sans" "Noto Sans" "Rubik" "Mukta" "Source Sans Pro" "Work Sans"
    "Quicksand" "Fira Sans" "Karla" "Libre Franklin" "Libre Baskerville"
    "Manrope" "DM Sans" "Space Grotesk" "Plus Jakarta Sans" "Outfit"
    "Noto Serif" "Crimson Text" "Bitter" "Archivo" "Barlow" "Josefin Sans"
    "Inconsolata" "Fira Code" "JetBrains Mono" "Source Code Pro" "IBM Plex Sans"
    "IBM Plex Mono" "Lexend" "Figtree" "Sora" "Epilogue" "Albert Sans"
    "Red Hat Display" "Red Hat Text" "Space Mono" "Commissioner" "Urbanist"
    "Heebo" "Mulish" "Exo 2" "Cabin" "Titillium Web" "Anton" "Dancing Script"
    "Pacifico" "Satisfy" "Righteous" "Bebas" "Permanent Marker" "Lobster"
    "Comfortaa" "Abel" "Zilla Slab" "Hind" "Overpass" "Arimo" "Varela Round"
    "Dosis" "Passion One" "Architects Daughter" "Alfa Slab One" "Francois One"
    "Abril Fatface" "Yellowtail" "Courgette" "Great Vibes" "Tangerine"
    "Shadows Into Light" "Amatic SC" "Indie Flower" "Caveat" "Kalam"
    "Patrick Hand" "Handlee" "Just Another Hand" "Covered By Your Grace"
    "Rock Salt" "Sue Ellen Francisco" "Reenie Beanie" "Walter Turncoat"
    "Neucha" "Bad Script" "Marck Script" "Annie Use Your Telescope"
    "Rajdhani" "Orbitron" "Bungee" "Press Start 2P" "VT323" "Audiowide"
    "Syncopate" "Monoton" "Poiret One" "Gruppo" "Michroma" "Electrolize"
    "Teko" "Yantramanav" "Hind Madurai" "Barlow Condensed" "Fjalla One"
    "Saira Condensed" "Yanone Kaffeesatz" "Asap Condensed" "PT Sans Narrow"
    "Nanum Gothic" "Noto Sans JP" "Noto Sans KR" "Noto Sans TC" "Noto Sans SC"
    "M PLUS Rounded 1c" "Sawarabi Gothic" "Kosugi Maru" "Sawarabi Mincho"
    "Philosopher" "Cormorant" "Cardo" "Spectral" "Alegreya" "Lora"
    "Old Standard TT" "EB Garamond" "Vollkorn" "Gentium Book Basic"
    "Cinzel" "Sorts Mill Goudy" "Neuton" "Adamina" "Judson" "Fanwood Text"
    "Cantata One" "Bentham" "Podkova" "Proza Libre" "Copse" "Poly"
    "Amiri" "Amethysta" "Goudy Bookletter 1911" "Unna" "Cambo"
)

# Buscar lista de fontes da API
print_color "$YELLOW" "🔎 Buscando lista de fontes do Google Fonts..."
FONTS_JSON=$(curl -s "https://www.googleapis.com/webfonts/v1/webfonts?key=$API_KEY" 2>/dev/null)

if [ -n "$FONTS_JSON" ] && echo "$FONTS_JSON" | jq -e '.items' >/dev/null 2>&1; then
    mapfile -t FONT_FAMILIES < <(echo "$FONTS_JSON" | jq -r '.items[].family' 2>/dev/null)
    if [ ${#FONT_FAMILIES[@]} -gt 0 ]; then
        TOTAL_FONTS=${#FONT_FAMILIES[@]}
        print_color "$GREEN" "✓ Encontradas $TOTAL_FONTS fontes da API!"
    else
        FONT_FAMILIES=("${POPULAR_FONTS[@]}")
        TOTAL_FONTS=${#FONT_FAMILIES[@]}
        print_color "$YELLOW" "⚠️  API não retornou dados. Usando lista de ${TOTAL_FONTS} fontes populares."
    fi
else
    FONT_FAMILIES=("${POPULAR_FONTS[@]}")
    TOTAL_FONTS=${#FONT_FAMILIES[@]}
    print_color "$YELLOW" "⚠️  API indisponível. Usando lista de ${TOTAL_FONTS} fontes populares."
fi

echo ""
print_color "$YELLOW" "⚠️  Serão baixadas até $TOTAL_FONTS fontes"
print_color "$YELLOW" "   Espaço estimado: 2-5 GB | Tempo: 30-60 min"
echo ""

read -p "Continuar com o download? (s/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
    print_color "$RED" "❌ Download cancelado."
    exit 0
fi

# Perguntar limite
echo ""
read -p "Quantas fontes baixar? (0 = todas, ou número específico): " LIMIT

if [ "$LIMIT" -eq 0 ] 2>/dev/null || [ -z "$LIMIT" ]; then
    LIMIT=$TOTAL_FONTS
elif ! [[ "$LIMIT" =~ ^[0-9]+$ ]] || [ "$LIMIT" -gt "$TOTAL_FONTS" ]; then
    LIMIT=$TOTAL_FONTS
fi

echo ""
print_color "$BLUE" "📥 Iniciando download de $LIMIT fontes..."
echo ""

# Contadores
SUCCESS_COUNT=0
FAIL_COUNT=0
CURRENT=0

# Log
LOG_FILE="/tmp/google-fonts-download-$(date +%Y%m%d_%H%M%S).log"
echo "Google Fonts Download Log - $(date)" > "$LOG_FILE"
echo "======================================" >> "$LOG_FILE"

# Função para baixar fonte
download_font() {
    local font="$1"
    local current="$2"
    local total="$3"
    
    local font_url="${font// /+}"
    local font_dir="$FONTS_DIR/$font"
    local temp_zip="/tmp/font_${current}_$$.zip"
    
    printf "[%d/%d] 📥 %-40s" "$current" "$total" "$font"
    
    mkdir -p "$font_dir"
    
    if wget -q -T 30 --tries=2 -O "$temp_zip" "https://fonts.google.com/download?family=$font_url" 2>/dev/null; then
        if unzip -q -o "$temp_zip" "*.ttf" "*.otf" -d "$font_dir" 2>/dev/null; then
            local file_count=$(find "$font_dir" -type f \( -name "*.ttf" -o -name "*.otf" \) 2>/dev/null | wc -l)
            if [ "$file_count" -gt 0 ]; then
                print_color "$GREEN" " ✓"
                echo "SUCCESS: $font ($file_count arquivos)" >> "$LOG_FILE"
                rm -f "$temp_zip"
                return 0
            fi
        fi
    fi
    
    print_color "$RED" " ✗"
    echo "FAIL: $font" >> "$LOG_FILE"
    rm -rf "$font_dir" "$temp_zip" 2>/dev/null
    return 1
}

# Download de fontes
for font in "${FONT_FAMILIES[@]}"; do
    CURRENT=$((CURRENT + 1))
    
    [ $CURRENT -gt $LIMIT ] && break
    
    if download_font "$font" "$CURRENT" "$LIMIT"; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
    
    sleep 0.3
done

# Resumo
TOTAL_FILES=$(find "$FONTS_DIR" -type f \( -name "*.ttf" -o -name "*.otf" \) 2>/dev/null | wc -l)
DISK_USAGE=$(du -sh "$FONTS_DIR" 2>/dev/null | cut -f1)

echo ""
print_color "$BLUE" "======================================================"
print_color "$BLUE" "                 📊 RESUMO"
print_color "$BLUE" "======================================================"
echo ""
print_color "$GREEN" "✅ Sucesso: $SUCCESS_COUNT"
print_color "$RED" "❌ Falhas: $FAIL_COUNT"
echo ""
print_color "$YELLOW" "📁 Total de arquivos: $TOTAL_FILES"
print_color "$YELLOW" "💾 Espaço usado: $DISK_USAGE"
print_color "$YELLOW" "📝 Log: $LOG_FILE"
echo ""
print_color "$BLUE" "======================================================"
print_color "$BLUE" "              🎯 PRÓXIMOS PASSOS"
print_color "$BLUE" "======================================================"
echo ""
echo "1️⃣  Copiar para container:"
print_color "$YELLOW" "   docker cp $FONTS_DIR/. <CONTAINER_ID>:/usr/share/fonts/custom/"
echo ""
echo "2️⃣  Reiniciar container:"
print_color "$YELLOW" "   docker restart <CONTAINER_ID>"
echo ""
echo "3️⃣  Tornar permanente (Portainer):"
print_color "$YELLOW" "   Container: /usr/share/fonts/custom → Host: $FONTS_DIR"
echo ""
print_color "$BLUE" "======================================================"
echo ""
#!/bin/bash

# Script para baixar TODAS as fontes do Google Fonts
# Uso: ./download-all-google-fonts.sh

echo "======================================================"
echo "   Download de TODAS as fontes do Google Fonts"
echo "======================================================"
echo ""

# API Key do Google Fonts (pública, sem restrições)
API_KEY="AIzaSyDilHfKDiN9uD4sbCJm8fQ2B_N2C6XNQEE"

# Diretório onde as fontes serão salvas
FONTS_DIR="/opt/photopea-fonts"

# Criar diretório se não existir
mkdir -p "$FONTS_DIR"

echo "📁 Fontes serão salvas em: $FONTS_DIR"
echo ""

# Verificar e instalar dependências
echo "🔍 Verificando dependências..."
DEPS_NEEDED=false

if ! command -v jq &> /dev/null; then
    echo "  ⚠️  jq não encontrado (necessário para processar JSON)"
    DEPS_NEEDED=true
fi

if ! command -v wget &> /dev/null; then
    echo "  ⚠️  wget não encontrado"
    DEPS_NEEDED=true
fi

if ! command -v unzip &> /dev/null; then
    echo "  ⚠️  unzip não encontrado"
    DEPS_NEEDED=true
fi

if [ "$DEPS_NEEDED" = true ]; then
    echo ""
    read -p "Instalar dependências necessárias? (s/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[SsYy]$ ]]; then
        echo "📦 Instalando dependências..."
        sudo apt-get update
        sudo apt-get install -y jq wget unzip curl
    else
        echo "❌ Dependências necessárias não instaladas. Abortando."
        exit 1
    fi
fi

echo "✓ Todas as dependências instaladas!"
echo ""

# Buscar lista de todas as fontes da API do Google Fonts
echo "🔎 Buscando lista de fontes da API do Google Fonts..."
FONTS_JSON=$(curl -s "https://www.googleapis.com/webfonts/v1/webfonts?key=$API_KEY")

# Verificar se a API respondeu corretamente
if [ -z "$FONTS_JSON" ] || [ "$FONTS_JSON" == "null" ]; then
    echo "❌ Erro ao buscar fontes da API. Tentando método alternativo..."
    
    # Método alternativo: lista pré-definida das fontes mais populares
    FONT_FAMILIES=(
        "Roboto" "Open Sans" "Lato" "Montserrat" "Oswald" "Raleway" "Poppins"
        "Ubuntu" "Nunito" "Playfair Display" "Inter" "Bebas Neue" "Merriweather"
        "PT Sans" "Noto Sans" "Rubik" "Mukta" "Source Sans Pro" "Work Sans"
        "Quicksand" "Fira Sans" "Karla" "Libre Franklin" "Libre Baskerville"
        "Manrope" "DM Sans" "Space Grotesk" "Plus Jakarta Sans" "Outfit"
        "Noto Serif" "Crimson Text" "Bitter" "Archivo" "Barlow" "Josefin Sans"
        "Inconsolata" "Fira Code" "JetBrains Mono" "Source Code Pro" "IBM Plex Sans"
        "IBM Plex Mono" "Lexend" "Figtree" "Sora" "Epilogue" "Albert Sans"
        "Red Hat Display" "Red Hat Text" "Space Mono" "Commissioner" "Urbanist"
    )
    
    TOTAL_FONTS=${#FONT_FAMILIES[@]}
else
    # Extrair nomes das fontes do JSON
    FONT_FAMILIES=($(echo "$FONTS_JSON" | jq -r '.items[].family'))
    TOTAL_FONTS=${#FONT_FAMILIES[@]}
    
    echo "✓ Encontradas $TOTAL_FONTS fontes disponíveis!"
fi

echo ""
echo "⚠️  ATENÇÃO: Serão baixadas $TOTAL_FONTS fontes!"
echo "   Isso pode levar MUITO tempo e ocupar bastante espaço em disco."
echo "   Espaço estimado: ~2-5 GB"
echo ""

read -p "Deseja continuar com o download? (s/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
    echo "❌ Download cancelado."
    exit 0
fi

# Perguntar se quer limitar o número de fontes
echo ""
read -p "Deseja baixar TODAS ($TOTAL_FONTS) ou limitar a quantidade? Digite o número ou 0 para todas: " LIMIT

if [ "$LIMIT" -eq 0 ] 2>/dev/null; then
    LIMIT=$TOTAL_FONTS
elif ! [[ "$LIMIT" =~ ^[0-9]+$ ]] || [ "$LIMIT" -gt "$TOTAL_FONTS" ]; then
    LIMIT=$TOTAL_FONTS
fi

echo ""
echo "📥 Iniciando download de $LIMIT fontes..."
echo ""

# Contadores
SUCCESS_COUNT=0
FAIL_COUNT=0
CURRENT=0

# Arquivo de log
LOG_FILE="/tmp/google-fonts-download.log"
echo "Log de download - $(date)" > "$LOG_FILE"

# Baixar cada fonte
for font in "${FONT_FAMILIES[@]}"; do
    CURRENT=$((CURRENT + 1))
    
    # Limitar se necessário
    if [ $CURRENT -gt $LIMIT ]; then
        break
    fi
    
    # Formatar nome da fonte para URL (substituir espaços por +)
    FONT_URL="${font// /+}"
    
    echo "[$CURRENT/$LIMIT] 📥 Baixando: $font..."
    
    # Criar diretório para a fonte
    FONT_DIR="$FONTS_DIR/$font"
    sudo mkdir -p "$FONT_DIR"
    
    # URL de download do Google Fonts
    URL="https://fonts.google.com/download?family=$FONT_URL"
    
    # Baixar o arquivo ZIP
    wget -q -T 30 --tries=2 -O "/tmp/font_$CURRENT.zip" "$URL" 2>&1
    
    if [ $? -eq 0 ] && [ -f "/tmp/font_$CURRENT.zip" ]; then
        # Extrair apenas arquivos .ttf e .otf
        sudo unzip -q -o "/tmp/font_$CURRENT.zip" "*.ttf" "*.otf" -d "$FONT_DIR" 2>/dev/null
        
        # Verificar se extraiu algum arquivo
        if [ "$(sudo find "$FONT_DIR" -type f \( -name "*.ttf" -o -name "*.otf" \) | wc -l)" -gt 0 ]; then
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            echo "  ✓ Sucesso!"
            echo "SUCCESS: $font" >> "$LOG_FILE"
        else
            FAIL_COUNT=$((FAIL_COUNT + 1))
            echo "  ✗ Nenhum arquivo de fonte encontrado"
            echo "FAIL: $font (no font files)" >> "$LOG_FILE"
            sudo rm -rf "$FONT_DIR"
        fi
        
        # Limpar arquivo temporário
        rm "/tmp/font_$CURRENT.zip"
    else
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo "  ✗ Erro no download"
        echo "FAIL: $font (download error)" >> "$LOG_FILE"
        sudo rm -rf "$FONT_DIR"
    fi
    
    # Pequena pausa para não sobrecarregar o servidor
    sleep 0.5
done

echo ""
echo "======================================================"
echo "              📊 RESUMO DO DOWNLOAD"
echo "======================================================"
echo ""
echo "✅ Fontes baixadas com sucesso: $SUCCESS_COUNT"
echo "❌ Fontes com erro: $FAIL_COUNT"
echo "📁 Total de arquivos de fonte: $(sudo find "$FONTS_DIR" -name "*.ttf" -o -name "*.otf" | wc -l)"
echo "💾 Espaço ocupado: $(du -sh "$FONTS_DIR" | cut -f1)"
echo ""
echo "📝 Log completo salvo em: $LOG_FILE"
echo ""
echo "======================================================"
echo "              🎯 PRÓXIMOS PASSOS"
echo "======================================================"
echo ""
echo "1️⃣  Copiar fontes para o container:"
echo "   docker cp $FONTS_DIR/. <CONTAINER_ID>:/usr/share/fonts/custom/"
echo ""
echo "2️⃣  Reiniciar o container:"
echo "   docker restart <CONTAINER_ID>"
echo ""
echo "3️⃣  Tornar permanente no Portainer:"
echo "   Containers → Edit → Volumes → Add volume"
echo "   Container: /usr/share/fonts/custom"
echo "   Host: $FONTS_DIR"
echo ""
echo "======================================================"
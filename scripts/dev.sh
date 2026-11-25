#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

show_usage() {
  cat <<'EOF'

Uso: ./scripts/dev.sh [accion] [-d <device_id>]

Acciones disponibles:
  menu     Muestra el menu interactivo (por defecto)
  android  Ejecuta la app en un dispositivo o emulador Android
  web      Ejecuta la app en Web (pregunta entre Chrome o Edge)
  apk      Ejecuta flutter clean, flutter pub get y flutter build apk --release
  help     Muestra esta ayuda

Ejemplos:
  ./scripts/dev.sh
  ./scripts/dev.sh android
  ./scripts/dev.sh android -d emulator-5554
  ./scripts/dev.sh web
  ./scripts/dev.sh web -d edge
  ./scripts/dev.sh apk

EOF
}

assert_flutter() {
  if ! command -v flutter >/dev/null 2>&1; then
    echo "[ERROR] No se encontro 'flutter' en el PATH." >&2
    exit 1
  fi
}

run_flutter_step() {
  local title="$1"
  shift
  echo ""
  echo "==> $title"
  echo "    flutter $*"
  flutter "$@"
}

# Devuelve lineas con formato: id|name|targetPlatform
list_devices_parsed() {
  local raw
  raw="$(flutter devices --machine 2>/dev/null || true)"
  if [[ -z "$raw" ]]; then
    return 0
  fi

  printf '%s\n' "$raw" | tr -d '\r' | awk '
    BEGIN { depth = 0; obj = "" }
    {
      n = length($0)
      for (i = 1; i <= n; i++) {
        c = substr($0, i, 1)
        if (c == "{") {
          if (depth == 1) { obj = "" }
          depth++
        }
        if (depth >= 2) {
          obj = obj c
        }
        if (c == "}") {
          depth--
          if (depth == 1 && obj != "") {
            id = ""; name = ""; plat = ""
            if (match(obj, /"id"[[:space:]]*:[[:space:]]*"[^"]*"/)) {
              s = substr(obj, RSTART, RLENGTH)
              sub(/^"id"[[:space:]]*:[[:space:]]*"/, "", s)
              sub(/"$/, "", s)
              id = s
            }
            if (match(obj, /"name"[[:space:]]*:[[:space:]]*"[^"]*"/)) {
              s = substr(obj, RSTART, RLENGTH)
              sub(/^"name"[[:space:]]*:[[:space:]]*"/, "", s)
              sub(/"$/, "", s)
              name = s
            }
            if (match(obj, /"targetPlatform"[[:space:]]*:[[:space:]]*"[^"]*"/)) {
              s = substr(obj, RSTART, RLENGTH)
              sub(/^"targetPlatform"[[:space:]]*:[[:space:]]*"/, "", s)
              sub(/"$/, "", s)
              plat = s
            }
            if (id != "") {
              print id "|" name "|" plat
            }
            obj = ""
          }
        }
      }
    }
  '
}

resolve_android_device() {
  local preferred="${1:-}"
  if [[ -n "$preferred" ]]; then
    printf '%s\n' "$preferred"
    return 0
  fi

  echo "" >&2
  echo "==> Buscando dispositivos Android..." >&2

  local -a ids=()
  local -a names=()
  local -a plats=()
  local id name plat

  while IFS='|' read -r id name plat; do
    if [[ "$plat" == android* ]]; then
      ids+=("$id")
      names+=("$name")
      plats+=("$plat")
    fi
  done < <(list_devices_parsed)

  local count="${#ids[@]}"
  if [[ "$count" -eq 0 ]]; then
    echo "[AVISO] No se detectaron dispositivos ni emuladores Android conectados." >&2
    echo "Emuladores disponibles:" >&2
    flutter emulators >&2 || true
    echo "" >&2
    echo "Conecta un dispositivo por USB (depuracion USB) o inicia un emulador y vuelve a intentar." >&2
    return 1
  fi

  if [[ "$count" -eq 1 ]]; then
    echo "    Dispositivo seleccionado: ${names[0]} (${ids[0]})" >&2
    printf '%s\n' "${ids[0]}"
    return 0
  fi

  echo "Se encontraron varios dispositivos Android:" >&2
  local i
  for ((i = 0; i < count; i++)); do
    echo "  [$((i + 1))] ${names[$i]} (${ids[$i]}) - ${plats[$i]}" >&2
  done

  local selection
  read -r -p "Elige un numero (Enter para 1): " selection
  if [[ -z "$selection" ]]; then
    printf '%s\n' "${ids[0]}"
    return 0
  fi
  if [[ "$selection" =~ ^[0-9]+$ ]] && ((selection >= 1 && selection <= count)); then
    printf '%s\n' "${ids[$((selection - 1))]}"
    return 0
  fi

  echo "[ERROR] Seleccion invalida." >&2
  return 1
}

resolve_web_device() {
  local preferred="${1:-}"
  if [[ -n "$preferred" ]]; then
    printf '%s\n' "$preferred"
    return 0
  fi

  local choice
  while true; do
    echo "" >&2
    echo "Selecciona el navegador Web:" >&2
    echo "  1. Chrome (por defecto)" >&2
    echo "  2. Edge" >&2
    read -r -p "Elige una opcion (Enter para Chrome): " choice
    choice="$(printf '%s' "$choice" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"

    case "$choice" in
      ""|1|chrome)
        printf '%s\n' "chrome"
        return 0
        ;;
      2|edge)
        printf '%s\n' "edge"
        return 0
        ;;
      *)
        echo "Opcion invalida. Elige 1 (Chrome) o 2 (Edge)." >&2
        ;;
    esac
  done
}

start_android() {
  local target
  target="$(resolve_android_device "${1:-}")"
  run_flutter_step "Ejecutando RepartoJusto en Android ($target)" run -d "$target"
}

start_web() {
  local target
  target="$(resolve_web_device "${1:-}")"
  run_flutter_step "Ejecutando RepartoJusto en Web ($target)" run -d "$target"
}

build_release_apk() {
  run_flutter_step "Limpiando proyecto (flutter clean)" clean
  run_flutter_step "Obteniendo dependencias (flutter pub get)" pub get
  run_flutter_step "Compilando APK Release (flutter build apk --release)" build apk --release

  local apk_path="$PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk"
  echo ""
  if [[ -f "$apk_path" ]]; then
    local size_bytes size_mb
    size_bytes="$(wc -c < "$apk_path" | tr -d '[:space:]')"
    size_mb="$(awk -v b="$size_bytes" 'BEGIN { printf "%.2f", b / 1048576 }')"
    echo "[OK] APK generado correctamente:"
    echo "     Ruta:   $apk_path"
    echo "     Tamano: ${size_mb} MB"
  else
    echo "[OK] Build completado."
  fi
}

show_menu() {
  local device="${1:-}"
  local option
  while true; do
    echo ""
    echo "========================================"
    echo "  RepartoJusto - Utilidades Flutter"
    echo "========================================"
    echo "  1. Correr en Android"
    echo "  2. Correr en Web (Chrome / Edge)"
    echo "  3. Crear APK Release (clean + pub get + build apk --release)"
    echo "  0. Salir"
    echo ""
    read -r -p "Selecciona una opcion: " option
    option="$(printf '%s' "$option" | tr -d '[:space:]')"

    case "$option" in
      1) start_android "$device" ;;
      2) start_web "$device" ;;
      3) build_release_apk ;;
      0) return 0 ;;
      *) echo "Opcion invalida. Elige 1, 2, 3 o 0." ;;
    esac
  done
}

ACTION="menu"
DEVICE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    menu|android|web|apk)
      ACTION="$1"
      shift
      ;;
    help|-h|--help)
      ACTION="help"
      shift
      ;;
    -d|--device)
      if [[ $# -lt 2 ]]; then
        echo "[ERROR] Falta el valor para $1." >&2
        exit 1
      fi
      DEVICE="$2"
      shift 2
      ;;
    *)
      if [[ -z "$DEVICE" && "$ACTION" != "menu" ]]; then
        DEVICE="$1"
        shift
      else
        echo "[ERROR] Argumento no reconocido: $1" >&2
        show_usage
        exit 1
      fi
      ;;
  esac
done

if [[ "$ACTION" == "help" ]]; then
  show_usage
  exit 0
fi

assert_flutter

case "$ACTION" in
  android) start_android "$DEVICE" ;;
  web)     start_web "$DEVICE" ;;
  apk)     build_release_apk ;;
  menu)    show_menu "$DEVICE" ;;
esac

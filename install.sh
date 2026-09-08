#!/usr/bin/env bash
#
# Compila el widget en Release y lo instala en /Applications.
# Uso: ./install.sh [--uninstall]
#

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="rotatingquotes.xcodeproj"
SCHEME="rotatingquotes"
APP_NAME="rotatingquotes.app"
INSTALL_DIR="/Applications"
INSTALLED_APP="$INSTALL_DIR/$APP_NAME"
BUILD_DIR="$PROJECT_DIR/build"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"

info()  { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
warn()  { printf '\033[1;33m==>\033[0m %s\n' "$1"; }
fail()  { printf '\033[1;31m==>\033[0m %s\n' "$1" >&2; exit 1; }

refresh_widget_daemons() {
    [[ -x "$LSREGISTER" ]] && "$LSREGISTER" -f "$INSTALLED_APP" >/dev/null 2>&1 || true
    killall chronod NotificationCenter >/dev/null 2>&1 || true
}

uninstall() {
    if [[ ! -d "$INSTALLED_APP" ]]; then
        info "No hay nada que desinstalar en $INSTALLED_APP"
        exit 0
    fi

    read -r -p "¿Eliminar $INSTALLED_APP? [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]] || fail "Cancelado."

    [[ -x "$LSREGISTER" ]] && "$LSREGISTER" -u "$INSTALLED_APP" >/dev/null 2>&1 || true
    rm -rf "$INSTALLED_APP"
    killall chronod NotificationCenter >/dev/null 2>&1 || true

    info "Desinstalado. Quita el widget manualmente si sigue en el escritorio."
    exit 0
}

if [[ "${1:-}" == "--uninstall" ]]; then
    uninstall
elif [[ -n "${1:-}" ]]; then
    fail "Opción desconocida: $1 (usa --uninstall o sin argumentos)"
fi

# xcode-select suele apuntar a CommandLineTools, que no incluye xcodebuild.
if ! DEVELOPER_DIR="$(xcode-select -p 2>/dev/null)" || [[ "$DEVELOPER_DIR" != *"Xcode.app"* ]]; then
    DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi
[[ -x "$DEVELOPER_DIR/usr/bin/xcodebuild" ]] || fail "No encontré xcodebuild. ¿Está Xcode instalado en /Applications?"
export DEVELOPER_DIR

cd "$PROJECT_DIR"
[[ -d "$PROJECT_NAME" ]] || fail "No encontré $PROJECT_NAME en $PROJECT_DIR"

info "Compilando $SCHEME en Release..."
if ! xcodebuild -project "$PROJECT_NAME" \
                -scheme "$SCHEME" \
                -configuration Release \
                -derivedDataPath "$BUILD_DIR" \
                -destination 'platform=macOS' \
                build > "$BUILD_DIR.log" 2>&1; then
    grep -E "error:" "$BUILD_DIR.log" | head -20 || true
    fail "La compilación falló. Log completo: $BUILD_DIR.log"
fi

BUILT_APP="$BUILD_DIR/Build/Products/Release/$APP_NAME"
[[ -d "$BUILT_APP" ]] || fail "No encontré la app compilada en $BUILT_APP"

info "Instalando en $INSTALLED_APP..."
if [[ -d "$INSTALLED_APP" ]]; then
    osascript -e "quit app \"$SCHEME\"" >/dev/null 2>&1 || true
    rm -rf "$INSTALLED_APP"
fi

if ! cp -R "$BUILT_APP" "$INSTALL_DIR/" 2>/dev/null; then
    fail "Sin permisos de escritura en $INSTALL_DIR. Copia manualmente: cp -R \"$BUILT_APP\" $INSTALL_DIR/"
fi

# La app debe ejecutarse al menos una vez para que el widget aparezca en la galería.
info "Registrando el widget..."
open "$INSTALLED_APP"
sleep 3
refresh_widget_daemons

rm -f "$BUILD_DIR.log"

info "Listo."
cat <<EOF

Para añadir el widget:
  Clic derecho en el escritorio -> "Editar widgets"
  (o clic en la fecha/hora de la barra de menús -> "Editar widgets")
  Busca "Quotes" y arrástralo donde quieras.

Notas:
  - No muevas ni borres $INSTALLED_APP: el widget vive dentro de ese bundle.
  - Las citas cambian en cada frontera de 5 minutos del reloj (:00, :05, :10...).
  - Para desinstalar: $0 --uninstall
EOF

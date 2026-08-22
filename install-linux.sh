#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly MSI="$SCRIPT_DIR/SetupFull.msi"
readonly REGISTRY_FILE="$SCRIPT_DIR/KeyStore.reg"
readonly DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
readonly APP_HOME="$DATA_HOME/enterprise-architect-14"
readonly WINE_PREFIX="$APP_HOME/prefix"
readonly USER_BIN="$HOME/.local/bin"
readonly LAUNCHER="$USER_BIN/enterprise-architect"
readonly APPLICATIONS_DIR="$DATA_HOME/applications"
readonly DESKTOP_FILE="$APPLICATIONS_DIR/enterprise-architect.desktop"
readonly MIME_PACKAGES_DIR="$DATA_HOME/mime/packages"
readonly MIME_FILE="$MIME_PACKAGES_DIR/enterprise-architect.xml"
readonly EA_EXE='C:\Program Files (x86)\Sparx Systems\EA\EA.exe'
readonly MSI_SHA256='e11aef1c7239133401cf426804c6bc51caed786c1121318f0cca9842491b9e0b'
readonly REGISTRY_SHA256='20484a8b888892b96629697c566f211c2d8fc56312f6e5e012253d53ae63c817'

die() {
  printf 'Erro: %s\n' "$*" >&2
  exit 1
}

verify_sha256() {
  local file="$1"
  local expected="$2"
  local actual

  actual="$(sha256sum "$file" | awk '{print $1}')"
  [[ "$actual" == "$expected" ]] || \
    die "$(basename "$file") está incompleto ou é diferente do arquivo testado (SHA-256: $actual)"
}

install_dependencies() {
  local distro_id='unknown'
  local distro_like=''
  local seven_zip_package=''

  if [[ -r /etc/os-release ]]; then
    # ID e ID_LIKE contêm identificadores da distribuição, não código shell.
    # shellcheck disable=SC1091
    source /etc/os-release
    distro_id="${ID:-unknown}"
    distro_like="${ID_LIKE:-}"
  fi

  if command -v omarchy >/dev/null 2>&1; then
    printf 'Instalando dependências com o Omarchy...\n'
    omarchy pkg add wine wine-gecko wine-mono unixodbc winetricks 7zip
  elif command -v pacman >/dev/null 2>&1; then
    printf 'Instalando dependências com o pacman...\n'
    sudo pacman -S --needed wine wine-gecko wine-mono unixodbc winetricks 7zip
  elif command -v apt-get >/dev/null 2>&1; then
    printf 'Instalando dependências com o APT...\n'
    if command -v dpkg >/dev/null 2>&1 && ! dpkg --print-foreign-architectures | grep -qx i386; then
      sudo dpkg --add-architecture i386
      sudo apt-get update
    fi
    if apt-cache show 7zip >/dev/null 2>&1; then
      seven_zip_package='7zip'
    else
      seven_zip_package='p7zip-full'
    fi
    sudo apt-get install -y wine wine32:i386 wine64 winetricks unixodbc "$seven_zip_package"
  elif command -v dnf >/dev/null 2>&1; then
    printf 'Instalando dependências com o DNF...\n'
    if dnf -q list --available 7zip >/dev/null 2>&1 || rpm -q 7zip >/dev/null 2>&1; then
      seven_zip_package='7zip'
      sudo dnf install -y wine winetricks unixODBC "$seven_zip_package"
    else
      sudo dnf install -y wine winetricks unixODBC p7zip p7zip-plugins
    fi
  elif command -v wine >/dev/null 2>&1 && \
       command -v wineserver >/dev/null 2>&1 && \
       command -v winetricks >/dev/null 2>&1 && \
       command -v 7z >/dev/null 2>&1; then
    printf 'Usando Wine, Winetricks e 7-Zip já instalados.\n'
  else
    die "distribuição sem instalação automática ($distro_id, ID_LIKE=$distro_like). Instale Wine com suporte a 32 bits, Winetricks, UnixODBC e 7-Zip e execute o script novamente"
  fi
}

for required_file in "$MSI" "$REGISTRY_FILE"; do
  [[ -f "$required_file" ]] || die "$(basename "$required_file") não foi encontrado ao lado deste script"
done

(( EUID != 0 )) || die "execute este script como seu usuário normal, não como root"
[[ "$(uname -m)" == 'x86_64' ]] || die "este instalador aceita apenas sistemas Linux x86-64"
command -v sha256sum >/dev/null 2>&1 || die "sha256sum é necessário para verificar os arquivos fornecidos"
verify_sha256 "$MSI" "$MSI_SHA256"
verify_sha256 "$REGISTRY_FILE" "$REGISTRY_SHA256"

printf 'O gerenciador de pacotes pode pedir sua senha do Linux.\n\n'
install_dependencies

command -v wine >/dev/null 2>&1 || die "Wine não foi encontrado depois da instalação dos pacotes"
command -v wineserver >/dev/null 2>&1 || die "wineserver não foi encontrado depois da instalação dos pacotes"
command -v winetricks >/dev/null 2>&1 || die "Winetricks é necessário para o analisador XML do Enterprise Architect"
command -v 7z >/dev/null 2>&1 || die "7-Zip é necessário para o reparo de compatibilidade do MSXML4"

mkdir -p "$WINE_PREFIX" "$USER_BIN" "$APPLICATIONS_DIR" "$MIME_PACKAGES_DIR"

export WINEPREFIX="$WINE_PREFIX"
export WINEARCH=win64
export WINEDEBUG=-all
export WINEDLLOVERRIDES=winemenubuilder.exe=d

printf '\nCriando o ambiente Wine privado...\n'
wineboot -u
wineserver -w

printf 'Instalando o Enterprise Architect 14.1...\n'
wine msiexec /i "$(winepath -w "$MSI")" /qn /norestart
wineserver -w

printf 'Adicionando a configuração da licença flutuante da UFSC...\n'
wine regedit /s "$(winepath -w "$REGISTRY_FILE")"
wineserver -w

printf 'Instalando os analisadores XML nativos exigidos pelo Enterprise Architect...\n'
printf 'A primeira execução baixa cerca de 910 MB de componentes verificados da Microsoft.\n'
winetricks -q msxml3

if ! winetricks -q msxml4; then
  # O EA 14 já instala um componente MSI chamado MSXML4. No Wine atual, isso
  # faz o instalador MSXML4 da Microsoft retornar o código 67. O Winetricks já
  # baixou e conferiu o MSI correto, então extraímos e registramos diretamente
  # as DLLs de 32 bits.
  readonly MSXML4_MSI="$HOME/.cache/winetricks/msxml4/msxml.msi"
  [[ -f "$MSXML4_MSI" ]] || die "o Winetricks não deixou um instalador MSXML4 verificado no cache"

  msxml_extract_dir="$(mktemp -d -t ea-msxml4-XXXXXX)"
  trap 'rm -r -- "$msxml_extract_dir"' EXIT
  7z e -y -o"$msxml_extract_dir" "$MSXML4_MSI" \
    'msxml4.dll.246EB7AD_459A_4FA8_83D1_41A46D7634B7' \
    'msxml4r.dll.246EB7AD_459A_4FA8_83D1_41A46D7634B7' >/dev/null
  install -m 0644 \
    "$msxml_extract_dir/msxml4.dll.246EB7AD_459A_4FA8_83D1_41A46D7634B7" \
    "$WINE_PREFIX/drive_c/windows/syswow64/msxml4.dll"
  install -m 0644 \
    "$msxml_extract_dir/msxml4r.dll.246EB7AD_459A_4FA8_83D1_41A46D7634B7" \
    "$WINE_PREFIX/drive_c/windows/syswow64/msxml4r.dll"
  wine 'C:\windows\syswow64\regsvr32.exe' /s 'C:\windows\syswow64\msxml4.dll'
  wineserver -w
fi

[[ -f "$WINE_PREFIX/drive_c/Program Files (x86)/Sparx Systems/EA/EA.exe" ]] || \
  die "o comando MSI terminou, mas EA.exe não foi instalado"

cat > "$LAUNCHER" <<'LAUNCHER'
#!/usr/bin/env bash

set -euo pipefail

readonly DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export WINEPREFIX="$DATA_HOME/enterprise-architect-14/prefix"
export WINEDEBUG="${WINEDEBUG:--all}"
readonly EA_EXE='C:\Program Files (x86)\Sparx Systems\EA\EA.exe'

wine_arguments=()
for argument in "$@"; do
  if [[ -e "$argument" ]]; then
    wine_arguments+=("$(winepath -w "$argument")")
  else
    wine_arguments+=("$argument")
  fi
done

exec wine "$EA_EXE" "${wine_arguments[@]}"
LAUNCHER
chmod 755 "$LAUNCHER"

cat > "$DESKTOP_FILE" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Enterprise Architect 14
Comment=Modelagem de software com UML e BPMN
Exec="$LAUNCHER" %f
Icon=wine
Terminal=false
StartupNotify=true
Categories=Development;Education;
MimeType=application/x-enterprise-architect;
DESKTOP

cat > "$MIME_FILE" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-enterprise-architect">
    <comment>Enterprise Architect model</comment>
    <glob pattern="*.eap"/>
    <glob pattern="*.eapx"/>
    <glob pattern="*.feap"/>
  </mime-type>
</mime-info>
XML

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APPLICATIONS_DIR" >/dev/null 2>&1 || true
fi
if command -v update-mime-database >/dev/null 2>&1; then
  update-mime-database "$DATA_HOME/mime" >/dev/null 2>&1 || true
fi
if command -v xdg-mime >/dev/null 2>&1; then
  xdg-mime default enterprise-architect.desktop application/x-enterprise-architect || true
fi

printf '\nEnterprise Architect foi instalado.\n'
printf 'Abra pelo menu de aplicativos ou execute:\n  %s\n' "$LAUNCHER"

if ! timeout 4 getent ahosts licenciador2012.setic.ufsc.br >/dev/null 2>&1; then
  printf '\nO servidor de licenças da UFSC não está acessível nesta rede.\n'
  printf 'Conecte-se à redeUFSC ou à VPN da UFSC antes de abrir o aplicativo.\n'
fi

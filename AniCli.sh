#!/bin/bash

# AniCli - V1.0 - By S0ulx3 #

# set -x	# DEBUG

# Función Ctrl_C
function ctrl_c(){
    [[ -n "$logfile" && -f "$logfile" ]] && rm "$logfile"
    clear
    echo -e "\n  ${red}[!] Saliendo...${end}\n"
    exit 1
}

trap ctrl_c INT


# ─────────────────────────────────────────
#   VARIABLES GLOBALES
# ─────────────────────────────────────────
series_dir="./series"
movies_dir="./peliculas"
favs_file="./favoritos.txt"
watch_later_dir="./watch_later"
TODAY=$(date +"%d/%m/%Y")

mkdir -p $movies_dir
mkdir -p $series_dir
mkdir -p $watch_later_dir
touch "$favs_file"


# ─────────────────────────────────────────
#   COLORES
# ─────────────────────────────────────────
red="\e[31m"
gre="\e[32m"
yel="\e[33m"
blu="\e[34m"
pur="\e[35m"
cia="\e[36m"
end="\e[0m"
bold="\e[1m"
dim="\e[2m"
whi="\e[97m"
gry="\e[90m"


# ─────────────────────────────────────────
#   UI HELPERS
# ─────────────────────────────────────────
logo(){
    echo -e "${cia}${bold}"
    echo -e "  ░█████╗░███╗░░██╗██╗░█████╗░██╗░░░░░██╗"
    echo -e "  ██╔══██╗████╗░██║██║██╔══██╗██║░░░░░██║"
    echo -e "  ███████║██╔██╗██║██║██║░░╚═╝██║░░░░░██║"
    echo -e "  ██╔══██║██║╚████║██║██║░░██╗██║░░░░░██║"
    echo -e "  ██║░░██║██║░╚███║██║╚█████╔╝███████╗██║"
    echo -e "  ╚═╝░░╚═╝╚═╝░░╚══╝╚═╝░╚════╝░╚══════╝╚═╝${end}"
    echo -e "  ${gry}          V1.0 · by S0ulx3${end}\n"
    echo -e " ${gry} Contenido extraído de: ${whi}jkanime.bz${end}"
}

sep(){
    echo -e "  ${gry}──────────────────────────────────────────${end}"
}

header(){
    clear
    logo
    sep
    echo -e "  ${bold}${whi}$1${end}"
    sep
    echo ""
}

ok()  { echo -e "  ${gre}[✓]${end} $1"; }
err() { echo -e "  ${red}[✗]${end} $1"; }
inf() { echo -e "  ${cia}[·]${end} $1"; }
war() { echo -e "  ${yel}[!]${end} $1"; }


WL_DIR="./watch_later"
mkdir -p "$WL_DIR"


# ─────────────────────────────────────────
#  DEPENDENCIAS
# ─────────────────────────────────────────
check_deps(){

	# Verificar instalación de python
    # Python3 primero (necesario para pipx/pup)
    if ! command -v python3 &>/dev/null; then
        war "python3 no está instalado"
        read -p "$(echo -e "  ${cia}[?]${end} ¿Instalar python3? [s/N]: ")" resp
        if [[ "$resp" == "s" || "$resp" == "S" ]]; then
            if command -v apt &>/dev/null; then
                sudo apt install -y python3 python3-pip
            elif command -v pacman &>/dev/null; then
                sudo pacman -S --noconfirm python
            elif command -v dnf &>/dev/null; then
                sudo dnf install -y python3 python3-pip
            else
                err "Instala python3 manualmente y vuelve a ejecutar."; exit 1
            fi
        else
            err "python3 es necesario, saliendo."; exit 1
        fi
    fi


    # Pup aparte porque no está en los repos estándar
    if ! command -v pup &>/dev/null; then
        war "pup no está instalado (necesario para parsear HTML)"
        read -p "$(echo -e "  ${cia}[?]${end} ¿Instalar pup? [s/N]: ")" resp
        if [[ "$resp" == "s" || "$resp" == "S" ]]; then
            pip3 install pipx --break-system-packages 2>/dev/null
            pipx install pup
            export PATH="$PATH:$HOME/.local/bin"
        else
            err "pup es necesario, saliendo."; exit 1
        fi
    fi

	# Verificación de dependencias
    local deps=(mpv curl wget fzf md5sum yt-dlp)
    local missing=()

    for dep in "${deps[@]}"; do
        command -v "$dep" &>/dev/null || missing+=("$dep")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "\n  ${yel}[!]${end} Dependencias que faltan: ${whi}${missing[*]}${end}"
        read -p "$(echo -e "  ${cia}[?]${end} ¿Instalar automáticamente? [s/N]: ")" resp
        if [[ "$resp" == "s" || "$resp" == "S" ]]; then
            if command -v apt &>/dev/null; then
                sudo apt install -y "${missing[@]}"
            elif command -v pacman &>/dev/null; then
                sudo pacman -S --noconfirm "${missing[@]}"
            elif command -v dnf &>/dev/null; then
                sudo dnf install -y "${missing[@]}"
            else
                err "Gestor de paquetes no reconocido. Instala manualmente: ${missing[*]}"
                exit 1
            fi
        else
            err "Faltan dependencias, saliendo."; exit 1
        fi
    fi
}


# ─────────────────────────────────────────
#   REPRODUCTOR
# ─────────────────────────────────────────
rep_content(){
    local LINK="$1"
    local TITULO="$2"
    local id=$(echo "$TITULO" | md5sum | cut -c1-8)
    local pos_file="./watch_later/$id.pos"
    local log_file="/tmp/anicli_pos_$$"

    mkdir -p ./watch_later

    local start_pos=""
    if [[ -f "$pos_file" ]]; then
        local saved=$(cat "$pos_file")
        [[ -n "$saved" ]] && start_pos="--start=$saved"
		inf "Retomando desde ${cia}$(echo "$saved" | cut -d'.' -f1)s${end}..."
        sleep 0.5
    fi

    # stdout al log, stderr descartado (warnings de MESA/VDPAU)
    mpv $start_pos --ontop --term-status-msg='POS=${=time-pos}' "$LINK" >"$log_file" 2>/dev/null

    # Última posición registrada
    local last_pos=$(grep "^POS=" "$log_file" | tail -n1 | cut -d'=' -f2)

    if [[ -n "$last_pos" && "$last_pos" != "0.000000" ]]; then
        echo "$last_pos" > "$pos_file"
		inf "Posición guardada: ${cia}$(echo "$last_pos" | cut -d'.' -f1)s${end}"
		sleep 1
    fi

    rm -f "$log_file"
}

# ─────────────────────────────────────────
#   CHECK LINK
# ─────────────────────────────────────────
check_link() {
    local url="$1"
    local status=$(curl -s -o /dev/null -w "%{http_code}" -A "Mozilla/5.0" --max-time 5 -L "$url")
    echo "$status"
}


# ─────────────────────────────────────────
#   SELECCIONAR SERVIDOR
# ─────────────────────────────────────────
seleccionar_servidor(){

    local selection
    local type="$2"
	local cap="$3"
    local dir
    local file_path
    local LINK
    local true_link
    local servidor

	# Determinar variables segun tipo de contenido
	case "$type" in		# 1=Series 2=Peliculas
	1)	 # SERIES
	dir="$series_dir"
	#echo " DOLLAR 1 = $1 | cap = $cap"; read
	selection="$1- Links.txt"

	header "Servidores  ·  $1"

	;;
	2)	# PELICULAS
	dir="$movies_dir"
	selection="$1 - Links.txt"

	header "Servidores  ·  $1"

	;;
	esac

    file_path="$dir/$selection"

    # Cargamos links, servidores y estados en arrays
    mapfile -t links   < <(grep "Download_link" "$file_path" | grep -oP 'https?://\S+')
    mapfile -t servers < <(grep "^server:" "$file_path" | cut -d':' -f2)
    mapfile -t states  < <(grep "Download_link" "$file_path" | grep -oP '\( \K[^)]+')

    # Mostramos la lista numerada con estado
    for i in "${!links[@]}"; do
        if echo "${states[$i]}" | grep -q "No Disponible"; then
            echo -e "  ${red}[$((i+1))]${end}  ${gry}✗  ${servers[$i]}  (no disponible)${end}"
        else
            echo -e "  ${gre}[$((i+1))]${end}  ${gre}✓${end}  ${whi}${servers[$i]}${end}"
        fi
    done

    echo ""
    sep
    echo -e "\n  ${gry}[ Enter para volver ]${end}\n"
    read -p "$(echo -e "  ${cia}[?]${end} Selecciona servidor: ")" server

    [[ -z "$server" ]] && return

    LINK="${links[$((server-1))]}"
    [[ -z "$LINK" ]] && { err "Opción no válida"; sleep 2; return; }

    # Detectamos y resolvemos según servidor
    servidor=$(echo "$LINK" | grep -oP '(?<=://)([^/]+)' | sed 's/www\.//')
    echo ""
    inf "Resolviendo ${cia}$servidor${end}..."

    case "$servidor" in
        mediafire.com)
			if [[ "$type" -eq 1 ]]; then	# Extraer bien el link. ( En series no aparece la disponibilidad en el archivo de links. En películas si. )
            LINK="$(grep -i "Mediafire" "$file_path" | head -n1 | cut -d ' ' -f3 | sed 's|mediafire.com|www.mediafire.com|')"
			else
			LINK="$(grep -i "Mediafire" "$file_path" | head -n1 | cut -d ' ' -f8 | sed 's|mediafire.com|www.mediafire.com|')"
			fi
            true_link=$(curl -s "$LINK" | grep "download" | grep "mp4" | cut -d '"' -f2 | head -n1)
            ;;
        *)
        	war "Servidor ( $servidor ) no testeado, es posible que no funcione. ( En el 90% de los casos mediafire funciona )"; sleep 2
            true_link="$LINK"
            ;;
    esac


	if [[ -z "$true_link" ]]; then		# Si no se pudo resolver el link

    	if [[ "$type" -eq 2 ]]; then   # Solo en películas donde sí hay estado
		err "Link no encontrado, prueba a descargar otra vez los links."
		sed -i "/$servidor/ s/Disponible/No Disponible/" "$movies_dir/$selection"
    	fi

    err "No se pudo resolver el link"
    sleep 2
    return
	fi

	# Verificar si el link está soportado por mpv	( Cambiar disponibilidad de links automáticamente )
	if ! yt-dlp --simulate --get-url --user-agent="Mozilla/5.0" "$true_link" >/dev/null 2>&1; then
	sed -i "/$servidor/ s/Disponible/No Disponible/" "$movies_dir/$selection"
	err "Link no soportado por mpv"
	inf "Prueba en el navegador introduciendo directamente el enlace: $true_link"
	sleep 3
	return
	fi

    ok "Link resuelto, abriendo mpv..."
    sleep 0.5

	if [[ "$type" -eq 2 ]]; then	# REPRODUCIR PELICULAS O SERIES ( $1 es el nombre del anime )
    rep_content "$true_link" "$1" # Reproducir Películas
	else
	rep_content "$true_link" "$1 Cap $cap"
	#rep_content "$true_link" "$selection Cap $cap"	# Reproducir Series
	fi
}


# ─────────────────────────────────────────
#   PELÍCULAS
# ─────────────────────────────────────────
movies(){

    local selection=$(ls "$movies_dir" | sed 's/ - Links.txt//' | fzf \
        --prompt="  Película > " \
        --header="  ENTER para gestionar · ESC para volver" \
        --border=rounded \
        --color="prompt:cyan,pointer:cyan,header:italic:gray")

    [[ -z "$selection" ]] && return

    while true; do
        header "Película  ·  $selection"

        echo -e "  ${cia}[1]${end}  Reproducir"
        echo -e "  ${yel}[2]${end}  Añadir a favoritos"
        echo -e "  ${red}[3]${end}  Eliminar de la biblioteca"
        echo -e "\n  ${gry}[4]  Volver${end}\n"
        sep

        read -p "$(echo -e "\n  ${cia}[?]${end} Opción: ")" opt
        case "$opt" in
            1) seleccionar_servidor "$selection" "2" ;;
            2)
				if ! cat "./favoritos.txt" | grep "$selection" &>/dev/null; then
                echo "[PELI] $selection" >> "$favs_file"
                ok "Añadido a favoritos."; sleep 1.5
                else
                err "El título $selection ya se encuentra en favoritos"; sleep 1.5
                fi
                ;;
            3)
                echo ""
                war "¿Seguro que quieres eliminar ${whi}$selection${end}? ${gry}[s/N]${end}"
                read -p "  " confirm
                if [[ "$confirm" == "s" || "$confirm" == "S" ]]; then
                    rm "$movies_dir/$selection - Links.txt"
                    ok "Eliminado."; sleep 1; return
                fi
                ;;
            4) return ;;
            *) err "Opción no válida"; sleep 1 ;;
        esac
    done
}


# ─────────────────────────────────────────
#   SERIES
# ─────────────────────────────────────────
series(){

    local selection=$(ls -v "$series_dir" | sed 's/- Links.txt//' | sort -u | fzf \
        --prompt="  Serie > " \
        --header="  ENTER para gestionar · ESC para volver" \
        --border=rounded \
        --color="prompt:cyan,pointer:cyan,header:italic:gray")

    [[ -z "$selection" ]] && return

    while true; do
        header "Serie  ·  $selection"

        echo -e "  ${cia}[1]${end}  Reproducir capítulo"
        echo -e "  ${yel}[2]${end}  Añadir a favoritos"
        echo -e "  ${red}[3]${end}  Eliminar de la biblioteca"
        echo -e "\n  ${gry}[4]  Volver${end}\n"
        sep

        read -p "$(echo -e "\n  ${cia}[?]${end} Opción: ")" opt
        case $opt in
            1) #seleccionar_servidor "$selection" "1" ;;
                # Listar caps disponibles con fzf
				local cap_sel=$(ls -v "$series_dir" | grep "^$selection" | sed 's/.* Cap //' | sed 's/ - Links.txt//')

                [[ -z "$cap_sel" ]] && continue

				#echo -e "[ Selection = $selection | cap_sel = $cap_sel ]"; read	#DEBUG
                seleccionar_servidor "$selection" "1" "${cap_sel}"
			;;
            2)
				if ! cat "./favoritos.txt" | grep "$selection" &>/dev/null; then
                echo "[SERIE] $selection" | sed 's/ - Cap.*//' >> "$favs_file"
                ok "Añadido a favoritos."; sleep 1
                else
                err "El título $selection ya se encuentra en favoritos"; sleep 1.5
                fi
                ;;
            3)
                echo ""
                war "¿Seguro que quieres eliminar ${whi}$selection${end}? ${gry}[s/N]${end}"
                read -p "  " confirm
                if [[ "$confirm" == "s" || "$confirm" == "S" ]]; then
                    rm -f "$series_dir/$selection"*".txt"
                    ok "Eliminado."; sleep 1; return
                fi
                ;;
            4) return ;;
            *) err "Opción no válida"; sleep 1 ;;
        esac
    done
}


# ─────────────────────────────────────────
#   FAVORITOS
# ─────────────────────────────────────────
favoritos(){

    header "Favoritos"

    if [[ ! -f "$favs_file" || ! -s "$favs_file" ]]; then
        war "No tienes favoritos guardados todavía."
        echo ""
        sep
        read -p "$(echo -e "\n  Pulsa Enter para volver: ")"
        return
    fi

    # Mostrar lista
    local i=1
    local nombres=()
    local tipos=()
    while IFS= read -r linea; do
        tipo=$(echo "$linea" | grep -oP '\[\K[^\]]+')
        nombre=$(echo "$linea" | sed 's/.*\] //')
        nombres+=("$nombre")
        tipos+=("$tipo")
        if [[ "$tipo" == "PELI" ]]; then
            echo -e "  ${pur}[$i]${end}  ${gry}[Peli ]${end}  $nombre"
        else
            echo -e "  ${cia}[$i]${end}  ${gry}[Serie]${end}  $nombre"
        fi
        ((i++))
    done < "$favs_file"

    echo ""
    sep
    echo -e "\n  ${gry}[ Enter para volver ]${end}\n"
    read -p "$(echo -e "  ${cia}[?]${end} Selecciona un número: ")" num

    [[ -z "$num" ]] && return

    # Validar que sea un número dentro del rango
    if ! [[ "$num" =~ ^[0-9]+$ ]] || [[ "$num" -lt 1 || "$num" -gt "${#nombres[@]}" ]]; then
        err "Opción inválida"; sleep 1; favoritos; return
    fi

    local sel_nombre="${nombres[$((num-1))]}"
    local sel_tipo="${tipos[$((num-1))]}"
	#local animename=$(echo "$sel_nombre" | tr ' ' '\n' | grep -B100 "Cap" | tr '\n' ' ' | cut -d '-' -f1)

    # Submenú del favorito seleccionado
    while true; do
        header "Favorito  ·  $sel_nombre"

        [[ "$sel_tipo" == "PELI" ]] \
            && echo -e "  ${cia}[1]${end}  Reproducir película" \
            || echo -e "  ${cia}[1]${end}  Reproducir serie"
        echo -e "  ${red}[2]${end}  Quitar de favoritos"
        echo -e "\n  ${gry}[3]  Volver${end}\n"
        sep

        read -p "$(echo -e "\n  ${cia}[?]${end} Opción: ")" opt
        case "$opt" in
            1)
                if [[ "$sel_tipo" == "PELI" ]]; then
                    seleccionar_servidor "$sel_nombre" "2"
                else
				 local nombre_serie=$(echo "$sel_nombre" | sed 's/ - Cap.*//' | sed 's/ $//')
                	#local cap_sel=$(ls -v "$series_dir" | grep "^$sel_nombre" | sed 's/.* Cap //' | sed 's/ - Links.txt//') # Metodo normal sin fzf, sin seleccionar 2 veces el cap. (afecta a seleccionar_servidor)
					local cap_sel=$(ls -v "$series_dir" | grep -i "^$nombre_serie" | sed 's/.* Cap //' | sed 's/ - Links.txt//' | fzf --prompt="  Capítulo > " --border=rounded --color="prompt:cyan,pointer:cyan")

					naame=$(echo "${nombre_serie} - Cap ${cap_sel} ")

					[[ -z "$cap_sel" ]] && continue

					#echo " Nombreserie = $nombre_serie | cap_sel = $cap_sel | "; read	# DEBUG

                    seleccionar_servidor "${naame}" "1" "$cap_sel"
                fi
                ;;
            2)
                # Eliminar la línea del favorito del archivo
				sed -i "/^\[$sel_tipo\] $sel_nombre$/d" "$favs_file"
                ok "Eliminado de favoritos."; sleep 1
                favoritos   # Volver a mostrar la lista actualizada
                return
                ;;
            3) favoritos; return ;;
            *) err "Opción no válida"; sleep 1 ;;
        esac
    done
}

# ─────────────────────────────────────────
#   BIBLIOTECA
# ─────────────────────────────────────────
library(){

    while true; do
        local count_m=$(ls "$movies_dir" 2>/dev/null | grep -c "Links.txt")
        local count_s=$(ls "$series_dir" 2>/dev/null | sed 's/ - Cap.*//' | sort -u | grep -c ".")
        local count_f=$(grep -c "." "$favs_file" 2>/dev/null || echo 0)

        header "Biblioteca"

        echo -e "  ${cia}[1]${end}  Películas      ${gry}($count_m títulos)${end}"
        echo -e "  ${gre}[2]${end}  Series         ${gry}($count_s títulos)${end}"
        echo -e "  ${yel}[3]${end}  Favoritos      ${gry}($count_f guardados)${end}"
        echo ""
        echo -e "  ${gry}[4]  Volver al menú principal${end}\n"
        sep

        read -p "$(echo -e "\n  ${cia}[?]${end} Opción: ")" option

        case "$option" in
            1) movies ;;
            2) series ;;
            3) favoritos ;;
            4) return ;;
            *) err "Opción no válida"; sleep 1 ;;
        esac
    done
}


# ─────────────────────────────────────────
#   EXTRACTOR DE PELÍCULAS
# ─────────────────────────────────────────
extract_movie(){

    local anime_url="$1"
    local anime_selected="$2"
    local dwn_link
    local code_status
    local count=0

    logfile="$anime_selected.weblog.txt"
    > "$movies_dir/$anime_selected - Links.txt"

    header "Extractor  ·  $anime_selected"
    inf "Descargando información de la película..."
    echo ""

    wget -q "${anime_url}pelicula/" -O "$logfile"

    for vuelta in {2..15}; do

        dwn_link=$(cat "$logfile" | grep "remote" | cut -d '{' -f"$vuelta" | cut -d ';' -f2 | xargs | tr ',' '\n' | grep -vE "slug|lang|append" | head -n 1 | cut -d ':' -f2 | base64 -d)

        [[ -z "$dwn_link" ]] && break

        code_status=$(check_link "$dwn_link")
        info_extra=$(cat "$logfile" | grep "remote" | cut -d '{' -f"$vuelta" | cut -d ';' -f2 | xargs | tr ',' '\n' | grep -vE "slug|lang|append" | tail -n3)
        local srv=$(echo "$dwn_link" | grep -oP '(?<=://)([^/]+)')

        case "$code_status" in
            200)
                ok "Disponible  ·  ${whi}$srv${end}"
                echo -e "Download_link ( Disponible - $TODAY ) : $dwn_link" >> "$movies_dir/$anime_selected - Links.txt"
                ;;
            *)
                err "No disponible  ·  ${gry}$srv${end}  ${gry}($code_status)${end}"
                echo -e "Download_link ( No Disponible - $TODAY ) : $dwn_link" >> "$movies_dir/$anime_selected - Links.txt"
                ;;
        esac

        echo -e "$info_extra" >> "$movies_dir/$anime_selected - Links.txt"
        ((count++))

    done

    rm "$logfile"
    logfile=""

    echo ""
    sep
    ok "$count links extraídos"
    inf "${gry}$movies_dir/$anime_selected - Links.txt${end}"
    sleep 2
}


# ─────────────────────────────────────────
#   EXTRACTOR DE SERIES
# ─────────────────────────────────────────
extract_series(){

    local anime_url="$1"
    local anime_selected="$2"
    local dwn_link

    header "Extractor  ·  $anime_selected"

    echo -e "  ${gry}Introduce un rango de capítulos.${end}"
    echo -e "  ${gry}Para un solo capítulo pon el mismo número dos veces.${end}\n"

    read -p "$(echo -e "  ${cia}[?]${end} Desde capítulo: ")" CAP_INICIO
    read -p "$(echo -e "  ${cia}[?]${end} Hasta capítulo: ")" CAP_FIN

    [[ -z "$CAP_INICIO" || -z "$CAP_FIN" ]] && return

    echo ""
    sep
    echo ""

    for CAP in $(seq $CAP_INICIO $CAP_FIN); do

        if [[ -f "$series_dir/$anime_selected - Cap $CAP - Links.txt" ]]; then
            war "Cap ${yel}$CAP${end} ya existe, saltando..."
            continue
        fi

        inf "Extrayendo cap ${cia}$CAP${end}..."

        logfile="$anime_selected-cap$CAP.weblog.txt"
        wget -q -p "$anime_url$CAP/" -O "$logfile"

        for vuelta in {2..15}; do

            dwn_link=$(cat "$logfile" | grep "remote" | cut -d '{' -f$vuelta | cut -d ';' -f2 | xargs | tr ',' '\n' | grep -vE "slug|lang|append" | head -n1 | cut -d ':' -f2 | base64 -d)

            [[ -z "$dwn_link" ]] && break

            info_extra=$(cat "$logfile" | grep "remote" | cut -d '{' -f$vuelta | cut -d ';' -f2 | xargs | tr ',' '\n' | grep -vE "slug|lang|append" | tail -n3)

            echo -e "Download_link : $dwn_link" >> "$series_dir/$anime_selected - Cap $CAP - Links.txt"
            echo -e "$info_extra" >> "$series_dir/$anime_selected - Cap $CAP - Links.txt"

        done

        rm "$logfile"
        logfile=""

        if [[ -f "$series_dir/$anime_selected - Cap $CAP - Links.txt" ]]; then
            ok "Cap $CAP guardado."
        else
            err "Cap $CAP sin links ${gry}(¿existe ese capítulo?)${end}"
        fi

    done

    echo ""
    sep
    ok "Extracción completada: caps ${cia}$CAP_INICIO${end} → ${cia}$CAP_FIN${end}"
    inf "${gry}Guardado en $series_dir/${end}"
    sleep 2
}


# ─────────────────────────────────────────
#   BUSCADOR / EXTRACTOR PRINCIPAL
# ─────────────────────────────────────────
extract_links(){

    header "Extractor de Links  ·  Jkanime.bz"

    echo -e "  ${gry}Busca series y películas para extraer sus links.${end}"
    echo -e "  ${gry}Enter vacío para volver al menú.${end}\n"

    read -p "$(echo -e "  ${cia}[?]${end} Buscar: ")" SEARCH

    [[ -z "$SEARCH" ]] && return

    echo ""
    inf "Buscando ${whi}$SEARCH${end}..."

    name_fm=$(echo "$SEARCH" | sed 's| |%20|g')
    list_animes=$(curl -s "https://jkanime.bz/buscar/$name_fm/" | pup '.anime__item__text h5 a text{}' | sed "s|&amp;|\&|g" | sed 's|&#39;|\`|g')

    if [[ -z "$list_animes" ]]; then
        err "Sin resultados para ${whi}$SEARCH${end}"; sleep 2; return
    fi

    anime_selected=$(echo "$list_animes" | fzf \
        --prompt="  Elige un anime > " \
        --border=rounded \
        --color="prompt:cyan,pointer:cyan")

    [[ -z "$anime_selected" ]] && return

    echo ""
    inf "Obteniendo información de ${whi}$anime_selected${end}..."

    anime_fm=$(echo "$anime_selected" | sed 's| |%20|g')
    anime_url=$(curl -s "https://jkanime.bz/buscar/$anime_fm" | pup ".anime__item__text h5 a attr{href}" | head -n1)
    anime_type=$(curl -s "$anime_url" | grep 'rel="tipo"' | head -n1 | pup 'li text{}' | tail -n1 | xargs)

    inf "Tipo: ${cia}$anime_type${end}"
    echo ""

    if [[ "$anime_type" == "Pelicula" ]]; then

        if [[ -f "$movies_dir/$anime_selected - Links.txt" ]]; then
            war "Ya tienes los links de esta película guardados."
            sleep 2; return
        fi

        extract_movie "$anime_url" "$anime_selected"

    elif [[ "$anime_type" == "Serie" ]]; then

        extract_series "$anime_url" "$anime_selected"

    else
        err "Tipo no reconocido: ${whi}$anime_type${end}"; sleep 2
    fi
}


# ─────────────────────────────────────────
#   MENÚ PRINCIPAL
# ─────────────────────────────────────────
menu(){
    while true; do
        clear
        logo
        sep
        echo ""
        echo -e "  ${cia}[1]${end}  Extractor de links"
        echo -e "       ${gry}Busca y guarda los enlaces de series y películas${end}"
        echo ""
        echo -e "  ${pur}[2]${end}  Biblioteca"
        echo -e "       ${gry}Gestiona tu contenido y favoritos${end}"
        echo ""
        echo -e "  ${red}[3]${end}  Salir"
        echo ""
        sep

        read -p "$(echo -e "\n  ${cia}[?]${end} Elige una opción: ")" option

        case $option in
            1) extract_links ;;
            2) library ;;
            3) ctrl_c ;;
            *) err "Opción no válida"; sleep 1 ;;
        esac
    done
}


# ─────────────────────────────────────────
#   INICIO
# ─────────────────────────────────────────
check_deps
menu

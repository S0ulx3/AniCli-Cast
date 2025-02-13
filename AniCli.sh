#!/bin/bash

# Función Ctrl+C
function ctrl_c(){

clear; tput civis
rm -rf /tmp/jkanime.bz &>/dev/null
echo -e "\n\n\t\e[31m[!]\e[33m Saliendo... \n\n"
sleep 1; tput cnorm;pkill mpv; exit 1

}

# CTRL+C

trap ctrl_c SIGINT


# Verifición e instalación automática de dependencias.
function dep(){
	tput civis; clear
	echo -e "\n\n\t\e[35m[!]\e[33m Verificando si las dependencias están instaladas..."; sleep 1.3
	clear

for requirements in fzf mpv wget curl pup python3; do

if ! $(which $requirements &>/dev/null)
then
clear
echo -e "\n\n\t\e[31m[!]\e[33m Comando \e[31m$requirements\e[33m no instalado.\e[0m"
sleep 2

	if [ $requirements == "pup" ]; then
	pip3 install python3-pipx || pip3 install pipx --break-system-packages; clear; pipx install pup
	fi

tput cnorm; sudo apt install $requirements -y

	else
	:

fi
done

tput civis; clear
echo -e "\n\n\t\e[32m[!]\e[33m Dependencias instaladas.\e[0m"
sleep 1.3; tput cnorm; menu

}

# Menú Principal
function menu(){
clear; tput cnorm

	echo -e "\n\n\t\e[35m[-------------------------]"
	echo -e "\t[ - ANICLI - En Español - ]"
	echo -e "\t[-------------------------]\e[34m"
	read -p "	[---Buscador--> " anime
	sleep 0.3; clear

anime2=$(echo "$anime" | tr ' ' '_')

LINKS=$(curl -s https://jkanime.bz/buscar/$anime2/ | pup 'a[href]' | grep -P '(?<=<a href=")[^"]*(?=")' | grep -vE "directorio|horario|top|hentai|facebook|youtube|usuario|guardado|solicitudes|listas|busquedas|tipoint|letrasint|tipo|genero|scrollToTopButton|#|index|discord|buscar" | sed 's|<a href="/">| |' | tr -d '><"= ' | sed 's/ahref/ /' | tr -d ' ' | sort -u)

# Uso de fzf para que el usuario eliga un anime
selected_link=$(echo "$LINKS" | fzf --prompt="Selecciona un enlace: ")
if [[ -n "$selected_link" ]]; then

selection=$(echo "$selected_link" | tr -d ' ')

else
clear; tput civis
echo -e "\n\n\t\e[31m[!]\e[33m Opción no válida, inténtalo de nuevo.\e[0m"; tput cnorm
fi

rep_cap

}

# Función para reproducir el capítulo

function rep_cap(){
clear; tput civis
echo -e "\n\n\t\e[35m[-------------------------]"
echo -e "\t[ - ANICLI - En Español - ]"
echo -e "\t[-------------------------]\e[34m"

 sleep 0.3; tput cnorm
 read -p "	[- Nº de Capítulo-> " cap
 clear

	CAP=$(echo "$cap/" | sed 's/ //')

	URL=$(echo "$selection$CAP")

wget -p "$URL" -P /tmp/ 2>/dev/null

ruta="/tmp/jkanime.bz/jk.php*"

if cat $ruta &>/dev/null; then

clear
url2="$(cat /tmp/jkanime.bz/jk.php* | grep "https" | tail -n1 | sed 's/url://' | tr -d "', ")"
:

else

tput civis;clear
echo -e "\n\n\t\e[31m[!]\e[33m El video contiene anuncios, por lo tanto no está disponible desde terminal."; sleep 0.4
echo -e "\t\e[31m[!]\e[33m Prueba con otro video."; sleep 2
tput cnorm; menu

fi

rm -rf /tmp/jkanime.bz &>/dev/null
mpv --referrer="https://jkanime.bz" $url2 2>/dev/null
}

rm -rf /tmp/jkanime.bz &>/dev/null
dep

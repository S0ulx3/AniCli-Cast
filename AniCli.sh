#!/bin/bash

# Función Ctrl+C
function ctrl_c(){

clear; tput civis
         echo -e "\n\n\e[31m|--------------------------|"
                   echo -e "|     [!] Saliendo...      |"
                   echo -e "|--------------------------|\e[0m\n\n"

tput cnorm; exit 1

}

# Ctrl+C
trap ctrl_c SIGINT

######################################################################################

# Función para verificar e instalar comandos

check_and_install() {
    command_name=$1
    install_command=$2

if ! command -v $command_name &>/dev/null
then

echo "$command_name no está instalado. Instalando..."

eval $install_command
else

: &>/dev/null

fi
}

# Verificar e instalar fzf
check_and_install "fzf" "sudo apt install fzf -y"

# Verificar e instalar bsdtar
check_and_install "bsdtar" "sudo apt install bsdtar -y" &>/dev/null

# Verificar e instalar pup
check_and_install "pup" "wget -qO- https://github.com/ericchiang/pup/releases/download/v0.4.0/pup_0.4.0_linux_amd64.zip | bsdtar -xvf- -C /usr/local/bin && chmod +x /usr/local/bin/pup"

# Verificar e instalar awk (aunque awk generalmente está preinstalado en la mayoría de los sistemas)
check_and_install "awk" "sudo apt install gawk -y" # gawk es una versión de awk
sleep 1; clear

# Buscar anime
rm -rf /tmp/jkanime/ /tmp/cap.txt  /tmp/page.txt  /tmp/tmp.txt /tmp/url.txt
clear; tput civis
echo -e "\n\e[34m -------------------------- "
echo -e "| \e[33m-\e[34m Bienvenido a \e[31mAni-cli\e[33m -\e[34m |"
echo -e " -------------------------- "
echo -e "| \e[33m-\e[31m En Español\e[33m -\e[34m |          "
echo -e " ----------------           "
sleep 0.3; tput cnorm
read -p "| -Buscador-> " anime
sleep 0.3; clear

anime_name_formatted=$(echo "$anime" | tr ' ' '_')

LINKS=$(curl -s https://jkanime.bz/buscar/$anime_name_formatted/ | pup 'a[href]' | grep -P '(?<=<a href=")[^"]*(?=")' | grep -vE "directorio|horario|top|hentai|facebook|youtube|usuario|guardado|solicitudes|listas|busquedas|tipoint|letrasint|tipo|genero|scrollToTopButton|#|index|discord|buscar" | sed 's|<a href="/">| |' | tr -d '><"= ' | sed 's/ahref/ /' | tr -d ' ' | sort -u)


# Uso de fzf para que el usuario eliga un anime
selected_link=$(echo "$LINKS" | fzf --prompt="Selecciona un enlace: ")
if [[ -n "$selected_link" ]]; then

    echo "$selected_link" | tr -d ' ' > /tmp/page.txt
rep_cap

else
clear; tput civis
echo -e "\n\t\e[31m[!] Opción no válida, inténtalo de nuevo... [!]\e[0m"
fi

# Reproducir el capítulo
clear; tput civis
echo -e " --------------------------- "
echo -e "|        - Ani-cli -        |"
echo -e " --------------------------- "
 sleep 0.3; tput cnorm
 read -p "| -Nº de Capítulo-> " cap
 clear
        echo "$cap/" > /tmp/cap.txt
        echo $(cat /tmp/page.txt) > /tmp/url.txt
        capp=$(cat /tmp/cap.txt | sed 's/ //')
        echo $(cat /tmp/cap.txt) >> /tmp/url.txt
        echo $(cat /tmp/url.txt) > /tmp/tmp.txt
        url=$(cat /tmp/tmp.txt | sed 's/ //')

wget -p "$url" -P /tmp/ &>/dev/null

url="$(grep url /tmp/jkanime.bz/um* | cut -d"'" -f2 | head -n 1)"

rm -rf /tmp/jkanime/ /tmp/cap.txt  /tmp/page.txt  /tmp/tmp.txt /tmp/url.txt; mpv --referrer="https://jkanime.bz" $url 2>/dev/null

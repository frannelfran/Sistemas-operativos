#!/bin/bash

# Práctica de Sistemas Operativos
# Un script que informa del estado del sistema

##### Constantes

TITLE="Información del sistema para $HOSTNAME"
RIGHT_NOW=$(date +"%x %r%Z")
TIME_STAMP="Actualizada el $RIGHT_NOW por $USER"
SPACE_TMP=$(du -sh /tmp)

##### Estilos

TEXT_BOLD=$(tput bold) # Letra en negrita
TEXT_GREEN=$(tput setaf 2) # Letra verde
TEXT_RESET=$(tput sgr0) # Quitar el formato
TEXT_ULINE=$(tput sgr 0 1) # Subraya el texto

##### Funciones

system_info() {
  echo "${TEXT_ULINE}Versión del sistema${TEXT_RESET}"
  echo # Nueva línea
  uname -a # Muestra la versión del sistema
}

show_uptime() {
  echo "${TEXT_ULINE}Tiempo de encendido del sistema${TEXT_RESET}"
  echo # Nueva línea
  uptime
}

drive_space() {
  echo "${TEXT_ULINE}Espacio ocupado en las particiones / discos duros del sistema${TEXT_RESET}"
  echo # Nueva línea
  df
}

home_space() {
  echo "${TEXT_ULINE}Espacio ocupado por cada uno de los subdirectorios en /home${TEXT_RESET}"
  if [$USER != root]; then
    du -hs ~
  else
    du -hs /home/*/
  fi
}

tmp_space() {
  if [ -d "/tmp" ]; then
    echo "Información del directorio temporal"
    echo "Espacio ocupado por /tmp $SPACE_TMP"
  fi
}

##### Programa principal

cat << _EOF_
$TEXT_BOLD$TITLE$TEXT_RESET
$(system_info)

$(show_uptime)

$(drive_space)

$(home_space)

$(tmp_space)
$TEXT_GREEN$TIME_STAMP$TEXT_RESET
_EOF_
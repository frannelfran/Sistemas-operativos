# VARIABLES
TITLE="Programa creado por $USER"

# ESTILOS
TEXT_BOLD=$(tput bold) # Letra en negrita
TEXT_GREEN=$(tput setaf 2) # Letra verde
TEXT_RESET=$(tput sgr0) # Quitar el formato
TEXT_ULINE=$(tput sgr 0 1) # Subraya el texto

# FUNCIONES
help() {
  echo "Uso: scdebug [-h] [-sto arg] [-v | -vall] [-nattch progtoattach] [prog [arg1 …]]"
}

# PROGRAMA PRINCIPAL
cat << salida
$TITLE



salida

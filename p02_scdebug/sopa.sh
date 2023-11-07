#!./ptbash

help() {
  echo "Uso: scdebug [-h] [-sto arg] [-v | -vall] [-nattch progtoattach] [prog [arg1 …]]"
}

# Función para crear las carpetas con los uuid
crear_subdirectorio() {
  # argv1 = programa
  # Obtener el nombre del programa y generar un UUID
  local program="$1"
  uuid=$(uuidgen)
  # Directorio de salida relativo al directorio home del usuario
  output_dir="$HOME/.scdebug/$program"
  output_file="$output_dir/trace_$uuid.txt"
  # Crear el directorio de salida si no existe
  if [ ! -d "$output_dir" ]; then
    mkdir -p "$output_dir"
  fi
  echo "$output_file"
}

# Función para obtener el PID del proceso más reciente con el nombre del programa
get_recent_pid() {
  # argv1 = programa para obtener su PID
  local program="$1"
  local recent_pid=$(pgrep -o "$program")
  echo "$recent_pid" # Obtener el PID
}

# Ejecutar strace
run_strace() {
  # argv1 = programa
  # argv2 = opciones del strace
  local program="$1"
  local strace_options="$2"
  local nattch_pid="$3"
  # Llamar a la función crear_subdirectorio
  output_file=$(crear_subdirectorio "$program")
  # Verificar si la opción -nattch está habilitada
  if [ -n "$nattch_pid" ]; then
    # Ejecutar strace en el proceso especificado
    strace "$strace_options" -p "$nattch_pid" -o "$output_file" & sleep 0.1 > "$output_file"
  else
    # Ejecutar el strace con las opciones
    strace $strace_options -o "$output_file" "$program" &
  fi
}

# main
strace_options=""
attach_program=""
recent_pid=""
while [ -n "$1" ]; do
  opcion="$1"
  case "$opcion" in
    -h)
      help
      exit 0
    ;;
    -sto)
      strace_options="$1"
      echo "$strace_options"
    ;;
    -nattch)
      attach_program="$1"
      echo "$attach_program"
    ;;
    *)
      program="$1"
      echo "$program"
    ;;
  esac
  shift
done
# Si se proporciona la opción -nattch, obtener el PID del proceso más reciente
if [ -n "$attach_program" ]; then
  recent_pid=$(get_recent_pid "$attach_program")
fi
run_strace "$program" "$strace_options" "$recent_pid"




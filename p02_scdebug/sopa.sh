#!./ptbash

help() {
  echo "Uso: scdebug [-h] [-sto arg] [-v | -vall] [-nattch program] [prog [arg1 …]]"
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
  pid=$(pgrep -o -u $USER "$program" | tail -n 1)
  if [ -z "$pid" ]; then
      echo "No se encontró un proceso en ejecución con el nombre: $program."
      exit 1
    fi
  echo "$pid"
}

# Ejecutar strace (con nattch o sin nattch)
run_strace() {
  # argv1 = programa
  # argv2 = opciones del strace
  local program="$1"
  local strace_options="$2" # Opciones de strace como una cadena
  local nattch_pid="$3"
  # Llamar a la función crear_subdirectorio
  output_file=$(crear_subdirectorio "$program")
  # Verificar si la opción -nattch está habilitada
  if [ -n "$nattch_pid" ]; then
    # Ejecutar strace en el proceso especificado
    strace $strace_options -p "$nattch_pid" -o "$output_file" & sleep 0.1> "$output_file"
  else
    # Ejecutar el strace con las opciones
    strace $strace_options -o "$output_file" "$program" &
  fi
}

# Función para matar los procesos trazadores del ususario
MatarProcesos() {
  for process_pid in $(ps -u $USER -o pid=); do
    tracer_pid=$(awk 'NR==8' /proc/$process_pid/status 2> /dev/null | awk '{print $2}')
    # Buscamos los procesos que estén siendo ejecutados
    if [ "$tracer_pid" != "0" ] && [ ! -z "$tracer_pid" ]; then
      # Matamos al proceso trazador y luego el proceso trazado
      kill $tracer_pid
      kill $process_pid
      echo "Eliminando el proceso con PID: $process_pid"
    fi
  done;
}


# Función para mostrar información sobre los procesos del usuario.
user_process() {
  echo "-----------------------------------------------------------"
  echo "    PROCESOS DEL USUARIO (PID - NOMBRE DEL PROCESO)"
  echo "-----------------------------------------------------------"
  ps -U $USER -o pid,comm --sort=start
}


# main
user_process
strace_options=()
attach_program=""
recent_pid=""
while [ -n "$1" ]; do
  opcion="$1"
  case "$opcion" in
    -h)
      help
      exit 0
    ;;
    -k)
      MatarProcesos # Matar los procesos trazadores
      exit 0
    ;;
    -sto)
      strace_options="$2" # Almacenar las opciones del strace
    ;;
    -nattch)
      attach_program="$1" # Verificar si se quiere hacer un attach al programa
    ;;
    *)
      program="$1" # Programa
    ;;
  esac
  shift
done
echo "$strace_options" 
echo "$attach_program" 
echo "$program"
# Si se proporciona la opción -nattch, obtener el PID del proceso más reciente
if [ -n "$attach_program" ]; then
  recent_pid=$(get_recent_pid "$program")
  echo "$recent_pid"
fi
run_strace "$program" "$strace_options" "$recent_pid"
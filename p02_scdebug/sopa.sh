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


# Función para obtener el nombre del comando dado el PID
get_command_name() {
  local pid="$1"
  local command_name
  command_name=$(ps -o comm= -p "$pid")
  echo "$command_name"
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
    eval "strace $strace_options -p $nattch_pid -o $output_file" 2>&1
  else
    # Ejecutar el strace con las opciones
    eval "strace $strace_options -o $output_file $program" 2>&1
  fi
}


# Hacer attach a los procesos según los PIDS
AttachPids() {
 # Obtener la lista de PID proporcionados como argumentos
 local pids=$(pgrep ...)
 for pid in "$pids"; do
   # Comprobar si el PID es válido
   if [ -d "/proc/$pid" ]; then
     local cmd_file="/proc/$pid/cmdline"
     local progtoattach=$(tr '\0' ' ' < "$cmd_file" | awk '{print $1}')
     if [ -n "$progtoattach" ]; then
       output_file=$(crear_subdirectorio "$progtoattach")
       # Ejecuta strace en modo attach al proceso especificado por PID.
       strace $strace_options -p "$pid" -o "$output_file" & sleep 0.1 > "$output_file"
     fi
   fi
 done
 exit 0
}


# Función para matar los procesos trazadores del ususario
MatarProcesos() {
  for process_pid in $(ps -u $USER -o pid=); do
    tracer_pid=$(awk 'NR==8' /proc/$process_pid/status 2> /dev/null | awk '{print $2}')
    # Buscamos los procesos que estén siendo ejecutados
    if [ "$tracer_pid" != "0" ] && [ ! -z "$tracer_pid" ]; then
      # Matamos al proceso trazador y luego el proceso trazado
      kill $tracer_pid 2> /dev/null
      kill -9 $process_pid 2> /dev/null
    fi
  done;
}

# Función para ver la última traza que se a hecho
VerUltimaTraza() {
  # argv1 = programa
  local progtoquery="$1"
  local base_dir="$HOME/.scdebug/$progtoquery"
  local latest_file=$(ls -t "$base_dir" | head -1)
  if [ -z "$latest_file" ]; then
    echo "No se encontraron trazas para el programa: $progtoquery."
    exit 1
  fi
  local latest_trace_file="$base_dir/$latest_file"
  local latest_trace_time=$(stat -c %y "$latest_trace_file")
  echo "=============== COMMAND: $progtoquery ======================="
  echo "=============== TRACE FILE: $latest_file ======================="
  echo "=============== TIME: $latest_trace_time ======================="
  cat "$latest_trace_file"
}


# Función para mostrar todas las trazas de un programa en orden de más reciente a más antiguo.
VerTodasLasTrazas() {
  # argv1 = programa
  local program="$1"
  local debug_dir="$HOME/.scdebug/$program"

  # Verificar que existe el directorio
  if [ ! -d "$debug_dir" ]; then
    echo "El directorio $debug_dir no existe."
    exit 1
  fi

  # Obtén la lista de archivos en el directorio ordenados por tiempo de modificación (más reciente a más antiguo)
  file_list=$(find "$debug_dir" -maxdepth 1 -type f -exec stat --format="%Y %n" {} + | sort -n | awk '{print $2}')

  # Itera sobre los archivos y muestra la cabecera y el contenido
  for file in $file_list; do
    echo "=============== COMMAND: $program ==============="
    echo "=============== TRACE FILE: $file ==============="
    file_mod_time=$(date -r "$file")
    echo "=============== TIME: $file_mod_time ==============="
    cat "$file"
  done
}


# Función para mostrar información sobre los procesos del usuario.
user_process() {
  echo "-----------------------------------------------------------"
  echo "    PROCESOS DEL USUARIO (PID - NOMBRE DEL PROCESO)"
  echo "-----------------------------------------------------------"
  # Obtén el ID de usuario actual
user_id=$(id -u)

  # Utiliza ps para obtener la lista de procesos del usuario actual
  # Filtra los procesos que tienen TracerPid distinto de 0 (están siendo trazados)
  ps -U $user_id -o pid,comm --no-headers | while read -r pid name; do
  if [ -f "/proc/$pid/status" ]; then
    tracer_pid=$(cat "/proc/$pid/status" | awk -F '\t' '/TracerPid/ {print $2}')
      if [[ "$tracer_pid" =~ ^[0-9]+$ && "$tracer_pid" -ne 0 ]]; then
        echo "$pid $name"
      fi
    fi
  done
}


# main
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
      strace_options=$2 # Almacenar las opciones del strace
    ;;
    -nattch)
      # attach_program="$1" # Verificar si se quiere hacer un attach al programa
      while [ "$1" != "" ] && [ "$1" != "-pattch" ]; do
        shift
        if [ "$1" = "" ] || [ "$1" = "-pattch" ]; then
          break;
        fi
        recent_pid=$(get_recent_pid $1)
        # cambiar el separador, para que a la hora de enviar los argumentos, no separe las strings por espacios
        IFS=:
        run_strace $1 $strace_options $recent_pid & sleep 0.1
      done
    ;;
    -pattch)
      while [ "$1" != "" ]; do
        shift
        if [ "$1" = "" ]; then
          break;
        fi
        pid="$1"
        command_name=$(get_command_name "$pid")
        strace -p "$pid" -o "$command_name" &
      done
    ;;
    -v)
      progtoquery="$2"
      VerUltimaTraza "$progtoquery" # Ver la última traza que se le ha echo al programa proporcionado
      exit 0
    ;;
    -vall)
      progtoqery="$2"
      VerTodasLasTrazas "$progtoqery"
      exit 0
    ;;
    *)
      program="$1" # Programa
    ;;
  esac
  # Mostrar los procesos que están siendo ejecutados
  user_process
  shift
done

# Si no se introduce nada mostrar mensaje de ayuda
if [ -z "$program" ]; then
  echo "Pruebe -h para más información"
  exit 0
fi
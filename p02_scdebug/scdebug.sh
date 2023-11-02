#!/bin/bash

# Función de ayuda para mostrar información sobre cómo usar el script.
help() {
  echo "scdebug [-h] [-sto opciones] [-nattach progtoattach] [prog [arg1 ...]]"
  echo "-h: Muestra este mensaje de ayuda."
  echo "-sto opciones: Opciones personalizadas para strace (encerradas entre comillas)."
  echo "-nattch progtoattach: Monitoriza un proceso existente por nombre."
  echo "-v: Muestra la última traza de un programa."
  echo "-vall: Muestra todas las trazas de un programa, ordenadas de más reciente a más antigua."
}

# Función para mostrar información sobre los procesos del usuario.
ProcesosDeUsuario() {
  echo "-----------------------------------------------------------"
  echo "    PROCESOS DEL USUARIO (PID - NOMBRE DEL PROCESO)"
  echo "-----------------------------------------------------------"
  ps -U $USER -o pid,comm --sort=start
}


# Función para adjuntar a un proceso en ejecución con strace.
AttachProceso() {
  local progtoattach="$1"
  # Encuentra el PID del proceso más reciente ejecutado por el usuario con el nombre especificado.
  local newest_pid=$(pgrep -o -u $USER "$progtoattach" | tail -n 1)
  if [ -z "$newest_pid" ]; then
    echo "No se encontró un proceso en ejecución con el nombre: $progtoattach."
    exit 1
  fi
  local base_dir="$HOME/.scdebug"
  local uuid=$(uuidgen)
  local program_dir="$base_dir/$progtoattach"
  if [ ! -d "$program_dir" ]; then
    mkdir -p "$program_dir"
  fi
  local output_file="$program_dir/trace_$uuid.txt"
  # Ejecuta strace en modo attach al proceso encontrado.
  local strace_command="strace -o $output_file ${strace_options} -p $newest_pid"
  $strace_command &
  local strace_pid=$!
  if [ $? -ne 0 ]; then
    echo "Error: strace ha producido un error. Consulta el archivo $output_file para más detalles."
    exit 1
  else
    echo "Ejecución exitosa en modo attach. Los resultados se guardan en $output_file."
  fi
}

# Función para adjuntar a un proceso en ejecución con strace.
AttachProcesos() {
  local program_names=("$@")
  
  for progtoattach in "${program_names[@]}"; do
    # Encuentra el PID del proceso más reciente ejecutado por el usuario con el nombre especificado.
    local newest_pid=$(pgrep -o -u $USER "$progtoattach" | tail -n 1)
    if [ -z "$newest_pid" ]; then
      echo "No se encontró un proceso en ejecución con el nombre: $progtoattach."
    else
      local base_dir="$HOME/.scdebug"
      local uuid=$(uuidgen)
      local program_dir="$base_dir/$progtoattach"
      if [ ! -d "$program_dir" ]; then
        mkdir -p "$program_dir"
      fi
      local output_file="$program_dir/trace_$uuid.txt"
      # Ejecuta strace en modo attach al proceso encontrado.
      local strace_command="strace -o $output_file ${strace_options} -p $newest_pid"
      $strace_command &
      local strace_pid=$!
      if [ $? -ne 0 ]; then
        echo "Error: strace ha producido un error. Consulta el archivo $output_file para más detalles."
      else
        echo "Ejecución exitosa en modo attach para el proceso: $progtoattach. Los resultados se guardan en $output_file."
      fi
    fi
  done
}

# Función para adjuntar a procesos en ejecución con strace a partir de los PIDs especificados.
AttachPids() {
  local pids=("$@")

  for pid in "${pids[@]}"; do
    # Comprobar si el PID es válido
    if [ -d "/proc/$pid" ]; then
      local cmd_file="/proc/$pid/cmdline"
      local progtoattach=$(tr '\0' ' ' < "$cmd_file" | awk '{print $1}')
      if [ -n "$progtoattach" ]; then
        local base_dir="$HOME/.scdebug"
        local uuid=$(uuidgen)
        local program_dir="$base_dir/$progtoattach"
        if [ ! -d "$program_dir" ]; then
          mkdir -p "$program_dir"
        fi
        local output_file="$program_dir/trace_$uuid.txt"
        # Ejecuta strace en modo attach al proceso especificado por PID.
        local strace_command="strace -o $output_file ${strace_options} -p $pid"
        $strace_command &
        local strace_pid=$!
        if [ $? -ne 0 ]; then
          echo "Error: strace ha producido un error. Consulta el archivo $output_file para más detalles."
        else
          echo "Ejecución exitosa en modo attach para el proceso (PID: $pid, Comando: $progtoattach). Los resultados se guardan en $output_file."
        fi
      else
        echo "No se pudo obtener el nombre del comando para el PID: $pid."
      fi
    else
      echo "El PID $pid no es válido o el proceso no existe."
    fi
  done
}

# Función para ver la última traza de un programa
VerUltimaTraza() {
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
  local progtoquery="$1"
  local base_dir="$HOME/.scdebug/$progtoquery"
  if [ ! -d "$base_dir" ]; then
    echo "No se encontraron trazas para el programa: $progtoquery."
    exit 1
  fi
  local trace_files=($(ls -t "$base_dir"))
  if [ ${#trace_files[@]} -eq 0 ]; then
    echo "No se encontraron trazas para el programa: $progtoquery."
    exit 1
  fi
  for trace_file in "${trace_files[@]}"; do
    local trace_path="$base_dir/$trace_file"
    local trace_time=$(stat -c %y "$trace_path")
    echo "=============== COMMAND: $progtoquery ======================="
    echo "=============== TRACE FILE: $trace_file ======================="
    echo "=============== TIME: $trace_time ======================="
    cat "$trace_path"
    echo "-----------------------------------------------------------"
  done
}

# Función para intentar terminar todos los procesos trazadores y trazados con la señal KILL.
MatarProcesos() {
  # Obtener el nombre de usuario actual
  current_user=$(whoami)

  # Obtener una lista de todos los PID de los procesos trazadores
  tracer_pids=$(pgrep -u $current_user)

  for pid in $tracer_pids; do
    if [ $pid != $$ ]; then  # No mate el propio script
      echo "Terminando proceso trazador: $pid"
      kill -9 $pid
    fi
  done

  # Obtener una lista de todos los PID de los procesos trazados
  traced_pids=$(pgrep -u $current_user -P 1)  # Procesos no trazadores con padre igual a 1 (init)

  for pid in $traced_pids; do
    if [ $pid != $$ ]; then  # No mate el propio script
      echo "Terminando proceso trazado: $pid"
      kill -9 $pid
    fi
  done
}

# Función para ejecutar y monitorear un programa con strace.
run_strace() {
  local prog="$1"
  local args=("$@")
  local base_dir="$HOME/.scdebug"
  local uuid=$(uuidgen)
  local program_dir="$base_dir/$prog"
  if [ ! -d "$program_dir" ]; then
    mkdir -p "$program_dir"
  fi
  local output_file="$program_dir/trace_$uuid.txt"
  # Ejecuta strace para rastrear el programa con opciones personalizadas si se proporcionan.
  local strace_command="strace -o $output_file ${strace_options} $prog ${args[@]}"
  $strace_command &
  local strace_pid=$!
  if [ $? -ne 0 ]; then
    echo "Error: strace ha producido un error. Consulta el archivo $output_file para más detalles."
    exit 1
  else
    echo "Ejecución exitosa. Los resultados se guardan en $output_file."
  fi
}
# Modificación
print_traces() {
  local base_dir="$HOME/.scdebug" # accedo al driectorio base
  
  echo "DIR NUM FICHERO_MAS_RECIENTE"
  echo "------------------------------------------------"
  
  for subdir in "$base_dir"/*; do
    if [ -d "$subdir" ]; then
      local dir_name=$(basename "$subdir")
      local num_files=$(find "$subdir" -type f | wc -l) # Número de archivos del subdirectorio
      local latest_file=$(ls -t "$subdir" | head -1) # Fichero mas reciente
      local latest_file_path="$subdir/$latest_file" 
      local latest_trace_time=$(date -d @"$(stat -c %Y "$latest_file_path")" "+%b %e %H:%M") # Tiempo más reciente del fichero
      echo "$dir_name $num_files $latest_trace_time $latest_file"
    fi
  done
  echo "------------------------------------------------"
}

# Visualizar los procesos de usuario
ProcesosDeUsuario
# Información de todos los subdirectorios
print_traces

opcion="$1"
case "$opcion" in
  -h)
    help
  ;;
  -k)
    MatarProcesos # Matar todos los procesos
  ;;
  -sto)
    strace_options="$2" # Opciones para el strace
    program_to_strace="$3" # Programa para hacer el strace
    run_strace "$program_to_strace"
    if [ "$3" == "-nattch" ]; then
      progtoattach="$4"
      AttachProceso "$progtoattach" # Hacer el nattch
    fi
  ;;
  -nattch)
    shift
    program_names=("$@")
    AttachProcesos "${program_names[@]}"
  ;;
  -pattch)
  shift
    pids=("$@")
    AttachPids "${pids[@]}"
  ;;
  -v)
    shift
    progtoquery="$1"
    VerUltimaTraza "$progtoquery"
    exit 0
  ;;
  -vall)
    shift
    progtoquery="$2"
    VerTodasLasTrazas "$progtoqery"
    exit 0
  ;;
esac
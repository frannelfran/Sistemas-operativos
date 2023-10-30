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
show_user_processes() {
  echo "-----------------------------------------------------------"
  echo "    PROCESOS DEL USUARIO (PID - NOMBRE DEL PROCESO)"
  echo "-----------------------------------------------------------"
  ps -U $USER -o pid,comm --sort=start
}


# Función para adjuntar a un proceso en ejecución con strace.
attach_to_process() {
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

# Función para ver la última traza de un programa
view_latest_trace() {
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

# Función para intentar terminar todos los procesos trazadores y trazados con la señal KILL.
kill_all_processes() {
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
  shift
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

opcion="$1"
case "$opcion" in
  -h)
    help
  ;;
  -k)
    kill_all_processes # Matar todos los procesos
  ;;
  -sto)
    shift
    strace_options="$1" # Lanzar el strace
    shift
  ;;
  -nattch)
    shift
    progtoattach="$1"
    attach_to_process "$progtoattach" # Ejecutar el nttach
  ;;
  -v)
    shift
    progtoquery="$1"
    view_latest_trace "$progtoquery"
    exit 0
  ;;
  *)
    run_strace "$@"
  ;;
esac
show_user_processes
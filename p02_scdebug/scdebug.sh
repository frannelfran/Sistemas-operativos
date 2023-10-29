#!/bin/bash

# Función de ayuda para mostrar información sobre cómo usar el script.
help() {
  echo "scdebug [-h] [-sto opciones] [-nattch progtoattach] [prog [arg1 ...]]"
  echo "-h: Muestra este mensaje de ayuda."
  echo "-sto opciones: Opciones personalizadas para strace (encerradas entre comillas)."
  echo "-nattch progtoattach: Monitoriza un proceso existente por nombre."
}

# Función para mostrar información sobre los procesos del usuario.
show_user_processes() {
  echo "Procesos del usuario (PID - Nombre del Proceso):"
  ps -U $USER -o pid,comm --sort=start
}

# Función para mostrar información detallada sobre los procesos, incluyendo trazadores y tracees.
show_all_processes() {
  echo "Procesos (PID - Nombre del Proceso - Tracer PID - Tracer Nombre):"
  for pid in $(ps -U $USER -o pid --no-headers); do
    comm=$(ps -p $pid -o comm --no-headers)
    tracer_pid=$(cat /proc/$pid/status | grep TracerPid | awk '{print $2}')
    tracer_name=$(ps -p $tracer_pid -o comm --no-headers)
    echo "$pid - $comm - $tracer_pid - $tracer_name"
  done
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

# Función para intentar terminar todos los procesos trazadores y trazados con la señal KILL.
kill_all_processes() {
  # Terminar todos los procesos trazados del usuario con la señal KILL.
  for pid in $(ps -U $USER -o pid --no-headers); do
    kill -9 $pid
  done

  # Terminar todos los procesos trazadores del usuario con la señal KILL.
  for pid in $(ps -U $USER -o pid --no-headers); do
    tracer_pid=$(cat /proc/$pid/status | grep TracerPid | awk '{print $2}')
    if [ "$tracer_pid" != "0" ]; then
      kill -9 $tracer_pid
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
  -v)
    show_user_processes
  ;;
  -vall)
    show_all_processes
  ;;
  -k)
    kill_all_processes
  ;;
  -sto)
    shift
    strace_options="$1"
    shift
  ;;
  -nattach)
    shift
    progtoattach="$1"
    attach_to_process "$progtoattach"
  ;;
  *)
    run_strace "$@"
  ;;
esac
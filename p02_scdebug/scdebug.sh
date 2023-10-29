#!/bin/bash

# Función de ayuda para mostrar información sobre cómo usar el script.
help() {
  echo "scdebug [-h] [-sto opciones] [-nattch progtoattach] [prog [arg1 ...]]"
  echo "-h: Muestra este mensaje de ayuda."
  echo "-sto opciones: Opciones personalizadas para strace (encerradas entre comillas)."
  echo "-nattch progtoattach: Monitoriza un proceso existente por nombre."
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
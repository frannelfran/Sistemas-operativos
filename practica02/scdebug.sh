#!/bin/bash

option=$1
help() {
  echo "Uso: scdebug [-h] [-sto arg] [-v | -vall] [-nattch progtoattach] [prog [arg1 …]]"
  exit 0
}

run_strace() {
  local program="$1"
  local output_dir=".scdebug/$program"
  local output_file="$output_dir/trace_$(uuidgen).txt"
  mkdir -p "$output_dir"
  shift
  strace "$@" -o "$output_file" "$program"
  if [ $? -ne 0 ]; then
    echo "Error al ejecutar strace para $program." >&2
    exit 1
  fi
  echo "strace ha finalizado para $program. Resultado en $output_file"
}

attach_strace() {
  local program_name="$1"
  local output_dir=".scdebug/$program_name"
  local output_file="$output_dir/trace_$(uuidgen).txt"
  mkdir -p "$output_dir"

  # Obtener el PID del proceso más reciente con el nombre del programa
  local pid
  pid=$(pgrep -n -f "$program_name")

  if [ -z "$pid" ]; then
    echo "No se encontraron procesos en ejecución con el nombre '$program_name'."
    exit 1
  fi

  strace -c -e file -p "$pid" -o "$output_file" &
  local strace_pid=$!

  echo "strace está monitoreando el proceso $pid en segundo plano."
  echo "Resultado en $output_file"
}

# Menú de opciones
case $option in
	-h)
    help
	;;
	-sto)
		sto_option="$2"
		shift 2
	;;
  -nattch)
  if [ -n "$sto_option" ]; then
    attach_strace "$1"
  else
    attach_strace "$1"
  fi
  ;;
esac

# Ejecutar el strace con las opciones marcadas
if [ -n "$sto_option" ]; then
  run_strace "$1" $sto_option
else
  run_strace "$1" "$@"
fi
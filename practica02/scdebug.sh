#!/bin/bash

# Función para ejecutar strace
run_strace() {
  program="$1"
  args=("${@:2}")
  options=("-o" "$output_dir/trace_$uuid.txt")

  # Crear el directorio de salida si no existe
  mkdir -p "$output_dir"

  strace "${options[@]}" "$program" "${args[@]}" &
  strace_pid=$!

  wait "$strace_pid"

  if [ "$?" -ne 0 ]; then
    echo "Error al ejecutar strace."
    exit 1
  fi

  echo "Strace en segundo plano en ejecución, salida en $output_dir/trace_$uuid.txt"
}

# Función para hacer attach a un proceso
attach_strace() {
  program="$1"
  options=("${@:2}")

  # Obtener el PID del proceso más reciente
  latest_pid=$(pgrep -u $USER "$program" | tail -n 1)

  if [ -z "$latest_pid" ]; then
    echo "No se encontraron procesos de $program en ejecución."
    return
  fi

# Modificación
  echo "Proceso $program más reciente encontrado (PID $latest_pid)."
  run_strace "$program" "-p $latest_pid" "${options[@]}"
  echo "Lista de PIDs para $program:"
  for pid in "${pid_list[@]}"; do
    echo "  $pid"
  done
  read -p "Elija el PID al que desea enganchar strace: " selected_pid

  # Revisar que el PID esta dentro de las opciones
  if [[ ! " ${pid_list[@]} " =~ " ${selected_pid} " ]]; then
    echo "PID no válido. Saliendo."
    exit 1
  fi

  echo "Enganchando strace al proceso con PID $selected_pid..."
  run_strace "$program" "-p $selected_pid" "${options[@]}"
}

  program="$1"
  args=("${@:2}")
  sto_option=""
  output_dir="$HOME/.scdebug/$program"
  uuid=$(uuidgen)

  # Función de ayuda
  help() {
    echo "scdebug [-h] [-sto arg] [-v | -vall] [-nattch progtoattach] [prog [arg1 …]]"
    exit 1
  }

  # Dependiendo de la opcion que se elija se hace una cosa u otra
case "$1" in
  -h)
    help
  ;;
  -sto)
    sto_option="$2"
    shift 2
  ;;
  -nattch)
    attach_strace "$2" $sto_option
    exit 0
  ;;
  *)
    break
    ;;
  esac

run_strace "$program" "${args[@]}" $sto_option

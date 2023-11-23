#include <iostream>
#include <cstdlib>
#include <vector>
#include <string>
#include <iterator>
#include <optional>
#include <string_view>
#pragma once

struct program_options {
  bool show_help = false;
  bool activar_escucha = false;
  std::string output_filename;
};

/**
 * @brief Manejar las opciones del programa
 * @param argc Número de argumentos
 * @param argv Array donde se almacenan los argumentos
 * @return Objeto options de la estructura program_options
*/

std::optional<program_options> parse_args(int argc, char* argv[]) {
  if (argc < 2) {
    std::cerr << "Pruebe [-h | --help] para más información\n";
    return std::nullopt;
  }
  std::vector<std::string_view> args(argv + 1, argv + argc);
  program_options options;
  for (auto it = args.begin(), end = args.end(); it != end; ++it) {
    if (*it == "-h" || *it == "--help") { // Mostrar ayuda si se detecta -h o --help
      options.show_help = true;
    }
    if (*it == "-l") { // Activar el modo escucha si el usuario lo solicita
      options.activar_escucha = true;
    }
    if (std::next(it) == end) { // Nombre del archivo
      options.output_filename = *it;
    }
  }
  return options;
}

void print_usage() {
  std::cout << "Modo de empleo: ./netcp testfile" << std::endl;
}
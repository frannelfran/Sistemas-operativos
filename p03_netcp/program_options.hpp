#include <iostream>
#include <cstdlib>
#include <vector>
#include <string>
#include <experimental/optional>
#include <experimental/string_view>
#pragma once

struct program_options {
  bool show_help = false;
  std::string output_filename;
};

/**
 * @brief Manejar las opciones del programa
 * @param argc Número de argumentos
 * @param argv Array donde se almacenan los argumentos
 * @return Objeto options de la estructura program_options
*/

std::experimental::optional<program_options> parse_args(int argc, char* argv[]) {
  std::vector<std::experimental::string_view> args(argv + 1, argv + argc);
  program_options options;
  for (auto it = args.begin(); it != args.end(); ++it) {
    if (*it == "-h" || *it == "--help") {
      options.show_help = true;
    }
    else if (it++ != args.end()) {
      options.output_filename == *it;
    }
    else {
      std::cerr << "Error...\n";
      return std::experimental::nullopt;
    }
  }
  return options;
}

void print_usage() {
  std::cout << "Modo de empleo: ./netcp testfile" << std::endl;
}
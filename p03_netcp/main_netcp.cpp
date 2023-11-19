#include "netcp.hpp"
#include "program_options.hpp"

int main (int argc, char* argv[]) {
  auto options = parse_args(argc, argv);
  if (!options) {
    return EXIT_FAILURE;
  }
  // Mostrar la ayuda si el usuario la solicita
  if (options.value().show_help) {
    print_usage();
    return EXIT_SUCCESS;
  }
  std::string data_file = options.value().output_filename;
  
  

  
  

  return EXIT_SUCCESS;
}
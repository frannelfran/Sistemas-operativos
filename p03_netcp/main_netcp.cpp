#include "netcp.hpp"
#include "program_options.hpp"

int main (int argc, char* argv[]) {
  auto options = parse_args(argc, argv);
  if (!options) {
    return EXIT_FAILURE;
  }
  if (argc != 2) {
    std::cout << "Pruebe [-h | --help] para más información" << std::endl;
  }
  // Mostrar la ayuda si el usuario la solicita
  if (options.value().show_help) {
    print_usage();
    return EXIT_SUCCESS;
  }
  std::string fd = options.value();
  

  
  

  return EXIT_SUCCESS;
}
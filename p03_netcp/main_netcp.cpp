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
  // Comprobar que el archivo se puede abrir
  std::string data_file = options.value().output_filename;
  std::expected<int, std::error_code> open_file_result = open_file(data_file, O_RDONLY, 0666);
  int fd;
  if (open_file_result) {
    fd = *open_file_result;
  }
  else {
    std::error_code error = open_file_result.error();
    std::cerr << "Error: (" << error.value() << ") " << error.message();
    std::cerr << " No se ha podido abrir el fichero" << std::endl;
    return EXIT_FAILURE;
  }
  // Verififcar si el fichero supera los 1iKB
  

  
  
  

  
  

  return EXIT_SUCCESS;
}
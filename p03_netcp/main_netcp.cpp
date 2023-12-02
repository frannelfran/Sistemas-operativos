#include "netcp.hpp"
#include "program_options.hpp"

int main (int argc, char* argv[]) {
  auto options = parse_args(argc, argv);
  if (!options) {
    return EXIT_FAILURE;
  }
  
  // Mostrar la ayuda si el usuario la solicita
  if (options.value().show_help) {
    std::cout << "Modo de empleo: ./netcp testfile" << std::endl;
    return EXIT_SUCCESS;
  }

  // Activar escucha si el usuario lo solicita
  if (options.value().activar_escucha) {
  }
  // Modo normal
  else {
    std::error_code netcp_send_file_error = netcp_send_file(options.value().output_filename);
    if (!netcp_send_file_error) {
      std::cout << "Mensaje enviado correctamente" << std::endl;
    }
    else {
      std::cerr << "Error: (" << netcp_send_file_error.value() << ") ";
      std::cerr << " No se ha podido enviar el mensaje" << std::endl;
    }
  }

  return EXIT_SUCCESS;
}
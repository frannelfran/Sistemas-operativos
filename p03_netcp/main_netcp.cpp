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

  // Señales del programa
  struct sigaction term_action;
  term_action.sa_handler = &term_signal_handler;

  sigaction(SIGTERM, &term_action, NULL);
  sigaction(SIGINT, &term_action, NULL);
  sigaction(SIGHUP, &term_action, NULL);
  sigaction(SIGQUIT, &term_action, NULL);

  // Activar escucha si el usuario lo solicita
  if (options.value().activar_escucha) {
    std::error_code netcp_receive_file_error = netcp_receive_file(options.value().output_filename);
    if (!netcp_receive_file_error) {
      std::cout << "Mensaje recibido correctamente" << std::endl;
    }
    else {
      if (netcp_receive_file_error.value() == EINTR) {
        return EXIT_SUCCESS;
      }
      std::cerr << "No se ha podido recibir el mensaje" << std::endl;
    }
  }
  
  // Modo normal
  else {
    std::error_code netcp_send_file_error = netcp_send_file(options.value().output_filename);
    if (!netcp_send_file_error) {
      std::cout << "Mensaje enviado correctamente" << std::endl;
    }
    else {
      if (netcp_send_file_error.value() == EINTR) {
        return EXIT_SUCCESS;
      }
      std::cerr << "No se ha podido enviar el mensaje" << std::endl;
    }
  }
  return EXIT_SUCCESS;
}
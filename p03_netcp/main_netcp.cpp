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
    std::cerr << "Error: (" << error.value() << ") ";
    std::cerr << " No se ha podido abrir el fichero" << std::endl;
    return EXIT_FAILURE;
  }
  // Comprobar que no se produce ningún fallo a la hora de utilizar stat
  struct stat file_data;
  if (stat(data_file.c_str(), &file_data) == -1) {
    close(fd); // Cerrar el descriptor en caso de error
    std::cerr << "Error al obtener los datos" << std::endl;
    return EXIT_FAILURE;
  }
  // Comprobar que el tamaño del fichero no supera los 1iKB
  else {
    if (file_data.st_size > 1024) {
      std::cerr << "El archivo tiene un tamaño mayor de 1iKB" << std::endl;
      return EXIT_FAILURE;
    }
  }
  // Asignar el puerto y la dirección IP al socket y crearlo
  auto address = make_ip_address("10.6.128.106", 8080);
  auto result = make_socket(address.value());
  int socket_fd;
  if (result) {
    socket_fd = *result;
  }
  else {
    std::error_code error_socket = result.error();
    std::cerr << "Error: (" << error_socket.value() << ") ";
    std::cerr << " No se ha podido crear el socket" << std::endl;
    close(socket_fd); // Cerrar el socket
    return EXIT_FAILURE;
  }

  // Mandar un mensaje
  




  
  
  
  

  
  

  return EXIT_SUCCESS;
}
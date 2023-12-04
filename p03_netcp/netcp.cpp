#include "netcp.hpp"

/**
 * @brief Leer el número de bytes del fichero
 * @param fd Clave propia del fichero
 * @param buffer Buffer que contiene los bytes del fichero
 * @return Número de bytes que tiene el fichero
*/

std::error_code read_file(int fd, std::vector<uint8_t>& buffer) {
  ssize_t bytes_read = read(fd, buffer.data(), buffer.size()); // Leer los bytes del fichero
  if (bytes_read < 0) {
    return std::error_code(errno, std::system_category()); // Código de error de read_file
  }
  buffer.resize(bytes_read);
  return std::error_code(0, std::system_category()); // Devolver 0 en caso de éxito
}

/**
 * @brief Escribir en el buffer
 * @param fd Clave propia del fichero
 * @param buffer Buffer que contiene los bytes del fichero
*/

std::error_code write_file(int fd, std::vector<uint8_t>& buffer) {
  ssize_t bytes_write = write(fd, buffer.data(), buffer.size());
  if (bytes_write < 0) {
    return std::error_code(errno, std::system_category()); // Código de error al escribir los bytes
  }
  buffer.resize(bytes_write);
  return std::error_code(); // Devolver éxito
}

/**
 * @brief Abrir el fichero y obtener un descriptor
 * @param path Nombre del archivo
 * @param flags Operación que se le va a hacer al fichero
 * @param mode Permisos que va a tener el archivo
 * @return Descriptor del archivo
*/

std::expected<int, std::error_code> open_file(const std::string& path, int flags, mode_t mode) {
  int fd = open(path.c_str(), flags, mode);
  if (fd == -1) {
    std::error_code error(errno, std::system_category());
    return std::unexpected(error);
  }
  return fd;
}

/**
 * @brief Función para crear la dirección IP y el puerto del socket
 * @param ip_address Dirección IP
 * @param port Puerto
 * @return Dirección IP
*/

std::optional<sockaddr_in> make_ip_address(const std::optional<std::string> ip_address, uint16_t port) {
  struct sockaddr_in local_address{};
  local_address.sin_family = AF_INET; // Establecer el tipo de conexión
  local_address.sin_port = htons(port); // Establecer el puerto
  if (ip_address.has_value()) {
    if (inet_pton(AF_INET, ip_address.value().c_str(), &(local_address.sin_addr)) < 0) {
      std::cerr << "Error: IP Inválida" << std::endl;
      return std::nullopt;
    }
  }
  else {
    // Si no se proporciona una dirección IP, establecerla como INADDR_ANY.
    local_address.sin_addr.s_addr = INADDR_ANY;
  }
  return local_address;
}

/**
 * @brief Crear el socket
 * @param address Dirección IP
 * @return socket
*/

std::expected<int, std::error_code> make_socket(std::optional<sockaddr_in> address) {
  int socket_fd = socket(AF_INET, SOCK_DGRAM, 0); // Crear el cocket
  if (socket_fd < 0) {
    std::error_code error(errno, std::system_category());
    return std::unexpected(error);
  }
  int result;
  if (address.has_value()) {
    result = bind(socket_fd, reinterpret_cast<const sockaddr*>(&address.value()), sizeof(address));
    if (result < 0) {
      std::error_code error(errno, std::system_category());
      return std::unexpected(error);
    }
  }
  return socket_fd;
}

/**
 * @brief Función para comprobar que se ha enviado el mensaje
 * @param fd Descriptor del socket
 * @param message Mensaje a enviar
 * @param address Dirección donde se va a enviar el mensaje
 * @return Código dependiendo de si se ha enviado el mensaje o no
*/

std::error_code send_to(int fd, const std::vector<uint8_t>& message, const sockaddr_in& address) {
  ssize_t bytes_send = sendto(fd, message.data(), message.size(), 0, reinterpret_cast<const sockaddr*>(&address), sizeof(address));
  if (bytes_send < 0) {
    std::error_code error(errno, std::system_category());
    std::cerr << "Error para mandar el mensaje: " << error.message() << std::endl;
    return error;
  }
  return std::error_code();  // No se produció ningún error
}

/**
 * @brief Funcion para recibir el mensaje
 * @param fd Descriptor del socket
 * @param message Mensaje a recibir
 * @param address Dirección donde se va a recibir el mensaje
 * @return Código dependiendo de si se ha recibido el mensaje 
*/

std::error_code receive_from(int fd, std::vector<uint8_t>& message, sockaddr_in& address) {
  socklen_t src_lent = sizeof(address);
  ssize_t receive_bytes = recvfrom(fd, message.data(), message.size(), 0, reinterpret_cast<sockaddr*>(&address), &src_lent);
  if (receive_bytes < 0) {
    std::error_code error(errno, std::system_category());
    std::cerr << "Error al recibir el mensaje" << std::endl;
    return error;
  }
  message.resize(receive_bytes);
  return std::error_code();
}

/**
 * @brief Función principal del programa para enviar los datos del fichero
 * @param filename Nombre del fichero para enviar su contenido
*/

std::error_code netcp_send_file(const std::string& filename) {
  // Comprobar que el archivo se puede abrir
  std::expected<int, std::error_code> open_file_result = open_file(filename, O_RDONLY, 0666);
  int fd;
  if (open_file_result) {
    fd = *open_file_result;
  }
  else {
    std::error_code error = open_file_result.error();
    std::cerr << "Error: (" << error.value() << ") ";
    std::cerr << " No se ha podido abrir el fichero" << std::endl;
    return error;
  }

  // Comprobar que no se produce ningún fallo a la hora de utilizar stat
  struct stat file_data;
  if (stat(filename.c_str(), &file_data) == -1) {
    close(fd); // Cerrar el descriptor en caso de error
    std::cerr << "Error al obtener los datos" << std::endl;
    return std::error_code(errno, std::generic_category());
  }

  // Asignar el puerto y la dirección IP al socket y crearlo
  auto address = make_ip_address("127.0.0.1", 8080);
  auto result = make_socket(std::nullopt);
  int socket_fd;
  if (result) {
    socket_fd = *result;
  }
  else {
    std::error_code error_socket = result.error();
    std::cerr << "Error: (" << error_socket.value() << ") ";
    std::cerr << " No se ha podido crear el socket" << std::endl;
    close(socket_fd); // Cerrar el archivo
    return error_socket;
  }

  // Declaramos el buffer
  std::vector<uint8_t> buffer(1024);
  // Vamos enviando el contenido del fichero mientras no hayamos leído su final
  do {
    // Leer los fragmentos del fichero
    std::error_code read_file_error = read_file(fd, buffer);
    if (read_file_error) {
      std::cerr << "Error: (" << read_file_error.value() << ") ";
      std::cerr << " No se ha podido crear el buffer" << std::endl;
      return read_file_error; // Salir del bucle en caso de error
    }

    // Enviar los fragmentos del fichero
    std::error_code send_message_error = send_to(socket_fd, buffer, address.value());
    if (send_message_error) {
      std::cerr << "Error: (" << send_message_error.value() << ") ";
      std::cerr << "Error al mandar el mensaje" << std::endl;
      return send_message_error; // salir del bucle en caso de error
    }
    // Verificar que hemos llegado al final del archivo
  } while (!buffer.empty());

  // Liberar
  close(socket_fd); // Cerrar el socket
  close(fd); // Cerrar el archivo
  return std::error_code(); // Devolver éxito
}

/**
 * @brief Modo esucha del programa
 * @param filename Fichero que recibe los datos
*/

std::error_code netcp_receive_file(const std::string& filename) {
  std::expected<int, std::error_code> open_file_result = open_file(filename, O_WRONLY, 0666); // Abrir el archivo para escritura
  int fd;
  if (open_file_result) {
    fd = *open_file_result;
  }
  else {
    std::error_code error = open_file_result.error();
    std::cerr << "Error: (" << error.value() << ") ";
    std::cerr << " No se ha podido abrir el fichero" << std::endl;
    return error;
  }

  // Comprobar que no se produce ningún fallo a la hora de utilizar stat
  struct stat file_data;
  if (stat(filename.c_str(), &file_data) == -1) {
    close(fd); // Cerrar el descriptor en caso de error
    std::cerr << "Error al obtener los datos" << std::endl;
    return std::error_code(errno, std::generic_category());
  }

  // Asignar el puerto y la dirección IP al socket y crearlo
  auto address = make_ip_address("127.0.0.1", 8080);
  auto result = make_socket(address.value());
  int socket_fd;
  if (result) {
    socket_fd = *result;
  }
  else {
    std::error_code error_socket = result.error();
    std::cerr << "Error: (" << error_socket.value() << ") ";
    std::cerr << " No se ha podido crear el socket" << std::endl;
    close(socket_fd); // Cerrar el archivo
    return error_socket;
  }

  // Recibir fragmentos del fichero
  ssize_t bytes_write;
  do {
    // Recibir los fragmentos del fichero
    std::vector<uint8_t> buffer(1024);
    std::error_code error_receive_from = receive_from(socket_fd, buffer, address.value());
    if (error_receive_from) {
      std::cerr << "Error: (" << error_receive_from.value() << ") ";
      std::cerr << " No se ha podido recibir el mensaje" << std::endl;
      return error_receive_from; // salir si no se recibe el mensaje
    }

    bytes_write = buffer.size();
    // Escribir los fragmentos en el fichero
    std::error_code error_write_file = write_file(fd, buffer);
    if (error_write_file) {
      std::cerr << "Error: (" << error_write_file.value() << ") ";
      std::cerr << " No se ha podido escribir en el fichero" << std::endl;
      return error_write_file; // salir si no se puede escribir en el fichero
    }
  } while (bytes_write > 0);

  // Cerrar el socket y realizar otras operaciones necesarias
  close(socket_fd);
  close(fd);

  return std::error_code(); // Devolver éxito
}
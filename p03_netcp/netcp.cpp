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
 * @brief Fucnión para comprobar que se ha enviado el mensaje
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
  message.resize(100);
  size_t receive_bytes = recvfrom(fd, message.data(), message.size(), 0, reinterpret_cast<sockaddr*>(&address), &src_lent);
  if (receive_bytes < 0) {
    std::error_code error(errno, std::system_category());
    std::cerr << "Error al recibir el mensaje" << std::endl;
    return error;
  }
  message.resize(receive_bytes);
  return std::error_code();
}
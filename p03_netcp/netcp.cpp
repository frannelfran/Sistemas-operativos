#include "netcp.hpp"

/**
 * @brief Obtener una cadena según el valor de una variable
 * @param name Nombre de la cadena
 * @return Obtener una cadena con el valor de una variable, si la variable existe, en caso contrario devuelve una cadena vacía
*/

std::string getenv(const std::string& name) {
  char* value = ::getenv(name.c_str());
  if (value) {
    return std::string(value);
  }
  else {
    return std::string();
  }
}

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
    if (inet_pton(AF_INET, ip_address.value().c_str(), &(local_address.sin_addr)) <= 0) {
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
  int result = bind(socket_fd, reinterpret_cast<const sockaddr*>(&address.value()), sizeof(address));
  return result;
}

/**
 * @brief Función para convertir la IP a una cadena de string
 * @param address Dirección a cambiar
 * @return String que contiene la dirección y el puerto
*/

// std::string ip_address_to_string(const sockaddr_in& address) {}
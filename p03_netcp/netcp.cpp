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
 * @brief Abrir el fichero y obtener un 
*/

std::expected<int, std::error_code> open_file(const std::string& path, int flags, mode_t mode) {
  int fd = open(path.c_str(), flags, mode);
  if (fd == -1) {
    std::error_code error(errno, std::system_category());
    return std::unexpected(error);
  }
  return fd;
}
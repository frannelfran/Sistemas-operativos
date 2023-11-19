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
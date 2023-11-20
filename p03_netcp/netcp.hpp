#pragma once
#include <cstdlib>
#include <cstdint>
#include <unistd.h>
#include <fcntl.h>
#include <system_error>
#include <expected>
#include <vector>
#include <string>

std::string getenv(const std::string& value); // Obtener una cadena con el valor de una variable
std::error_code read_file(int fd, std::vector<uint8_t>& buffer); // Leer el buffer
std::expected<int, std::error_code> open_file(const std::string& path, int flags, mode_t mode); // Abrir el archivo

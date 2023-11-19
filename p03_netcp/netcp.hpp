#include <cstdlib>
#include <cstdint>
#include <unistd.h>
#include <iostream>
#include <system_error>
#include <vector>
#include <string>
#pragma once

std::string getenv(const std::string& value); // Obtener una cadena con el valor de una variable
std::error_code read_file(int fd, std::vector<uint8_t>& buffer); // Leer el biffer 
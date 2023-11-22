#include <iostream>
#include <cstdlib>
#include <cstdint>
#include <unistd.h>
#include <fcntl.h>
#include <system_error>
#include <expected>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/ip.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <optional>
#include <vector>
#include <string>
#pragma once

std::string getenv(const std::string& value); // Obtener una cadena con el valor de una variable
std::error_code read_file(int fd, std::vector<uint8_t>& buffer); // Leer el buffer
std::expected<int, std::error_code> open_file(const std::string& path, int flags, mode_t mode); // Abrir el archivo
std::string ip_address_to_string (const sockaddr_in& address); // Convertir la IP a string
std::optional<sockaddr_in> make_ip_address(const std::optional<std::string> ip_address, uint16_t port); // Crear direcciones sockaddr_in a partir de la IP y un número de puerto
std::expected<int, std::error_code> make_socket(std::optional<sockaddr_in> address); // Crear el socket
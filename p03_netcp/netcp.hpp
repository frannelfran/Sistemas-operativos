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
#include <atomic>
#include <optional>
#include <vector>
#include <string>
#pragma once

std::error_code read_file(int fd, std::vector<uint8_t>& buffer); // Leer el buffer
std::error_code write_file(int fd, std::vector<uint8_t>& buffer); // Escribir en el buffer
std::expected<int, std::error_code> open_file(const std::string& path, int flags, mode_t mode); // Abrir el archivo
std::optional<sockaddr_in> make_ip_address(const std::optional<std::string> ip_address, uint16_t port); // Crear direcciones sockaddr_in a partir de la IP y un número de puerto
std::expected<int, std::error_code> make_socket(std::optional<sockaddr_in> address); // Crear el socket
std::error_code send_to(int fd, const std::vector<uint8_t>& message, const sockaddr_in& address); // Enviar un mensaje
std::error_code receive_from(int fd, std::vector<uint8_t>& message, sockaddr_in& address); // Recibir un mensaje
std::error_code netcp_send_file(const std::string& filename); // Modo normal del programa
std::error_code netcp_receive_file(const std::string& filename); // Modo escucha del programa
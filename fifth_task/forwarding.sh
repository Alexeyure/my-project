#!/bin/bash

# Вводим переменные для конфигурации
CLIENT="name_client_server"        # Имя пользователя клиента для передачи ему конфигурационного файла
CLIENT_ADDRESS="ip_client"         # IP-адрес клиента для передачи ему конфигурационного файла 
CLIEN_OVPN=".ovpn"                # Введите название клиентского файла
# Отправляем файл .ovpn клиенту
scp ~/clients/files/$CLIENT_OVPN $CLIENT@$CLIENT_ADDRESS:~/ 
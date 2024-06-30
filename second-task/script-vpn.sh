#!/bin/bash

# Вводим переменные для конфигурации
USER="name_rsa_server"             # Имя пользователя для SSH подключения к серверу с easy-rsa
HOST="ip_rsa_server"               # IP-адрес для SSH подключения к серверу с easy-rsa
SERVER_ADDRESS="ip_vpn_server"     # IP-адрес для передачи файлов на OpenVPN сервер
REMOTE_USER="name_vpn_server"      # Имя пользователя для передачи файлов на OpenVPN сервер
CLIENT="name_client_server"        # Имя пользователя клиента для передачи ему конфигурационного файла
CLIENT_ADDRESS="ip_client"         # IP-адрес клиента для передачи ему конфигурационного файла 
TIMEOUT=10         # Тайм-аут подключения в секундах




# Обновляем список пакетов
sudo apt update
if [ $? -ne 0 ]; then
    echo "Ошибка при обновлении списка пакетов."
    exit 1
fi

# Устанавливаем OpenVPN, если он не установлен
if ! dpkg -l | grep -q openvpn; then
    sudo apt install openvpn -y
    if [ $? -ne 0 ]; then
        echo "Ошибка при установке пакета OpenVPN."
        exit 1
    else
        echo "OpenVPN успешно установлен."
    fi
else
    echo "OpenVPN уже установлен."
fi


# Устанавливаем и сохраняем необходимые права
sudo apt-get install iptables-persistent
sudo iptables -A INPUT -p udp --dport 1194 -j ACCEPT
sudo netfilter-persistent save

# Создаем необходимые директории
mkdir -p ~/clients/keys
mkdir -p ~/clients/files


# Подключение по SSH к удалённому серверу easy-rsa
ssh -o ConnectTimeout=$TIMEOUT $USER@$HOST


# Переходим в директорию easy-rsa
cd ~/easy-rsa


# Генерируем запрос сертификата для сервера и подписываем его
./easyrsa gen-req server nopass
if [ $? -ne 0 ]; then
    echo "Ошибка при генерации запроса сертификата для сервера."
    exit 1
fi

./easyrsa sign-req server server
if [ $? -ne 0 ]; then
    echo "Ошибка при подписывании запроса сертификата сервера."
    exit 1
fi


# Копируем сгенерированные сертификаты на удаленный сервер
scp pki/issued/server.crt $REMOTE_USER@$SERVER_ADDRESS:/etc/openvpn/server/
if [ $? -ne 0 ]; then
    echo "Ошибка при копировании server.crt на удаленный сервер."
    exit 1
fi

scp pki/ca.crt $REMOTE_USER@$SERVER_ADDRESS:/etc/openvpn/server/
if [ $? -ne 0 ]; then
    echo "Ошибка при копировании ca.crt на удаленный сервер."
    exit 1
fi

# Создаём директорию и меняем на неё права
mkdir -p ~/clients/keys
chmod -R 700 ~/clients


# Меняем права
sudo chown $USER:$USER ~/clients/keys

# Генерируем запрос сертификата для клиента
./easyrsa gen-req client-1 nopass
if [ $? -ne 0 ]; then
    echo "Ошибка при генерации запроса сертификата для клиента."
    exit 1
fi
sudo cp pki/private/client-1.key ~/clients/keys/
./easyrsa sign-req client client-1
if [ $? -ne 0 ]; then
    echo "Ошибка при подписывании запроса сертификата клиента."
    exit 1
fi


# Копируем клиентские сертификаты и ключи на сервер OpenVpn
scp pki/issued/client-1.crt $REMOTE_USER@$SERVER_ADDRESS:~/clients/keys/
scp pki/private/server.key $REMOTE_USER@$SERVER_ADDRESS:/etc/openvpn/server/
scp pki/ca.crt $REMOTE_USER@$SERVER_ADDRESS:~/clients/keys/


# Прекращаем ssh подключение
exit

# Меняем права
sudo chown $REMOTE_USER:$REMOTE_USER ~/clients/keys


# Генерируем ключ-файл ta.key и копируем его на сервер и в директорию клиентов
openvpn --genkey --secret ta.key
if [ $? -ne 0 ]; then
    echo "Ошибка при генерации ta.key."
    exit 1
fi
sudo cp ta.key /etc/openvpn/server/
sudo cp ta.key ~/clients/keys/
sudo chown $REMOTE_USER:$REMOTE_USER ~/clients/keys/ta.key


# Копируем и настраиваем файл конфигурации сервера OpenVPN
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/server/
if [ $? -ne 0 ]; then
    echo "Ошибка при копировании server.conf."
    exit 1
fi

sudo cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/clients/base.conf

# Устанавливаем deb-пакет vpn-config
sudo dpkg -i /home/$REMOTE_USER/vpn/deb/vpn-config_0.1-1_all.deb
if [ $? -ne 0 ]; then
    echo "Ошибка при установке deb-пакета vpn-config."
    exit 1
fi


# Применяем настройки
sudo sysctl -p
sudo ./iptables.sh ens3 udp 1194
sudo systemctl -f enable openvpn-server@server.service


chmod 700 ~/clients/make_config.sh
sudo chown $REMOTE_USER:$REMOTE_USER ~/clients/keys/ca.crt

./clients/make_config.sh client-1
if [ $? -ne 0 ]; then
    echo "Ошибка при выполнении скрипта make_config.sh."
    exit 1
fi

echo "Настройка OpenVPN сервера и клиентов завершена успешно."


scp ~/clients/files/client-1.ovpn $CLIENT@$CLIENT_ADDRESS:~/ 


 
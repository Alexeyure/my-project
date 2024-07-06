#!/bin/bash

# Функция для обработки ошибок
handle_error() {
    echo "Ошибка: $1"
    exit 1
}

# Название клиента
CLIENT_NAME=$1

# Удалённые серверы
EASY_RSA_SERVER="name@ip"                        # Укажите данные сервера с easy-rsa
OPENVPN_SERVER="name@ip"                         # Укажите данные сервера OpenVPN

# Пути к директориям на удалённых серверах 
EASY_RSA_PATH="~/easy-rsa"                       # Укажите путь к директории easy-rsa (~/ это домашняя директория)
OPENVPN_CLIENTS_PATH="~/clients/keys"            # Укажите путь к директории clients (~/ это домашняя директория)

if [ -z "$CLIENT_NAME" ]; then
    handle_error "Не указано имя клиента"
fi

# Создание каталога для клиента на сервере OpenVPN
ssh $OPENVPN_SERVER "mkdir -p ${OPENVPN_CLIENTS_PATH}/$CLIENT_NAME" || handle_error "Не удалось создать каталог для клиента на сервере OpenVPN"

# Переход в директорию EasyRSA и выполнение команд для создания сертификатов клиента на сервере EasyRSA
ssh $EASY_RSA_SERVER ь
cd $EASY_RSA_PATH || exit 1
./easyrsa init-pki || exit 1
./easyrsa gen-req $CLIENT_NAME nopass || exit 1
./easyrsa sign-req client $CLIENT_NAME || exit 1
EOF

if [ $? -ne 0 ]; then
    handle_error "Не удалось создать или подписать сертификаты на сервере EasyRSA"
fi

# Копирование необходимых файлов с сервера EasyRSA на сервер OpenVPN
scp $EASY_RSA_SERVER:$EASY_RSA_PATH/pki/private/${CLIENT_NAME}.key $OPENVPN_SERVER:${OPENVPN_CLIENTS_PATH}/$CLIENT_NAME/ || handle_error "Не удалось скопировать ключ клиента"
scp $EASY_RSA_SERVER:$EASY_RSA_PATH/pki/issued/${CLIENT_NAME}.crt $OPENVPN_SERVER:${OPENVPN_CLIENTS_PATH}/$CLIENT_NAME/ || handle_error "Не удалось скопировать сертификат клиента"
scp $EASY_RSA_SERVER:$EASY_RSA_PATH/pki/ca.crt $OPENVPN_SERVER:${OPENVPN_CLIENTS_PATH}/$CLIENT_NAME/ || handle_error "Не удалось скопировать сертификат CA"

# Создание клиентского конфигурационного файла на сервере OpenVPN
# Подключаемся к удалённом серверу OpenVPN
ssh $OPENVPN_SERVER 
# Переходим в директорию clients
cd clients
# После создания openVpn по инструкции из "second-task", у нас остался скрипт, который автоматизирует создание конфигурационного файла для клиента
./make_config.sh $CLIENT_NAME


if [ $? -ne 0 ]; then
    handle_error "Не удалось создать клиентский конфигурационный файл на сервере OpenVPN"
fi

echo "Сертификат для клиента ${CLIENT_NAME} успешно создан и сохранен в каталоге ${OPENVPN_CLIENTS_PATH}/$CLIENT_NAME на сервере OpenVPN"




#Если у вас нет скрипта ./make_config.sh , я предоставлю вам его ниже
#!/bin/bash
# First argument: Client identifier
#KEY_DIR=~/clients/keys
#OUTPUT_DIR=~/clients/files
#BASE_CONFIG=~/clients/base.conf
#cat ${BASE_CONFIG} \
#<(echo -e '<ca>') \
#${KEY_DIR}/ca.crt \
#<(echo -e '</ca>\n<cert>') \
#${KEY_DIR}/${1}.crt \
#<(echo -e '</cert>\n<key>') \
#${KEY_DIR}/${1}.key \
#<(echo -e '</key>\n<tls-crypt>') \
#${KEY_DIR}/ta.key \
#<(echo -e '</tls-crypt>') \
#> ${OUTPUT_DIR}/${1}.ovpn
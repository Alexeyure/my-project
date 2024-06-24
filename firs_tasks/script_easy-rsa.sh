#!/bin/bash

# Проверяем наличие Easy-RSA и, если не установлен, скачиваем его
if [ ! -d "/usr/share/easy-rsa" ]; then
    echo "Easy-RSA не установлен. Производится установка..."
    sudo apt-get update
    sudo apt-get install easy-rsa -y
    if [ $? -ne 0 ]; then
        echo "Ошибка: Не удалось установить Easy-RSA. Проверьте подключение к интернету или выполните установку вручную."
        exit 1
    fi
    echo "Easy-RSA успешно установлен."
fi

# Создаем директорию для Easy-RSA
mkdir ~/easy-rsa
if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось создать директорию ~/easy-rsa"
    exit 1
fi

# Создаем символьную ссылку на установленные файлы Easy-RSA
ln -s /usr/share/easy-rsa/* ~/easy-rsa/
if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось создать символьную ссылку на установленные файлы Easy-RSA"
    exit 1
fi

# Устанавливаем права на директорию
chmod 700 ~/easy-rsa/
if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось установить права на директорию ~/easy-rsa/"
    exit 1
fi

# Переходим в директорию Easy-RSA
cd ~/easy-rsa/
if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось перейти в директорию ~/easy-rsa/"
    exit 1
fi

# Инициализируем инфраструктуру открытого ключа PKI
./easyrsa init-pki
if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось инициализировать инфраструктуру PKI. Проверьте права доступа."
    exit 1
fi

# Копируем файл vars.example в vars
cp vars.example vars
if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось скопировать файл vars.example в vars"
    exit 1
fi

# Создаем файл options с новыми параметрами
cat << EOF > options
set_var EASYRSA_REQ_COUNTRY    "RU"
set_var EASYRSA_REQ_PROVINCE   "Moscow"
set_var EASYRSA_REQ_CITY       "Moscow"
set_var EASYRSA_REQ_ORG        "IT"
set_var EASYRSA_REQ_EMAIL      "adminrsa@example.com"
set_var EASYRSA_REQ_OU         "My_rsa_server"

set_var EASYRSA_ALGO           ec
set_var EASYRSA_DIGEST         "sha512"
EOF

# Добавляем новые параметры в файл vars
cat options >> ~/easy-rsa/vars
echo "Новые параметры успешно добавлены в файл vars"

# Создаем центр сертификации
./easyrsa build-ca
if [ $? -ne 0 ]; then
    echo "Ошибка: Не удалось создать центр сертификации"
    exit 1
fi

echo "Центр сертификации успешно создан"


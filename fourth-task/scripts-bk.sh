Шаблон скрипта для бэкопирования (на примере easy-rsa)


#!/bin/bash

# Параметры для исходного сервера (где находится Easy-RSA)
SOURCE_USER="name"
SOURCE_SERVER="ip"
SOURCE_DIR="/etc/openvpn/easy-rsa"

# Параметры для целевого сервера (где будет храниться бэкап)
DEST_USER="name"
DEST_SERVER="ip"
DEST_DIR="~backup/easy-rsa"

# Локальная временная директория для хранения бэкапа перед отправкой на целевой сервер
TEMP_DIR="/tmp/easy-rsa-backup"

# Функция для обработки ошибок
function handle_error {
    echo "Произошла ошибка в строке $1: $2"
    exit 1
}

# Создаем временную директорию для бэкапа, если она не существует
mkdir -p "$TEMP_DIR" || handle_error $? "Не удалось создать временную директорию $TEMP_DIR"

# Копируем файлы с исходного сервера в локальную временную директорию
scp -r "$SOURCE_USER@$SOURCE_SERVER:$SOURCE_DIR" "$TEMP_DIR" || handle_error $? "Не удалось скопировать файлы с $SOURCE_SERVER"

# Копируем файлы из временной директории на целевой сервер
scp -r "$TEMP_DIR/easy-rsa" "$DEST_USER@$DEST_SERVER:$DEST_DIR" || handle_error $? "Не удалось скопировать файлы на $DEST_SERVER"

# Удаляем временную директорию (игнорируем ошибки удаления)
rm -rf "$TEMP_DIR"

# Выводим сообщение о завершении операции
echo "Бэкап Easy-RSA с $SOURCE_SERVER на $DEST_SERVER завершен."




#Далее настраиваем cron 
crontab -e 
0 6 * * 1 ~/backup-easy-rsa.sh
# Скрипт будет выполняться каждый понедельник в 6 утра
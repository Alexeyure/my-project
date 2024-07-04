#!/bin/bash
REMOTE_USER="Введите имя удалённого сервера"
REMOTE_HOST="Введите ip-адрес удалённого сервера"


# Функция для обработки ошибок
handle_error() {
    echo "Ошибка при выполнении команды: $1"
    exit 1
}

# Проверка на root-доступ
if [ "$EUID" -ne 0 ]; then 
    echo "Пожалуйста, запустите скрипт с правами root"
    exit 1
fi

# Установка OpenSSH
echo "Установка OpenSSH..."
if [ -f /etc/debian_version ]; then
    apt-get update || handle_error "apt-get update"
    apt-get install -y openssh-server || handle_error "apt-get install -y openssh-server"
elif [ -f /etc/redhat-release ]; then
    yum install -y openssh-server || handle_error "yum install -y openssh-server"
    systemctl enable sshd || handle_error "systemctl enable sshd"
    systemctl start sshd || handle_error "systemctl start sshd"
else
    handle_error "Не удалось определить дистрибутив Linux. Установите OpenSSH вручную."
fi

# Создание SSH-ключа, если его нет
SSH_KEY="$HOME/.ssh/id_rsa"
if [ ! -f "$SSH_KEY" ]; then
    echo "Создание SSH-ключа..."
    ssh-keygen -t rsa -b 4096 -C "ваш_email@example.com" -f "$SSH_KEY" -N "" || handle_error "ssh-keygen"
fi

# Ввод данных для удалённого пользователя и хоста
read -p "Введите имя пользователя на удалённой машине: " REMOTE_USER
read -p "Введите адрес удалённой машины: " REMOTE_HOST

# Проверка доступности удалённого хоста
echo "Проверка доступности удалённого хоста..."
ping -c 1 "$REMOTE_HOST" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    handle_error "Удалённый хост $REMOTE_HOST недоступен."
fi

# Копируем публичный ключ на удалённую машину
echo "Копируем публичный ключ на удалённую машину..."
ssh-copy-id "$REMOTE_USER@$REMOTE_HOST"
if [ $? -ne 0 ]; then
    handle_error "Не удалось скопировать публичный ключ на удалённую машину."
else
    echo "Публичный ключ успешно скопирован на удалённую машину."
fi

# Уведомление об успешной настройке
echo "Теперь вы можете подключиться к удалённой машине с помощью:"
echo "ssh $REMOTE_USER@$REMOTE_HOST"
echo "Установка и настройка SSH завершены."


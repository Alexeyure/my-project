#!/bin/bash

USER="name"    # Имя пользователя для SSH подключения к серверу OpenVPN
HOST="ip"      # IP-адрес для SSH подключения к серверу OpenVPN


# Устанавливаем и сохраняем необходимые права
sudo apt-get install iptables-persistent
iptables -A INPUT -p tcp --dport 9090 -j ACCEPT
sudo netfilter-persistent save   

# СоздаЁм функцию для обработки ошибок
check_error() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}

# Установка Prometheus, Alertmanager и Node Exporter
sudo apt-get update
check_error "Не удалось обновить список пакетов"

sudo apt-get install -y prometheus prometheus-alertmanager prometheus-node-exporter
check_error "Не удалось установить Prometheus, Alertmanager, and Node Exporter"

# Установка дебпакета Prometheus с конфигурациями
sudo dpkg -i my-prometheus-conf_0.1-1_all.deb


# Подключение к серверу с OpenVPN для настройки node-exporter
ssh $USER@$HOST -p 22 
sudo apt-get update
sudo apt-get install prometheus-node-exporter


# Создание каталога для Node Exporter
sudo mkdir -p /etc/node_exporter
if [ $? -ne 0 ]; then
    echo "Ошибка: не удалось создать директорию /etc/node_exporter"
    exit 1
fi

# Установка пакета Node Exporter конфигурации
sudo dpkg -i my-node-exporter-conf_0.1-1_all.deb
if [ $? -ne 0 ]; then
    echo "Ошибка: не удалось установить дебпакет"
    exit 1
fi

# Выход из удаленной сессии
exit


echo "Скпипт выполнен успешно."

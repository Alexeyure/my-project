#!/bin/bash

# Функция для обработки ошибок
handle_error() {
    echo "Ошибка при выполнении команды: $1"
    exit 1
}

# Установка netfilter-persistent
echo "Установка netfilter-persistent..."
sudo apt-get update || handle_error "sudo apt-get update"
sudo apt-get install -y netfilter-persistent || handle_error "sudo apt-get install -y netfilter-persistent"

# Очищаем все правила
echo "Очищение всех iptables правил..."
iptables -F || handle_error "iptables -F"
iptables -X || handle_error "iptables -X"
iptables -Z || handle_error "iptables -Z"

# Разрешаем трафик на lo (loopback) интерфейсе
echo "Разрешение трафика на loopback-интерфейсе..."
iptables -A INPUT -i lo -j ACCEPT || handle_error "iptables -A INPUT -i lo -j ACCEPT"

# Разрешаем установленные и связанные соединения
echo "Разрешение установленных и связанных соединений..."
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT || handle_error "iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT"

# Разрешаем SSH доступ
echo "Разрешение SSH доступа на порт 22..."
iptables -A INPUT -p tcp --dport 22 -j ACCEPT || handle_error "iptables -A INPUT -p tcp --dport 22 -j ACCEPT"

# Сохраняем изменения
echo "Сохранение изменений для iptables..."
sudo netfilter-persistent save || handle_error "sudo netfilter-persistent save"

echo "Конфигурация iptables успешно обновлена и сохранена."
exit 0
 
echo "Конфигурация iptables успешно обновлена и сохранена."
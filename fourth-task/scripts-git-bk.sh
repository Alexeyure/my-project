Шаблон скрипта для бэкапа на GitHub (на примере easy-rsa)

#Генерируем GPG ключи 
gpg --full-generate-key


#!/bin/bash

# Параметры для Easy-RSA
EASY_RSA_DIR="~/easy-rsa"                               # Это путь к директории, где хранятся файлы Easy-RSA
BACKUP_FILE="~/tmp/easy-rsa-backup.tar.gz"              # Это путь и имя файла, который будет создан для хранения архива бэкапа.
ENCRYPTED_FILE="~/tmp/easy-rsa-backup.tar.gz.gpg"       # Это путь и имя файла для зашифрованного бэкапа.
GPG_RECIPIENT="email@example.com"                       # Электронная почта
GIT_REPO_DIR="~/git/repo"                               # Это локальная директория, где размещается Git репозиторий 
COMMIT_MESSAGE="Добавлен зашифрованный бэкап Easy-RSA"  # Это сообщение, которое будет использовано для коммита в Git

# Создание архива бэкапа
tar -czf "$BACKUP_FILE" -C "$EASY_RSA_DIR" . || { echo "Ошибка создания архива бэкапа."; exit 1; }

# Проверка наличия архива
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Архив бэкапа $BACKUP_FILE не найден."
    exit 1
fi

# Шифрование файла
gpg -e -r "$GPG_RECIPIENT" "$BACKUP_FILE" || { echo "Ошибка шифрования файла."; exit 1; }

# Проверка успешности шифрования
if [ ! -f "$ENCRYPTED_FILE" ]; then
    echo "Зашифрованный файл $ENCRYPTED_FILE не найден."
    exit 1
fi

# Копирование зашифрованного файла в директорию репозитория
cp "$ENCRYPTED_FILE" "$GIT_REPO_DIR" || { echo "Ошибка копирования зашифрованного файла в репозиторий."; exit 1; }

# Переход в директорию репозитория
cd "$GIT_REPO_DIR" || { echo "Ошибка перехода в директорию репозитория."; exit 1; }

# Добавление изменений в git
git add "$(basename "$ENCRYPTED_FILE")" || { echo "Ошибка добавления файла в git."; exit 1; }

# Коммит изменений
git commit -m "$COMMIT_MESSAGE" || { echo "Ошибка коммита изменений."; exit 1; }

# Отправка изменений в удаленный репозиторий
git push origin master || { echo "Ошибка отправки изменений в удаленный репозиторий."; exit 1; }

# Удаление временных файлов
rm -f "$BACKUP_FILE" "$ENCRYPTED_FILE"

# Вывод сообщения о завершении операции
echo "Бэкап Easy-RSA зашифрован и отправлен в репозиторий GitHub."





#Далее настраиваем crone
crontab -e
0 6 13 * * ./scripts-git-bk.sh
#Скрипт будет автоматически выполнятся 13 числа каждого мусяца в 6 утра 
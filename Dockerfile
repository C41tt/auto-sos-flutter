FROM mobiledevops/flutter-sdk-image:latest

# Фиксим ошибку прав доступа для git
USER root
RUN git config --global --add safe.directory /home/mobiledevops/.flutter-sdk

# Ставим рабочую директорию
WORKDIR /app

# Копируем файлы
COPY --chown=mobiledevops:mobiledevops . .

# Переключаемся на обычного пользователя, чтобы flutter не ругался
USER mobiledevops

# Запускаем получение пакетов
RUN flutter pub get
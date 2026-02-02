FROM mobiledevops/flutter-sdk-image:latest

# Разрешаем гит и работу под рутом для флаттера
USER root
RUN git config --global --add safe.directory /home/mobiledevops/.flutter-sdk

WORKDIR /app

# Копируем всё
COPY . .

# Главная магия: отключаем проверку рута через переменную окружения
ENV CHROME_EXECUTABLE=/usr/bin/google-chrome
ENV FLUTTER_ALLOW_HTTP=true

# Запускаем через флаг --suppress-analytics на всякий случай
RUN flutter pub get
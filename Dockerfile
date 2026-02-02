FROM mobiledevops/flutter-sdk-image:latest

USER root
RUN git config --global --add safe.directory /home/mobiledevops/.flutter-sdk

# Копируем всё в временную папку
WORKDIR /tmp/setup
COPY . .

# Магия: если файлы упали внутрь лишней папки, вытаскиваем их в корень /app
RUN if [ -d "auto-sos-flutter" ]; then mv auto-sos-flutter/* /app/ && mv auto-sos-flutter/.[!.]* /app/ ; else mv * /app/ && mv .[!.]* /app/ ; fi

WORKDIR /app

# Убеждаемся, что мы в корне проекта (где pubspec.yaml) и запускаем
RUN flutter pub get
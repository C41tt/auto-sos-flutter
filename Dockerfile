FROM mobiledevops/flutter-sdk-image:latest

USER root
RUN git config --global --add safe.directory /home/mobiledevops/.flutter-sdk

# Создаем папку app заранее
RUN mkdir -p /app

# Копируем всё во временную папку
WORKDIR /tmp/setup
COPY . .

# Перемещаем файлы. Теперь /app точно есть.
RUN if [ -d "auto-sos-flutter" ]; then mv auto-sos-flutter/* /app/ 2>/dev/null || true; mv auto-sos-flutter/.[!.]* /app/ 2>/dev/null || true; else mv * /app/ 2>/dev/null || true; mv .[!.]* /app/ 2>/dev/null || true; fi

WORKDIR /app

# Запускаем flutter pub get
RUN flutter pub get
# Используем образ с Flutter (хорошо работает на M1)
FROM mobiledevops/flutter-sdk-image:latest

WORKDIR /app
COPY . .
RUN flutter pub get
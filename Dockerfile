FROM mobiledevops/flutter-sdk-image:latest

USER root
RUN git config --global --add safe.directory /home/mobiledevops/.flutter-sdk

# Создаем папку вручную, чтобы она точно была
RUN mkdir -p /app
WORKDIR /app

# Копируем проект
COPY . .

# Оставляем контейнер работать, чтобы ты мог зайти
CMD ["tail", "-f", "/dev/null"]
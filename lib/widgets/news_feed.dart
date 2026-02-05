import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Новостная лента или экстренные оповещения в нижней части экрана
class NewsFeed extends StatefulWidget {
  const NewsFeed({super.key});

  @override
  State<NewsFeed> createState() => _NewsFeedState();
}

class _NewsFeedState extends State<NewsFeed> {
  // Заглушка для новостей. В реальном приложении здесь будет API/RSS парсинг.
  final List<Map<String, String>> _newsItems = [
    {'title': 'ИИ-помощник: Введите VIN для подбора запчастей.', 'url': 'https://example.com/ai'},
    {'title': 'Движение перекрыто из-за сильного снегопада на трассе А-3', 'url': 'https://example.com/snow'},
    {'title': 'Проверка связи: Система 112 работает в штатном режиме.', 'url': 'https://example.com/system'},
    {'title': 'Акция: СТО "Батыр" предлагает скидку 15% на ремонт ходовой.', 'url': 'https://example.com/sto'},
  ];
  
  // Вспомогательный метод для открытия ссылки
  Widget _buildNewsItem(String title, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Не удалось открыть ссылку: $url')),
            );
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Используем иконку в зависимости от типа новости
            Icon(
              title.contains('ИИ') ? Icons.flash_on : Icons.info_outline, 
              size: 18, 
              color: title.contains('ИИ') ? Colors.orange : Colors.blue
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title, 
                style: const TextStyle(fontSize: 14, decoration: TextDecoration.underline),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ConnectivityResult>(
      future: Connectivity().checkConnectivity(),
      builder: (context, snapshot) {
        // Показываем заглушку, если нет подключения
        if (snapshot.connectionState == ConnectionState.waiting || snapshot.data == ConnectivityResult.none) {
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Лента ИИ-помощника / Новости',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
                const Divider(height: 10, thickness: 1),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Нет подключения к Интернету.\nОтображение новостей недоступно.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        
        // Показываем ленту при наличии подключения
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.only(top: 10.0, left: 16.0, right: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Лента ИИ-помощника / Новости 📰',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
              const Divider(height: 10, thickness: 1),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: _newsItems.map((item) => _buildNewsItem(item['title']!, item['url']!)).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
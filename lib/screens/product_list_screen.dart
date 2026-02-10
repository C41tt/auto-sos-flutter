import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'cloud_service.dart'; // Подключаем наш сервис

class ProductListScreen extends StatelessWidget {
  final String categoryTitle; // "Двигатель", "Масла" и т.д.

  const ProductListScreen({super.key, required this.categoryTitle});

  Future<void> _callSeller(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final Uri url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1012),
      appBar: AppBar(
        title: Text(categoryTitle, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F1012),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // 📡 StreamBuilder слушает Firebase в реальном времени
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: CloudService.getProductsByCategory(categoryTitle),
        builder: (context, snapshot) {
          // 1. Идет загрузка
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.red));
          }

          // 2. Ошибка
          if (snapshot.hasError) {
            return Center(child: Text("Ошибка: ${snapshot.error}", style: const TextStyle(color: Colors.white)));
          }

          final products = snapshot.data ?? [];

          // 3. Пусто (нет товаров в этой категории)
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 60, color: Colors.white24),
                  const SizedBox(height: 10),
                  Text(
                    "В категории \"$categoryTitle\"\nпока нет объявлений.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // 4. Есть данные -> Рисуем список
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final item = products[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF25282B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Место под фото
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: item['image'] != null && item['image'].toString().isNotEmpty
                          ? Image.network(item['image'], fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, color: Colors.white24))
                          : const Center(
                              child: Icon(Icons.image_not_supported, size: 50, color: Colors.white24),
                            ),
                    ),
                    
                    // Описание
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] ?? 'Без названия', 
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${item['price']} ₸", 
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['desc'] ?? '', 
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          
                          // Кнопка "Позвонить"
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _callSeller(item['phone']),
                              icon: const Icon(Icons.phone, color: Colors.white),
                              label: Text("Позвонить: ${item['seller'] ?? 'Продавец'}"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[800],
                                foregroundColor: Colors.white,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      
      // ВРЕМЕННАЯ КНОПКА: Добавить тестовый товар (чтобы ты проверил работу)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
        onPressed: () {
          CloudService.addProduct(
            "Тестовая деталь для $categoryTitle", 
            categoryTitle, 
            "15 000", 
            "Это реальная запись, созданная из приложения.", 
            "Тест-Мастер", 
            "+77000000000"
          );
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Товар отправлен в базу данных!"))
          );
        },
      ),
    );
  }
}
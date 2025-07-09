import 'package:flutter/material.dart';
import '../config/app_config.dart';

class ErrorHelper {
  static void showConnectionErrorDialog(BuildContext context, String message) {
    final currentUrl = AppConfig().apiBaseUrl;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Koneksi Gagal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              const SizedBox(height: 16),
              const Text(
                'Kemungkinan penyebab:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Server backend tidak berjalan'),
              const Text('• URL server tidak benar'),
              const Text('• Masalah jaringan'),
              const Text('• Perangkat menggunakan jaringan berbeda'),
              const SizedBox(height: 16),
              Text(
                'URL saat ini:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                currentUrl,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () {
              // This would ideally show a dialog to input new URL
              Navigator.of(context).pop();
              _showUrlUpdateDialog(context);
            },
            child: const Text('Ubah URL'),
          ),
        ],
      ),
    );
  }

  static void _showUrlUpdateDialog(BuildContext context) {
    final controller = TextEditingController(text: AppConfig().apiBaseUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah URL Server'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukkan URL server backend:'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'http://192.168.1.100:8000/api/v1',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                AppConfig().updateApiBaseUrl(controller.text);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('URL diperbarui: ${controller.text}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

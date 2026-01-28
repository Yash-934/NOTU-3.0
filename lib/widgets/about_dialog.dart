import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutNotuDialog extends StatelessWidget {
  const AboutNotuDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final packageInfo = snapshot.data!;

        return AlertDialog(
          title: const Text('About Notu'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('App Version: ${packageInfo.version}'),
              const SizedBox(height: 16),
              const Text('Made by Yash Pradeep'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

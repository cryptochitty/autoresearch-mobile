import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ResponseCard extends StatelessWidget {
  final String text;
  final bool canDownload;
  final VoidCallback? onDownload;

  const ResponseCard({
    super.key,
    required this.text,
    this.canDownload = false,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.article, size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Research Result',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  tooltip: 'Copy',
                ),
                if (canDownload)
                  IconButton(
                    icon: const Icon(Icons.download, size: 18, color: Color(0xFF6C63FF)),
                    onPressed: onDownload,
                    tooltip: 'Download paper',
                  )
                else
                  Tooltip(
                    message: 'Subscribe ₹499/mo to download papers',
                    child: IconButton(
                      icon: const Icon(Icons.lock, size: 18, color: Colors.grey),
                      onPressed: null,
                    ),
                  ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  text,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

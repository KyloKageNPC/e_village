import 'package:flutter/material.dart';
import 'dart:io';
// import 'package:file_picker/file_picker.dart'; // Add to pubspec.yaml
// import 'package:image_picker/image_picker.dart'; // Add to pubspec.yaml

class AttachmentPicker extends StatelessWidget {
  final Function(File file, String type) onFilePicked;

  const AttachmentPicker({
    super.key,
    required this.onFilePicked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Attach File',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildOption(
                context,
                icon: Icons.photo_library,
                label: 'Gallery',
                color: Colors.purple,
                onTap: () => _pickImage(context, fromCamera: false),
              ),
              _buildOption(
                context,
                icon: Icons.camera_alt,
                label: 'Camera',
                color: Colors.blue,
                onTap: () => _pickImage(context, fromCamera: true),
              ),
              _buildOption(
                context,
                icon: Icons.insert_drive_file,
                label: 'Document',
                color: Colors.orange,
                onTap: () => _pickDocument(context),
              ),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, {required bool fromCamera}) async {
    Navigator.pop(context);

    // TODO: Implement image picker
    // Uncomment when you add image_picker package
    /*
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      onFilePicked(File(image.path), 'image');
    }
    */

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Add image_picker to pubspec.yaml to enable'),
        backgroundColor: Colors.orange.shade600,
      ),
    );
  }

  Future<void> _pickDocument(BuildContext context) async {
    Navigator.pop(context);

    // TODO: Implement file picker
    // Uncomment when you add file_picker package
    /*
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xlsx', 'xls'],
    );

    if (result != null && result.files.single.path != null) {
      onFilePicked(File(result.files.single.path!), 'document');
    }
    */

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Add file_picker to pubspec.yaml to enable'),
        backgroundColor: Colors.orange.shade600,
      ),
    );
  }
}

class AttachmentPreview extends StatelessWidget {
  final String fileName;
  final String fileType;
  final VoidCallback onRemove;

  const AttachmentPreview({
    super.key,
    required this.fileName,
    required this.fileType,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileIcon(),
              color: Colors.orange.shade600,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  fileType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red),
            onPressed: onRemove,
            constraints: BoxConstraints(),
            padding: EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon() {
    switch (fileType.toLowerCase()) {
      case 'image':
        return Icons.image;
      case 'document':
        return Icons.description;
      case 'video':
        return Icons.videocam;
      default:
        return Icons.attach_file;
    }
  }
}

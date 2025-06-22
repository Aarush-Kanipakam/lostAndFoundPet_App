import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PictureUploadSection extends StatefulWidget {
  final Function(File?)? onImageSelected;
  final String? initialImagePath;
  final String title;
  final String buttonText;
  final double? imageHeight;
  final double? imageWidth;
  
  const PictureUploadSection({
    Key? key,
    this.onImageSelected,
    this.initialImagePath,
    this.title = 'Add Picture',
    this.buttonText = 'Choose Photo',
    this.imageHeight = 200,
    this.imageWidth,
  }) : super(key: key);

  @override
  State<PictureUploadSection> createState() => _PictureUploadSectionState();
}

class _PictureUploadSectionState extends State<PictureUploadSection> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null) {
      _selectedImage = File(widget.initialImagePath!);
    }
  }

  Future<void> _pickImage() async {
    try {
      // Show dialog to choose between camera and gallery
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        
        // Call the callback function if provided
        if (widget.onImageSelected != null) {
          widget.onImageSelected!(_selectedImage);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
    
    if (widget.onImageSelected != null) {
      widget.onImageSelected!(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _selectedImage != null
          ? _buildSelectedImageView()
          : _buildImagePickerView(),
    );
  }

  Widget _buildImagePickerView() {
    return Column(
      children: [
        Icon(
          Icons.camera_alt,
          size: 48,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 8),
        Text(
          widget.title,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _pickImage,
          child: Text(widget.buttonText),
        ),
      ],
    );
  }

  Widget _buildSelectedImageView() {
    return Column(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _selectedImage!,
                height: widget.imageHeight,
                width: widget.imageWidth ?? double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _removeImage,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.edit),
              label: const Text('Change Photo'),
            ),
            TextButton.icon(
              onPressed: _removeImage,
              icon: const Icon(Icons.delete),
              label: const Text('Remove'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Getter to access the selected image from outside
  File? get selectedImage => _selectedImage;
  
  // Method to programmatically set image
  void setImage(File? image) {
    setState(() {
      _selectedImage = image;
    });
  }
  
  // Method to clear image
  void clearImage() {
    _removeImage();
  }
}
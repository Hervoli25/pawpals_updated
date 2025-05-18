import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../../widgets/common_widgets.dart';

class GalleryScreen extends StatefulWidget {
  final String title;
  final List<String> images;

  const GalleryScreen({
    super.key,
    required this.title,
    required this.images,
  });

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Main image viewer
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Toggle app bar and bottom bar visibility
                  },
                  child: Center(
                    child: Hero(
                      tag: 'gallery_image_$index',
                      child: InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 3.0,
                        child: _buildImage(widget.images[index]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Image counter
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.black,
            child: Text(
              '${_currentIndex + 1} / ${widget.images.length}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          
          // Thumbnail gallery
          Container(
            height: 80,
            color: Colors.black,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _currentIndex == index
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: _buildImage(widget.images[index], isThumbnail: true),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImage(String imagePath, {bool isThumbnail = false}) {
    // Check if it's a network image (starts with http)
    if (imagePath.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(Icons.error, color: Colors.red),
        ),
      );
    } 
    // Check if it's an asset image (dog1.jpg to dog12.jpeg)
    else if (imagePath.contains('dog')) {
      return Image.asset(
        'assets/images/$imagePath',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.error, color: Colors.red),
          );
        },
      );
    } 
    // Default placeholder
    else {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      );
    }
  }
}

// Helper class to launch the gallery
class GalleryLauncher {
  static void openGallery(BuildContext context, {
    required String title,
    required List<String> images,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryScreen(
          title: title,
          images: images,
        ),
      ),
    );
  }
}

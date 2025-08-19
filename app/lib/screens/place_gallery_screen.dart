import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/place_model.dart';

class PlaceGalleryScreen extends StatefulWidget {
  final Place place;
  const PlaceGalleryScreen({super.key, required this.place});

  @override
  State<PlaceGalleryScreen> createState() => _PlaceGalleryScreenState();
}

class _PlaceGalleryScreenState extends State<PlaceGalleryScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentImageIndex = 0;
  List<String> _validImageUrls = [];
  Set<String> _failedUrls = {};

  @override
  void initState() {
    super.initState();
    _initializeValidUrls();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  void _initializeValidUrls() {
    // Filter out any obviously invalid URLs and convert Google Drive URLs
    _validImageUrls = widget.place.imageUrls
        .where((url) => url.isNotEmpty && Uri.tryParse(url) != null)
        .map((url) => _convertGoogleDriveUrl(url))
        .toList();

    if (_validImageUrls.isEmpty) {
      debugPrint('Warning: No valid image URLs found');
    }
  }

  String _convertGoogleDriveUrl(String url) {
    // Convert Google Drive view URLs to direct download URLs
    if (url.contains('drive.google.com/file/d/')) {
      // Extract file ID from various Google Drive URL formats
      RegExp regExp = RegExp(r'/file/d/([a-zA-Z0-9-_]+)');
      Match? match = regExp.firstMatch(url);

      if (match != null) {
        String fileId = match.group(1)!;
        // Convert to direct view URL
        return 'https://drive.google.com/uc?export=view&id=$fileId';
      }
    }

    // If it's already a direct URL or not a Google Drive URL, return as is
    return url;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onImageError(String url) {
    setState(() {
      _failedUrls.add(url);
    });
    debugPrint('Image failed to load: $url');
  }

  List<String> get _workingImageUrls {
    return _validImageUrls.where((url) => !_failedUrls.contains(url)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final workingUrls = _workingImageUrls;
    final hasMultipleImages = workingUrls.length > 1;

    // Handle case where no images are available
    if (workingUrls.isEmpty) {
      return _buildNoImagesScreen();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '✨ A Memory from...',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (hasMultipleImages)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.3),
                ),
              ),
              child: Text(
                '${_currentImageIndex + 1} of ${workingUrls.length}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Image gallery section
              _buildImageGallery(hasMultipleImages, workingUrls),

              // Cute image indicator dots (only for multiple images)
              if (hasMultipleImages) _buildImageIndicator(workingUrls.length),

              // Failed images warning (if any)
              if (_failedUrls.isNotEmpty) _buildFailedImagesWarning(),

              // Description card
              _buildDescriptionCard(workingUrls.length),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoImagesScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '✨ A Memory from...',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'No images available',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodyLarge?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'All images failed to load or no valid images found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _buildDescriptionCard(0),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedImagesWarning() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${_failedUrls.length} image${_failedUrls.length == 1 ? '' : 's'} failed to load',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(bool hasMultipleImages, List<String> workingUrls) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: hasMultipleImages
            ? _buildPageView(workingUrls)
            : _buildSingleImage(workingUrls.first),
      ),
    );
  }

  Widget _buildPageView(List<String> workingUrls) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        if (mounted) {
          setState(() {
            _currentImageIndex = index;
          });
        }
      },
      itemCount: workingUrls.length,
      itemBuilder: (context, index) {
        return Hero(
          tag: '${widget.place.id}_$index',
          child: _buildImageContainer(workingUrls[index]),
        );
      },
    );
  }

  Widget _buildSingleImage(String imageUrl) {
    return Hero(tag: widget.place.id, child: _buildImageContainer(imageUrl));
  }

  Widget _buildImageContainer(String imageUrl) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.1)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            // Add memory cache configuration
            memCacheWidth: 1024,
            memCacheHeight: 1024,
            // Add better HTTP configuration for Google Drive
            httpHeaders: const {
              'User-Agent': 'OurLittleWorld/1.0 (Flutter App)',
              'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
              'Accept-Language': 'en-US,en;q=0.9',
            },
            // Add error retry configuration
            errorListener: (error) {
              debugPrint('CachedNetworkImage error for $imageUrl: $error');
            },
            // Improved placeholder
            placeholder: (context, url) => Container(
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading memory...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Improved error widget with retry functionality
            errorWidget: (context, url, error) {
              // Mark this URL as failed
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onImageError(url);
              });

              return Container(
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withOpacity(0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image_rounded,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Image failed to load',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This memory couldn\'t be displayed',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Clear cache and try again
                        CachedNetworkImage.evictFromCache(url);
                        setState(() {
                          _failedUrls.remove(url);
                        });
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 32),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageIndicator(int imageCount) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          imageCount,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: _currentImageIndex == index ? 24 : 8,
            decoration: BoxDecoration(
              color: _currentImageIndex == index
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.secondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionCard(int imageCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).cardColor,
                Theme.of(context).cardColor.withOpacity(0.8),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar and author section
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.transparent,
                        child: Image.asset(
                          widget.place.authorRole == 'Panda'
                              ? 'assets/images/panda_avatar.png'
                              : 'assets/images/penguin_avatar.png',
                          width: 45,
                          height: 45,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              widget.place.authorRole == 'Panda'
                                  ? Icons.pets
                                  : Icons.ac_unit,
                              size: 30,
                              color: Theme.of(context).colorScheme.secondary,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shared by ${widget.place.authorRole}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.photo_library_rounded,
                                size: 16,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                imageCount == 0
                                    ? 'No images'
                                    : imageCount == 1
                                    ? '1 memory'
                                    : '$imageCount memories',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (_failedUrls.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 12,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '(${_failedUrls.length} failed)',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Description section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Memory Description',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.place.description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Location info
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lat: ${widget.place.latitude.toStringAsFixed(6)}, '
                        'Long: ${widget.place.longitude.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Timestamp info
                if (widget.place.timestamp != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Created on ${_formatTimestamp(widget.place.timestamp!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).textTheme.bodySmall?.color?.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      }
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${_formatTime(timestamp)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${_formatTime(timestamp)}';
    }
  }

  String _formatTime(DateTime timestamp) {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

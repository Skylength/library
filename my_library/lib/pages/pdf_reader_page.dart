import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import '../themes/colors.dart';

/// Realistic PDF Reader Page
///
/// Features:
/// - Paper texture effect
/// - 3D page flip animation
/// - Book shadow and depth
/// - Double page spread mode
class PdfReaderPage extends StatefulWidget {
  final String pdfAssetPath;
  final String title;

  const PdfReaderPage({
    super.key,
    required this.pdfAssetPath,
    required this.title,
  });

  @override
  State<PdfReaderPage> createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<PdfReaderPage>
    with TickerProviderStateMixin {
  PdfDocument? _document;
  final Map<int, PdfPageImage?> _pageCache = {};
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isLoading = true;
  bool _showControls = true;

  // PDF actual aspect ratio (width / height)
  double _pdfAspectRatio = 1 / 1.414;
  // Device pixel ratio for high-res rendering
  double _devicePixelRatio = 1.0;

  // Flip animation controller
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFlipping = false;
  bool _flipForward = true;

  // Zoom control
  double _scale = 1.0;
  final double _minScale = 0.8;
  final double _maxScale = 3.0;

  @override
  void initState() {
    super.initState();
    _initFlipAnimation();
    _loadDocument();
  }

  void _initFlipAnimation() {
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _flipController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          if (_flipForward && _currentPage < _totalPages - 1) {
            _currentPage++;
          } else if (!_flipForward && _currentPage > 0) {
            _currentPage--;
          }
          _isFlipping = false;
        });
        _flipController.reset();
        _preloadAdjacentPages();
      }
    });
  }

  Future<void> _loadDocument() async {
    // Get device pixel ratio for high-res rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    });

    try {
      final doc = await PdfDocument.openAsset(widget.pdfAssetPath);

      // Get first page to determine actual PDF aspect ratio
      final firstPage = await doc.getPage(1);
      final actualAspectRatio = firstPage.width / firstPage.height;
      await firstPage.close();

      setState(() {
        _document = doc;
        _totalPages = doc.pagesCount;
        _pdfAspectRatio = actualAspectRatio;
        _isLoading = false;
      });

      await _loadPage(_currentPage);
      _preloadAdjacentPages();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load PDF: $e')),
        );
      }
    }
  }

  Future<void> _loadPage(int pageIndex) async {
    if (_document == null || _pageCache.containsKey(pageIndex)) return;
    if (pageIndex < 0 || pageIndex >= _totalPages) return;

    final page = await _document!.getPage(pageIndex + 1);

    // Render at high resolution based on device pixel ratio
    // Use at least 3x for crisp text, but cap at 4x to avoid memory issues
    final renderScale = math.min(_devicePixelRatio * 2, 4.0).clamp(3.0, 4.0);

    final pageImage = await page.render(
      width: page.width * renderScale,
      height: page.height * renderScale,
      format: PdfPageImageFormat.png,
      backgroundColor: '#FFFFFF',
    );
    await page.close();

    if (mounted) {
      setState(() {
        _pageCache[pageIndex] = pageImage;
      });
    }
  }

  Future<void> _preloadAdjacentPages() async {
    final pagesToLoad = [
      _currentPage - 1,
      _currentPage + 1,
      _currentPage + 2,
    ];

    for (final page in pagesToLoad) {
      if (page >= 0 && page < _totalPages && !_pageCache.containsKey(page)) {
        await _loadPage(page);
      }
    }
  }

  void _flipToNextPage() {
    if (_isFlipping || _currentPage >= _totalPages - 1) return;
    setState(() {
      _isFlipping = true;
      _flipForward = true;
    });
    _flipController.forward();
  }

  void _flipToPreviousPage() {
    if (_isFlipping || _currentPage <= 0) return;
    setState(() {
      _isFlipping = true;
      _flipForward = false;
    });
    _flipController.forward();
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _totalPages || page == _currentPage) return;
    setState(() => _currentPage = page);
    _loadPage(page);
    _preloadAdjacentPages();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _document?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2A2520),
      body: Stack(
        children: [
          // Wood background
          _buildWoodBackground(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                if (_showControls) _buildTopBar(),

                // PDF display area
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showControls = !_showControls),
                    onHorizontalDragEnd: _handleSwipe,
                    child: _isLoading
                        ? _buildLoadingIndicator()
                        : _buildBookView(),
                  ),
                ),

                // Bottom bar
                if (_showControls) _buildBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWoodBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF3D3530),
            Color(0xFF2A2520),
            Color(0xFF1E1A18),
          ],
        ),
      ),
      child: CustomPaint(
        painter: WoodGrainPainter(),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.6),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: ClaudeColors.textMain),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                color: ClaudeColors.textMain,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen, color: ClaudeColors.textMain),
            onPressed: () {
              SystemChrome.setEnabledSystemUIMode(
                SystemUiMode.immersiveSticky,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page progress
          Row(
            children: [
              Text(
                '${_currentPage + 1}',
                style: const TextStyle(
                  color: ClaudeColors.textMain,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _currentPage.toDouble(),
                  min: 0,
                  max: (_totalPages - 1).toDouble().clamp(0, double.infinity),
                  activeColor: ClaudeColors.accent,
                  inactiveColor: ClaudeColors.border,
                  onChanged: (value) => _goToPage(value.round()),
                ),
              ),
              Text(
                '$_totalPages',
                style: const TextStyle(color: ClaudeColors.textMuted),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Zoom control
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_out, color: ClaudeColors.textMuted),
                onPressed: () {
                  setState(() {
                    _scale = (_scale - 0.2).clamp(_minScale, _maxScale);
                  });
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: ClaudeColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(_scale * 100).round()}%',
                  style: const TextStyle(
                    color: ClaudeColors.textMain,
                    fontSize: 12,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in, color: ClaudeColors.textMuted),
                onPressed: () {
                  setState(() {
                    _scale = (_scale + 0.2).clamp(_minScale, _maxScale);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ClaudeColors.accent),
          ),
          const SizedBox(height: 16),
          const Text(
            'Opening book...',
            style: TextStyle(color: ClaudeColors.textMuted),
          ),
        ],
      ),
    );
  }

Widget _buildBookView() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final availableHeight = constraints.maxHeight;
      final availableWidth  = constraints.maxWidth;

      final aspectRatio = _pdfAspectRatio;

      // 先按不缩放算出书本原始宽高
      double pageHeight = availableHeight;
      double pageWidth  = pageHeight * aspectRatio;

      final spineWidth = math.max(pageWidth * 0.03, 8.0);
      final bookWidth  = pageWidth * 2 + spineWidth;
      final bookHeight = pageHeight;

      // 计算“刚好能放下”的缩放比例
      final fitScale = math.min(
        availableWidth / bookWidth,
        availableHeight / bookHeight,
      );

      // totalScale = “适屏比例” * 你的用户缩放
      final totalScale = fitScale * _scale;

      final pageOffset = pageWidth / 2 + spineWidth / 2;

      return Center(
        child: Transform.scale(
          scale: totalScale,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              _buildBookShadow(bookWidth),
              if (_isFlipping) _buildFlippingPage(pageWidth, pageHeight),
              _buildPage(_currentPage,
                  isLeftPage: true,
                  pageWidth: pageWidth,
                  pageHeight: pageHeight,
                  pageOffset: pageOffset),
              if (_currentPage + 1 < _totalPages)
                _buildPage(_currentPage + 1,
                    isLeftPage: false,
                    pageWidth: pageWidth,
                    pageHeight: pageHeight,
                    pageOffset: pageOffset),
              _buildBookSpine(spineWidth, pageHeight),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildBookShadow(double width) {
    return Positioned(
      bottom: -20,
      child: Container(
        width: width,
        height: 40,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int pageIndex, {
    required bool isLeftPage,
    required double pageWidth,
    required double pageHeight,
    required double pageOffset,
  }) {
    final pageImage = _pageCache[pageIndex];
    final offset = isLeftPage ? Offset(-pageOffset, 0) : Offset(pageOffset, 0);

    return Transform.translate(
      offset: offset,
      child: Container(
        width: pageWidth,
        height: pageHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.horizontal(
            left: isLeftPage ? const Radius.circular(4) : Radius.zero,
            right: isLeftPage ? Radius.zero : const Radius.circular(4),
          ),
          boxShadow: [
            // Main shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: Offset(isLeftPage ? -5 : 5, 8),
            ),
            // Stack effect - simulates page thickness
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 2,
              offset: Offset(isLeftPage ? -1 : 1, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.horizontal(
            left: isLeftPage ? const Radius.circular(4) : Radius.zero,
            right: isLeftPage ? Radius.zero : const Radius.circular(4),
          ),
          child: Stack(
            children: [
              // PDF content - high quality rendering
              if (pageImage != null)
                Positioned.fill(
                  child: Image.memory(
                    pageImage.bytes,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                  ),
                )
              else
                Container(
                  color: Colors.white,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),

              // Subtle paper texture overlay (very light)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: PaperTexturePainter(),
                  ),
                ),
              ),

              // Page curl effect at spine
              _buildPageCurl(isLeftPage, pageWidth),

              // Page edge highlight
              _buildPageEdgeShadow(isLeftPage),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageCurl(bool isLeftPage, double pageWidth) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: isLeftPage ? null : 0,
      right: isLeftPage ? 0 : null,
      width: pageWidth * 0.1,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: isLeftPage ? Alignment.centerLeft : Alignment.centerRight,
            end: isLeftPage ? Alignment.centerRight : Alignment.centerLeft,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.05),
              Colors.black.withValues(alpha: 0.1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageEdgeShadow(bool isLeftPage) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: isLeftPage ? 0 : null,
      right: isLeftPage ? null : 0,
      width: 15,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: isLeftPage ? Alignment.centerRight : Alignment.centerLeft,
            end: isLeftPage ? Alignment.centerLeft : Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlippingPage(double pageWidth, double pageHeight) {
    final progress = _flipAnimation.value;
    final angle = _flipForward
        ? -progress * math.pi
        : -(1 - progress) * math.pi;

    final pageIndex = _flipForward ? _currentPage : _currentPage - 1;
    final pageImage = _pageCache[pageIndex];

    return Transform(
      alignment: _flipForward ? Alignment.centerRight : Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(angle),
      child: Container(
        width: pageWidth,
        height: pageHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEF8),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4 * (1 - progress.abs())),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: pageImage != null
              ? Image.memory(pageImage.bytes, fit: BoxFit.contain)
              : const SizedBox(),
        ),
      ),
    );
  }

  Widget _buildBookSpine(double spineWidth, double pageHeight) {
    return Container(
      width: spineWidth,
      height: pageHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5D4037),
            Color(0xFF4E342E),
            Color(0xFF3E2723),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Spine decoration
          Container(
            width: spineWidth * 0.7,
            height: 2,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 20),
          Container(
            width: spineWidth * 0.7,
            height: 2,
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  void _handleSwipe(DragEndDetails details) {
    if (details.primaryVelocity == null) return;

    if (details.primaryVelocity! < -300) {
      _flipToNextPage();
    } else if (details.primaryVelocity! > 300) {
      _flipToPreviousPage();
    }
  }
}

/// Wood grain background painter
class WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    final random = math.Random(42);

    for (int i = 0; i < 50; i++) {
      final y = random.nextDouble() * size.height;
      final startX = random.nextDouble() * size.width * 0.3;
      final endX = startX + random.nextDouble() * size.width * 0.7;

      canvas.drawLine(
        Offset(startX, y),
        Offset(endX, y + random.nextDouble() * 10 - 5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paper texture painter - very subtle overlay
class PaperTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Very subtle texture dots - almost invisible
    final random = math.Random(123);
    final dotPaint = Paint()..color = Colors.brown.withValues(alpha: 0.008);

    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.0 + 0.3;
      canvas.drawCircle(Offset(x, y), radius, dotPaint);
    }

    // Very subtle fiber lines
    final fiberPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.01)
      ..strokeWidth = 0.3;

    for (int i = 0; i < 15; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final endX = startX + random.nextDouble() * 15 - 7.5;
      final endY = startY + random.nextDouble() * 15 - 7.5;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        fiberPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

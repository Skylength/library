import 'dart:typed_data';

import 'package:flip_curl_animation_widget/flip_curl_animation_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';

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

class _PdfReaderPageState extends State<PdfReaderPage> {
  final PageFlipController _pageFlipController = PageFlipController();

  PdfDocument? _pdfDocument;
  final Map<int, Uint8List> _pageImageCache = {};
  final Map<int, TransformationController> _transformControllers = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _isInterfaceVisible = false;
  int _totalPages = 0;
  int _currentPage = 0; // CustomPageFlip uses 0-based index
  static const Color _parchmentBg = Color(0xFFF2E8D5);
  static const Color _inkColor = Color(0xFF3E2723);

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    _initPdfAndRender();
  }

  Future<void> _initPdfAndRender() async {
    try {
      _pdfDocument = await PdfDocument.openAsset(widget.pdfAssetPath);
      _totalPages = _pdfDocument!.pagesCount;
      await _preRenderAllPages();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "PDF 加载失败: $e";
        });
      }
    }
  }

  Future<void> _preRenderAllPages() async {
    if (_pdfDocument == null) return;
    for (int i = 1; i <= _totalPages; i++) {
      final pageImage = await _renderSinglePage(i);
      if (pageImage != null) {
        _pageImageCache[i - 1] = pageImage;
      }
      if (mounted) setState(() {});
    }
  }

  Future<Uint8List?> _renderSinglePage(int pageNumber) async {
    if (_pdfDocument == null) return null;
    try {
      final page = await _pdfDocument!.getPage(pageNumber);
      // Lower resolution a bit to keep flip animation smooth on slower devices.
      final image = await page.render(
        width: page.width * 1.5,
        height: page.height * 1.5,
        format: PdfPageImageFormat.png,
      );
      await page.close();
      return image?.bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    for (final controller in _transformControllers.values) {
      controller.dispose();
    }
    _transformControllers.clear();
    _pdfDocument?.close();
    _pageImageCache.clear();
    super.dispose();
  }

  void _toggleInterface() {
    setState(() {
      _isInterfaceVisible = !_isInterfaceVisible;
    });
    if (_isInterfaceVisible) {
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    }
  }

  void _jumpToPage(int pageNumber) {
    // pageNumber is 1-based, convert to index
    int targetIndex = pageNumber - 1;
    if (targetIndex < 0 || targetIndex >= _totalPages) return;

    _pageFlipController.goToPage(targetIndex);
    setState(() {
      _currentPage = targetIndex;
    });
  }

  TransformationController _buildTransformationController(int index) {
    return _transformControllers.putIfAbsent(
      index,
      () => TransformationController(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _parchmentBg,
        body: const Center(
          child: CircularProgressIndicator(color: _inkColor),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: _parchmentBg,
        body: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: _inkColor, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _parchmentBg,
      body: Stack(
        children: [
          // 1) Background layer
          Positioned.fill(
            child: Container(
              color: _parchmentBg,
            ),
          ),

          // 2) Flip animation layer (supports drag and pinch zoom)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: CustomPageFlip(
                controller: _pageFlipController,
                backgroundColor: _parchmentBg,
                initialIndex: _currentPage,
                cutoffForward: 0.8,
                cutoffPrevious: 0.15,
                transformationControllerBuilder: _buildTransformationController,
                children: _buildPageWidgets(),
                lastPage: Container(
                  color: _parchmentBg,
                  child: const Center(
                    child: Text(
                      "已读完",
                      style: TextStyle(color: _inkColor),
                    ),
                  ),
                ),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
              ),
            ),
          ),

          // 3) Local tap area to toggle interface bars
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _toggleInterface,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.height * 0.5,
                color: Colors.transparent,
              ),
            ),
          ),

          // 4) UI overlay (AppBar & BottomBar)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: _isInterfaceVisible ? 0 : -100,
            left: 0,
            right: 0,
            child: _buildCustomAppBar(context),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: _isInterfaceVisible ? 0 : -140,
            left: 0,
            right: 0,
            child: _buildBottomBar(context),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageWidgets() {
    return List.generate(_totalPages, (index) {
      final imageBytes = _pageImageCache[index];

      // Each child is one page for the flip animation
      return Container(
        color: _parchmentBg,
        child: imageBytes != null
            ? Image.memory(
                imageBytes,
                fit: BoxFit.contain, // Keep aspect ratio of PDF content
                gaplessPlayback: true,
              )
            : const Center(child: CircularProgressIndicator()),
      );
    });
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      height: 80,
      color: _parchmentBg,
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _inkColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title, style: const TextStyle(color: _inkColor)),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      color: _parchmentBg,
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${_currentPage + 1} / $_totalPages",
            style: const TextStyle(color: _inkColor),
          ),
          // Optional: add a Slider for quick jumps.
        ],
      ),
    );
  }
}

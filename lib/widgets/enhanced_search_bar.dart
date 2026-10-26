import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';


class EnhancedSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String searchQuery;
  final bool isLoading;
  final List<String>? autocompleteSuggestions;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String>? onSuggestionTap;

  const EnhancedSearchBar({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.isLoading,
    this.autocompleteSuggestions,
    required this.onChanged,
    required this.onClear,
    this.onSuggestionTap,
  });

  @override
  State<EnhancedSearchBar> createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends State<EnhancedSearchBar>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  bool _isFocused = false;
  late AnimationController _animController;
  late Animation<double> _glowAnimation;

  // Typewriter effect
  final List<String> _hints = [
    'Search "Biryani"...',
    'Craving "Pizza"?',
    'Find "Burger"...',
    'Search for dishes...',
  ];
  int _currentHintIndex = 0;
  String _currentHint = '';
  int _charIndex = 0;
  Timer? _typewriterTimer;

  // Overlay for autocomplete
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _startTypewriterEffect();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_isFocused) {
      _animController.forward();
      _showOverlay();
    } else {
      _animController.reverse();
      _removeOverlay();
    }
  }

  void _startTypewriterEffect() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      if (_focusNode.hasFocus) return; // Don't animate hint when typing

      final targetWord = _hints[_currentHintIndex];
      if (_charIndex < targetWord.length) {
        setState(() {
          _currentHint = targetWord.substring(0, _charIndex + 1);
          _charIndex++;
        });
      } else {
        timer.cancel();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _currentHint = '';
              _charIndex = 0;
              _currentHintIndex = (_currentHintIndex + 1) % _hints.length;
            });
            _startTypewriterEffect();
          }
        });
      }
    });
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 8.0),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            child: widget.autocompleteSuggestions == null ||
                    widget.autocompleteSuggestions!.isEmpty
                ? const SizedBox.shrink()
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: widget.autocompleteSuggestions!.length,
                      itemBuilder: (context, index) {
                        final suggestion = widget.autocompleteSuggestions![index];
                        return ListTile(
                          leading: Icon(Icons.search, color: Colors.grey.shade400),
                          title: Text(
                            suggestion,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onTap: () {
                            _focusNode.unfocus();
                            if (widget.onSuggestionTap != null) {
                              widget.onSuggestionTap!(suggestion);
                            }
                          },
                        );
                      },
                    ),
                  ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void didUpdateWidget(EnhancedSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isFocused && widget.autocompleteSuggestions != oldWidget.autocompleteSuggestions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _overlayEntry?.markNeedsBuild();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _animController.dispose();
    _typewriterTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                if (_isFocused)
                  BoxShadow(
                    color: Colors.pinkAccent.withValues(alpha: 0.3 * _glowAnimation.value),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: _isFocused ? 0.95 : 0.85),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: _isFocused
                          ? Colors.pinkAccent.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    onChanged: widget.onChanged,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: _isFocused ? 'Search...' : _currentHint,
                      hintStyle: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: _isFocused ? Colors.pinkAccent : Colors.grey.shade600,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.isLoading)
                            const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          if (widget.searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                widget.onClear();
                                _focusNode.unfocus();
                              },
                            ),
                          const SizedBox(width: 4),
                          Container(width: 1, height: 24, color: Colors.grey.shade300),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.mic, color: Colors.pinkAccent),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.tune, color: Colors.grey),
                            onPressed: () {},
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

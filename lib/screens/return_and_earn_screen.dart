

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


class AppColors {
  const AppColors._();

  static const Color maroon = Color(0xFF7A0042);
  static const Color heroStart = Color(0xFFBA0165);
  static const Color heroEnd = Color(0xFF7D0143);

  static const Color pageBackground = Color(0xFFFFF6FB);
  static const Color softPink = Color(0xFFFCF4F1);
  static const Color hairline = Color(0xFFEFE6EA);
  static const Color cardBorder = Color(0xFFEDE7E9);

  static const Color titleDark = Color(0xFF141414);
  static const Color bodyGrey = Color(0xFF6E6A6C);
  static const Color labelGrey = Color(0xFF9E9498);

  static const Color green = Color(0xFF099918);
  static const Color creditGreen = Color(0xFF208900);
  static const Color checkboxRed = Color(0xFFB30816);

  static const Color storeRed = Color(0xFFD81F1F);
  static const Color storeGreen = Color(0xFF099918);
  static const Color storeTan = Color(0xFFA68167);

  // Gradient taken from the third reference image.
  static const Color gradientStart = Color(0xFFC31269);
  static const Color gradientEnd = Color(0xFF5C1435);
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// A piece of packaging from a recent order that can be handed back.
class PackagingItem {
  PackagingItem({
    required this.store,
    required this.storeColor,
    required this.placedAt,
    required this.title,
    required this.material,
    required this.units,
    required this.estimate,
    this.imagePath,
    this.selected = false,
  });

  final String store;
  final Color storeColor;
  final String placedAt;
  final String title;
  final String material;
  final int units;
  final double estimate;

  /// Optional asset path, e.g. 'assets/images/biryani_container.png'.
  final String? imagePath;

  bool selected;

  String get subtitle =>
      '$material · $units ${units == 1 ? 'unit' : 'units'} · est. ₹${_money(estimate)}';
}



String _money(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ReturnAndEarnScreen extends StatefulWidget {
  const ReturnAndEarnScreen({super.key});

  @override
  State<ReturnAndEarnScreen> createState() => _ReturnAndEarnScreenState();
}

class _ReturnAndEarnScreenState extends State<ReturnAndEarnScreen> {
  final List<PackagingItem> _packaging = [
    PackagingItem(
      store: 'SWADISHTT',
      storeColor: AppColors.storeRed,
      placedAt: 'YESTERDAY 7:30 PM',
      title: 'Biryani container',
      material: 'Aluminium foil box',
      units: 1,
      estimate: 6,
      imagePath: 'assets/Swadishtt/container.png',
    ),
    PackagingItem(
      store: 'SWADISHTT',
      storeColor: AppColors.storeRed,
      placedAt: 'YESTERDAY 7:30 PM',
      title: 'Naan packaging bag',
      material: 'Paper bag',
      units: 1,
      estimate: 3,
    ),
    PackagingItem(
      store: 'GROKLY',
      storeColor: AppColors.storeGreen,
      placedAt: 'TODAY 9:15 AM',
      title: 'Amul milk tetra pack',
      material: 'Tetra Pak carton',
      units: 2,
      estimate: 4,
    ),
    PackagingItem(
      store: 'INSTASTYLE',
      storeColor: AppColors.storeTan,
      placedAt: 'TODAY 11:00 AM',
      title: 'Kurta set poly bag',
      material: 'Plastic packaging',
      units: 1,
      estimate: 2,
    ),
  ];

  void _togglePackaging(int index) =>
      setState(() => _packaging[index].selected = !_packaging[index].selected);

  void _onAddPhotos() {
    final selectedItems = _packaging.where((p) => p.selected).toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReturnAndEarnAddPhotosScreen(selectedItems: selectedItems),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          const _ReturnHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                const _HeroCard(),
                const SizedBox(height: 16),
                const _EligibilityNotice(),
                const SizedBox(height: 26),
                const _SectionLabel('ELIGIBLE FROM YOUR RECENT ORDERS'),
                const SizedBox(height: 12),
                _buildPackagingList(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomBar(onAddPhotos: _onAddPhotos),
    );
  }

  Widget _buildPackagingList() {
    return _CardShell(
      child: Column(
        children: [
          for (var i = 0; i < _packaging.length; i++) ...[
            _PackagingRow(
              item: _packaging[i],
              onToggle: () => _togglePackaging(i),
            ),
            if (i != _packaging.length - 1) const _RowDivider(),
          ],
        ],
      ),
    );
  }

}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _ReturnHeader extends StatelessWidget {
  const _ReturnHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.maroon,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Column(
            children: [
              Row(
                children: [
                  _CircleBackButton(onTap: () => Navigator.maybePop(context)),
                  const SizedBox(width: 14),
                  const Text(
                    'Return & Earn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _PageDot(width: 30, active: true),
                  SizedBox(width: 6),
                  _PageDot(width: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x24FFFFFF),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          height: 44,
          width: 44,
          child: Icon(Icons.chevron_left_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.width, this.active = false});

  final double width;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 5,
      width: width,
      decoration: BoxDecoration(
        color: active ? Colors.white : const Color(0x59FFFFFF),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero + notices
// ---------------------------------------------------------------------------

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.heroStart, AppColors.heroEnd],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.recycling, color: Colors.white, size: 38),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Return our packaging, earn wallet credits',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Only packaging from your recent Accesco orders qualifies. '
                  'Hand it to your delivery rider — we\'ll verify at our '
                  'warehouse and credit your wallet.',
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 14.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EligibilityNotice extends StatelessWidget {
  const _EligibilityNotice();

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontSize: 14.5,
      height: 1.5,
      color: AppColors.titleDark,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F5C1435),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule, size: 20, color: AppColors.bodyGrey),
          const SizedBox(width: 12),
          const Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Only packaging from orders placed '),
                  TextSpan(
                    text: 'in the last 48 hours',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: ' is eligible. Older returns won\'t be accepted — '
                        'schedule your return with your next order.',
                  ),
                ],
              ),
              style: base,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: AppColors.labelGrey,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Packaging rows (screen 1)
// ---------------------------------------------------------------------------

class _PackagingRow extends StatelessWidget {
  const _PackagingRow({required this.item, required this.onToggle});

  final PackagingItem item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ItemThumbnail(imagePath: item.imagePath, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.store} · ${item.placedAt}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: item.storeColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.titleDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.35,
                      color: AppColors.bodyGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _SquareCheckbox(
              value: item.selected,
              activeColor: AppColors.green,
              size: 32,
              onTap: onToggle,
            ),
          ],
        ),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Bottom bar — "Add photos" with the reference gradient
// ---------------------------------------------------------------------------

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onAddPhotos});

  final VoidCallback onAddPhotos;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 18, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: AddPhotosButton(onPressed: onAddPhotos),
        ),
      ),
    );
  }
}

/// Full-width CTA using the gradient sampled from the third reference image
/// (#C31269 → #5C1435, left to right with a slight diagonal).
class AddPhotosButton extends StatelessWidget {
  const AddPhotosButton({super.key, required this.onPressed, this.label = 'Add photos'});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x335C1435), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          splashColor: const Color(0x1AFFFFFF),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 21),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x0A5C1435), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider({this.indent = 14});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      endIndent: indent,
      color: AppColors.hairline,
    );
  }
}

class _SquareCheckbox extends StatelessWidget {
  const _SquareCheckbox({
    required this.value,
    required this.onTap,
    required this.activeColor,
    this.size = 30,
    this.radius = 8,
  });

  final bool value;
  final VoidCallback onTap;
  final Color activeColor;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: value ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: value ? activeColor : AppColors.cardBorder,
            width: 1.4,
          ),
        ),
        child: value
            ? Icon(Icons.check_rounded, size: size * 0.66, color: Colors.white)
            : null,
      ),
    );
  }
}

/// Product image with a neutral fallback so the screen renders before assets
/// are added. Pass an asset path on the model to show the real photo.
class _ItemThumbnail extends StatelessWidget {
  const _ItemThumbnail({required this.size, this.imagePath});

  final double size;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1F2),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: imagePath == null
          ? Image.asset(
              'assets/Swadishtt/container.png',
              fit: BoxFit.cover,
            )
          : Image.asset(imagePath!, fit: BoxFit.cover),
    );
  }
}

// ---------------------------------------------------------------------------
// Screen 2: Add Photos
// ---------------------------------------------------------------------------

class ReturnAndEarnAddPhotosScreen extends StatefulWidget {
  const ReturnAndEarnAddPhotosScreen({super.key, required this.selectedItems});
  
  final List<PackagingItem> selectedItems;

  @override
  State<ReturnAndEarnAddPhotosScreen> createState() => _ReturnAndEarnAddPhotosScreenState();
}

class _ReturnAndEarnAddPhotosScreenState extends State<ReturnAndEarnAddPhotosScreen> {
  final List<String> _photoPaths = [];
  String _selectedCondition = 'Empty & rinsed';
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'Upload photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.titleDark,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.maroon),
              title: const Text('Take a photo', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.maroon),
              title: const Text('Choose from gallery', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          if (_photoPaths.length < 3) {
            _photoPaths.add(image.path);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          const _AddPhotosHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                _SelectedItemsSummary(items: widget.selectedItems),
                const SizedBox(height: 16),
                _PhotosAndConditionCard(
                  photoPaths: _photoPaths,
                  onAddPhoto: _pickImage,
                  selectedCondition: _selectedCondition,
                  onConditionChanged: (val) => setState(() => _selectedCondition = val),
                ),
                const SizedBox(height: 16),
                const _WhyPhotosCard(),
                const SizedBox(height: 16),
                const _DeliveryNoticeCard(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ReturnToCartBottomBar(
        onPressed: () {
          int count = 0;
          Navigator.of(context).popUntil((_) => count++ >= 2);
        },
      ),
    );
  }
}

class _AddPhotosHeader extends StatelessWidget {
  const _AddPhotosHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.maroon,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Column(
            children: [
              Row(
                children: [
                  _CircleBackButton(onTap: () => Navigator.maybePop(context)),
                  const SizedBox(width: 14),
                  const Text(
                    'Add photos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _PageDot(width: 14),
                  SizedBox(width: 6),
                  _PageDot(width: 30, active: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedItemsSummary extends StatelessWidget {
  const _SelectedItemsSummary({required this.items});

  final List<PackagingItem> items;

  @override
  Widget build(BuildContext context) {
    final count = items.fold<int>(0, (sum, i) => sum + i.units);
    final totalEstimate = items.fold<double>(0, (sum, i) => sum + i.estimate);
    final names = items.map((i) => i.title.replaceAll(' packaging bag', ' bag').replaceAll(' container', ' container')).join(' · ');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.softPink,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset('assets/Swadishtt/container.png', fit: BoxFit.cover),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${count == 1 ? 'item' : 'items'} selected',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.maroon,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$names · est. ₹${_money(totalEstimate)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.bodyGrey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotosAndConditionCard extends StatelessWidget {
  const _PhotosAndConditionCard({
    required this.photoPaths,
    required this.onAddPhoto,
    required this.selectedCondition,
    required this.onConditionChanged,
  });

  final List<String> photoPaths;
  final VoidCallback onAddPhoto;
  final String selectedCondition;
  final ValueChanged<String> onConditionChanged;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('PHOTOS OF PACKAGING'),
          const SizedBox(height: 12),
          Row(
            children: [
              _PhotoBox(
                imagePath: photoPaths.isNotEmpty ? photoPaths[0] : null,
                isDashed: photoPaths.isEmpty,
                onTap: photoPaths.isEmpty ? onAddPhoto : null,
              ),
              const SizedBox(width: 12),
              _PhotoBox(
                imagePath: photoPaths.length > 1 ? photoPaths[1] : null,
                isDashed: photoPaths.length == 1,
                onTap: photoPaths.length == 1 ? onAddPhoto : null,
              ),
              const SizedBox(width: 12),
              _PhotoBox(
                imagePath: photoPaths.length > 2 ? photoPaths[2] : null,
                isDashed: photoPaths.length == 2,
                onTap: photoPaths.length == 2 ? onAddPhoto : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Minimum 2 clear photos showing the packaging and our brand label/logo on it.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.labelGrey,
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('PACKAGING CONDITION'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              _ConditionChip(
                label: 'Empty & rinsed',
                isSelected: selectedCondition == 'Empty & rinsed',
                onTap: () => onConditionChanged('Empty & rinsed'),
              ),
              _ConditionChip(
                label: 'Empty, not rinsed',
                isSelected: selectedCondition == 'Empty, not rinsed',
                onTap: () => onConditionChanged('Empty, not rinsed'),
              ),
              _ConditionChip(
                label: 'Crushed / flat',
                isSelected: selectedCondition == 'Crushed / flat',
                onTap: () => onConditionChanged('Crushed / flat'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({
    this.imagePath,
    this.isDashed = false,
    this.onTap,
  });

  final String? imagePath;
  final bool isDashed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null;
    final borderColor = hasImage 
        ? AppColors.heroStart.withOpacity(0.2) 
        : (isDashed ? AppColors.heroStart.withOpacity(0.15) : AppColors.cardBorder);
    final bgColor = hasImage 
        ? Colors.white 
        : (isDashed ? AppColors.heroStart.withOpacity(0.06) : Colors.white);
    
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage 
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(imagePath!), fit: BoxFit.cover),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle, color: AppColors.green, size: 16),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isDashed ? Icons.add : Icons.camera_alt_outlined,
                      color: isDashed ? AppColors.titleDark : AppColors.labelGrey,
                      size: 26,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDashed ? AppColors.labelGrey : AppColors.labelGrey,
                      ),
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}

class _ConditionChip extends StatelessWidget {
  const _ConditionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.maroon : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppColors.maroon : AppColors.titleDark,
          ),
        ),
      ),
    );
  }
}

class _WhyPhotosCard extends StatelessWidget {
  const _WhyPhotosCard();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Why photos?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.titleDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Our warehouse team uses your photos to confirm it's our packaging before crediting your wallet. This keeps the system fair for everyone.",
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.bodyGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryNoticeCard extends StatelessWidget {
  const _DeliveryNoticeCard();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule, size: 20, color: AppColors.bodyGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Hand the packaging to your rider at the time of your '),
                  const TextSpan(
                    text: 'next delivery',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.titleDark),
                  ),
                  const TextSpan(
                    text: '. They\'ll carry it back to our warehouse for verification.',
                  ),
                ],
              ),
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: AppColors.bodyGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnToCartBottomBar extends StatelessWidget {
  const _ReturnToCartBottomBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pageBackground,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Material(
            color: AppColors.maroon,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Container(
                height: 56,
                alignment: Alignment.center,
                child: const Text(
                  'Return to Cart',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

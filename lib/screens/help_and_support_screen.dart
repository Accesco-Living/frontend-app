import 'dart:convert';

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';



/// ACCESCO Living — Help & Support



class HelpAndSupportScreen extends StatefulWidget {

  const HelpAndSupportScreen({

    super.key,

    this.onBack,

  });



  final VoidCallback? onBack;



  @override

  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();

}



class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> {

  static const Color _pageBackground = Color(0xFFFFF7FA);

  static const Color _dark = Color(0xFF1A1A1A);

  static const Color _primary = Color(0xFF7A0042);

  static const Color _pink = Color(0xFFC4126A);

  static const Color _muted = Color(0xFF6B7280);

  static const Color _cardBorder = Color(0xFFEDEDED);

  static const Color _iconCircle = Color(0xFFFDF2F5);



  final TextEditingController _searchController = TextEditingController();



  late final Uint8List _heroBytes = base64Decode(_helpHeroBase64);

  late final Uint8List _headsetBytes = base64Decode(_helpHeadsetBase64);

  late final Uint8List _searchBytes = base64Decode(_helpSearchBase64);

  late final Uint8List _headerBackBytes = base64Decode(_helpHeaderBackBase64);

  late final Uint8List _sectionChevronBytes = base64Decode(_helpSectionChevronBase64);



  String _query = '';



  final List<_HelpTopic> _topics = const [

    _HelpTopic('My Orders', 'Track, modify or cancel', _HelpIconType.orders),

    _HelpTopic(

      'Payments & Refunds',

      'Payments, refunds and offers',

      _HelpIconType.payment,

    ),

    _HelpTopic(

      'Delivery & Tracking',

      'Delivery status, delays & more',

      _HelpIconType.delivery,

    ),

    _HelpTopic(

      'Account & Login',

      'Profile, security and settings',

      _HelpIconType.account,

    ),

    _HelpTopic(

      'Returns & Cancellations',

      'Hassle-free returns',

      _HelpIconType.returns,

    ),

    _HelpTopic(

      'Offers & Rewards',

      'Codes, offers and benefits',

      _HelpIconType.rewards,

    ),

  ];



  final List<String> _questions = const [

    'How long does it take to get a response?',

    'I have an issue with my order.',

    'I want to become a delivery partner, vender or creator',

    'Where is Accesco Living based',

  ];



  @override

  void dispose() {

    _searchController.dispose();

    super.dispose();

  }



  TextStyle _montserrat({

    double size = 14,

    FontWeight weight = FontWeight.w400,

    Color color = _dark,

    double? height,

    double letterSpacing = 0,

  }) {

    return GoogleFonts.montserrat(

      fontSize: size,

      fontWeight: weight,

      color: color,

      height: height == null ? null : height / size,

      letterSpacing: letterSpacing,

    );

  }



  List<_HelpTopic> get _filteredTopics {

    final query = _query.trim().toLowerCase();

    if (query.isEmpty) return _topics;



    return _topics

        .where(

          (topic) =>

              topic.title.toLowerCase().contains(query) ||

              topic.description.toLowerCase().contains(query),

        )

        .toList();

  }



  List<String> get _filteredQuestions {

    final query = _query.trim().toLowerCase();

    if (query.isEmpty) return _questions;



    return _questions

        .where((question) => question.toLowerCase().contains(query))

        .toList();

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: _pageBackground,

      body: SafeArea(

        child: LayoutBuilder(

          builder: (context, constraints) {

            final width = constraints.maxWidth;

            final scale = (width / 402.0).toDouble();



            return SingleChildScrollView(

              physics: const BouncingScrollPhysics(),

              child: _buildPage(context, scale, width),

            );

          },

        ),

      ),

    );

  }



  Widget _buildPage(BuildContext context, double s, double width) {

    final side = 17.0 * s;

    final contentWidth = width - (side * 2);



    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        // Figma: Header top 17, height 26.

        SizedBox(height: 17 * s),

        _buildHeader(context, s),

        // Figma: Hero starts immediately after the header at y=43.

        _buildHero(s, width),

        // Figma: Search y=184, 10 px below hero.

        SizedBox(height: 20 * s),
        _buildSearch(s, width),

        // Figma: Popular topics y=230.

        SizedBox(height: 24 * s),
        _buildSectionHeader('Popular topics', s, onViewAll: _showAllTopics),

        // Figma: cards y=263.

        SizedBox(height: 16 * s),
        _buildTopics(s, contentWidth),

        // Figma: Common question starts 17 px after second card row.

        SizedBox(height: 32 * s),
        _buildSectionHeader('Common question', s, onViewAll: _showAllQuestions),

        SizedBox(height: 16 * s),
        _buildQuestions(s, contentWidth),

        // Figma/reference spacing before Contact Us.

        SizedBox(height: 32 * s),
        _buildContactTitle(s),

        SizedBox(height: 16 * s),
        _buildContactCards(s, contentWidth),

        SizedBox(height: 32 * s),
        _buildMessageCard(s, contentWidth),

        SizedBox(height: 48 * s),

      ],

    );

  }



  Widget _buildHeader(BuildContext context, double s) {

    return SizedBox(

      height: 26 * s,

      child: Padding(

        padding: EdgeInsets.symmetric(horizontal: 22.08 * s),

        child: Row(

          children: [

            SizedBox(

              width: 20 * s,

              height: 26 * s,

              child: InkWell(

                borderRadius: BorderRadius.circular(18 * s),

                onTap: widget.onBack ??

                    () => Navigator.of(context).maybePop(),

                child: Center(

                  child: SizedBox(

                    width: 14 * s,

                    height: 18 * s,

                    child: CustomPaint(

                      painter: _BackArrowPainter(

                        color: const Color(0xFF1A1A1A),

                        strokeWidth: 1.83 * s,

                      ),

                    ),

                  ),

                ),

              ),

            ),

            Expanded(

              child: Center(

                child: Text(

                  'Help & Support',

                  style: _montserrat(

                    size: 17 * s,

                    weight: FontWeight.w600,

                    color: const Color(0xFF1A1A1A),

                    height: 25.5 * s,

                    letterSpacing: -0.43 * s,

                  ),

                ),

              ),

            ),

            SizedBox(

              width: 20 * s,

              height: 26 * s,

              child: Center(

                child: Icon(Icons.headset_mic_outlined, color: const Color(0xFF7A0042), size: 20 * s),

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildHero(double s, double width) {

    return SizedBox(

      width: width,

      height: 131 * s,

      child: Stack(

        clipBehavior: Clip.none,

        children: [

          // Stack preserves the Figma visual positions without a Column overflow.

          Positioned(

            left: 14 * s,

            top: 17 * s,

            width: (width < 380 ? 178 : 190) * s,

            height: 116 * s,

            child: Stack(

              clipBehavior: Clip.none,

              children: [

                Positioned(

                  left: 0, top: 0, width: (width < 380 ? 178 : 190) * s, height: 16 * s,

                  child: Text(

                    "WE'RE HERE FOR YOU", maxLines: 1,

                    style: _montserrat(size: 10 * s, weight: FontWeight.w700, color: _pink, height: 16 * s, letterSpacing: 1 * s),

                  ),

                ),

                Positioned(

                  left: 0, top: 20 * s, width: (width < 380 ? 178 : 190) * s, height: 30 * s,

                  child: Text(

                    'How can we', maxLines: 1, softWrap: false,

                    style: _montserrat(size: 23 * s, weight: FontWeight.w700, color: const Color(0xFF1A1A1A), height: 30 * s),

                  ),

                ),

                Positioned(

                  left: 0, top: 50 * s, width: (width < 380 ? 178 : 190) * s, height: 30 * s,

                  child: Text(

                    'help you today?', maxLines: 1, softWrap: false,

                    style: _montserrat(size: 23 * s, weight: FontWeight.w700, color: const Color(0xFF7A0042), height: 30 * s),

                  ),

                ),

                Positioned(

                  left: 0, top: 84 * s, width: (width < 380 ? 176 : 184) * s, height: 36 * s,

                  child: Text(

                    'Find answers, get support, or reach out to our team.', maxLines: 2, overflow: TextOverflow.clip,

                    style: _montserrat(size: 12 * s, color: _muted, height: 18 * s),

                  ),

                ),

              ],

            ),

          ),

          Positioned(

            left: 190 * s,

            top: 2 * s,

            width: 204 * s,

            height: 140 * s,

            child: Image.asset(

              'assets/images/support.png',

              fit: BoxFit.contain,

              alignment: Alignment.topLeft,

              filterQuality: FilterQuality.high,

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildSearch(double s, double width) {

    return Padding(

      padding: EdgeInsets.symmetric(horizontal: 13 * s),

      child: Container(

        width: width - 26 * s,

        height: 39 * s,

        decoration: BoxDecoration(

          color: _muted.withOpacity(0.10),

          borderRadius: BorderRadius.circular(25 * s),

        ),

        padding: EdgeInsets.only(left: 12 * s, right: 21 * s),

        child: Row(

          children: [

            Icon(Icons.search, color: const Color(0xFF7A0042), size: 19.41 * s),

            SizedBox(width: 7 * s),

            Expanded(

              child: TextField(

                controller: _searchController,

                onChanged: (value) => setState(() => _query = value),

                cursorColor: _primary,

                textAlignVertical: TextAlignVertical.center,

                style: _montserrat(

                  size: 12 * s,

                  color: const Color(0xFF1A1A1A),

                  height: 15 * s,

                ),

                decoration: InputDecoration(

                  hintText:

                      'Search for help (e.g. order, refund, payment...)',

                  hintStyle: _montserrat(

                    size: 12 * s,

                    color: _muted,

                    height: 15 * s,

                  ),

                  border: InputBorder.none,

                  isCollapsed: true,

                  contentPadding: EdgeInsets.zero,

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildSectionHeader(

    String title,

    double s, {

    required VoidCallback onViewAll,

  }) {

    return Padding(

      padding: EdgeInsets.only(left: 18 * s, right: 12 * s),

      child: SizedBox(

        height: 24 * s,

        child: Row(

          crossAxisAlignment: CrossAxisAlignment.center,

          children: [

            Text(

              title,

              style: _montserrat(

                size: 16,

                weight: FontWeight.w700,

                color: const Color(0xFF1A1A1A),

                height: 24 * s,

                letterSpacing: -0.4 * s,

              ),

            ),

            const Spacer(),

            // This is a real interactive control, not decorative text.

            Material(

              color: Colors.transparent,

              child: InkWell(

                borderRadius: BorderRadius.circular(8 * s),

                onTap: onViewAll,

                child: SizedBox(

                  width: 66 * s,

                  height: 24 * s,

                  child: Row(

                    mainAxisAlignment: MainAxisAlignment.end,

                    children: [

                      SizedBox(

                        width: 51 * s,

                        height: 19 * s,

                        child: FittedBox(

                          fit: BoxFit.scaleDown,

                          alignment: Alignment.centerLeft,

                          child: Text(

                            'View all',

                            maxLines: 1,

                            softWrap: false,

                            style: _montserrat(

                              size: 12.5 * s,

                              weight: FontWeight.w600,

                              color: _pink,

                              height: 18.75 * s,

                            ),

                          ),

                        ),

                      ),

                      SizedBox(width: 1 * s),

                      SizedBox(

                        width: 14 * s,

                        height: 14 * s,

                        child: CustomPaint(

                          painter: _ViewAllChevronPainter(scale: s),

                        ),

                      ),

                    ],

                  ),

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget _buildTopics(double s, double contentWidth) {

    final topics = _filteredTopics;



    if (topics.isEmpty) {

      return Padding(

        padding: EdgeInsets.symmetric(horizontal: 17 * s),

        child: _emptyState(s),

      );

    }



    // Exact Figma/reference positions at 402 px:

    // x = 17, 145, 281; card = 112 x 123.25.

    // The asymmetric second gap is intentional because these are the

    // measured Figma positions, not a generic equal-spacing grid.

    final cardWidth = 112 * s;

    final cardHeight = 123.25 * s;

    final firstGap = 16 * s;

    final secondGap = 24 * s;



    if (contentWidth >= 365 * s && topics.length <= 3) {

      return Padding(

        padding: EdgeInsets.only(left: 17 * s),

        child: Row(

          children: [

            for (int i = 0; i < topics.length; i++) ...[

              SizedBox(

                width: cardWidth,

                height: cardHeight,

                child: _TopicCard(

                  topic: topics[i],

                  scale: s,

                  textStyle: _montserrat,

                  onTap: () => _openTopic(topics[i]),

                ),

              ),

              if (i == 0 && topics.length > 1)

                SizedBox(width: firstGap),

              if (i == 1 && topics.length > 2)

                SizedBox(width: secondGap),

            ],

          ],

        ),

      );

    }



    // Dynamic search state: keep the same three-column Figma rhythm.

    final rows = <Widget>[];

    for (int start = 0; start < topics.length; start += 3) {

      final end = start + 3 < topics.length ? start + 3 : topics.length;

      final rowItems = topics.sublist(start, end);



      rows.add(

        Padding(

          padding: EdgeInsets.only(left: 17 * s),

          child: Row(

            children: [

              for (int i = 0; i < rowItems.length; i++) ...[

                SizedBox(

                  width: cardWidth,

                  height: cardHeight,

                  child: _TopicCard(

                    topic: rowItems[i],

                    scale: s,

                    textStyle: _montserrat,

                    onTap: () => _openTopic(rowItems[i]),

                  ),

                ),

                if (i == 0 && rowItems.length > 1)

                  SizedBox(width: firstGap),

                if (i == 1 && rowItems.length > 2)

                  SizedBox(width: secondGap),

              ],

            ],

          ),

        ),

      );



      if (start + 3 < topics.length) {

        rows.add(SizedBox(height: 16 * s));

      }

    }



    return Column(children: rows);

  }



  Widget _buildQuestions(double s, double contentWidth) {

    final questions = _filteredQuestions;



    if (questions.isEmpty) {

      return Padding(

        padding: EdgeInsets.symmetric(horizontal: 17 * s),

        child: _emptyState(s),

      );

    }



    return Padding(

      padding: EdgeInsets.symmetric(horizontal: 17 * s),

      child: Container(

        width: contentWidth,

        decoration: BoxDecoration(

          color: Colors.white,

          borderRadius: BorderRadius.circular(12 * s),

          border: Border.all(color: _cardBorder, width: s),

        ),

        clipBehavior: Clip.antiAlias,

        child: Column(

          children: [

            for (int i = 0; i < questions.length; i++)

              _QuestionRow(

                text: questions[i],

                scale: s,

                textStyle: _montserrat,

                showDivider: i != questions.length - 1,

                onTap: () => _openQuestion(questions[i]),

              ),

          ],

        ),

      ),

    );

  }



  Widget _buildContactTitle(double s) {

    return Padding(

      padding: EdgeInsets.symmetric(horizontal: 17 * s),

      child: SizedBox(

        height: 19 * s,

        child: Text(

          'Contact Us',

          style: _montserrat(

            size: 16,

            weight: FontWeight.w700,

            color: const Color(0xFF1A1A1A),

            height: 19 * s,

            letterSpacing: -0.4 * s,

          ),

        ),

      ),

    );

  }



  Widget _buildContactCards(double s, double contentWidth) {

    // Figma reference: 402 px frame, 17 px side padding,

    // 112 x 175 px cards, 16 px gaps.

    const double figmaCardWidth = 112;

    const double figmaGap = 16;



    return Padding(

      padding: EdgeInsets.symmetric(horizontal: 17 * s),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          SizedBox(

            width: figmaCardWidth * s,

            height: 175 * s,

            child: _ContactCard(

              icon: _HelpIconType.mail,

              title: 'Email us',

              accent: 'support@acce\nscoliving.com',

              description: 'We usually respond within 24 hours.',

              scale: s,

              textStyle: _montserrat,

            ),

          ),

          SizedBox(width: figmaGap * s),

          SizedBox(

            width: figmaCardWidth * s,

            height: 175 * s,

            child: _ContactCard(

              icon: _HelpIconType.phone,

              title: 'Call us',

              accent: '+91 8012345678',

              description: 'Mon – Sat · 9 AM – 6 PM IST Available for urgent queries.',

              scale: s,

              textStyle: _montserrat,

            ),

          ),

          SizedBox(width: figmaGap * s),

          SizedBox(

            width: figmaCardWidth * s,

            height: 175 * s,

            child: _ContactCard(

              icon: _HelpIconType.location,

              title: 'Our Office',

              accent: 'Bengaluru,\nKarnataka, India',

              description: 'Visit us at our registered office.',

              scale: s,

              textStyle: _montserrat,

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildMessageCard(double s, double contentWidth) {

    return Padding(

      padding: EdgeInsets.symmetric(horizontal: 17 * s),

      child: Material(

        color: Colors.transparent,

        child: InkWell(

          borderRadius: BorderRadius.circular(16 * s),

          onTap: _openMessage,

          child: Container(

            width: 367 * s,

            height: 81.99 * s,

            padding: EdgeInsets.symmetric(horizontal: 15 * s),

            decoration: BoxDecoration(

              color: const Color(0xFFFDF2F5).withOpacity(0.90),

              borderRadius: BorderRadius.circular(16 * s),

              border: Border.all(

                color: const Color(0xFF7A0042).withOpacity(0.10),

                width: s,

              ),

            ),

            child: Row(

              children: [

                SizedBox(

                  width: 44, height: 44,

                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
                      color: const Color(0xFF7A0042),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(Icons.send, color: Colors.white, size: 20 * s),
                    ),
                  ),

                ),

                SizedBox(width: 13 * s),

                Expanded(

                  child: Column(

                    mainAxisAlignment: MainAxisAlignment.center,

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(

                        'Send us a message',

                        style: _montserrat(

                          size: 13.5 * s,

                          weight: FontWeight.w700,

                          color: const Color(0xFF1A1A1A),

                          height: 16.88 * s,

                        ),

                      ),

                      SizedBox(height: 2 * s),

                      Text(

                        "Share your query and we'll get back to you\nsoon.",

                        maxLines: 2,

                        style: _montserrat(

                          size: 11 * s,

                          color: _muted,

                          height: 16.5 * s,

                        ),

                      ),

                    ],

                  ),

                ),

                SizedBox(width: 8 * s),

                Icon(Icons.chevron_right, color: const Color(0xFF7A0042), size: 16),

                SizedBox(width: 4 * s),

              ],

            ),

          ),

        ),

      ),

    );

  }



  Widget _emptyState(double s) {

    return Container(

      width: double.infinity,

      padding: EdgeInsets.symmetric(

        vertical: 18 * s,

        horizontal: 14 * s,

      ),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(12 * s),

        border: Border.all(color: _cardBorder),

      ),

      child: Text(

        'No matching help topics found.',

        textAlign: TextAlign.center,

        style: _montserrat(size: 12 * s, color: _muted),

      ),

    );

  }



  void _showAllTopics() {

    showModalBottomSheet<void>(

      context: context,

      backgroundColor: _pageBackground,

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),

      ),

      builder: (sheetContext) => SafeArea(

        child: Padding(

          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text('Popular topics', style: _montserrat(size: 18, weight: FontWeight.w700)),

              const SizedBox(height: 8),

              ..._topics.map(

                (topic) => ListTile(

                  contentPadding: EdgeInsets.zero,

                  leading: Image.memory(

                    base64Decode(_topicIconBase64(topic.icon)),

                    width: 36,

                    height: 36,

                  ),

                  title: Text(topic.title, style: _montserrat(size: 14, weight: FontWeight.w700)),

                  subtitle: Text(topic.description, style: _montserrat(size: 11, color: _muted)),

                  onTap: () {

                    Navigator.pop(sheetContext);

                    _openTopic(topic);

                  },

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }



  void _showAllQuestions() {

    showModalBottomSheet<void>(

      context: context,

      backgroundColor: _pageBackground,

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),

      ),

      builder: (sheetContext) => SafeArea(

        child: Padding(

          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),

          child: Column(

            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text('Common question', style: _montserrat(size: 18, weight: FontWeight.w700)),

              const SizedBox(height: 8),

              ..._questions.map(

                (question) => ListTile(

                  contentPadding: EdgeInsets.zero,

                  title: Text(question, style: _montserrat(size: 13.5)),

                  trailing: Icon(Icons.chevron_right, color: const Color(0xFF7A0042), size: 14),

                  onTap: () {

                    Navigator.pop(sheetContext);

                    _openQuestion(question);

                  },

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }



  void _openTopic(_HelpTopic topic) {

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(topic.title),

        behavior: SnackBarBehavior.floating,

      ),

    );

  }



  void _openQuestion(String question) {

    showModalBottomSheet<void>(

      context: context,

      backgroundColor: Colors.white,

      shape: RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(

          top: Radius.circular(20),

        ),

      ),

      builder: (context) => SafeArea(

        child: Padding(

          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),

          child: Text(

            question,

            style: _montserrat(

              size: 16,

              weight: FontWeight.w600,

              color: const Color(0xFF1A1A1A),

              height: 24,

            ),

          ),

        ),

      ),

    );

  }



  void _openMessage() {

    showModalBottomSheet<void>(

      context: context,

      backgroundColor: Colors.white,

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),

      ),

      builder: (context) => SafeArea(

        child: Padding(

          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),

          child: Text(

            'Send us a message',

            style: _montserrat(

              size: 18,

              weight: FontWeight.w700,

              color: const Color(0xFF1A1A1A),

            ),

          ),

        ),

      ),

    );

  }

}



class _BackArrowPainter extends CustomPainter {

  const _BackArrowPainter({

    required this.color,

    required this.strokeWidth,

  });



  final Color color;

  final double strokeWidth;



  @override

  void paint(Canvas canvas, Size size) {

    final paint = Paint()

      ..color = color

      ..style = PaintingStyle.stroke

      ..strokeWidth = strokeWidth

      ..strokeCap = StrokeCap.round

      ..strokeJoin = StrokeJoin.round;



    final path = Path()

      ..moveTo(size.width * 0.68, size.height * 0.17)

      ..lineTo(size.width * 0.27, size.height * 0.50)

      ..lineTo(size.width * 0.68, size.height * 0.83);



    canvas.drawPath(path, paint);

  }



  @override

  bool shouldRepaint(covariant _BackArrowPainter oldDelegate) =>

      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;

}



class _HelpTopic {

  const _HelpTopic(this.title, this.description, this.icon);



  final String title;

  final String description;

  final _HelpIconType icon;

}



enum _HelpIconType {

  orders,

  payment,

  delivery,

  account,

  returns,

  rewards,

  mail,

  phone,

  location,

}



class _TopicCard extends StatelessWidget {

  const _TopicCard({

    required this.topic,

    required this.scale,

    required this.textStyle,

    required this.onTap,

  });



  final _HelpTopic topic;

  final double scale;

  final TextStyle Function({

    double size,

    FontWeight weight,

    Color color,

    double? height,

    double letterSpacing,

  }) textStyle;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    return Material(

      color: Colors.transparent,

      child: InkWell(

        borderRadius: BorderRadius.circular(16 * scale),

        onTap: onTap,

        child: Container(

          width: 112 * scale,

          height: 123.25 * scale,

          decoration: BoxDecoration(

            color: Colors.white,

            borderRadius: BorderRadius.circular(16 * scale),

            border: Border.all(

              color: const Color(0xFFEDEDED),

              width: scale,

            ),

            boxShadow: [

              BoxShadow(

                color: Colors.black.withOpacity(0.03),

                offset: Offset(0, 1 * scale),

                blurRadius: 3 * scale,

              ),

              BoxShadow(

                color: Colors.black.withOpacity(0.02),

                offset: Offset(0, 2 * scale),

                blurRadius: 10 * scale,

              ),

            ],

          ),

          child: Stack(

            children: [

              // Figma icon container: 36 x 36, #FDF2F5.

              Positioned(

                left: 14 * scale,

                top: 13 * scale,

                child: Container(
                  width: 36 * scale,
                  height: 36 * scale,
                  decoration: const BoxDecoration(
                    color: const Color(0xFFFDF2F5),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(_getTopicIcon(topic.icon), color: const Color(0xFF7A0042), size: 20 * scale),
                  ),
                ),

              ),

              // Figma title area begins around y=38.

              Positioned(

                left: 14 * scale,

                top: 55 * scale,

                width: 84 * scale,

                height: 34 * scale,

                child: Text(

                  topic.title,

                  maxLines: 2,

                  softWrap: true,

                  overflow: TextOverflow.fade,

                  style: textStyle(

                    size: 12 * scale,

                    weight: FontWeight.w700,

                    color: const Color(0xFF1A1A1A),

                    height: 16.5 * scale,

                  ),

                ),

              ),

              // Figma description starts around y=76.

              Positioned(

                left: 14 * scale,

                top: 89 * scale,

                width: 84 * scale,

                height: 30 * scale,

                child: Text(

                  topic.description,

                  maxLines: 2,

                  overflow: TextOverflow.clip,

                  style: textStyle(

                    size: 10 * scale,

                    color: const Color(0xFF6B7280),

                    height: 12.5 * scale,

                  ),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}



class _QuestionRow extends StatelessWidget {

  const _QuestionRow({

    required this.text,

    required this.scale,

    required this.textStyle,

    required this.showDivider,

    required this.onTap,

  });



  final String text;

  final double scale;

  final TextStyle Function({

    double size,

    FontWeight weight,

    Color color,

    double? height,

    double letterSpacing,

  }) textStyle;

  final bool showDivider;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    return Material(

      color: Colors.transparent,

      child: InkWell(

        onTap: onTap,

        child: Container(

          height: 48 * scale,

          padding: EdgeInsets.symmetric(horizontal: 10 * scale),

          decoration: BoxDecoration(

            border: showDivider

                ? Border(

                    bottom: BorderSide(

                      color: const Color(0xFFEDEDED),

                      width: scale,

                    ),

                  )

                : null,

          ),

          child: Row(

            children: [

              Expanded(

                child: Text(

                  text,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: textStyle(

                    size: 13.5 * scale,

                    color: _HelpAndSupportColors.dark,

                    height: 20 * scale,

                  ),

                ),

              ),

              SizedBox(width: 5 * scale),

              Icon(Icons.chevron_right, color: const Color(0xFF7A0042), size: 14),

            ],

          ),

        ),

      ),

    );

  }

}



class _ContactCard extends StatelessWidget {

  const _ContactCard({

    required this.icon,

    required this.title,

    required this.accent,

    required this.description,

    required this.scale,

    required this.textStyle,

  });



  final _HelpIconType icon;

  final String title;

  final String accent;

  final String description;

  final double scale;

  final TextStyle Function({

    double size,

    FontWeight weight,

    Color color,

    double? height,

    double letterSpacing,

  }) textStyle;



  @override

  Widget build(BuildContext context) {

    return Container(

      width: 112 * scale,

      height: 175 * scale,

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(16 * scale),

        border: Border.all(

          color: const Color(0xFFEDEDED),

          width: scale,

        ),

      ),

      child: Stack(

        clipBehavior: Clip.hardEdge,

        children: [

          // The supplied Figma icon export is a 69 px canvas with

          // a 57 px pink circle. Rendering it at 44 px gives the

          // required 36 px circle at the 402 px reference scale.

          Positioned(

            left: 13 * scale,

            top: 14 * scale,

            width: 44 * scale,
            height: 44 * scale,
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 36 * scale,
                height: 36 * scale,
                decoration: const BoxDecoration(
                  color: const Color(0xFFFDF2F5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(_getContactIcon(icon), color: const Color(0xFF7A0042), size: 18 * scale),
                ),
              ),
            ),
            ),



          Positioned(

            left: 13 * scale,

            top: 52 * scale,

            right: 8 * scale,

            height: 18 * scale,

            child: Text(

              title,

              maxLines: 1,

              overflow: TextOverflow.clip,

              style: textStyle(

                size: 12 * scale,

                weight: FontWeight.w700,

                color: _HelpAndSupportColors.dark,

                height: 15 * scale,

              ),

            ),

          ),



          Positioned(

            left: 13 * scale,

            top: 74 * scale,

            right: 7 * scale,

            height: 44 * scale,

            child: Text(

              accent,

              maxLines: icon == _HelpIconType.phone ? 1 : 3,

              overflow: TextOverflow.clip,

              style: textStyle(

                size: 11 * scale,

                weight: FontWeight.w700,

                color: const Color(0xFF7A0042),

                height: 14 * scale,

              ),

            ),

          ),



          Positioned(

            left: 13 * scale,

            top: (icon == _HelpIconType.location ? 116 : 108) * scale,

            right: 7 * scale,

            height: (icon == _HelpIconType.phone ? 58 : 42) * scale,

            child: Text(

              description,

              maxLines: icon == _HelpIconType.phone ? 5 : 4,

              overflow: TextOverflow.clip,

              style: textStyle(

                size: 10 * scale,

                weight: FontWeight.w400,

                color: const Color(0xFF8E8E93),

                height: 13.5 * scale,

              ),

            ),

          ),

        ],

      ),

    );

  }

}



class _ViewAllChevronPainter extends CustomPainter {

  const _ViewAllChevronPainter({required this.scale});



  final double scale;



  @override

  void paint(Canvas canvas, Size size) {

    final paint = Paint()

      ..color = const Color(0xFFC4126A)

      ..style = PaintingStyle.stroke

      ..strokeWidth = 1.28 * scale

      ..strokeCap = StrokeCap.round

      ..strokeJoin = StrokeJoin.round;



    // Figma vector: 4.08 x 8.17 px, centered in a 14 x 14 px container.

    final cx = size.width / 2;

    final top = (size.height - 8.17 * scale) / 2;

    final left = cx - 2.04 * scale;

    final path = Path()

      ..moveTo(left, top)

      ..lineTo(left + 3.55 * scale, top + 4.08 * scale)

      ..lineTo(left, top + 8.17 * scale);

    canvas.drawPath(path, paint);

  }



  @override

  bool shouldRepaint(covariant _ViewAllChevronPainter oldDelegate) =>

      oldDelegate.scale != scale;

}



class _HelpAndSupportColors {

  static const Color dark = Color(0xFF1A1A1A);

  static const Color primary = Color(0xFF7A0042);

  static const Color iconCircle = Color(0xFFFDF2F5);

}



// Exact icon crops taken from the supplied 402 px reference image. They are

// displayed at their Figma dimensions, so the icon shapes/colors match the

// reference rather than relying on a platform-dependent Material icon.



String _topicIconBase64(_HelpIconType type) {

  switch (type) {

    case _HelpIconType.orders:

      return _helpOrdersIconBase64;

    case _HelpIconType.payment:

      return _helpPaymentIconBase64;

    case _HelpIconType.delivery:

      return _helpDeliveryIconBase64;

    case _HelpIconType.account:

      return _helpAccountIconBase64;

    case _HelpIconType.returns:

      return _helpReturnsIconBase64;

    case _HelpIconType.rewards:

      return _helpRewardsIconBase64;

    default:

      return _helpOrdersIconBase64;

  }

}



String _contactIconBase64(_HelpIconType type) {

  switch (type) {

    case _HelpIconType.mail:

      return _helpMailIconBase64;

    case _HelpIconType.phone:

      return _helpPhoneIconBase64;

    case _HelpIconType.location:

      return _helpLocationIconBase64;

    default:

      return _helpMailIconBase64;

  }

}





const String _helpQuestionChevronBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
const String _helpOrdersIconBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
const String _helpLocationIconBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
const String _helpDeliveryIconBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
const String _helpSearchBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
const String _helpSectionChevronBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
const String _helpHeroBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
const String _helpHeadsetBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
const String _helpReturnsIconBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
const String _helpHeaderBackBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
const String _helpPaymentIconBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
const String _helpRewardsIconBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
const String _helpPhoneIconBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
const String _helpSendCircleBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
const String _helpAccountIconBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
const String _helpMailIconBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
const String _helpMessageChevronBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

IconData _getTopicIcon(_HelpIconType type) {
  switch (type) {
    case _HelpIconType.orders: return Icons.inventory_2_outlined;
    case _HelpIconType.payment: return Icons.payment_outlined;
    case _HelpIconType.delivery: return Icons.local_shipping_outlined;
    case _HelpIconType.account: return Icons.person_outline;
    case _HelpIconType.returns: return Icons.published_with_changes_outlined;
    case _HelpIconType.rewards: return Icons.card_giftcard_outlined;
    default: return Icons.inventory_2_outlined;
  }
}

IconData _getContactIcon(_HelpIconType type) {
  switch (type) {
    case _HelpIconType.mail: return Icons.mail_outline;
    case _HelpIconType.phone: return Icons.phone_outlined;
    case _HelpIconType.location: return Icons.location_on_outlined;
    default: return Icons.mail_outline;
  }
}

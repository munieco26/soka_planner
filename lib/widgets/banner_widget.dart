import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/event.dart';
import '../utils/globals.dart';

class BannerWidget extends StatelessWidget {
  final List<Event> banners;
  final VoidCallback? onClose;

  const BannerWidget({super.key, required this.banners, this.onClose});

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    print('📢 Displaying ${banners.length} banner(s)');

    return LayoutBuilder(
      builder: (context, constraints) {
        final wideScreen = isWide(context);

        if (wideScreen) {
          // Desktop: Display banners in a row (flex-row)
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: banners
                .map(
                  (banner) =>
                      Expanded(child: _buildBannerCard(banner, isWide: true)),
                )
                .toList(),
          );
        } else {
          // Mobile: Display banners in a column (flex-column)
          return Column(
            children: banners
                .map(
                  (banner) => _buildBannerCard(
                    banner,
                    isWide: false,
                    showCloseButton: onClose != null,
                  ),
                )
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildBannerCard(
    Event banner, {
    required bool isWide,
    bool showCloseButton = false,
  }) {
    // Use text color from event, default to white if not specified
    final textColor = banner.textColor != null
        ? Color(banner.textColor!)
        : Colors.white;
    final textColor70 = banner.textColor != null
        ? Color(banner.textColor!).withOpacity(0.7)
        : Colors.white70;

    return Container(
      width: isWide ? null : double.infinity,
      constraints: isWide
          ? const BoxConstraints(minHeight: 80) // Rectangle shape for desktop
          : null,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 20 : 14,
        vertical: isWide ? 16 : 8,
      ),
      margin: isWide
          ? const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ) // Small gap between banners
          : const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
      decoration: BoxDecoration(
        color: Color(banner.color),
        borderRadius: BorderRadius.circular(10),
        border: isWide
            ? Border(
                right: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              )
            : null,
      ),
      child: Stack(
        children: [
          // Content with padding to avoid overlap with close button
          Padding(
            padding: EdgeInsets.only(
              right: showCloseButton
                  ? 32
                  : 0, // Add padding when close button is visible
            ),
            child: Center(
              child: Html(
                data: banner.description ?? '<h1>${banner.title}</h1>',
                style: {
                  "body": Style(
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    color: textColor,
                    fontSize: FontSize(13),
                    textAlign: TextAlign.center,
                  ),
                  "h1": Style(
                    color: textColor,
                    fontSize: FontSize(isWide ? 16 : 12),
                    fontWeight: FontWeight.w800,
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    textAlign: TextAlign.center,
                    lineHeight: LineHeight(1.5),
                  ),
                  "h2": Style(
                    color: textColor,
                    fontSize: FontSize(isWide ? 16 : 13),
                    fontWeight: FontWeight.w800,
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    textAlign: TextAlign.center,
                    lineHeight: LineHeight(1.3),
                  ),
                  "p": Style(
                    color: textColor70,
                    fontSize: FontSize(isWide ? 12 : 11),
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                    textAlign: TextAlign.center,
                    lineHeight: LineHeight(1.2),
                  ),
                },
              ),
            ),
          ),
          // Close button positioned at top right, near the border
          if (showCloseButton)
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, color: textColor, size: 18),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

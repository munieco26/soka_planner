import 'package:flutter/material.dart';
import '../utils/globals.dart';
import '../utils/calendar_view_type.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final int unreadNotificationCount;
  final VoidCallback? onSettings;
  final Function(CalendarViewType)? onChangeView;
  final VoidCallback? onNotifications;
  final bool showViewButton;
  final CalendarViewType? currentViewType;
  final List<Widget>? additionalActions;
  final VoidCallback? onShowBanner;
  final bool showBannerIcon;
  final VoidCallback? onMenuTap;

  const CustomAppBar({
    super.key,
    this.title,
    this.unreadNotificationCount = 0,
    this.onSettings,
    this.onChangeView,
    this.onNotifications,
    this.showViewButton = true,
    this.currentViewType,
    this.additionalActions,
    this.onShowBanner,
    this.showBannerIcon = false,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool mobileScreen = isMobile(context);

    return AppBar(
      backgroundColor: AppColors.white,
      title: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              Image.asset('web/icons/Icon-192.png', height: 36, width: 36),
              if (!mobileScreen && title != null) ...[
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    title!,
                    style: const TextStyle(
                      color: AppColors.soka,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          );
        },
      ),
      iconTheme: const IconThemeData(color: AppColors.soka),
      leading: mobileScreen && onMenuTap != null
          ? IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuTap,
              tooltip: 'Menú',
            )
          : null,
      actions: [
        if (showBannerIcon && onShowBanner != null)
          IconButton(
            tooltip: 'Mostrar banner',
            onPressed: onShowBanner,
            icon: const Icon(Icons.comment),
          ),
        // Hide settings and view button on mobile (they're in the drawer)
        if (!mobileScreen && onSettings != null)
          IconButton(
            tooltip: 'Configuración',
            onPressed: onSettings,
            icon: const Icon(Icons.settings),
          ),
        if (!mobileScreen && showViewButton && onChangeView != null)
          PopupMenuButton<CalendarViewType>(
            tooltip: 'Vista',
            icon: const Icon(Icons.calendar_month),
            onSelected: onChangeView,
            itemBuilder: (context) => [
              PopupMenuItem<CalendarViewType>(
                value: CalendarViewType.day,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: currentViewType == CalendarViewType.day
                          ? AppColors.primary
                          : AppColors.black87,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      CalendarViewType.day.displayName,
                      style: TextStyle(
                        fontWeight: currentViewType == CalendarViewType.day
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: currentViewType == CalendarViewType.day
                            ? AppColors.primary
                            : AppColors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<CalendarViewType>(
                value: CalendarViewType.week,
                child: Row(
                  children: [
                    Icon(
                      Icons.view_week,
                      size: 18,
                      color: currentViewType == CalendarViewType.week
                          ? AppColors.primary
                          : AppColors.black87,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      CalendarViewType.week.displayName,
                      style: TextStyle(
                        fontWeight: currentViewType == CalendarViewType.week
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: currentViewType == CalendarViewType.week
                            ? AppColors.primary
                            : AppColors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<CalendarViewType>(
                value: CalendarViewType.month,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 18,
                      color: currentViewType == CalendarViewType.month
                          ? AppColors.primary
                          : AppColors.black87,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      CalendarViewType.month.displayName,
                      style: TextStyle(
                        fontWeight: currentViewType == CalendarViewType.month
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: currentViewType == CalendarViewType.month
                            ? AppColors.primary
                            : AppColors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<CalendarViewType>(
                value: CalendarViewType.year,
                child: Row(
                  children: [
                    Icon(
                      Icons.view_module,
                      size: 18,
                      color: currentViewType == CalendarViewType.year
                          ? AppColors.primary
                          : AppColors.black87,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      CalendarViewType.year.displayName,
                      style: TextStyle(
                        fontWeight: currentViewType == CalendarViewType.year
                            ? FontWeight.w700
                            : FontWeight.normal,
                        color: currentViewType == CalendarViewType.year
                            ? AppColors.primary
                            : AppColors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        if (onNotifications != null)
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notificaciones',
                onPressed: onNotifications,
                icon: const Icon(Icons.notifications),
              ),
              if (unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadNotificationCount > 99
                          ? '99+'
                          : '$unreadNotificationCount',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        if (additionalActions != null) ...additionalActions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

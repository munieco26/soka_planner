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
            itemBuilder: (context) => CalendarViewType.values
                .map((v) => PopupMenuItem<CalendarViewType>(
                      value: v,
                      child: Row(
                        children: [
                          Icon(
                            _viewIcon(v),
                            size: 18,
                            color: currentViewType == v
                                ? AppColors.primary
                                : AppColors.black87,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            v.displayName,
                            style: TextStyle(
                              fontWeight: currentViewType == v
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              color: currentViewType == v
                                  ? AppColors.primary
                                  : AppColors.black87,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
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

  IconData _viewIcon(CalendarViewType v) {
    switch (v) {
      case CalendarViewType.day:
        return Icons.calendar_today;
      case CalendarViewType.week:
        return Icons.view_week;
      case CalendarViewType.month:
        return Icons.calendar_month;
      case CalendarViewType.year:
        return Icons.view_module;
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import '../services/calendar_repository.dart';
import '../services/permission_service.dart';
import '../services/google_sheets_service.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/weeks_list_widget.dart';
import '../widgets/event_detail_sheet.dart';
import '../widgets/banner_widget.dart';
import '../widgets/notification_list_modal.dart';
import '../widgets/custom_app_bar.dart';
import '../services/notification_storage_service.dart';
import '../utils/globals.dart';
import '../utils/calendar_view_type.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Event> _events = [];
  List<Event> _sheetsEvents = [];
  bool _loading = true;
  bool _loadingSheets = true;
  final _sheetsService = GoogleSheetsService();
  int _unreadNotificationCount = 0;
  late CalendarViewType _currentViewType;
  bool _bannerVisible = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Default to month view, will be adjusted in build if mobile
    _currentViewType = CalendarViewType.month;
    _loadMonth(_focusedDay);
    _loadSheetsData();
    _loadUnreadCount();
    _loadBannerVisibility();
  }

  Future<void> _loadBannerVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bannerVisible = prefs.getBool('banner_visible') ?? true;
    });
  }

  Future<void> _hideBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('banner_visible', false);
    setState(() {
      _bannerVisible = false;
    });
  }

  Future<void> _showBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('banner_visible', true);
    setState(() {
      _bannerVisible = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set default view based on screen size after context is available
    // Desktop: Month, Mobile: Week
    if (_currentViewType == CalendarViewType.month) {
      // Only set default if still on initial month view
      final bool mobile = isMobile(context);
      if (mobile && mounted) {
        setState(() {
          _currentViewType = CalendarViewType.week;
        });
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotificationStorageService.getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadNotificationCount = count;
      });
    }
  }

  Future<void> _loadSheetsData() async {
    setState(() => _loadingSheets = true);
    try {
      final events = await _sheetsService.fetchEvents();
      final banners = events
          .where((e) => e.tag.toLowerCase() == 'banner')
          .length;
      final weeks = events.where((e) => e.tag.toLowerCase() == 'week').length;
      setState(() {
        _sheetsEvents = events;
        _loadingSheets = false;
      });
      print('✅ Loaded ${events.length} events from Google Sheets');
      print('   📢 Banners: $banners');
      print('   📅 Weeks: $weeks');
    } catch (e) {
      setState(() => _loadingSheets = false);
      print('❌ Error loading Google Sheets data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos de Google Sheets: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _loadMonth(DateTime anchor) async {
    setState(() => _loading = true);
    try {
      final first = DateTime(anchor.year, anchor.month, 1);
      final last = DateTime(anchor.year, anchor.month + 1, 0);
      final repo = context.read<CalendarRepository>();
      final events = await repo.fetchEvents(from: first, to: last);
      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar eventos: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Refresh all data (calendar events and Google Sheets data)
  Future<void> _refreshAllData() async {
    await Future.wait([
      _loadMonth(_focusedDay),
      _loadSheetsData(),
      _loadUnreadCount(),
    ]);
  }

  // Filtering by day is handled inside the calendar widget; Google Sheets items are filtered by month/year.

  @override
  Widget build(BuildContext context) {
    // Month title handled inside calendar header
    final bool wideScreen = isWide(context);
    final bool isMobileScreen = isMobile(context);
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: 'Agenda Soka',
        unreadNotificationCount: _unreadNotificationCount,
        onSettings: _showSettings,
        onChangeView: _changeView,
        onNotifications: _showNotifications,
        currentViewType: _currentViewType,
        onShowBanner: _showBanner,
        showBannerIcon: !_bannerVisible && isMobileScreen,
        onMenuTap: isMobileScreen
            ? () => _scaffoldKey.currentState?.openDrawer()
            : null,
      ),
      drawer: isMobileScreen ? _buildDrawer() : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [AppColors.gradient1, AppColors.gradient2],
            stops: [0.0, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Banner section - Display banners from Google Sheets
            if (_bannerVisible)
              _loadingSheets
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      color: AppColors.blue,
                      child: const Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    )
                  : BannerWidget(
                      banners: _sheetsEvents
                          .where((e) => e.tag.toLowerCase() == 'banner')
                          .where(
                            (e) =>
                                (e.sheetMonth == null ||
                                    e.sheetMonth == _focusedDay.month) &&
                                (e.sheetYear == null ||
                                    e.sheetYear == _focusedDay.year),
                          )
                          .toList(),
                      onClose: isMobile(context) ? _hideBanner : null,
                    ),

            // Calendario + Lista
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : LayoutBuilder(
                      builder: (context, c) {
                        // Build calendar widget
                        final calendar = CalendarWidget(
                          focusedDay: _focusedDay,
                          selectedDay: _selectedDay,
                          events: _events,
                          viewType: _currentViewType,
                          onDaySelected: (selected, focused) {
                            setState(() {
                              _selectedDay = selected;
                              _focusedDay = focused;
                            });
                          },
                          onPageChanged: (focused) {
                            setState(() {
                              _focusedDay = focused;
                              _selectedDay = null;
                            });
                            _loadMonth(focused);
                          },
                          onEventTap: (event) =>
                              EventDetailSheet.show(context, event),
                        );

                        // Build Google Sheets event list (only weeks, not banners)
                        final sheetsList = WeeksListWidget(
                          sheetsEvents: _sheetsEvents
                              .where((e) => e.tag.toLowerCase() == 'week')
                              .where(
                                (e) =>
                                    (e.sheetMonth == null ||
                                        e.sheetMonth == _focusedDay.month) &&
                                    (e.sheetYear == null ||
                                        e.sheetYear == _focusedDay.year),
                              )
                              .toList(),
                          isLoading: _loadingSheets,
                          onRefresh: _loadSheetsData,
                        );

                        // Show sheets list on left, calendar on right
                        if (wideScreen) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 450,
                                constraints: const BoxConstraints(
                                  maxWidth: 450,
                                ),
                                child: sheetsList,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: calendar,
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          // On narrow screens, make the whole content scrollable with pull-to-refresh
                          final embeddedWeeks = WeeksListWidget(
                            sheetsEvents: _sheetsEvents
                                .where((e) => e.tag.toLowerCase() == 'week')
                                .where(
                                  (e) =>
                                      (e.sheetMonth == null ||
                                          e.sheetMonth == _focusedDay.month) &&
                                      (e.sheetYear == null ||
                                          e.sheetYear == _focusedDay.year),
                                )
                                .toList(),
                            isLoading: _loadingSheets,
                            onRefresh: _loadSheetsData,
                            embedded: true,
                          );

                          return RefreshIndicator(
                            onRefresh: _refreshAllData,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Padding(
                                padding: const EdgeInsets.all(0),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 7.5,
                                      ),
                                      child: calendar,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 15,
                                        left: 0,
                                        right: 0,
                                      ),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: embeddedWeeks,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings() async {
    final notificationGranted =
        await PermissionService.isNotificationPermissionGranted();
    final locationGranted =
        await PermissionService.isLocationPermissionGranted();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Configuración',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: notificationGranted
                        ? AppColors.primary
                        : AppColors.grey,
                  ),
                  title: const Text('Notificaciones'),
                  subtitle: Text(
                    notificationGranted
                        ? 'Activadas - Recibirás notificaciones de eventos'
                        : 'Desactivadas - No recibirás notificaciones',
                  ),
                  trailing: Icon(
                    notificationGranted ? Icons.check_circle : Icons.cancel,
                    color: notificationGranted
                        ? AppColors.primary
                        : AppColors.grey,
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    Icons.location_on,
                    color: locationGranted ? AppColors.blue : AppColors.grey,
                  ),
                  title: const Text('Ubicación'),
                  subtitle: Text(
                    locationGranted
                        ? 'Activada - Verás eventos cercanos'
                        : 'Desactivada - No se usa tu ubicación',
                  ),
                  trailing: Icon(
                    locationGranted ? Icons.check_circle : Icons.cancel,
                    color: locationGranted ? AppColors.blue : AppColors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                if (!notificationGranted || !locationGranted)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        PermissionService.openSettings();
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Abrir Configuración'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changeView(CalendarViewType viewType) {
    setState(() {
      _currentViewType = viewType;
    });
  }

  void _showNotifications() async {
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) =>
            NotificationListModal(scrollController: scrollController),
      ),
    );

    // Reload unread count after modal closes
    await _loadUnreadCount();
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Image.asset('web/icons/Icon-192.png', height: 48, width: 48),
                const SizedBox(height: 8),
                const Text(
                  'Agenda Soka',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // View options
          ListTile(
            leading: Icon(
              Icons.calendar_today,
              color: _currentViewType == CalendarViewType.day
                  ? AppColors.primary
                  : AppColors.black87,
            ),
            title: Text(
              CalendarViewType.day.displayName,
              style: TextStyle(
                fontWeight: _currentViewType == CalendarViewType.day
                    ? FontWeight.w700
                    : FontWeight.normal,
                color: _currentViewType == CalendarViewType.day
                    ? AppColors.primary
                    : AppColors.black87,
              ),
            ),
            selected: _currentViewType == CalendarViewType.day,
            onTap: () {
              Navigator.pop(context);
              _changeView(CalendarViewType.day);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.view_week,
              color: _currentViewType == CalendarViewType.week
                  ? AppColors.primary
                  : AppColors.black87,
            ),
            title: Text(
              CalendarViewType.week.displayName,
              style: TextStyle(
                fontWeight: _currentViewType == CalendarViewType.week
                    ? FontWeight.w700
                    : FontWeight.normal,
                color: _currentViewType == CalendarViewType.week
                    ? AppColors.primary
                    : AppColors.black87,
              ),
            ),
            selected: _currentViewType == CalendarViewType.week,
            onTap: () {
              Navigator.pop(context);
              _changeView(CalendarViewType.week);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.calendar_month,
              color: _currentViewType == CalendarViewType.month
                  ? AppColors.primary
                  : AppColors.black87,
            ),
            title: Text(
              CalendarViewType.month.displayName,
              style: TextStyle(
                fontWeight: _currentViewType == CalendarViewType.month
                    ? FontWeight.w700
                    : FontWeight.normal,
                color: _currentViewType == CalendarViewType.month
                    ? AppColors.primary
                    : AppColors.black87,
              ),
            ),
            selected: _currentViewType == CalendarViewType.month,
            onTap: () {
              Navigator.pop(context);
              _changeView(CalendarViewType.month);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.view_module,
              color: _currentViewType == CalendarViewType.year
                  ? AppColors.primary
                  : AppColors.black87,
            ),
            title: Text(
              CalendarViewType.year.displayName,
              style: TextStyle(
                fontWeight: _currentViewType == CalendarViewType.year
                    ? FontWeight.w700
                    : FontWeight.normal,
                color: _currentViewType == CalendarViewType.year
                    ? AppColors.primary
                    : AppColors.black87,
              ),
            ),
            selected: _currentViewType == CalendarViewType.year,
            onTap: () {
              Navigator.pop(context);
              _changeView(CalendarViewType.year);
            },
          ),

          const Divider(),
          // Configuration option
          ListTile(
            leading: const Icon(Icons.settings, color: AppColors.black87),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              _showSettings();
            },
          ),
        ],
      ),
    );
  }
}

String toTitleCase(String s) => s
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

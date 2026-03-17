import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/calendar_provider.dart';
import '../models/calendar_model.dart';
import '../utils/globals.dart';
import '../utils/calendar_view_type.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/event_detail_sheet.dart';
import '../widgets/notification_list_modal.dart';
import '../services/notification_storage_service.dart';
import 'event_form_page.dart';
import 'calendar_settings_page.dart';
import 'join_calendar_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarViewType _currentViewType = CalendarViewType.month;
  int _unreadNotificationCount = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialView();
      _loadCurrentMonthEvents();
    });
  }

  void _setInitialView() {
    if (isMobile(context)) {
      setState(() => _currentViewType = CalendarViewType.week);
    }
  }

  void _loadCurrentMonthEvents() {
    final calendarProvider = context.read<CalendarProvider>();
    final from = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    final to = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);
    calendarProvider.loadEvents(from: from, to: to);
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotificationStorageService.getUnreadCount();
    if (mounted) setState(() => _unreadNotificationCount = count);
  }

  void _onMonthChanged(DateTime focusedDay) {
    setState(() => _focusedDay = focusedDay);
    _loadCurrentMonthEvents();
  }

  @override
  Widget build(BuildContext context) {
    final calendarProvider = context.watch<CalendarProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: calendarProvider.selectedCalendar?.name ?? 'Soka Planner',
        unreadNotificationCount: _unreadNotificationCount,
        currentViewType: _currentViewType,
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        onChangeView: (view) => setState(() => _currentViewType = view),
        onNotifications: () => _showNotifications(context),
        onSettings: calendarProvider.selectedCalendar != null
            ? () => _openCalendarSettings(context)
            : null,
      ),
      drawer: _buildDrawer(context, calendarProvider, authProvider),
      body: calendarProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(calendarProvider),
      floatingActionButton: calendarProvider.canEdit
          ? FloatingActionButton(
              onPressed: () => _createEvent(context),
              backgroundColor: AppColors.soka,
              child: const Icon(Icons.add, color: AppColors.white),
            )
          : null,
    );
  }

  Widget _buildBody(CalendarProvider provider) {
    return Column(
      children: [
        Expanded(
          child: CalendarWidget(
            events: provider.events,
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            viewType: _currentViewType,
            onDaySelected: (day, focused) {
              setState(() {
                _selectedDay = day;
                _focusedDay = focused;
              });
            },
            onPageChanged: _onMonthChanged,
            onEventTap: (event) => EventDetailSheet.show(context, event),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    CalendarProvider calProvider,
    AuthProvider authProvider,
  ) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // User header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: authProvider.user?.photoURL != null
                        ? NetworkImage(authProvider.user!.photoURL!)
                        : null,
                    child: authProvider.user?.photoURL == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.user?.displayName ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          authProvider.user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Calendar list
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Calendarios',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.black54,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const JoinCalendarPage(),
                        ),
                      );
                    },
                    tooltip: 'Unirse a calendario',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: calProvider.calendars.length,
                padding: EdgeInsets.zero,
                itemBuilder: (context, index) {
                  final cal = calProvider.calendars[index];
                  final isSelected =
                      cal.id == calProvider.selectedCalendar?.id;
                  return _buildCalendarTile(
                      context, cal, isSelected, calProvider);
                },
              ),
            ),
            const Divider(height: 1),

            // View type selector (mobile)
            if (isMobile(context))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SegmentedButton<CalendarViewType>(
                  segments: CalendarViewType.values
                      .map((v) => ButtonSegment(
                            value: v,
                            label: Text(v.displayName,
                                style: const TextStyle(fontSize: 11)),
                          ))
                      .toList(),
                  selected: {_currentViewType},
                  onSelectionChanged: (selection) {
                    setState(
                        () => _currentViewType = selection.first);
                    Navigator.pop(context);
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),

            // Sign out
            ListTile(
              leading: const Icon(Icons.logout, size: 20),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Navigator.pop(context);
                context.read<CalendarProvider>().clear();
                context.read<AuthProvider>().signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarTile(
    BuildContext context,
    CalendarModel cal,
    bool isSelected,
    CalendarProvider provider,
  ) {
    return ListTile(
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Color(cal.color),
          shape: BoxShape.circle,
        ),
      ),
      title: Text(
        cal.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          color: isSelected ? AppColors.soka : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      selected: isSelected,
      dense: true,
      onTap: () {
        provider.selectCalendar(cal);
        _loadCurrentMonthEvents();
        Navigator.pop(context);
      },
      trailing: isSelected ? const Icon(Icons.check, size: 18) : null,
    );
  }

  void _createEvent(BuildContext context) {
    final calendarProvider = context.read<CalendarProvider>();
    if (calendarProvider.selectedCalendar == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventFormPage(
          calendarId: calendarProvider.selectedCalendar!.id,
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationListModal(),
    ).then((_) => _loadUnreadCount());
  }

  void _openCalendarSettings(BuildContext context) {
    final cal = context.read<CalendarProvider>().selectedCalendar;
    if (cal == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CalendarSettingsPage(calendar: cal),
      ),
    );
  }
}

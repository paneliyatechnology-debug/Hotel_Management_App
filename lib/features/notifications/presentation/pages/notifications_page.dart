import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

enum NotificationCategory { all, unread, checkIn, billing, housekeeping, maintenance }
enum NotificationPriority { urgent, high, normal, info }

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final String time;
  final NotificationCategory category;
  final NotificationPriority priority;
  final String? roomNumber;
  final String? guestName;
  final String? referenceId;
  final String? actionLabel;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.category,
    this.priority = NotificationPriority.normal,
    this.roomNumber,
    this.guestName,
    this.referenceId,
    this.actionLabel,
    this.isRead = false,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  NotificationCategory _selectedCategory = NotificationCategory.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  late List<NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = [
      NotificationItem(
        id: 'notif_1',
        title: 'Pending Settlement Overdue',
        description: 'Room #105 (Vikram Mehta) has pending folio dues of ₹1,600 past checkout deadline.',
        time: 'Just now',
        category: NotificationCategory.billing,
        priority: NotificationPriority.urgent,
        roomNumber: '105',
        guestName: 'Vikram Mehta',
        referenceId: 'BK-991204-102',
        actionLabel: 'Settle Payment',
        isRead: false,
      ),
      NotificationItem(
        id: 'notif_2',
        title: 'Express Check-In Completed',
        description: 'Tushar Paneliya successfully checked in to Room #1001. Keycard issued and active.',
        time: '8m ago',
        category: NotificationCategory.checkIn,
        priority: NotificationPriority.normal,
        roomNumber: '1001',
        guestName: 'Tushar Paneliya',
        referenceId: 'BK-857385-254',
        actionLabel: 'View Folio',
        isRead: false,
      ),
      NotificationItem(
        id: 'notif_3',
        title: 'Housekeeping Service Requested',
        description: 'Room #102 marked for priority cleaning by front desk. Assigned to shift cleaner.',
        time: '24m ago',
        category: NotificationCategory.housekeeping,
        priority: NotificationPriority.high,
        roomNumber: '102',
        actionLabel: 'Assign Staff',
        isRead: false,
      ),
      NotificationItem(
        id: 'notif_4',
        title: 'AC Maintenance Reported',
        description: 'Guest in Room #109 reported cooling issue. Engineering ticket #ENG-402 raised.',
        time: '1h ago',
        category: NotificationCategory.maintenance,
        priority: NotificationPriority.high,
        roomNumber: '109',
        referenceId: 'ENG-402',
        actionLabel: 'Track Ticket',
        isRead: true,
      ),
      NotificationItem(
        id: 'notif_5',
        title: 'Online Payment Received via UPI',
        description: 'Received ₹2,900 for Booking #BK-857385-254. Auto-reconciled with cash drawer.',
        time: '2h ago',
        category: NotificationCategory.billing,
        priority: NotificationPriority.normal,
        referenceId: 'RCP-691574',
        actionLabel: 'View Receipt',
        isRead: true,
      ),
      NotificationItem(
        id: 'notif_6',
        title: 'Regulatory Govt ID Verified',
        description: 'Aadhaar ID front and back document proofs verified for Tushar Paneliya.',
        time: '3h ago',
        category: NotificationCategory.checkIn,
        priority: NotificationPriority.info,
        guestName: 'Tushar Paneliya',
        isRead: true,
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  List<NotificationItem> get _filteredNotifications {
    return _notifications.where((item) {
      // Category filter
      if (_selectedCategory == NotificationCategory.unread && item.isRead) {
        return false;
      }
      if (_selectedCategory == NotificationCategory.checkIn && item.category != NotificationCategory.checkIn) {
        return false;
      }
      if (_selectedCategory == NotificationCategory.billing && item.category != NotificationCategory.billing) {
        return false;
      }
      if (_selectedCategory == NotificationCategory.housekeeping && item.category != NotificationCategory.housekeeping) {
        return false;
      }
      if (_selectedCategory == NotificationCategory.maintenance && item.category != NotificationCategory.maintenance) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = item.title.toLowerCase().contains(query);
        final matchDesc = item.description.toLowerCase().contains(query);
        final matchRoom = item.roomNumber?.toLowerCase().contains(query) ?? false;
        final matchGuest = item.guestName?.toLowerCase().contains(query) ?? false;
        return matchTitle || matchDesc || matchRoom || matchGuest;
      }

      return true;
    }).toList();
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read.'),
        backgroundColor: AppColors.primary,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearAllNotifications() {
    final backup = List<NotificationItem>.from(_notifications);
    setState(() {
      _notifications.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All notifications cleared.'),
        backgroundColor: const Color(0xFF334155),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: const Color(0xFF6EE7B7),
          onPressed: () {
            setState(() {
              _notifications = backup;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 650;
          final filtered = _filteredNotifications;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                children: [
                  // 1. Telemetry Status Header + Search Bar
                  _buildHeaderSection(isCompact),

                  // 2. Horizontal Filter Chips
                  _buildFilterChipsBar(),

                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // 3. Notification List or Empty State
                  Expanded(
                    child: filtered.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            color: AppColors.primary,
                            onRefresh: () async {
                              await Future.delayed(const Duration(milliseconds: 600));
                              setState(() {});
                            },
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return _buildNotificationCard(item, isCompact);
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- APP BAR ---
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, size: 22, color: AppColors.textPrimary),
        onPressed: () => Navigator.maybePop(context),
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Notifications',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (_unreadCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF86EFAC), width: 0.8),
                  ),
                  child: Text(
                    '$_unreadCount NEW',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ],
          ),
          Text(
            'Live Front Desk & System Alerts',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        if (_unreadCount > 0)
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all_rounded, size: 20, color: AppColors.primary),
            onPressed: _markAllAsRead,
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF64748B)),
          onSelected: (val) {
            if (val == 'read_all') _markAllAsRead();
            if (val == 'clear_all') _clearAllNotifications();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'read_all',
              child: Row(
                children: [
                  Icon(Icons.mark_email_read_outlined, size: 18, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text('Mark all as read', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear_all',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep_outlined, size: 18, color: Color(0xFFEF4444)),
                  SizedBox(width: 10),
                  Text('Clear all notifications', style: TextStyle(fontSize: 13, color: Color(0xFFEF4444))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFF1F5F9)),
      ),
    );
  }

  // --- HEADER SECTION: SEARCH & STATS ---
  Widget _buildHeaderSection(bool isCompact) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search by room, guest, or alert keyword...',
            hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF64748B)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  // --- HORIZONTAL FILTER CHIPS BAR ---
  Widget _buildFilterChipsBar() {
    final filters = [
      {'category': NotificationCategory.all, 'label': 'All (${_notifications.length})'},
      {'category': NotificationCategory.unread, 'label': 'Unread ($_unreadCount)'},
      {
        'category': NotificationCategory.checkIn,
        'label': 'Check-In (${_notifications.where((n) => n.category == NotificationCategory.checkIn).length})',
      },
      {
        'category': NotificationCategory.billing,
        'label': 'Billing (${_notifications.where((n) => n.category == NotificationCategory.billing).length})',
      },
      {
        'category': NotificationCategory.housekeeping,
        'label': 'Housekeeping (${_notifications.where((n) => n.category == NotificationCategory.housekeeping).length})',
      },
      {
        'category': NotificationCategory.maintenance,
        'label': 'Maintenance (${_notifications.where((n) => n.category == NotificationCategory.maintenance).length})',
      },
    ];

    return Container(
      color: Colors.white,
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final cat = filter['category'] as NotificationCategory;
          final isSelected = _selectedCategory == cat;

          return InkWell(
            onTap: () => setState(() => _selectedCategory = cat),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Text(
                filter['label'] as String,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- NOTIFICATION CARD WIDGET ---
  Widget _buildNotificationCard(NotificationItem item, bool isCompact) {
    Color iconColor;
    Color iconBg;
    IconData iconData;

    switch (item.category) {
      case NotificationCategory.checkIn:
        iconColor = const Color(0xFF059669);
        iconBg = const Color(0xFFECFDF5);
        iconData = Icons.login_rounded;
        break;
      case NotificationCategory.billing:
        iconColor = const Color(0xFF0D9488);
        iconBg = const Color(0xFFE6FFFA);
        iconData = Icons.receipt_long_outlined;
        break;
      case NotificationCategory.housekeeping:
        iconColor = const Color(0xFFD97706);
        iconBg = const Color(0xFFFFFBEB);
        iconData = Icons.cleaning_services_rounded;
        break;
      case NotificationCategory.maintenance:
        iconColor = const Color(0xFFDC2626);
        iconBg = const Color(0xFFFEF2F2);
        iconData = Icons.build_circle_outlined;
        break;
      default:
        iconColor = const Color(0xFF0284C7);
        iconBg = const Color(0xFFF0F9FF);
        iconData = Icons.notifications_none_rounded;
    }

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 6),
            Text('Dismiss', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          _notifications.removeWhere((n) => n.id == item.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dismissed: ${item.title}'),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: const Color(0xFF6EE7B7),
              onPressed: () {
                setState(() {
                  _notifications.insert(0, item);
                });
              },
            ),
          ),
        );
      },
      child: InkWell(
        onTap: () {
          setState(() {
            item.isRead = true;
          });
          _showNotificationDetailsModal(item);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead ? const Color(0xFFE2E8F0) : const Color(0xFF99F6E4),
              width: item.isRead ? 1 : 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: item.isRead
                    ? Colors.black.withOpacity(0.015)
                    : const Color(0xFF0F766E).withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                // Unread Indicator Left Border Strip
                if (!item.isRead)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 4,
                    child: Container(color: const Color(0xFF0F766E)),
                  ),

                Padding(
                  padding: EdgeInsets.fromLTRB(!item.isRead ? 18 : 14, 14, 14, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon Circle
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: iconColor.withOpacity(0.2)),
                        ),
                        alignment: Alignment.center,
                        child: Icon(iconData, size: 20, color: iconColor),
                      ),
                      const SizedBox(width: 12),

                      // Content Body
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row 1: Title + Priority + Time
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: item.isRead ? FontWeight.w700 : FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (item.priority == NotificationPriority.urgent)
                                  _buildPriorityBadge('URGENT', const Color(0xFFFEF2F2), const Color(0xFFDC2626)),
                                if (item.priority == NotificationPriority.high)
                                  _buildPriorityBadge('HIGH', const Color(0xFFFFFBEB), const Color(0xFFD97706)),
                                const SizedBox(width: 6),
                                Text(
                                  item.time,
                                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Description
                            Text(
                              item.description,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF475569),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Metadata Tags & Action Row
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (item.roomNumber != null)
                                  _buildMetaTag(Icons.meeting_room_outlined, 'Room #${item.roomNumber}'),
                                if (item.guestName != null)
                                  _buildMetaTag(Icons.person_outline_rounded, item.guestName!),
                                if (item.referenceId != null)
                                  _buildMetaTag(Icons.tag_rounded, item.referenceId!),
                                if (item.actionLabel != null)
                                  InkWell(
                                    onTap: () {
                                      setState(() => item.isRead = true);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Triggered "${item.actionLabel}" for ${item.title}'),
                                          backgroundColor: AppColors.primary,
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6FFFA),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFF99F6E4)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            item.actionLabel!,
                                            style: GoogleFonts.inter(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF0F766E),
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(Icons.arrow_forward_rounded, size: 11, color: Color(0xFF0F766E)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER TAG WIDGETS ---
  Widget _buildPriorityBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.w800, color: textCol),
      ),
    );
  }

  Widget _buildMetaTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF64748B)),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
          ),
        ],
      ),
    );
  }

  // --- EMPTY STATE ---
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFE6FFFA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_off_outlined, size: 36, color: Color(0xFF0F766E)),
            ),
            const SizedBox(height: 16),
            Text(
              'No Alerts Found',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No notifications match "$_searchQuery".'
                  : 'All caught up! No operational alerts in this category.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            if (_selectedCategory != NotificationCategory.all || _searchQuery.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedCategory = NotificationCategory.all;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset Filters'),
              ),
          ],
        ),
      ),
    );
  }

  // --- DETAIL BOTTOM SHEET MODAL ---
  void _showNotificationDetailsModal(NotificationItem item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                ),
                Text(item.time, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.description,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 16),
            if (item.roomNumber != null || item.guestName != null || item.referenceId != null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (item.roomNumber != null) _buildMetaTag(Icons.meeting_room_outlined, 'Room #${item.roomNumber}'),
                  if (item.guestName != null) _buildMetaTag(Icons.person_outline_rounded, item.guestName!),
                  if (item.referenceId != null) _buildMetaTag(Icons.tag_rounded, item.referenceId!),
                ],
              ),
              const SizedBox(height: 20),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

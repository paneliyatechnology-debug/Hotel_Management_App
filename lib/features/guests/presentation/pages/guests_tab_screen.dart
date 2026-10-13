import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/guests_bloc.dart';
import '../bloc/guests_event.dart';
import '../bloc/guests_state.dart';
import '../widgets/advanced_filter_bottom_sheet.dart';
import '../widgets/date_filter_bottom_sheet.dart';
import '../widgets/guest_card.dart';
import '../widgets/guest_skeleton_loader.dart';
import 'guest_details_screen.dart';

class GuestsTabScreen extends StatefulWidget {
  const GuestsTabScreen({super.key});

  @override
  State<GuestsTabScreen> createState() => _GuestsTabScreenState();
}

class _GuestsTabScreenState extends State<GuestsTabScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Load guests with status=CHECKED_OUT from /api/v1/receptionist/bookings
    context.read<GuestsBloc>().add(const LoadGuestsEvent(status: 'CHECKED_OUT'));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: SafeArea(
        child: BlocBuilder<GuestsBloc, GuestsState>(
          builder: (context, state) {
            final isWideScreen = MediaQuery.of(context).size.width >= 900;

            if (isWideScreen) {
              return _buildTabletSplitLayout(context, state);
            }

            return _buildMobileLayout(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, GuestsState state) {
    return Column(
      children: [
        // STICKY HEADER & CONTROLS
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(state),
              const SizedBox(height: 12),
              _buildStatusFilterRow(state),
              const SizedBox(height: 10),
              _buildSecondaryFilterBar(context, state),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.borderSubtle),

        // GUEST LIST OR SKELETON OR EMPTY STATE
        Expanded(
          child: _buildGuestListContent(context, state, isWideScreen: false),
        ),
      ],
    );
  }

  Widget _buildTabletSplitLayout(BuildContext context, GuestsState state) {
    return Column(
      children: [
        // STICKY HEADER & CONTROLS
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(flex: 3, child: _buildSearchBar(state)),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildSecondaryFilterBar(context, state)),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatusFilterRow(state),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.borderSubtle),

        // SPLIT VIEW FOR TABLET
        Expanded(
          child: Row(
            children: [
              // Guest list pane
              Expanded(
                flex: 5,
                child: _buildGuestListContent(context, state, isWideScreen: true),
              ),
              const VerticalDivider(width: 1, color: AppColors.borderSubtle),
              // Guest detail pane
              Expanded(
                flex: 6,
                child: state.selectedGuest != null
                    ? GuestDetailsScreen(guest: state.selectedGuest!)
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_rounded, size: 54, color: AppColors.neutral300),
                            SizedBox(height: 12),
                            Text(
                              'Select a guest to view details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutral600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'KYC, current stay, and complete history will appear here',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.neutral400,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(GuestsState state) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _searchFocus.hasFocus ? AppColors.primary : AppColors.borderSubtle,
          width: _searchFocus.hasFocus ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.neutral900,
        ),
        onChanged: (query) {
          context.read<GuestsBloc>().add(SearchGuestsEvent(query));
        },
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search guest name, mobile, email, room...',
          hintStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.neutral500,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.neutral500,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.neutral600),
                  onPressed: () {
                    _searchController.clear();
                    context.read<GuestsBloc>().add(const SearchGuestsEvent(''));
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        ),
      ),
    );
  }

  Widget _buildStatusFilterRow(GuestsState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildStatusChip(
            label: 'All (${state.totalCount})',
            isSelected: state.statusFilter == 'All',
            onTap: () {
              context.read<GuestsBloc>().add(const ChangeStatusFilterEvent('All'));
            },
          ),
          const SizedBox(width: 8),
          _buildStatusChip(
            label: 'In-House (${state.inHouseCount})',
            isSelected: state.statusFilter == 'In-House',
            activeColor: AppColors.statusSuccess,
            onTap: () {
              context.read<GuestsBloc>().add(const ChangeStatusFilterEvent('In-House'));
            },
          ),
          const SizedBox(width: 8),
          _buildStatusChip(
            label: 'Checked-Out (${state.checkedOutCount})',
            isSelected: state.statusFilter == 'Checked-Out',
            activeColor: AppColors.primary,
            onTap: () {
              context.read<GuestsBloc>().add(const ChangeStatusFilterEvent('Checked-Out'));
            },
          ),
          if (state.registeredCount > 0) ...[
            const SizedBox(width: 8),
            _buildStatusChip(
              label: 'Registered (${state.registeredCount})',
              isSelected: state.statusFilter == 'Registered',
              activeColor: const Color(0xFFD97706),
              onTap: () {
                context.read<GuestsBloc>().add(const ChangeStatusFilterEvent('Registered'));
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color activeColor = AppColors.primary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.neutral700,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryFilterBar(BuildContext context, GuestsState state) {
    final hasActiveDate = state.dateFilterOption != DateFilterOption.allTime;
    final hasActiveFilters = state.activeFilterCount > 0;

    return Row(
      children: [
        // DATE FILTER BUTTON
        Expanded(
          child: InkWell(
            onTap: () {
              DateFilterBottomSheet.show(
                context,
                initialOption: state.dateFilterOption,
                initialCustomRange: state.customDateRange,
                onApply: (result) {
                  context.read<GuestsBloc>().add(ChangeDateFilterEvent(
                        option: result.option,
                        customRange: result.customRange,
                      ));
                },
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: hasActiveDate ? AppColors.primarySurface : AppColors.neutral100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasActiveDate ? AppColors.primary : AppColors.borderSubtle,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: hasActiveDate ? AppColors.primary : AppColors.neutral600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      state.dateFilterLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: hasActiveDate ? FontWeight.w700 : FontWeight.w500,
                        color: hasActiveDate ? AppColors.primary : AppColors.neutral800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.neutral500),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // ADVANCED FILTERS BUTTON
        InkWell(
          onTap: () {
            AdvancedFilterBottomSheet.show(
              context,
              initialFilters: state.advancedFilters,
              onApply: (newFilters) {
                context.read<GuestsBloc>().add(ApplyAdvancedFiltersEvent(newFilters));
              },
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: hasActiveFilters ? AppColors.primarySurface : AppColors.neutral100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasActiveFilters ? AppColors.primary : AppColors.borderSubtle,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.tune_rounded,
                  size: 15,
                  color: hasActiveFilters ? AppColors.primary : AppColors.neutral700,
                ),
                const SizedBox(width: 6),
                Text(
                  hasActiveFilters ? 'Filters (${state.activeFilterCount})' : 'Filters',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: hasActiveFilters ? FontWeight.w700 : FontWeight.w600,
                    color: hasActiveFilters ? AppColors.primary : AppColors.neutral800,
                  ),
                ),
              ],
            ),
          ),
        ),

        // RESET BUTTON IF ANY FILTERS ARE ACTIVE
        if (state.hasAnyFiltersActive) ...[
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, size: 20, color: AppColors.neutral600),
            tooltip: 'Clear All Filters',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {
              _searchController.clear();
              context.read<GuestsBloc>().add(const ClearAllFiltersEvent());
            },
          ),
        ],
      ],
    );
  }

  Widget _buildGuestListContent(BuildContext context, GuestsState state, {required bool isWideScreen}) {
    if (state.status == GuestsStatus.loading) {
      return const GuestSkeletonLoader(count: 6);
    }

    if (state.filteredGuests.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          context.read<GuestsBloc>().add(const RefreshGuestsEvent(status: 'CHECKED_OUT'));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: _buildEmptyState(context),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<GuestsBloc>().add(const RefreshGuestsEvent(status: 'CHECKED_OUT'));
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        itemCount: state.filteredGuests.length,
        separatorBuilder: (_, _) => const SizedBox.shrink(),
        itemBuilder: (context, index) {
          final guest = state.filteredGuests[index];
          return GuestCard(
            guest: guest,
            onTap: () {
              if (isWideScreen) {
                context.read<GuestsBloc>().add(SelectGuestEvent(guest));
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GuestDetailsScreen(guest: guest),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.person_off_rounded,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No guests found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.neutral900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try a different name, mobile number, email or date range.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.neutral600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                _searchController.clear();
                context.read<GuestsBloc>().add(const ClearAllFiltersEvent());
              },
              child: const Text(
                'Clear Filters',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/guests_bloc.dart';
import '../bloc/guests_event.dart';
import '../bloc/guests_state.dart';
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
    context.read<GuestsBloc>().add(const LoadGuestsEvent());
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
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE8EEF2))),
            boxShadow: [
              BoxShadow(
                color: Color(0x060F172A),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: _buildSearchBar(state),
        ),
        Expanded(
          child: _buildGuestListContent(context, state, isWideScreen: false),
        ),
      ],
    );
  }

  Widget _buildTabletSplitLayout(BuildContext context, GuestsState state) {
    return Column(
      children: [
        // STICKY HEADER — search only
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: _buildSearchBar(state),
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
                    ? GuestDetailsScreen(guest: state.selectedGuest!, isEmbedded: true)
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _searchFocus.hasFocus ? AppColors.primary : const Color(0xFFE2E8F0),
          width: _searchFocus.hasFocus ? 1.4 : 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        onTap: () => setState(() {}),
        onChanged: (query) {
          context.read<GuestsBloc>().add(SearchGuestsEvent(query));
          setState(() {});
        },
        style: GoogleFonts.inter(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search guest name, mobile, email, room...',
          hintStyle: GoogleFonts.inter(
            fontSize: 12.5,
            color: const Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF64748B),
            size: 19,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 17, color: Color(0xFF64748B)),
                  onPressed: () {
                    _searchController.clear();
                    context.read<GuestsBloc>().add(const SearchGuestsEvent(''));
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  void _clearSearch(BuildContext context) {
    _searchController.clear();
    context.read<GuestsBloc>().add(const SearchGuestsEvent(''));
    context.read<GuestsBloc>().add(const ClearAllFiltersEvent());
    setState(() {});
  }

  Widget _buildGuestListContent(BuildContext context, GuestsState state, {required bool isWideScreen}) {
    if (state.status == GuestsStatus.loading) {
      return const GuestSkeletonLoader(count: 6);
    }

    if (state.filteredGuests.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          context.read<GuestsBloc>().add(const RefreshGuestsEvent());
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

    final showLoader = state.loadingMore;
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 160) {
          context.read<GuestsBloc>().add(const LoadMoreGuestsEvent());
        }
        return false;
      },
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          context.read<GuestsBloc>().add(const RefreshGuestsEvent());
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
          itemCount: state.filteredGuests.length + (showLoader ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 0),
          itemBuilder: (context, index) {
            if (index >= state.filteredGuests.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ),
              );
            }
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
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF99F6E4)),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_search_rounded,
                  size: 30,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No guests found',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different guest name, mobile number, or email.',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              ),
              onPressed: () => _clearSearch(context),
              child: Text(
                'Clear Search',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

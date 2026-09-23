import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../check_in_wizard/presentation/bloc/check_in_bloc.dart';
import '../../../check_in_wizard/presentation/bloc/check_in_event.dart';
import '../../../check_in_wizard/presentation/pages/check_in_wizard_page.dart';
import '../../../folios/presentation/pages/in_house_folios_page.dart';
import '../../../govt_id_compliance/presentation/pages/govt_id_compliance_page.dart';
import '../../../pos_settlement/presentation/pages/pos_settlement_page.dart';
import '../../../rooms/presentation/pages/rooms_page.dart';
import '../../../rooms/presentation/widgets/room_status_dialog.dart';
import '../../../rooms/data/models/room_model.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/front_desk_banner.dart';
import '../widgets/kpi_metrics_grid.dart';
import '../widgets/recent_folios_table.dart';
import '../widgets/room_matrix_section.dart';
import '../widgets/sidebar_navigation.dart';
import '../widgets/top_app_bar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  NavItem _selectedNav = NavItem.availableRooms;

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboardDataEvent());
  }

  void _onNavSelected(NavItem item) {
    setState(() {
      _selectedNav = item;
    });

    if (item == NavItem.fiveStepCheckIn) {
      context.read<CheckInBloc>().add(InitCheckInWizardEvent());
    }
  }

  Widget _buildBody(BuildContext context, DashboardState state) {
    switch (_selectedNav) {
      case NavItem.availableRooms:
        return _buildMainDashboardContent(context, state);
      case NavItem.inHouseFolios:
        return const InHouseFoliosPage();
      case NavItem.fiveStepCheckIn:
        return const CheckInWizardPage(hasScaffold: false);
      case NavItem.govtIdCompliance:
        return const GovtIdCompliancePage();
      case NavItem.posSettlementDesk:
        return const PosSettlementPage();
      case NavItem.profileSettings:
        return const RoomsPage();
    }
  }

  Widget _buildMainDashboardContent(BuildContext context, DashboardState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Front Desk Operations Blue Banner
          FrontDeskBanner(
            onExpressCheckIn: () {
              context.read<CheckInBloc>().add(InitCheckInWizardEvent());
              setState(() => _selectedNav = NavItem.fiveStepCheckIn);
            },
            onGovtIdHub: () {
              setState(() => _selectedNav = NavItem.govtIdCompliance);
            },
            onPosInvoice: () {
              setState(() => _selectedNav = NavItem.posSettlementDesk);
            },
            onRefresh: () {
              context.read<DashboardBloc>().add(RefreshDashboardDataEvent());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dashboard data refreshed.'),
                  duration: Duration(milliseconds: 1200),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // 2. 5 KPI Status Metric Cards
          KpiMetricsGrid(
            stats: state.stats,
            onMetricSelected: (filter) {
              if (filter == 'InHouseFolios') {
                setState(() => _selectedNav = NavItem.inHouseFolios);
              } else {
                context.read<DashboardBloc>().add(
                      FilterRoomsEvent(
                        searchQuery: state.searchQuery,
                        floor: state.selectedFloor,
                        status: filter,
                      ),
                    );
              }
            },
          ),

          const SizedBox(height: 20),

          // 3. Live Room Status Matrix Section
          RoomMatrixSection(
            rooms: state.filteredRooms,
            searchQuery: state.searchQuery,
            onSearchChanged: (query) {
              context.read<DashboardBloc>().add(
                    FilterRoomsEvent(
                      searchQuery: query,
                      floor: state.selectedFloor,
                      status: state.selectedStatus,
                    ),
                  );
            },
            selectedFloor: state.selectedFloor,
            onFloorChanged: (floor) {
              if (floor != null) {
                context.read<DashboardBloc>().add(
                      FilterRoomsEvent(
                        searchQuery: state.searchQuery,
                        floor: floor,
                        status: state.selectedStatus,
                      ),
                    );
              }
            },
            selectedStatus: state.selectedStatus,
            onStatusChanged: (status) {
              if (status != null) {
                context.read<DashboardBloc>().add(
                      FilterRoomsEvent(
                        searchQuery: state.searchQuery,
                        floor: state.selectedFloor,
                        status: status,
                      ),
                    );
              }
            },
            onRoomSelected: (RoomModel room) {
              RoomStatusDialog.show(
                context: context,
                room: room,
                onStatusChanged: (newStatus) {
                  context.read<DashboardBloc>().add(
                        ChangeRoomStatusDashboardEvent(
                          roomId: room.id,
                          newStatus: newStatus,
                        ),
                      );
                },
                onCheckIn: () {
                  context.read<CheckInBloc>().add(InitCheckInWizardEvent(preselectedRoom: room));
                  setState(() => _selectedNav = NavItem.fiveStepCheckIn);
                },
              );
            },
            onQuickCheckIn: (RoomModel room) {
              context.read<CheckInBloc>().add(InitCheckInWizardEvent(preselectedRoom: room));
              setState(() => _selectedNav = NavItem.fiveStepCheckIn);
            },
          ),

          const SizedBox(height: 20),

          // 4. Recent Front Desk Check-Ins & In-House Folios Table
          RecentFoliosTable(
            folios: state.folios,
            onViewAll: () {
              setState(() => _selectedNav = NavItem.inHouseFolios);
            },
            onFolioTap: (folio) {
              setState(() => _selectedNav = NavItem.inHouseFolios);
            },
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final isDesktop = ResponsiveLayout.isDesktop(context);

        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: !isDesktop
              ? Drawer(
                  child: SidebarNavigation(
                    selectedItem: _selectedNav,
                    onItemSelected: (item) {
                      Navigator.of(context).pop(); // Close drawer
                      _onNavSelected(item);
                    },
                  ),
                )
              : null,
          body: Row(
            children: [
              // Desktop Fixed Sidebar
              if (isDesktop)
                SidebarNavigation(
                  selectedItem: _selectedNav,
                  onItemSelected: _onNavSelected,
                ),

              // Main Content Area
              Expanded(
                child: Column(
                  children: [
                    // Top App Bar
                    Builder(
                      builder: (innerContext) {
                        return TopAppBar(
                          resortName: 'Mayal Resort 2',
                          showMenuButton: !isDesktop,
                          onOpenDrawer: () {
                            Scaffold.of(innerContext).openDrawer();
                          },
                        );
                      },
                    ),

                    // Main View Body
                    Expanded(
                      child: state.status == DashboardStatus.loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : _buildBody(context, state),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType, ExpansionTile, Theme, ThemeData, Colors, ColorScheme, ListTileThemeData, IconThemeData;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/auth_controller.dart'; // Import AuthController
import '../controllers/activity_controller.dart';
import '../models/task_entry.dart';
import '../models/daily_log.dart';
import '../widgets/styled_card.dart';
import '../main.dart';

class AllDaysLoggingScreen extends StatelessWidget {
  const AllDaysLoggingScreen({Key? key}) : super(key: key);

  // _showErrorDialog can remain if needed for other potential errors, though not used currently
  // void _showErrorDialog(BuildContext context, String title, String content) { /* ... */ }

  @override
  Widget build(BuildContext context) {
    final activityController = context.watch<ActivityController>();
    // Get AuthController to access the current userId
    final authController = context.watch<AuthController>(); // Added this
    final String? currentUserId = authController.userId; // Get current user ID

    final cupertinoTheme = CupertinoTheme.of(context);

    final Map<String, List<TaskEntry>> groupedTasksByDate = activityController.sortedActivitiesByDate;

    // Filter the dailyLogsMap for the current user before using it
    final Map<String, DailyLog> dailyLogsMap = {};
    if (currentUserId != null) {
      for (var log in activityController.sortedAllLogsForDisplay) {
        if (log.userId == currentUserId) { // Ensure it's current user's log
          dailyLogsMap[log.dateString] = log;
        }
      }
    }

    final List<String> sortedDates = groupedTasksByDate.keys.toList();

    return CupertinoPageScaffold(
      backgroundColor: cupertinoTheme.scaffoldBackgroundColor,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Activity History'),
        previousPageTitle: 'Today',
      ),
      child: SafeArea(
        bottom: false,
        child: Material(
          type: MaterialType.transparency,
          child: Builder(
            builder: (BuildContext materialContext) {
              if (activityController.isLoading && groupedTasksByDate.isEmpty) {
                return const Center(child: CupertinoActivityIndicator(radius: 20));
              }
              final syncError = activityController.syncStatusMessage;
              if (syncError != null && syncError.toLowerCase().contains("error") && groupedTasksByDate.isEmpty) {
                return _buildErrorState(context, syncError);
              }
              if (groupedTasksByDate.isEmpty) {
                return _buildEmptyHistoryState(context);
              }
              return ListView.builder(
                padding: EdgeInsets.only(top: 8, bottom: 18 + MediaQuery.of(context).padding.bottom),
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final dateKey = sortedDates[index];
                  // groupedTasksByDate from activityController is already filtered by user implicitly
                  // because _currentUserLogsFromHive is filtered by userId.
                  final tasksOnDate = groupedTasksByDate[dateKey]!;

                  // currentDayLog needs to be fetched from the filtered dailyLogsMap
                  final currentDayLog = dailyLogsMap[dateKey];
                  final isDaySynced = currentDayLog?.isSynced ?? false;
                  final date = DateFormat('yyyy-MM-dd').parse(dateKey);
                  final displayDateHeader = DateFormat('MMMM d, yyyy').format(date);
                  final displayDayOfWeek = DateFormat('EEEE').format(date);

                  return StyledCard(
                    margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    padding: EdgeInsets.zero,
                    border: Border.all(color: kSubtleBorderColorLight.withOpacity(0.6), width: 0.7),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 12.0,
                        offset: Offset(0, 4),
                      ),
                    ],
                    child: Theme(
                      data: ThemeData(
                        dividerColor: Colors.transparent,
                        listTileTheme: const ListTileThemeData(dense: true, minVerticalPadding: 0),
                        colorScheme: ColorScheme.fromSeed(seedColor: kAppPrimaryColor, brightness: cupertinoTheme.brightness ?? Brightness.light),
                        iconTheme: IconThemeData(color: CupertinoDynamicColor.resolve(kAppPrimaryColor, materialContext)),
                        splashColor: kAppPrimaryColor.withOpacity(0.1),
                        highlightColor: kAppPrimaryColor.withOpacity(0.05),
                      ),
                      child: ExpansionTile(
                        key: PageStorageKey(dateKey),
                        backgroundColor: Colors.transparent,
                        collapsedBackgroundColor: Colors.transparent,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                        leading: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: (isDaySynced ? kAppPrimaryColor : kAppAccentColor).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isDaySynced ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.cloud_upload_fill,
                            size: 24,
                            color: isDaySynced ? kAppPrimaryColor : kAppAccentColor,
                          ),
                        ),
                        title: Text(
                          displayDateHeader,
                          style: cupertinoTheme.textTheme.textStyle.copyWith(fontSize: 17.5, fontWeight: FontWeight.w600, color: kTextColorLight),
                        ),
                        subtitle: Text(
                          '$displayDayOfWeek • ${tasksOnDate.length} entr${tasksOnDate.length == 1 ? 'y' : 'ies'}',
                          style: cupertinoTheme.textTheme.tabLabelTextStyle.copyWith(color: kSecondaryTextColorLight, fontSize: 14.5, fontWeight: FontWeight.w500),
                        ),
                        childrenPadding: const EdgeInsets.only(bottom: 16, left: 20, right: 20, top: 4),
                        children: tasksOnDate.map((task) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 12.0, left: 48 + 18.0 - 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.5, right: 14.0),
                                  child: Icon(CupertinoIcons.circle_fill, size: 7.0, color: kAppPrimaryColor.withOpacity(0.6)),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(task.description, style: cupertinoTheme.textTheme.textStyle.copyWith(fontSize: 16, color: kTextColorLight, height: 1.35)),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('h:mm a').format(task.timestamp),
                                        style: cupertinoTheme.textTheme.tabLabelTextStyle.copyWith(color: kSecondaryTextColorLight, fontSize: 13.5, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryState(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/empty_history.png', height: 150,
                errorBuilder: (c,o,s) => const Icon(CupertinoIcons.archivebox_fill, size: 80, color: CupertinoColors.systemGrey2)),
            const SizedBox(height: 28),
            Text('Your History Awaits', style: theme.textTheme.navTitleTextStyle.copyWith(fontSize: 22, fontWeight: FontWeight.bold, color: kTextColorLight)),
            const SizedBox(height: 12),
            Text("Logged activities from previous days will appear here. Let's build some momentum!",
              style: theme.textTheme.textStyle.copyWith(color: kSecondaryTextColorLight, fontSize: 16.5, height: 1.45),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    final theme = CupertinoTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_octagon_fill, size: 70, color: CupertinoColors.systemRed),
            const SizedBox(height: 24),
            Text('An Error Occurred', style: theme.textTheme.navTitleTextStyle.copyWith(fontSize: 22, fontWeight: FontWeight.bold, color: kTextColorLight)),
            const SizedBox(height: 12),
            Text(errorMessage,
              style: theme.textTheme.textStyle.copyWith(color: kSecondaryTextColorLight, fontSize: 16, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
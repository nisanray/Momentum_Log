import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider, Material, MaterialType, ScaffoldMessenger, SnackBar;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/auth_controller.dart';
import '../controllers/activity_controller.dart';
import '../models/daily_log.dart';
import '../models/task_entry.dart';
import 'all_days_logging_screen.dart';
import 'settings_screen.dart';
import '../widgets/styled_card.dart';
import '../main.dart';

class DailyLoggingScreen extends StatefulWidget {
  const DailyLoggingScreen({Key? key}) : super(key: key);

  @override
  _DailyLoggingScreenState createState() => _DailyLoggingScreenState();
}

class _DailyLoggingScreenState extends State<DailyLoggingScreen> {
  final TextEditingController _activityInputController = TextEditingController();

  @override
  void dispose() {
    _activityInputController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String content) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          CupertinoDialogAction(isDefaultAction: true, child: const Text('OK'), onPressed: () => Navigator.of(ctx).pop())
        ],
      ),
    );
  }

  Future<void> _submitActivity() async {
    // Use listen:false for actions
    final activityController = Provider.of<ActivityController>(context, listen: false);
    final String description = _activityInputController.text.trim();

    if (description.isEmpty) {
      _showErrorDialog('Empty Activity', 'Please enter a description.');
      return;
    }

    final error = await activityController.addTask(description);
    if (error == null) {
      _activityInputController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } else if (mounted) {
      _showErrorDialog('Error Adding Activity', error);
    }
  }

  void _confirmDelete(TaskEntry task) {
    final activityController = Provider.of<ActivityController>(context, listen: false);
    final String dateString = activityController.currentDateKey;

    showCupertinoDialog( /* ... (same as before, ensure listen:false used for action) ... */
      context: context,
      builder: (BuildContext ctx) => CupertinoAlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${task.description}"?'),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(child: const Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              // listen: false for action
              final error = await Provider.of<ActivityController>(context, listen: false).deleteTask(dateString, task);
              if (error != null && mounted) _showErrorDialog('Error Deleting Activity', error);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, AuthController authController) {
    // ... (same as before) ...
    final theme = CupertinoTheme.of(context);
    String userName = authController.displayName ?? authController.userEmail?.split('@').first ?? "Momentum User";
    if (authController.displayName == null && authController.userEmail != null) {
      userName = userName.isNotEmpty ? userName[0].toUpperCase() + userName.substring(1) : "Momentum User";
    }

    String greetingText = "Hello, $userName!";
    int hour = DateTime.now().hour;
    if (hour < 5) greetingText = "Burning the midnight oil, $userName?";
    else if (hour < 12) greetingText = "Good Morning, $userName!";
    else if (hour < 18) greetingText = "Good Afternoon, $userName!";
    else greetingText = "Good Evening, $userName!";

    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 12.0, top: 20.0, bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greetingText, style: theme.textTheme.navLargeTitleTextStyle.copyWith(fontSize: 28, color: kTextColorLight), overflow: TextOverflow.ellipsis, maxLines: 1,),
                const SizedBox(height: 3),
                Text(DateFormat('EEEE, MMMM d').format(DateTime.now()), style: theme.textTheme.textStyle.copyWith(fontSize: 17, color: kSecondaryTextColorLight, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kAppPrimaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.settings, color: kAppPrimaryColor, size: 26),
            ),
            onPressed: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => const SettingsScreen())),
          )
        ],
      ),
    );
  }

  Widget _buildSyncStatus(BuildContext context, ActivityController activityController) {
    // ... (same as before) ...
    final theme = CupertinoTheme.of(context);
    Color statusColor = kSecondaryTextColorLight;
    IconData statusIconData = CupertinoIcons.time;
    String message = activityController.syncStatusMessage ?? "";

    if (activityController.isLoading && message.isEmpty) {
      message = "Loading data...";
      statusIconData = CupertinoIcons.refresh_thin;
      statusColor = kAppPrimaryColor;
    } else if (activityController.isLoading && (message.contains("Syncing") || message.contains("Fetching"))) {
      statusIconData = CupertinoIcons.refresh_circled_solid;
      statusColor = kAppPrimaryColor;
    } else if (message.contains("Error")) {
      statusIconData = CupertinoIcons.exclamationmark_shield_fill;
      statusColor = CupertinoColors.systemRed;
    } else if (message.contains("Offline")) {
      statusIconData = CupertinoIcons.wifi_slash;
      statusColor = CupertinoColors.systemOrange;
    } else if (message.contains("synced") || message.contains("up-to-date") || message.contains("complete") || message.contains("locally")) {
      statusIconData = CupertinoIcons.checkmark_alt_circle_fill;
      statusColor = CupertinoColors.systemGreen;
      if (message.contains("locally")) statusColor = kAppPrimaryColor;
    } else if (message.isNotEmpty) {
      statusIconData = CupertinoIcons.info_circle_fill;
    } else {
      return const SizedBox(height: 22);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(statusIconData, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: theme.textTheme.tabLabelTextStyle.copyWith(color: statusColor, fontSize: 13.5, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final activityController = context.watch<ActivityController>();
    final theme = CupertinoTheme.of(context);

    // Use the pre-sorted list from the controller
    final List<TaskEntry> todaysTasks = activityController.sortedTodayTasks;
    final DailyLog? todayLogObject = activityController.todayLogObject; // For isSynced status

    return CupertinoPageScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildGreeting(context, authController),
              _buildSyncStatus(context, activityController),

              StyledCard( /* ... (Input card same as before) ... */
                margin: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CupertinoTextField(
                      controller: _activityInputController,
                      placeholder: "What's today's focus?",
                      style: theme.textTheme.textStyle.copyWith(fontSize: 17),
                      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 18.0),
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.done,
                      decoration: BoxDecoration(
                        color: kTextFieldBackgroundLight,
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      prefix: const Padding(padding: EdgeInsets.only(left:18), child: Icon(CupertinoIcons.sparkles, color: kAppAccentColor, size: 22,)),
                      onSubmitted: (activityController.isLoading && _activityInputController.text.isNotEmpty) ? null : (_) => _submitActivity(),
                    ),
                    const SizedBox(height: 18.0),
                    (activityController.isLoading && _activityInputController.text.isNotEmpty)
                        ? const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: CupertinoActivityIndicator())
                        : SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: kAppPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        borderRadius: BorderRadius.circular(14),
                        onPressed: _submitActivity,
                        child: Text('Log Momentum', style: theme.textTheme.textStyle.copyWith(color: CupertinoColors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding( /* ... (Header for list same as before) ... */
                padding: const EdgeInsets.only(left: 22.0, top: 10.0, bottom: 10.0, right: 14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Today's Log (${todaysTasks.length})", style: theme.textTheme.navTitleTextStyle.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      onPressed: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => const AllDaysLoggingScreen())),
                      child: Row(children: [
                        Text('View History', style: theme.textTheme.actionTextStyle.copyWith(fontSize: 16, color: kAppPrimaryColor, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 5),
                        const Icon(CupertinoIcons.time_solid, size: 20, color: kAppPrimaryColor)
                      ]),
                    )
                  ],
                ),
              ),
              Expanded(
                child: (activityController.isLoading && todaysTasks.isEmpty && todayLogObject == null)
                    ? const Center(child: CupertinoActivityIndicator(radius: 20))
                    : todaysTasks.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.separated( // Using pre-sorted todaysTasks
                  separatorBuilder: (context, index) => Divider(height: 0.5, indent: 74, endIndent: 20, color: kSubtleBorderColorLight.withOpacity(0.6)),
                  padding: EdgeInsets.only(top: 0, left: 18, right: 18, bottom: 18 + MediaQuery.of(context).padding.bottom),
                  itemCount: todaysTasks.length,
                  itemBuilder: (context, index) {
                    final task = todaysTasks[index];
                    // Get isSynced from the overall todayLogObject, not per task
                    final bool isSynced = todayLogObject?.isSynced ?? false;
                    return _buildTaskListItem(context, task, isSynced);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskListItem(BuildContext context, TaskEntry task, bool isSynced) {
    // ... (same as before, this item build is already quite efficient) ...
    final theme = CupertinoTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: (isSynced ? kAppPrimaryColor : kAppAccentColor).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSynced ? CupertinoIcons.checkmark_alt : CupertinoIcons.hourglass_bottomhalf_fill,
              size: 22.0,
              color: isSynced ? kAppPrimaryColor : kAppAccentColor,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.description, style: theme.textTheme.textStyle.copyWith(fontSize: 17, fontWeight: FontWeight.w500, color: kTextColorLight, height: 1.3), maxLines: 3, overflow: TextOverflow.ellipsis,),
                const SizedBox(height: 5),
                Text(
                  DateFormat('h:mm a').format(task.timestamp),
                  style: theme.textTheme.tabLabelTextStyle.copyWith(fontSize: 14.5, color: kSecondaryTextColorLight, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: const EdgeInsets.all(10),
            onPressed: () => _confirmDelete(task),
            child: const Icon(CupertinoIcons.trash, color: CupertinoColors.systemGrey, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    // ... (same as before) ...
    final theme = CupertinoTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/empty_today.png', height: 150, errorBuilder: (c,o,s) => const Icon(CupertinoIcons.square_stack_3d_down_right_fill, size: 80, color: CupertinoColors.systemGrey2)),
              const SizedBox(height: 28),
              Text(
                "Log Your First Momentum!",
                style: theme.textTheme.navTitleTextStyle.copyWith(fontSize: 22, fontWeight: FontWeight.bold, color: kTextColorLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "What will you accomplish today? Every entry builds your progress towards your goals.",
                style: theme.textTheme.textStyle.copyWith(color: kSecondaryTextColorLight, fontSize: 16.5, height: 1.45),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
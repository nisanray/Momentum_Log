import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SnackBar, ScaffoldMessenger, Material, MaterialType; // For SnackBar
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../controllers/auth_controller.dart';
import '../controllers/activity_controller.dart';
import '../controllers/connectivity_controller.dart';
import '../widgets/styled_card.dart'; // Assuming you have this
import '../main.dart'; // For theme colors, etc.

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  Widget _buildSettingsItem({
    required BuildContext context,
    required String title,
    String? subtitle,
    required IconData leadingIcon,
    Color? leadingIconColor,
    Color? leadingIconBackgroundColor,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    final theme = CupertinoTheme.of(context);
    return StyledCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      onTap: onTap,
      color: kCardBackgroundLight,
      boxShadow: const [],
      border: Border(bottom: BorderSide(color: kSubtleBorderColorLight.withOpacity(0.4), width: 0.5)),
      borderRadius: BorderRadius.zero,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (leadingIconBackgroundColor ?? (leadingIconColor ?? kAppPrimaryColor).withOpacity(0.12)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(leadingIcon, color: leadingIconColor ?? kAppPrimaryColor, size: 22),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: theme.textTheme.textStyle.copyWith(fontSize: 17, color: titleColor ?? kTextColorLight, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis,),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(subtitle, style: theme.textTheme.tabLabelTextStyle.copyWith(fontSize: 14.5, color: kSecondaryTextColorLight, fontWeight: FontWeight.w400), maxLines: 1, overflow: TextOverflow.ellipsis,),
                ]
              ],
            ),
          ),
          if (trailing != null) Padding(padding: const EdgeInsets.only(left: 8.0), child: trailing),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final activityController = context.watch<ActivityController>();
    final connectivityController = context.watch<ConnectivityController>();
    final theme = CupertinoTheme.of(context);

    String syncSubtitle;
    if (activityController.isLoading && (activityController.syncStatusMessage?.toLowerCase().contains('sync') ?? false)) {
      syncSubtitle = "Syncing in progress...";
    } else if (!connectivityController.isOnline) {
      syncSubtitle = "Offline - Sync when online";
    } else {
      syncSubtitle = activityController.syncStatusMessage ?? "Tap to sync all data";
      if(syncSubtitle.length > 40) syncSubtitle = "Last sync status available.";
    }

    String profileTitle = authController.displayName?.trim() ?? 'User Profile';
    if (profileTitle.isEmpty || (profileTitle == 'User Profile' && authController.userEmail != null && authController.userEmail!.isNotEmpty) ) {
      profileTitle = authController.userEmail!.split('@').first;
      profileTitle = profileTitle.isNotEmpty ? profileTitle[0].toUpperCase() + profileTitle.substring(1) : 'User Profile';
    }
    String profileSubtitle = authController.userEmail ?? 'No email available';

    return CupertinoPageScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings & Account'),
        previousPageTitle: 'Today',
      ),
      child: SafeArea(
        top: true,
        bottom: true,
        child: Material( // For SnackBar context
          type: MaterialType.transparency,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            children: <Widget>[
              StyledCard(
                margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8.0),
                padding: EdgeInsets.zero,
                child: _buildSettingsItem(
                  context: context,
                  title: profileTitle,
                  subtitle: profileSubtitle,
                  leadingIcon: CupertinoIcons.person_crop_circle_fill,
                  leadingIconColor: kAppSecondaryColor,
                  leadingIconBackgroundColor: kAppSecondaryColor.withOpacity(0.12),
                ),
              ),
              StyledCard(
                margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8.0),
                padding: EdgeInsets.zero,
                child: _buildSettingsItem(
                  context: context,
                  title: 'Data Synchronization',
                  subtitle: syncSubtitle,
                  leadingIcon: CupertinoIcons.arrow_2_circlepath_circle_fill,
                  leadingIconColor: kAppPrimaryColor,
                  trailing: connectivityController.isOnline
                      ? ((activityController.isLoading && (activityController.syncStatusMessage?.toLowerCase().contains('sync') ?? false))
                      ? const CupertinoActivityIndicator(radius: 11)
                      : Icon(CupertinoIcons.chevron_forward, color: kSubtleTextColorLight, size: 20))
                      : Icon(CupertinoIcons.wifi_slash, color: CupertinoColors.systemOrange, size: 20),
                  onTap: connectivityController.isOnline && !(activityController.isLoading && (activityController.syncStatusMessage?.toLowerCase().contains('sync') ?? false))
                      ? () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Attempting to sync all data...'), duration: Duration(seconds: 2))
                    );
                    await Provider.of<ActivityController>(context, listen: false).syncAllData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text( Provider.of<ActivityController>(context, listen: false).syncStatusMessage ?? 'Sync process completed.'), duration: Duration(seconds: 3))
                      );
                    }
                  }
                      : null,
                ),
              ),
              StyledCard(
                margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8.0),
                padding: EdgeInsets.zero,
                child: _buildSettingsItem(
                  context: context,
                  title: 'Sign Out',
                  leadingIcon: CupertinoIcons.square_arrow_left_fill,
                  leadingIconColor: CupertinoColors.systemRed,
                  titleColor: CupertinoColors.systemRed,
                  trailing: Icon(CupertinoIcons.chevron_forward, color: kSubtleTextColorLight, size: 20),
                  onTap: () async {
                    showCupertinoModalPopup(
                      context: context,
                      builder: (BuildContext ctx) => CupertinoActionSheet(
                        title: Text('Confirm Sign Out', style: theme.textTheme.navTitleTextStyle.copyWith(fontSize: 18, color: kTextColorLight)),
                        message: Text('Are you sure you want to sign out?', style: theme.textTheme.textStyle.copyWith(fontSize: 15, color: kSecondaryTextColorLight)),
                        actions: <CupertinoActionSheetAction>[
                          CupertinoActionSheetAction(
                            onPressed: () async {
                              Navigator.of(ctx).pop(); // Dismiss the action sheet
                              // CRITICAL: Use listen: false for actions
                              await Provider.of<AuthController>(context, listen: false).logout();
                              // AuthGate should handle navigation based on AuthController's state change
                            },
                            isDestructiveAction: true,
                            child: const Text('Sign Out'),
                          ),
                        ],
                        cancelButton: CupertinoActionSheetAction(
                          isDefaultAction: true,
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
                child: Text(
                  'Momentum Log v1.0.3\n© ${DateFormat('yyyy').format(DateTime.now())} nisanray', // Updated version
                  textAlign: TextAlign.center,
                  style: theme.textTheme.tabLabelTextStyle.copyWith(color: kSubtleTextColorLight, fontSize: 13.5, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
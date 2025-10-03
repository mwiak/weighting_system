import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../widgets/user_form_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh user list when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().getAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ScaffoldPage.scrollable(
      header: PageHeader(
        title: Text(l10n.userManagement),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.add),
              label: Text(l10n.addUser),
              onPressed: () => _showAddUserDialog(),
            ),
          ],
        ),
      ),
      children: [
        Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            if (userProvider.allUsers.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(l10n.noUsersFound),
                ),
              );
            }

            return Card(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    // Table header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: FluentTheme.of(context)
                            .accentColor
                            .withOpacity(0.1),
                        border: Border(
                          bottom: BorderSide(
                            color: FluentTheme.of(context).accentColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              l10n.username,
                              style: FluentTheme.of(context)
                                  .typography
                                  .bodyStrong,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              l10n.type,
                              style: FluentTheme.of(context)
                                  .typography
                                  .bodyStrong,
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              l10n.actions,
                              style: FluentTheme.of(context)
                                  .typography
                                  .bodyStrong,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // User rows
                    ...userProvider.allUsers.map(
                      (user) => _buildUserRow(context, user, userProvider),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUserRow(
      BuildContext context, User user, UserProvider userProvider) {
    final l10n = AppLocalizations.of(context)!;
    final isAdmin = user.type == UserRanks.admin;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[60],
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Username
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isAdmin
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  child: Text(
                    user.username.characters.first.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isAdmin ? Colors.blue : Colors.grey[160],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  user.username,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          // Type badge
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isAdmin
                    ? Colors.blue.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isAdmin ? l10n.admin : l10n.user,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isAdmin ? Colors.blue : Colors.grey[160],
                ),
              ),
            ),
          ),

          // Action buttons
          Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Edit button
                Button(
                  onPressed: () => _showEditUserDialog(user),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(FluentIcons.edit, size: 14),
                      const SizedBox(width: 4),
                      Text(l10n.edit),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Change password button
                Button(
                  onPressed: () => _showChangePasswordDialog(user),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(FluentIcons.password_field, size: 14),
                      const SizedBox(width: 4),
                      Text(l10n.password),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Delete button
                FutureBuilder<bool>(
                  future: userProvider.canDeleteUser(user.id!),
                  builder: (context, snapshot) {
                    final canDelete = snapshot.data ?? false;

                    return Button(
                      onPressed:
                          canDelete ? () => _showDeleteConfirmation(user) : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FluentIcons.delete,
                            size: 14,
                            color: canDelete ? Colors.red : Colors.grey[100],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.delete,
                            style: TextStyle(
                              color: canDelete ? Colors.red : Colors.grey[100],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddEditUserDialog(),
    );
  }

  void _showEditUserDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AddEditUserDialog(user: user),
    );
  }

  void _showChangePasswordDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => ChangePasswordDialog(user: user),
    );
  }

  void _showDeleteConfirmation(User user) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(l10n.confirmDelete),
        content: Text(
          l10n.deleteUserConfirm(user.username),
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await context.read<UserProvider>().deleteUser(user.id!, context);
              if (mounted) {
                navigator.pop();
              }
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red),
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

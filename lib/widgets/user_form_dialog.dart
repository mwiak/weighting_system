import 'package:fluent_ui/fluent_ui.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';

/// Dialog for adding or editing a user
class AddEditUserDialog extends StatefulWidget {
  final User? user; // null for add, populated for edit

  const AddEditUserDialog({super.key, this.user});

  @override
  State<AddEditUserDialog> createState() => _AddEditUserDialogState();
}

class _AddEditUserDialogState extends State<AddEditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRanks _selectedType = UserRanks.normal;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = false;

  bool get isEditMode => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _usernameController.text = widget.user!.username;
      _selectedType = widget.user!.type;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    final l10n = AppLocalizations.of(context)!;
    // Validate form
    if (_usernameController.text.trim().isEmpty) {
      _showError(l10n.usernameRequired);
      return;
    }

    if (!isEditMode) {
      // For new users, password is required
      if (_passwordController.text.isEmpty) {
        _showError(l10n.passwordRequired);
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        _showError(l10n.passwordsDoNotMatch);
        return;
      }
    }

    setState(() => _isLoading = true);

    final userProvider = context.read<UserProvider>();

    bool success;
    if (isEditMode) {
      // Update user
      final updatedUser = User();
      updatedUser.id = widget.user!.id;
      updatedUser.username = _usernameController.text.trim();
      updatedUser.password = widget.user!.password; // Keep existing password
      updatedUser.type = _selectedType;

      success = await userProvider.updateUser(updatedUser, context);
    } else {
      // Create new user
      final newUser = User();
      newUser.username = _usernameController.text.trim();
      newUser.password = _passwordController.text;
      newUser.type = _selectedType;

      success = await userProvider.createNewUser(newUser, context);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showError(String message) {
    final l10n = AppLocalizations.of(context)!;
    displayInfoBar(context, builder: (context, close) {
      return InfoBar(
        title: Text(l10n.validationError),
        content: Text(message),
        severity: InfoBarSeverity.warning,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ContentDialog(
      title: Text(isEditMode ? l10n.editUser : l10n.addNewUser),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username field
                InfoLabel(
                  label: l10n.username,
                  child: TextBox(
                    controller: _usernameController,
                    placeholder: l10n.enterUsername,
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(height: 16),

                // User type selector
                InfoLabel(
                  label: l10n.userType,
                  child: ComboBox<UserRanks>(
                    value: _selectedType,
                    items: [
                      ComboBoxItem(
                        value: UserRanks.normal,
                        child: Text(l10n.normalUser),
                      ),
                      ComboBoxItem(
                        value: UserRanks.admin,
                        child: Text(l10n.admin),
                      ),
                    ],
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _selectedType = value);
                            }
                          },
                  ),
                ),
                const SizedBox(height: 16),

                // Password fields (only for new users)
                if (!isEditMode) ...[
                  InfoLabel(
                    label: l10n.password,
                    child: TextBox(
                      controller: _passwordController,
                      placeholder: l10n.enterPassword,
                      obscureText: _hidePassword,
                      enabled: !_isLoading,
                      suffix: IconButton(
                        icon: Icon(_hidePassword
                            ? FluentIcons.red_eye
                            : FluentIcons.hide),
                        onPressed: () {
                          setState(() => _hidePassword = !_hidePassword);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InfoLabel(
                    label: l10n.confirmPassword,
                    child: TextBox(
                      controller: _confirmPasswordController,
                      placeholder: l10n.reEnterPassword,
                      obscureText: _hideConfirmPassword,
                      enabled: !_isLoading,
                      suffix: IconButton(
                        icon: Icon(_hideConfirmPassword
                            ? FluentIcons.red_eye
                            : FluentIcons.hide),
                        onPressed: () {
                          setState(() =>
                              _hideConfirmPassword = !_hideConfirmPassword);
                        },
                      ),
                    ),
                  ),
                ],

                if (isEditMode) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.passwordChangeHint,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[120],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        Button(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: ProgressRing(strokeWidth: 2),
                )
              : Text(isEditMode ? l10n.update : l10n.create),
        ),
      ],
    );
  }
}

/// Dialog for changing user password
class ChangePasswordDialog extends StatefulWidget {
  final User user;

  const ChangePasswordDialog({super.key, required this.user});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    final l10n = AppLocalizations.of(context)!;
    // Validate
    if (_newPasswordController.text.isEmpty) {
      _showError(l10n.passwordRequired);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError(l10n.passwordsDoNotMatch);
      return;
    }

    setState(() => _isLoading = true);

    final userProvider = context.read<UserProvider>();
    final success = await userProvider.changePassword(
      widget.user.id!,
      _newPasswordController.text,
      context,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showError(String message) {
    final l10n = AppLocalizations.of(context)!;
    displayInfoBar(context, builder: (context, close) {
      return InfoBar(
        title: Text(l10n.validationError),
        content: Text(message),
        severity: InfoBarSeverity.warning,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ContentDialog(
      title: Text(l10n.changePasswordFor(widget.user.username)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoLabel(
              label: l10n.newPassword,
              child: TextBox(
                controller: _newPasswordController,
                placeholder: l10n.enterNewPassword,
                obscureText: _hidePassword,
                enabled: !_isLoading,
                suffix: IconButton(
                  icon: Icon(
                      _hidePassword ? FluentIcons.red_eye : FluentIcons.hide),
                  onPressed: () {
                    setState(() => _hidePassword = !_hidePassword);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            InfoLabel(
              label: l10n.confirmNewPassword,
              child: TextBox(
                controller: _confirmPasswordController,
                placeholder: l10n.reEnterNewPassword,
                obscureText: _hideConfirmPassword,
                enabled: !_isLoading,
                suffix: IconButton(
                  icon: Icon(_hideConfirmPassword
                      ? FluentIcons.red_eye
                      : FluentIcons.hide),
                  onPressed: () {
                    setState(
                        () => _hideConfirmPassword = !_hideConfirmPassword);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: ProgressRing(strokeWidth: 2),
                )
              : Text(l10n.changePassword),
        ),
      ],
    );
  }
}

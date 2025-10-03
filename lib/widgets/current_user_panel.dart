import 'dart:ui';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/user.dart';
import '../providers/user_provider.dart';

class CurrentUserPanel extends StatefulWidget {
  const CurrentUserPanel({super.key});

  @override
  State<CurrentUserPanel> createState() => _CurrentUserPanelState();
}

class _CurrentUserPanelState extends State<CurrentUserPanel>
    with SingleTickerProviderStateMixin {
  final GlobalKey _parentKey = GlobalKey();
  late User user;
  bool isHovered = false;
  bool isPressed = false;
  final overlayPortalController = OverlayPortalController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  void _toggleOverlay() {
    if (overlayPortalController.isShowing) {
      overlayPortalController.hide();
      _animationController.reverse();
    } else {
      overlayPortalController.show();
      _animationController.forward();
    }
    setState(() {
      isPressed = !isPressed;
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<UserProvider>();
      user = provider.activeUser!;
      provider.addListener(() {
        if (provider.activeUser != null) {
          user = provider.activeUser!;
        }
      });
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color get _avatarColor {
    if (isPressed) return Colors.blue.light;
    if (isHovered) return Colors.blue.lighter;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Consumer<UserProvider>(
      builder: (context, value, child) {
        if (value.activeUser == null) {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.withOpacity(0.3),
            ),
            child: const Center(
              child: ProgressRing(strokeWidth: 3),
            ),
          );
        }

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _toggleOverlay,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _avatarColor,
                boxShadow: isHovered || isPressed
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: OverlayPortal(
                controller: overlayPortalController,
                overlayChildBuilder: (context) =>
                    _buildOverlay(context, value, theme),
                child: Center(
                  key: _parentKey,
                  child: Text(
                    value.activeUser!.username.characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverlay(
      BuildContext context, UserProvider value, FluentThemeData theme) {
    final RenderBox? targetBox =
        _parentKey.currentContext?.findRenderObject() as RenderBox?;
    if (targetBox == null) return const SizedBox.shrink();

    final position = targetBox.localToGlobal(Offset.zero);

    return GestureDetector(
      onTap: _toggleOverlay,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          // Backdrop
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                color: Colors.black.withOpacity(0.2),
              ),
            ),
          ),
          // Overlay panel
          Positioned(
            top: position.dy + 75,
            left: position.dx + 20,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.topLeft,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: () {}, // Prevent closing when tapping the panel
                  child: _buildUserPanel(value, theme),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserPanel(UserProvider value, FluentThemeData theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: 280,
          constraints: const BoxConstraints(maxHeight: 400),
          decoration: BoxDecoration(
            color: theme.micaBackgroundColor.withOpacity(0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.inactiveColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: theme.inactiveColor.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      FluentIcons.switch_user,
                      size: 16,
                      color: theme.accentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Switch User',
                      style: theme.typography.bodyStrong,
                    ),
                  ],
                ),
              ),
              // User list
              if (value.otherUsers.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: value.otherUsers.length,
                    itemBuilder: (context, index) => _UserListItem(
                      user: value.otherUsers[index],
                      onTap: () {
                        _toggleOverlay();
                        showSwitchUserDialog(value.otherUsers[index]);
                      },
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        FluentIcons.contact,
                        size: 48,
                        color: theme.inactiveColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No other users available',
                        style: theme.typography.body?.copyWith(
                          color: theme.inactiveColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void showSwitchUserDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => SwitchUserDialog(username: user.username),
    );
  }
}

class _UserListItem extends StatefulWidget {
  final User user;
  final VoidCallback onTap;

  const _UserListItem({
    required this.user,
    required this.onTap,
  });

  @override
  State<_UserListItem> createState() => _UserListItemState();
}

class _UserListItemState extends State<_UserListItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isHovered
                ? theme.accentColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Avatar
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isHovered ? theme.accentColor : theme.accentColor.dark,
                  boxShadow: isHovered
                      ? [
                          BoxShadow(
                            color: theme.accentColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    widget.user.username.characters.first.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.username,
                      style: theme.typography.body?.copyWith(
                        fontWeight:
                            isHovered ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
              // Arrow icon
              AnimatedRotation(
                turns: isHovered ? 0.0 : -0.25,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  FluentIcons.chevron_right,
                  size: 16,
                  color: isHovered
                      ? theme.accentColor
                      : theme.inactiveColor.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SwitchUserDialog extends StatefulWidget {
  final String username;
  const SwitchUserDialog({super.key, required this.username});

  @override
  State<SwitchUserDialog> createState() => _SwitchUserDialogState();
}

class _SwitchUserDialogState extends State<SwitchUserDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  bool _hidePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    // Auto-focus password field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _passwordFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocus.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _shake() {
    _shakeController.forward(from: 0.0);
  }

  Future<void> _handleLogin() async {
    if (_passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Password is required');
      _shake();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userProvider = context.read<UserProvider>();

      await userProvider.attemptLogin(
        widget.username,
        _passwordController.text,
        null,
      );

      if (mounted) {
        // Check if user changed successfully
        if (userProvider.activeUser?.username == widget.username) {
          Navigator.of(context).pop();
        } else {
          setState(() {
            _errorMessage = 'Invalid password';
            _isLoading = false;
          });
          _shake();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Login failed: ${e.toString()}';
          _isLoading = false;
        });
        _shake();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 400),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.accentColor,
            ),
            child: Center(
              child: Text(
                widget.username.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Switch to ${widget.username}',
                  style: theme.typography.subtitle,
                ),
                const SizedBox(height: 2),
                Text(
                  'Enter password to continue',
                  style: theme.typography.caption?.copyWith(
                    color: theme.inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final offset = _shakeController.value *
                  10 *
                  (1 - _shakeController.value) *
                  ((_shakeController.value * 8).floor().isEven ? 1 : -1);
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoLabel(
                  label: 'Password',
                  child: TextBox(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: _hidePassword,
                    placeholder: 'Enter your password',
                    suffix: IconButton(
                      icon: Icon(
                        _hidePassword ? FluentIcons.lock : FluentIcons.unlock,
                        size: 16,
                      ),
                      onPressed: () {
                        setState(() => _hidePassword = !_hidePassword);
                      },
                    ),
                    onSubmitted: (_) => _handleLogin(),
                    enabled: !_isLoading,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.errorPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.errorPrimaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          FluentIcons.error_badge,
                          size: 16,
                          color: Colors.errorPrimaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: theme.typography.caption?.copyWith(
                              color: Colors.errorPrimaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      actions: [
        Button(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleLogin,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: ProgressRing(strokeWidth: 2),
                )
              : Text(AppLocalizations.of(context)!.signIn),
        ),
      ],
    );
  }
}

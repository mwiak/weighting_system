import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:weighing_system/providers/user_provider.dart';
import 'package:weighing_system/screens/main_dashboard.dart';
import 'package:weighing_system/utils/navigator_methods.dart';
import 'package:weighing_system/widgets/user_login_avatar.dart';
import '../l10n/app_localizations.dart';
import 'package:weighing_system/theme/app_theme.dart';

import '../models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool isShowingPasswordPanel = false;
  List<User> users = [];
  String usernameToLog = '';
  TextEditingController passWordController = TextEditingController();
  bool hidePassword = true;
  bool isLoading = false;
  String? errorMessage;
  late VoidCallback _listener;
  late UserProvider provider;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  FocusNode passwordNode = FocusNode();

  void attemptLogin(UserProvider provider) {}

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start animation
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider = context.read<UserProvider>();
      provider.getAllUsers();
      _listener = () {
        userListener(provider);
      };

      provider.addListener(_listener);
    });
  }

  void userListener(UserProvider provider) {
    if (provider.activeUser != null) {
      navigateToWithReplacement(MainDashboard(), context);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    passWordController.dispose();
    provider.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<UserProvider>(
      builder: (BuildContext context, UserProvider value, Widget? child) {
        if (value.isInitializing) {
          return ScaffoldPage(
            padding: EdgeInsets.zero,
            content: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ProgressRing(),
                  const SizedBox(height: 16),
                  Text(
                    l10n.loadingDots,
                    style: FluentTheme.of(context).typography.body,
                  ),
                ],
              ),
            ),
          );
        }
        users = value.allUsers;

        return ScaffoldPage(
          padding: EdgeInsets.zero,
          content: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.grad1,
                  AppTheme.grad2,
                  AppTheme.grad3,
                  // Colors.blue;
                  // FluentTheme.of(context).accentColor.withOpacity(0.05),
                  // FluentTheme.of(context).scaffoldBackgroundColor,
                  // FluentTheme.of(context).accentColor.withOpacity(0.03),
                ],
              ),
            ),
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: RepaintBoundary(
                    child: Card(
                      backgroundColor: const Color(0x30E6E0E0),
                      borderRadius: const BorderRadius.all(Radius.circular(25)),
                      padding: const EdgeInsets.all(48),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Text(
                              l10n.chooseUser,
                              style: FluentTheme.of(context)
                                  .typography
                                  .title
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 32),

                            // User avatars with staggered animation
                            Wrap(
                              spacing: 20,
                              runSpacing: 20,
                              alignment: WrapAlignment.center,
                              children: List.generate(
                                value.allUsers.length,
                                (index) => _buildAnimatedAvatar(
                                  value.allUsers[index],
                                  index,
                                ),
                              ),
                            ),

                            // Password panel
                            const SizedBox(height: 24),
                            showPasswordPanel(),

                            // Error message
                            if (errorMessage != null) ...[
                              const SizedBox(height: 16),
                              InfoBar(
                                title: Text(l10n.loginFailed),
                                content: Text(errorMessage!),
                                severity: InfoBarSeverity.error,
                                onClose: () {
                                  setState(() => errorMessage = null);
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
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

  Widget _buildAnimatedAvatar(User user, int index) {
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 300 + (index * 100)),
        tween: Tween(begin: 0.0, end: 1.0),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          // Clamp value to ensure it's between 0.0 and 1.0
          final clampedValue = value.clamp(0.0, 1.0);
          return Transform.scale(
            scale: clampedValue,
            child: Opacity(
              opacity: clampedValue,
              child: UserLoginAvatar(
                onPressed: (v) {
                  setState(() {
                    usernameToLog = v;
                    isShowingPasswordPanel = true;
                    errorMessage = null;
                  });
                },
                user: user,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget showPasswordPanel() {
    passwordNode.hasFocus ? null : passwordNode.requestFocus();
    final l10n = AppLocalizations.of(context)!;
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: isShowingPasswordPanel
          ? TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 400),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Column(
                      children: [
                        // Selected user indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: FluentTheme.of(context)
                                .accentColor
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.loggingInAs(usernameToLog),
                            style: FluentTheme.of(context)
                                .typography
                                .bodyStrong
                                ?.copyWith(
                                  color: FluentTheme.of(context).accentColor,
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        SizedBox(
                          width: 300,
                          child: InfoLabel(
                            label: l10n.password,
                            child: TextBox(
                              focusNode: passwordNode,
                              textDirection: TextDirection.ltr,
                              placeholder: l10n.enterYourPassword,
                              suffix: IconButton(
                                icon: Icon(
                                  hidePassword
                                      ? FluentIcons.red_eye
                                      : FluentIcons.hide,
                                ),
                                onPressed: () {
                                  setState(() {
                                    hidePassword = !hidePassword;
                                  });
                                },
                              ),
                              obscureText: hidePassword,
                              controller: passWordController,
                              enabled: !isLoading,
                              onSubmitted: (value) => _handleLogin(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login button with animation
                        SizedBox(
                          width: 300,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: FilledButton(
                              onPressed: isLoading ? null : _handleLogin,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: ProgressRing(strokeWidth: 2),
                                    )
                                  : Text(l10n.continue_),
                            ),
                          ),
                        ),

                        // Back button
                        const SizedBox(height: 12),
                        Button(
                          onPressed: isLoading
                              ? null
                              : () {
                                  setState(() {
                                    isShowingPasswordPanel = false;
                                    passWordController.clear();
                                    errorMessage = null;
                                  });
                                },
                          child: Text(l10n.back),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : const SizedBox.shrink(),
    );
  }

  Future<void> _handleLogin() async {
    final l10n = AppLocalizations.of(context)!;
    if (passWordController.text.isEmpty) {
      setState(() {
        errorMessage = l10n.pleaseEnterPassword;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    // Get user data to verify password
    final userProvider = context.read<UserProvider>();
    final userData = await userProvider.databaseHelper.query(
      'users',
      where: 'username = ?',
      whereArgs: [usernameToLog],
    );

    if (userData.isNotEmpty) {
      final actualPassword = userData[0]['password'] ?? '';
      if (passWordController.text.trim() == actualPassword) {
        // Success - let the provider handle navigation
        await userProvider.attemptLogin(
          usernameToLog,
          passWordController.text.trim(),
          null,
        );
      } else {
        // Wrong password
        setState(() {
          isLoading = false;
          errorMessage = l10n.incorrectPassword;
          passWordController.clear();
        });
      }
    } else {
      // User not found (shouldn't happen)
      setState(() {
        isLoading = false;
        errorMessage = l10n.userNotFound;
      });
    }
  }

  void navigateToMain() {
    Navigator.of(context).pushReplacement(
        FluentPageRoute(builder: (context) => MainDashboard()));
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/mediator_portal_controller.dart';
import '../../widgets/app_scaffold_bits.dart';

class DesktopLoginScreen extends ConsumerStatefulWidget {
  const DesktopLoginScreen({super.key});

  @override
  ConsumerState<DesktopLoginScreen> createState() => _DesktopLoginScreenState();
}

class _DesktopLoginScreenState extends ConsumerState<DesktopLoginScreen> {
  final _adminFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@Elite.jo');
  final _passwordController = TextEditingController(text: '12345678');
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authActionState = ref.watch(authActionControllerProvider);

    return DefaultTabController(
      length: 2,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 540,
              child: SectionCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'دخول الإدارة'),
                        Tab(text: 'دخول بالرمز'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 380,
                      child: TabBarView(
                        children: [
                          Form(
                            key: _adminFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'تسجيل دخول الإدارة',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'هذا المسار مخصص للأدمن عبر البريد الإلكتروني وكلمة المرور.',
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    labelText: 'البريد الإلكتروني',
                                  ),
                                  validator: (value) => value == null || value.trim().isEmpty
                                      ? 'البريد مطلوب'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: const InputDecoration(
                                    labelText: 'كلمة المرور',
                                  ),
                                  validator: (value) => value == null || value.trim().isEmpty
                                      ? 'كلمة المرور مطلوبة'
                                      : null,
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: authActionState.isLoading
                                        ? null
                                        : () async {
                                            if (!_adminFormKey.currentState!.validate()) {
                                              return;
                                            }

                                            await ref
                                                .read(authActionControllerProvider.notifier)
                                                .signInAdmin(
                                                  email: _emailController.text.trim(),
                                                  password: _passwordController.text.trim(),
                                                );

                                            final result =
                                                ref.read(authActionControllerProvider);
                                            if (result.hasError) {
                                              final error = result.error;
                                              final message =
                                                  error is FirebaseAuthException
                                                      ? error.message ?? error.code
                                                      : '$error';
                                              if (mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(message),
                                                  ),
                                                );
                                              }
                                              return;
                                            }

                                            final session = ref.read(authSessionProvider);
                                            if (session.isAdmin && mounted) {
                                              context.go('/admin/dashboard');
                                            }
                                          },
                                    child: Text(
                                      authActionState.isLoading
                                          ? 'جاري تسجيل الدخول...'
                                          : 'دخول الإدارة',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Form(
                            key: _codeFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'دخول الوسيط بالرمز',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'هذا المسار يسمح للوسيط بفتح صفحته عبر الرمز فقط.',
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _codeController,
                                  maxLength: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'رمز الوسيط',
                                  ),
                                  validator: (value) {
                                    final code = value?.trim() ?? '';
                                    if (code.length != 4) return 'يجب إدخال 4 أحرف';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (!_codeFormKey.currentState!.validate()) {
                                        return;
                                      }

                                      try {
                                        await ref
                                            .read(mediatorSessionProvider.notifier)
                                            .signInWithCode(_codeController.text.trim());
                                        if (mounted) {
                                          context.go('/mediator/dashboard');
                                        }
                                      } catch (error) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('$error'),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text('دخول الوسيط'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

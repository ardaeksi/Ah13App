import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../models/deed.dart';
import '../services/deed_service.dart';
import '../theme.dart';

class DeedDetailPortal extends StatefulWidget {
  /// If `deed` is null, the page will show a lightweight error UI.
  final Deed? deed;
  const DeedDetailPortal({super.key, required this.deed});

  @override
  State<DeedDetailPortal> createState() => _DeedDetailPortalState();
}

class _DeedDetailPortalState extends State<DeedDetailPortal> {
  bool _isCompleting = false;
  final DeedService _deedService = DeedService();

  @override
  Widget build(BuildContext context) {
    final deed = widget.deed;
    if (deed == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ATIBA DEED')),
        body: Center(
          child: Text(
            'Could not load this deed.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ATIBA DEED'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DeedHeroCard(deed: deed).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),
              const SizedBox(height: 14),
              _DeedInfoCard(deed: deed).animate().fadeIn(delay: 80.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),
              const Spacer(),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.black],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton.icon(
                  onPressed: (_isCompleting || deed.isCompleted) ? null : _handleComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isCompleting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(deed.isCompleted ? Icons.verified_rounded : Icons.verified_outlined, color: Colors.white),
                  label: Text(
                    _isCompleting
                        ? 'Verifying…'
                        : (deed.isCompleted ? 'Deed completed' : 'Complete deed'),
                    style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Parent Safety PIN required to complete.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleComplete() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first.')),
      );
      return;
    }

    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ParentsPinSheet(),
    );
    if (!mounted || pin == null) return;

    setState(() => _isCompleting = true);
    try {
      await Future.delayed(const Duration(milliseconds: 250));
      final ok = await auth.verifyParentsPin(pin);
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect Parent Safety PIN.')),
        );
        return;
      }

      final deed = widget.deed;
      final uid = auth.currentUser?.uid;
      if (deed == null || uid == null) return;

      await _deedService.markCompleted(uid: uid, deedId: deed.id);

      if (!mounted) return;
      context.pop(true);
    } catch (e) {
      debugPrint('Failed to complete deed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not complete deed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }
}

class _DeedHeroCard extends StatelessWidget {
  final Deed deed;
  const _DeedHeroCard({required this.deed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.black],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(DeedIcons.fromKey(deed.iconKey), color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(deed.title, style: AppTextStyles.headlineMedium),
                const SizedBox(height: 4),
                Text(deed.highlight, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _XpPill(points: deed.points),
        ],
      ),
    );
  }
}

class _DeedInfoCard extends StatelessWidget {
  final Deed deed;
  const _DeedInfoCard({required this.deed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What to do', style: AppTextStyles.titleLarge),
          const SizedBox(height: 10),
          Text(deed.description, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.visibility_rounded, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tap Complete when finished. A parent must approve with the Safety PIN.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _XpPill extends StatelessWidget {
  final int points;
  const _XpPill({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Text(
        '+$points XP',
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _ParentsPinSheet extends StatefulWidget {
  const _ParentsPinSheet();

  @override
  State<_ParentsPinSheet> createState() => _ParentsPinSheetState();
}

class _ParentsPinSheetState extends State<_ParentsPinSheet> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final size = MediaQuery.sizeOf(context);

    // This sheet is rendered as a "raised panel" higher up so the keyboard
    // doesn't cover the input on smaller screens.
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 56, bottom: viewInsets.bottom + 16),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 520, maxHeight: size.height * 0.62),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          height: 5,
                          width: 44,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('Parent approval', style: AppTextStyles.titleLarge),
                      const SizedBox(height: 6),
                      Text('Enter the 4-digit Parent Safety PIN to complete.', style: AppTextStyles.bodySmall),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        obscureText: _obscure,
                        autofocus: true,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                        decoration: InputDecoration(
                          labelText: 'Parent Safety PIN',
                          hintText: '4 digits',
                          prefixIcon: const Icon(Icons.shield_outlined),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                          ),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: BorderSide(color: AppColors.white.withValues(alpha: 0.12)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Verify'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ).animate().slideY(begin: 0.10, end: 0, duration: 220.ms).fadeIn(duration: 220.ms),
    );
  }

  void _submit() {
    final pin = _controller.text.trim();
    if (pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be exactly 4 digits.')),
      );
      return;
    }
    context.pop(pin);
  }
}

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/child_account_service.dart';
import '../../services/firestore_errors.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/validators.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/primary_button.dart';

/// Lets a parent add a child Auth account plus Firestore records without
/// signing the parent out.
class AddChildScreen extends StatefulWidget {
  const AddChildScreen({super.key});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  final ChildAccountService _childAccounts = ChildAccountService();

  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final String? parentUid = AuthService.instance.currentFirebaseUser?.uid;
    if (parentUid == null) {
      setState(() => _error = 'We couldn’t find your family. Please try again.');
      return;
    }

    setState(() => _busy = true);
    try {
      final String? familyId = await _parentFamilyId();
      if (familyId == null) {
        throw const FirestoreException(
          'We couldn’t find your family. Please try again.',
        );
      }

      final String childUid = await _childAccounts.createChildAuthAccount(
        email: _email.text,
        password: _password.text,
        name: _name.text,
      );

      if (AuthService.instance.currentFirebaseUser?.uid != parentUid) {
        throw const AuthException(
          'Something went wrong. Please try again.',
        );
      }

      await FirestoreService.instance.addChild(
        familyId: familyId,
        uid: childUid,
        name: _name.text,
        email: _email.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } on FirestoreException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _parentFamilyId() async {
    final String? uid = AuthService.instance.currentFirebaseUser?.uid;
    if (uid == null) return null;
    final profile = await FirestoreService.instance.getUserProfile(uid);
    return profile?.familyId;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AuthScaffold(
      title: 'Add a child',
      subtitle: 'They’ll use this email on their own phone.',
      child: KidCard(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _name,
                enabled: !_busy,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Child name',
                  prefixIcon: Icon(Icons.child_care_outlined),
                ),
                validator: Validators.name,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Child email',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _password,
                enabled: !_busy,
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: Validators.password,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _confirm,
                enabled: !_busy,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: (String? value) =>
                    Validators.confirmPassword(value, _password.text),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: _busy ? 'Adding child…' : 'Add child',
                onPressed: _busy ? null : _submit,
                expand: true,
                compact: true,
              ),
              TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

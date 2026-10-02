import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../models/child_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/family_session.dart';
import '../services/firestore_service.dart';
import 'app_page.dart';
import 'status_views.dart';

class FamilyScope {
  const FamilyScope({
    required this.user,
    required this.familyId,
    required this.children,
    this.selectedChild,
  });

  final UserModel user;
  final String familyId;
  final List<ChildModel> children;
  final ChildModel? selectedChild;
}

class FamilyGate extends StatelessWidget {
  const FamilyGate({
    super.key,
    required this.title,
    required this.builder,
    this.tint,
    this.requireChild = false,
    this.actions = const <Widget>[],
    this.constrainWidth = true,
    this.safeArea = true,
  });

  final String title;
  final Color? tint;
  final bool requireChild;
  final List<Widget> actions;
  final bool constrainWidth;
  final bool safeArea;
  final Widget Function(BuildContext context, FamilyScope scope) builder;

  @override
  Widget build(BuildContext context) {
    final String? uid = Firebase.apps.isEmpty
        ? null
        : AuthService.instance.currentFirebaseUser?.uid;
    if (uid == null) {
      return AppPage(
        title: title,
        tint: tint,
        actions: actions,
        constrainWidth: constrainWidth,
        safeArea: safeArea,
        child: const MessageView('Sign in to see your family.'),
      );
    }

    return StreamBuilder<UserModel?>(
      stream: FirestoreService.instance.watchUserProfile(uid),
      builder: (BuildContext context, AsyncSnapshot<UserModel?> userSnap) {
        if (userSnap.hasError) {
          return AppPage(
            title: title,
            tint: tint,
            actions: actions,
            constrainWidth: constrainWidth,
            safeArea: safeArea,
            child: const MessageView('Something went wrong. Please try again.'),
          );
        }
        if (!userSnap.hasData &&
            userSnap.connectionState == ConnectionState.waiting) {
          return AppPage(
            title: title,
            tint: tint,
            actions: actions,
            constrainWidth: constrainWidth,
            safeArea: safeArea,
            child: const LoadingView(),
          );
        }
        final UserModel? user = userSnap.data;
        if (user == null) {
          return AppPage(
            title: title,
            tint: tint,
            actions: actions,
            constrainWidth: constrainWidth,
            safeArea: safeArea,
            child: const MessageView(
              'We couldn’t find your profile. Please try again.',
            ),
          );
        }
        final String? familyId = user.familyId;
        if (familyId == null || familyId.isEmpty) {
          return AppPage(
            title: title,
            tint: tint ?? user.role.tint,
            actions: actions,
            constrainWidth: constrainWidth,
            safeArea: safeArea,
            child: const MessageView(
              'We couldn’t find your family. Please try again.',
            ),
          );
        }

        return AppPage(
          title: title,
          tint: tint ?? user.role.tint,
          actions: actions,
          constrainWidth: constrainWidth,
          safeArea: safeArea,
          child: StreamBuilder<List<ChildModel>>(
            stream: FirestoreService.instance.watchChildren(familyId),
            builder:
                (BuildContext context, AsyncSnapshot<List<ChildModel>> kids) {
              if (kids.hasError) {
                return const MessageView(
                  'Unable to load your family right now.',
                );
              }
              final List<ChildModel> children = kids.data ?? <ChildModel>[];
              FamilySession.instance.hydrate(children);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                FamilySession.instance.syncWith(children);
              });
              return AnimatedBuilder(
                animation: FamilySession.instance,
                builder: (BuildContext context, Widget? _) {
                  ChildModel? selected;
                  if (user.role == UserRole.child) {
                    ChildModel? match;
                    for (final ChildModel child in children) {
                      if (child.uid == user.uid) {
                        match = child;
                        break;
                      }
                    }
                    selected = match ??
                        ChildModel(
                          uid: user.uid,
                          name: user.name,
                          email: user.email,
                          familyId: familyId,
                        );
                  } else {
                    selected = FamilySession.instance.resolve(children);
                  }
                  if (requireChild && selected == null) {
                    return const MessageView(
                      'Add a child to start using this screen.',
                      icon: Icons.child_care_outlined,
                    );
                  }
                  return builder(
                    context,
                    FamilyScope(
                      user: user,
                      familyId: familyId,
                      children: children,
                      selectedChild: selected,
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

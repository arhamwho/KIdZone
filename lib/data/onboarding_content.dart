import 'package:flutter/material.dart';

import '../models/onboarding_page_data.dart';
import '../theme/app_colors.dart';

/// The three screens shown before a role is chosen.
const List<OnboardingPageData> onboardingPages = <OnboardingPageData>[
  OnboardingPageData(
    title: 'A smarter way to care & learn',
    message:
        'KidZone brings your family\'s routines, learning and screen habits '
        'together in one calm, friendly place.',
    icon: Icons.favorite_rounded,
    color: AppColors.sky,
    iconColor: AppColors.primary,
  ),
  OnboardingPageData(
    title: 'Keep track of activities & routines',
    message:
        'Plan the day together, check things off as they happen and see how '
        'the week is going at a glance.',
    icon: Icons.event_available_rounded,
    color: AppColors.mint,
    iconColor: AppColors.mintInk,
  ),
  OnboardingPageData(
    title: 'Learn, play & earn!',
    message:
        'Fun games, friendly challenges and badges that make every bit of '
        'progress worth celebrating.',
    icon: Icons.emoji_events_rounded,
    color: AppColors.sunshine,
    iconColor: AppColors.sunshineInk,
  ),
];

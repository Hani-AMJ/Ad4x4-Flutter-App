import 'package:flutter/material.dart';

/// Info item for displaying member contact/vehicle information
class MemberInfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const MemberInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

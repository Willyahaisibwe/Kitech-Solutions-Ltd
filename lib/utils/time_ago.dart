// lib/utils/time_ago.dart

/// Formats a DateTime as a short relative time string, e.g.
/// "5s ago", "12m ago", "3h ago", "2d ago", "3w ago", "4mo ago", "1y ago".
String timeAgo(DateTime dateTime) {
  final now = DateTime.now();
  final diff = now.difference(dateTime);

  // Guard against clock skew (e.g. server timestamp slightly ahead)
  if (diff.isNegative) return 'just now';

  if (diff.inSeconds < 60) {
    return diff.inSeconds <= 5 ? 'just now' : '${diff.inSeconds}s ago';
  }
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}

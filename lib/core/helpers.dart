String shortText(String s, [int limit = 60]) {
  if (s.length <= limit) return s;
  return s.substring(0, limit) + '...';
}

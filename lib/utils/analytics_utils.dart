double percentChange(int previous, int current) {
  if (previous == 0) return 0.0;
  return (current - previous) / previous * 100.0;
}

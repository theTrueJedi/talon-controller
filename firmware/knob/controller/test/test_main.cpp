#include "testing.h"

TestCase* g_tests = nullptr;
int g_failures = 0;

int main() {
  int n = 0;
  for (TestCase* t = g_tests; t; t = t->next, n++) {
    int before = g_failures;
    t->fn();
    std::printf("%s %s\n", g_failures == before ? "ok  " : "FAIL", t->name);
  }
  std::printf("%d tests, %d failed checks\n", n, g_failures);
  return g_failures ? 1 : 0;
}

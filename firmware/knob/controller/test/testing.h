// Minimal host test framework: TEST(name) { CHECK(cond); }
#pragma once
#include <cmath>
#include <cstdio>

struct TestCase { const char* name; void (*fn)(); TestCase* next; };
extern TestCase* g_tests;
extern int g_failures;
struct TestReg { TestReg(TestCase* t) { t->next = g_tests; g_tests = t; } };

#define TEST(name)                                         \
  static void test_##name();                               \
  static TestCase tc_##name = {#name, test_##name, nullptr}; \
  static TestReg reg_##name(&tc_##name);                   \
  static void test_##name()

#define CHECK(cond)                                                       \
  do {                                                                    \
    if (!(cond)) {                                                        \
      std::printf("  FAIL %s:%d: %s\n", __FILE__, __LINE__, #cond);       \
      g_failures++;                                                       \
    }                                                                     \
  } while (0)

#define CHECK_NEAR(a, b, eps) CHECK(std::fabs((double)(a) - (double)(b)) <= (eps))

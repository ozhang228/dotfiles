---
applies_to: C++ projects (*.cpp, *.h, *.hpp)
skip_if: Working in TypeScript, Python, or any non-C++ language
---

# C++

- Always mark meaningful return values as `[[nodiscard]]`.
- When asserting on `std::expected` in tests, pipe the error into the assertion so failures are readable:
  ```cpp
  ASSERT_TRUE(result.has_value()) << result.error();
  ```


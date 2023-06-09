#include "infra/assertions.h"

#include <cstdio>

namespace concurrencpp::tests::details {
    std::string to_string(bool value) {
        return value ? "true" : "false";
    }

    std::string to_string(int value) {
        return std::to_string(value);
    }

    std::string to_string(long value) {
        return std::to_string(value);
    }

    std::string to_string(long long value) {
        return std::to_string(value);
    }

    std::string to_string(unsigned value) {
        return std::to_string(value);
    }

    std::string to_string(unsigned long value) {
        return std::to_string(value);
    }

    std::string to_string(unsigned long long value) {
        return std::to_string(value);
    }

    std::string to_string(float value) {
        return std::to_string(value);
    }

    std::string to_string(double value) {
        return std::to_string(value);
    }

    std::string to_string(long double value) {
        return std::to_string(value);
    }

    const std::string& to_string(const std::string& str) {
        return str;
    }

    std::string to_string(const char* str) {
        return str;
    }

    std::string to_string(const std::string_view str) {
        return {str.begin(), str.end()};
    }

    void assert_equal_failed_impl(const std::string& a, const std::string& b) {
        std::string error_msg = "assertion failed. ";
        error_msg += "expected [";
        error_msg += a;
        error_msg += "] == [";
        error_msg += b;
        error_msg += "]";

        fprintf(stderr, "%s", error_msg.data());
        std::abort();
    }

    void assert_not_equal_failed_impl(const std::string& a, const std::string& b) {
        std::string error_msg = "assertion failed. ";
        error_msg += "expected: [";
        error_msg += a;
        error_msg += "] =/= [";
        error_msg += b;
        error_msg += "]";

        fprintf(stderr, "%s", error_msg.data());
        std::abort();
    }

    void assert_bigger_failed_impl(const std::string& a, const std::string& b) {
        std::string error_msg = "assertion failed. ";
        error_msg += "expected [";
        error_msg += a;
        error_msg += "] > [";
        error_msg += b;
        error_msg += "]";

        fprintf(stderr, "%s", error_msg.data());
        std::abort();
    }

    void assert_smaller_failed_impl(const std::string& a, const std::string& b) {
        std::string error_msg = "assertion failed. ";
        error_msg += "expected [";
        error_msg += a;
        error_msg += "] < [";
        error_msg += b;
        error_msg += "]";

        fprintf(stderr, "%s", error_msg.data());
        std::abort();
    }

    void assert_bigger_equal_failed_impl(const std::string& a, const std::string& b) {
        std::string error_msg = "assertion failed. ";
        error_msg += "expected [";
        error_msg += a;
        error_msg += "] >= [";
        error_msg += b;
        error_msg += "]";

        fprintf(stderr, "%s", error_msg.data());
        std::abort();
    }

    void assert_smaller_equal_failed_impl(const std::string& a, const std::string& b) {
        std::string error_msg = "assertion failed. ";
        error_msg += "expected [";
        error_msg += a;
        error_msg += "] <= [";
        error_msg += b;
        error_msg += "]";

        fprintf(stderr, "%s", error_msg.data());
        std::abort();
    }

}  // namespace concurrencpp::tests::details

namespace concurrencpp::tests {
    void assert_true(bool condition) {
        if (!condition) {
            fprintf(stderr, "%s", "assertion faild. expected: [true] actual: [false].");
            std::abort();
        }
    }

    void assert_false(bool condition) {
        if (condition) {
            fprintf(stderr, "%s", "assertion faild. expected: [false] actual: [true].");
            std::abort();
        }
    }
}  // namespace concurrencpp::tests

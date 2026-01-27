module;
#include <algorithm>
#include <ranges>
#include <vector>
export module test;

export std::vector<size_t> get_random_data(size_t size);

export size_t acc(std::span<size_t const> data) {
    return std::ranges::fold_left(data, 0uz, [](size_t sum, size_t e) { return sum + e; });
}

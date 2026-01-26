module;
#include <vector>
#include <random>
#include <ranges>

module test;

std::vector<size_t> random_data(size_t size) { return {std::from_range, std::views::iota(0uz, size)}; }

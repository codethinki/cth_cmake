module;
#include <vector>
#include <random>
#include <ranges>

module test;

std::vector<size_t> get_random_data(size_t size) { 
    auto r = std::views::iota(0uz, size);
    return std::vector<size_t>(r.begin(), r.end()); 
}

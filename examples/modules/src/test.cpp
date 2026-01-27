module;
#include <vector>
#include <random>
#include <ranges>

module test;

std::vector<size_t> get_random_data(size_t size) { 
    return std::vector<size_t>(std::from_range, std::views::iota(0uz, size)); 
}

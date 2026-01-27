#include <range/v3/view/concat.hpp>

#include "main.hpp"

#include <algorithm>
#include <numeric>
#include <vector>

int main() {
    static_assert(do_something() != 0, "test assertion");

    std::vector<int> someIntVec(100);
    std::ranges::iota(someIntVec, 0);

    std::vector<double> someDoubleVec(100);
    std::ranges::fill(someDoubleVec, 42);

    auto sum = 0;
    for(auto const& x : ranges::views::concat(someDoubleVec, someIntVec))
        sum += x;

    std::println("{}", sum);
    return 0;
}

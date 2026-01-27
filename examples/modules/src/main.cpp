#include <print>

import test;



int main() {
    auto data = get_random_data(10);
    std::println("{}", acc(data));
    return 0;
}
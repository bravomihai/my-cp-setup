#pragma once
// clang-format off
#include <bits/stdc++.h>
#include <chrono>

#include <ext/pb_ds/assoc_container.hpp>
#include <ext/pb_ds/tree_policy.hpp>

#ifndef ONLINE_JUDGE
#  include "debug.cpp"
#else
#  define out(...)
#endif

template <typename T>
using oset = __gnu_pbds::tree<T, __gnu_pbds::null_type, std::less<T>, __gnu_pbds::rb_tree_tag, __gnu_pbds::tree_order_statistics_node_update>;
template <typename T>
using omset = __gnu_pbds::tree<T, __gnu_pbds::null_type, std::less_equal<T>, __gnu_pbds::rb_tree_tag, __gnu_pbds::tree_order_statistics_node_update>;
template <typename T>
using oset_desc = __gnu_pbds::tree<T, __gnu_pbds::null_type, std::greater<T>, __gnu_pbds::rb_tree_tag, __gnu_pbds::tree_order_statistics_node_update>;
template <typename T>
using omset_desc = __gnu_pbds::tree<T, __gnu_pbds::null_type, std::greater_equal<T>, __gnu_pbds::rb_tree_tag, __gnu_pbds::tree_order_statistics_node_update>;

using ll = long long;
using ld = long double;
using str = std::string;
using pll = std::pair<ll,ll>;
using vl = std::vector<ll>;
using vvl = std::vector<vl>;

constexpr long long MOD_CONST = 998244353LL;
constexpr long long INF = std::numeric_limits<long long>::max();

#define all(v) (v).begin(), (v).end()
#define rall(v) (v).rbegin(), (v).rend()
#define srt(v) std::sort(all(v))
#define rsrt(v) std::sort(rall(v))
#define rvr(v) std::reverse(all(v))
#define acc(v) std::accumulate(all(v), 0LL)
#define sz(v) static_cast<int>((v).size())
#define mini(v) *std::min_element(all(v))
#define maxi(v) *std::max_element(all(v))
#define mp std::make_pair
#define eb std::vector::emplace_back
#define emp std::emplace
#define pb std::vector::push_back
#define ppb std::vector::pop_back
#define ff first
#define ss second
#define bitnr(x) __builtin_popcountll(x)
#define cnt(v, x) std::count(all(v), (x))
#define cntnz(v) std::count_if(all(v), [](int x){ return x != 0; })

// loops
#define rep(i,a,n) for(int i=(a); i<(n); ++i)  // [a,n)
#define rrep(i,a,n) for(int i=(a); i>(n); --i) // (n,a]
#define repk(i,a,n,k) for(int i=(a); i<(n); i+=(k))
#define rrepk(i,a,n,k) for(int i=(a); i>(n); i-=(k))

#define in(a) std::cin >> (a)
#define in2(a,b) std::cin >> (a) >> (b)
#define in3(a,b,c) std::cin >> (a) >> (b) >> (c)
#define in4(a,b,c,d) std::cin >> (a) >> (b) >> (c) >> (d)

#define rdv(v) for(auto& e : (v)) std::cin >> e
#define rdvp(v) for(auto& i : (v)) std::cin >> i.first >> i.second
#define rdvv(v) for(auto& i : (v)) for(auto& j : (i)) std::cin >> j

#define pr(a) (std::cout << (a) << '\n')
#define prs(a) (std::cout << (a) << ' ')
#define pr2(a,b) (std::cout << (a) << ' ' << (b) << '\n')
#define pr3(a,b,c) (std::cout << (a) << ' ' << (b) << ' ' << (c) << '\n')
#define prv(v) { for(auto& i : (v)) std::cout << i << ' '; std::cout << '\n'; }
#define prvns(v) { for(auto& i : (v)) std::cout << i; std::cout << '\n'; }
#define prvp(v) { for(auto& i : (v)) { std::cout << i.first << ' ' << i.second; std::cout << '\n'; } }
#define prvv(v) { for(auto& i : (v)) { for(auto& j : (i)) std::cout << j << ' '; std::cout << '\n'; } }
#define prvvc(v) { for(auto& i : (v)) { for(auto& j : (i)) std::cout << j; std::cout << '\n'; } }
#define prc(b,x,y) (std::cout << ((b) ? (x) : (y)) << '\n')
#define prcc(b1,x,b2,y,z) (std::cout << ((b1) ? (x) : (b2 ? y : z)) << '\n')
#define yn(a) (std::cout << ((a) ? "Yes" : "No") << '\n')
#define nl std::cout << '\n'

#define ret return
#define max3(a,b,c) std::max(std::max((a),(b)), (c))
#define min3(a,b,c) std::min(std::min((a),(b)), (c))
#define nr1e5 100'000
#define nr1e9 1'000'000'000

template<class T>
auto make_vector(size_t n, T val) {
    return std::vector<T>(n, val);
}

template<class... Args>
auto make_vector(size_t n, Args... args) {
    return std::vector(n, make_vector(args...));
}

#define inside(x, y, H, W) (0 <= (x) && (x) < (H) && 0 <= (y) && (y) < (W))

// clang-format on
// end of cp.hpp
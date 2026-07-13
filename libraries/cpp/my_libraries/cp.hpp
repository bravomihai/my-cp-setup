#pragma once
// clang-format off
#include <bits/stdc++.h>
#include <chrono>

#include <ext/pb_ds/assoc_container.hpp>
#include <ext/pb_ds/tree_policy.hpp>

template <typename T>
using oset = __gnu_pbds::tree<T, __gnu_pbds::null_type, std::less<T>, __gnu_pbds::rb_tree_tag, __gnu_pbds::tree_order_statistics_node_update>;
template <typename T>
using oset_desc = __gnu_pbds::tree<T, __gnu_pbds::null_type, std::greater<T>, __gnu_pbds::rb_tree_tag, __gnu_pbds::tree_order_statistics_node_update>;

template <typename T, typename Compare = std::less<T>>
class ordered_multiset {
    using id_type = std::uint64_t;
    using key_type = std::pair<T, id_type>;

    struct key_compare {
        Compare compare{};

        bool operator()(const key_type& lhs, const key_type& rhs) const {
            if (compare(lhs.first, rhs.first)) return true;
            if (compare(rhs.first, lhs.first)) return false;
            return lhs.second < rhs.second;
        }
    };

    using tree_type = __gnu_pbds::tree<key_type, __gnu_pbds::null_type, key_compare, __gnu_pbds::rb_tree_tag, __gnu_pbds::tree_order_statistics_node_update>;

    tree_type values_;
    id_type next_id_ = 0;
    Compare compare_{};

    bool equivalent(const T& lhs, const T& rhs) const {
        return !compare_(lhs, rhs) && !compare_(rhs, lhs);
    }

public:
    using size_type = std::size_t;

    void insert(const T& value) {
        values_.insert({value, next_id_++});
    }

    void insert(T&& value) {
        values_.insert({std::move(value), next_id_++});
    }

    bool erase_one(const T& value) {
        auto it = values_.lower_bound({value, 0});
        if (it == values_.end() || !equivalent(it->first, value)) return false;
        values_.erase(*it);
        return true;
    }

    size_type erase_all(const T& value) {
        std::vector<key_type> matches;
        for (auto it = values_.lower_bound({value, 0}); it != values_.end() && equivalent(it->first, value); ++it) {
            matches.push_back(*it);
        }
        for (const auto& key : matches) values_.erase(key);
        return matches.size();
    }

    size_type count(const T& value) const {
        const auto first = values_.order_of_key({value, 0});
        const auto last = values_.order_of_key({value, std::numeric_limits<id_type>::max()});
        return last - first;
    }

    size_type order_of_key(const T& value) const {
        return values_.order_of_key({value, 0});
    }

    std::optional<T> find_by_order(size_type order) const {
        auto it = values_.find_by_order(order);
        if (it == values_.end()) return std::nullopt;
        return it->first;
    }

    bool contains(const T& value) const {
        return count(value) != 0;
    }

    size_type size() const {
        return values_.size();
    }

    bool empty() const {
        return values_.empty();
    }

    void clear() {
        values_.clear();
        next_id_ = 0;
    }
};

template <typename T>
using omset = ordered_multiset<T>;
template <typename T>
using omset_desc = ordered_multiset<T, std::greater<T>>;

#if !defined(DISABLE_DEBUG) && !defined(ONLINE_JUDGE)
#  include "debug.cpp"
#else
#  define out(...)
#  define timer_out(...)
#endif

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
#define eb emplace_back
#define emp emplace
#define pb push_back
#define ppb pop_back
#define ff first
#define ss second
#define bitnr(x) __builtin_popcountll(x)
#define cnt(v, x) std::count(all(v), (x))
#define cntnz(v) std::count_if(all(v), [](const auto& x){ return x != 0; })

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

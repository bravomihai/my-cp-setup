#pragma once
#include <bits/stdc++.h>
#include <ext/pb_ds/assoc_container.hpp>
#include <ext/pb_ds/tree_policy.hpp>
using namespace std;
using namespace __gnu_pbds;
template <typename T>
using oset = tree<T, null_type, less<T>, rb_tree_tag, tree_order_statistics_node_update>;
template <typename T>
using omset = tree<T, null_type, less_equal<T>, rb_tree_tag, tree_order_statistics_node_update>;
// forward declarations
template <typename T>
ostream &print(ostream &os, T val);

template <size_t I = 0, typename... Ts>
void print_tuple(ostream &os, const tuple<Ts...> &t);

template <typename... Ts>
ostream &operator<<(ostream &os, const tuple<Ts...> &t);

template <typename T, typename U>
ostream &operator<<(ostream &os, const pair<T, U> &p);

template <typename Container>
ostream &print_iterable(ostream &os, const Container &c, const char *open = "[", const char *close = "]", const char *between = ", ");

template <typename T>
ostream &operator<<(ostream &os, const vector<T> &v);

template <typename T>
ostream &operator<<(ostream &os, const vector<vector<T>> &vv);

template <typename T>
ostream &operator<<(ostream &os, const deque<T> &d);

template <typename T>
ostream &operator<<(ostream &os, const list<T> &l);

template <typename T>
ostream &operator<<(ostream &os, const set<T> &s);

template <typename T>
ostream &operator<<(ostream &os, const multiset<T> &ms);

template <typename K, typename V>
ostream &operator<<(ostream &os, const map<K, V> &m);

template <typename K, typename V>
ostream &operator<<(ostream &os, const unordered_map<K, V> &m);

template <typename T>
ostream &operator<<(ostream &os, const oset<T> &s);

template <typename T>
ostream &operator<<(ostream &os, const omset<T> &s);

template <typename T>
ostream &operator<<(ostream &os, stack<T> s);

template <typename T, typename Container, typename Compare>
ostream &operator<<(ostream &os, priority_queue<T, Container, Compare> pq);

template <typename T>
ostream &operator<<(ostream &os, queue<T> q);

template <typename... T>
void out(const T &...args);

// print tuples
template <size_t I, typename... Ts>
void print_tuple(ostream &os, const tuple<Ts...> &t) {
    if constexpr (I < sizeof...(Ts)) {
        if constexpr (I > 0)
            os << ", ";
        print(os, get<I>(t));
        print_tuple<I + 1>(os, t);
    }
}
template <typename... Ts>
ostream &operator<<(ostream &os, const tuple<Ts...> &t) {
    os << '(';
    print_tuple(os, t);
    os << ')';
    return os;
}
// print pairs
template <typename T, typename U>
ostream &operator<<(ostream &os, const pair<T, U> &p) {
    os << '(';
    print(os, p.first);
    os << ": ";
    print(os, p.second);
    os << ')';
    return os;
}
// print iterable containers
template <typename Container>
ostream &print_iterable(ostream &os, const Container &c, const char *open, const char *close, const char *between) {
    if constexpr (!is_same_v<typename Container::value_type, string>) {
        os << open;
    }
    auto it = c.begin();
    while (it != c.end()) {
        print(os, *it);
        if constexpr (is_same_v<typename Container::value_type, string>) {
            os << "\n";
        } else {
            if (next(it) != c.end()) os << between;
        }
        ++it;
    }
    if constexpr (!is_same_v<typename Container::value_type, string>) {
        os << close;
    }
    os << "\n";
    return os;
}

// operators for iterable containers
template <typename T>
ostream &operator<<(ostream &os, const vector<T> &v) {
    return print_iterable(os, v, "[", "]");
}

template <typename T>
ostream &operator<<(ostream &os, const vector<vector<T>> &vv) {
    return print_iterable(os, vv, "", "", "\n");
}

template <typename T>
ostream &operator<<(ostream &os, const deque<T> &d) {
    return print_iterable(os, d, "[", "]");
}

template <typename T>
ostream &operator<<(ostream &os, const list<T> &l) {
    return print_iterable(os, l, "[", "]");
}

template <typename T>
ostream &operator<<(ostream &os, const set<T> &s) {
    return print_iterable(os, s, "{", "}");
}

template <typename T>
ostream &operator<<(ostream &os, const multiset<T> &ms) {
    return print_iterable(os, ms, "{", "}");
}

template <typename K, typename V>
ostream &operator<<(ostream &os, const map<K, V> &m) {
    return print_iterable(os, m, "{", "}");
}

template <typename K, typename V>
ostream &operator<<(ostream &os, const unordered_map<K, V> &m) {
    return print_iterable(os, m, "{", "}");
}

template <typename T>
ostream &operator<<(ostream &os, const oset<T> &s) {
    return print_iterable(os, s, "{", "}");
}

template <typename T>
ostream &operator<<(ostream &os, const omset<T> &s) {
    return print_iterable(os, s, "{", "}");
}

// print stack
template <typename T>
ostream &operator<<(ostream &os, stack<T> s) {
    os << "[";
    vector<T> tmp;
    while (!s.empty()) {
        tmp.push_back(s.top());
        s.pop();
    }
    // afisăm în ordinea originală (bottom -> top)
    for (size_t i = tmp.size(); i > 0; --i) {
        print(os, tmp[i - 1]);
        if (i > 1) os << ", ";
    }
    os << "]";
    return os;
}
// print priority_queue
template <typename T, typename Container, typename Compare>
ostream &operator<<(ostream &os, priority_queue<T, Container, Compare> pq) {
    os << "[";
    vector<T> tmp;
    while (!pq.empty()) {
        tmp.push_back(pq.top());
        pq.pop();
    }
    for (size_t i = 0; i < tmp.size(); ++i) {
        print(os, tmp[i]);
        if (i + 1 < tmp.size()) os << ", ";
    }
    os << "]";
    return os;
}
// print queue
template <typename T>
ostream &operator<<(ostream &os, queue<T> q) {
    os << "[";
    while (!q.empty()) {
        print(os, q.front());
        q.pop();
        if (!q.empty()) os << ", ";
    }
    os << "]";
    return os;
}
// prints inf for LLONG_MAX
template <typename T>
ostream &print(ostream &os, T val) {
    if constexpr (is_arithmetic_v<T>) { // numerics
        if (val == LLONG_MAX)
            os << "inf";
        else if (val == -LLONG_MAX)
            os << "-inf";
        else
            os << val;
    } else if (is_same_v<T, string>) {
        os << "\"" << val << "\"";
    } else {
        os << val; // non-numerics, containers etc.
    }
    return os;
}
// variadic debug function
template <typename... T>
void out(const T &...args) {
    cerr << setprecision(15);
    (([&]() {
         print(cerr, args);
         using A = decay_t<decltype(args)>;
         if (is_arithmetic_v<A> || is_same_v<A, string> || is_same_v<A, const char *> || is_same_v<A, char *>) cerr << " ";
     }()),
     ...);
    cerr << '\n';
}

void timer_out(double seconds) {
    ostringstream formatted;
    formatted << fixed << setprecision(6) << seconds << 's';
    cerr << formatted.str() << '\n';
}
// redirect input/output general
void IO() {
    freopen("D:\\studying\\comp_prog\\debug\\input.txt", "r", stdin);
    // freopen("D:\\studying\\comp_prog\\debug\\output.txt", "w", stdout);
}

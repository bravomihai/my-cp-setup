#include <my_libraries/cp.hpp>
#include <atcoder/all>

using namespace std;
using namespace atcoder;

void solve() {
    cout << "Hello, World!\n";
}
// clang-format off

/*   /\_/\
    (= ._.)
    / >  \>
*/

int main() {
    ios::sync_with_stdio(0); cin.tie(0); cout.tie(0); cout << setprecision(15); cerr << setprecision(15);
    auto start = chrono::high_resolution_clock::now();

    int tc = 1; //cin>>tc;
    while(tc--) solve();
    
    auto end = chrono::high_resolution_clock::now();
    chrono::duration<double> elapsed = end - start;
    timer_out(elapsed.count());
    return 0;
}

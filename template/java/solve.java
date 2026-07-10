import my_libraries.Cp;

public class solve {
    static void solve() throws Exception {
        Cp.println("Hello, World!");
    }

    /*   /\_/\
        (= ._.)
        / >  \>
    */

    public static void main(String[] args) throws Exception {
        Cp.Timer timer = new Cp.Timer();

        int tc = 1; // tc = Cp.fs.nextInt();
        while (tc-- > 0) {
            solve();
        }

        Cp.flush();
        Cp.out("\n");
        Cp.out(String.format(java.util.Locale.US, "%.6fs", timer.elapsed()));
    }
}

import static my_libraries.Cp.*;

public class solve {
    static void solve() throws Exception {
        println("hello world!");
    }

    public static void main(String[] args) throws Exception {
        Timer timer = new Timer();

        int tc = 1;
        // tc = fs.nextInt();
        while (tc-- > 0) {
            solve();
        }

        flush();
        err(String.format(java.util.Locale.US, "%.6fs", timer.elapsed()));
    }
}

package my_libraries;

import java.io.*;
import java.util.*;

public final class Cp {
    public static final boolean DEBUG = true;
    public static final long MOD_CONST = 998_244_353L;
    public static final long INF = Long.MAX_VALUE;
    public static final int NR1E5 = 100_000;
    public static final int NR1E9 = 1_000_000_000;
    public static final FastScanner fs = new FastScanner(System.in);
    private static final StringBuilder out = new StringBuilder();

    private Cp() {}

    public static void print(Object x) {
        out.append(x);
    }

    public static void println() {
        out.append('\n');
    }

    public static void println(Object x) {
        out.append(x).append('\n');
    }

    public static void yn(boolean value) {
        println(value ? "Yes" : "No");
    }

    public static void flush() {
        System.out.print(out);
        out.setLength(0);
    }

    public static void printArray(int[] values) {
        for (int i = 0; i < values.length; i++) {
            if (i > 0) out.append(' ');
            out.append(values[i]);
        }
    }

    public static void printlnArray(int[] values) {
        printArray(values);
        println();
    }

    public static void printArray(long[] values) {
        for (int i = 0; i < values.length; i++) {
            if (i > 0) out.append(' ');
            out.append(values[i]);
        }
    }

    public static void printlnArray(long[] values) {
        printArray(values);
        println();
    }

    public static int min3(int a, int b, int c) {
        return Math.min(Math.min(a, b), c);
    }

    public static int max3(int a, int b, int c) {
        return Math.max(Math.max(a, b), c);
    }

    public static long min3(long a, long b, long c) {
        return Math.min(Math.min(a, b), c);
    }

    public static long max3(long a, long b, long c) {
        return Math.max(Math.max(a, b), c);
    }

    public static boolean inside(int x, int y, int height, int width) {
        return 0 <= x && x < height && 0 <= y && y < width;
    }

    public static void err(Object... values) {
        for (int i = 0; i < values.length; i++) {
            if (i > 0) System.err.print(' ');
            System.err.print(format(values[i]));
        }
        System.err.println();
    }

    public static void out(Object... values) {
        if (DEBUG) err(values);
    }

    public static void timerOut(double seconds) {
        if (DEBUG) System.err.printf(Locale.US, "%.6fs%n", seconds);
    }

    private static String format(Object value) {
        if (value == null) return "null";
        Class<?> cls = value.getClass();
        if (!cls.isArray()) return String.valueOf(value);
        if (value instanceof Object[]) return Arrays.deepToString((Object[])value);

        int n = java.lang.reflect.Array.getLength(value);
        StringBuilder s = new StringBuilder("[");
        for (int i = 0; i < n; i++) {
            if (i > 0) s.append(", ");
            s.append(java.lang.reflect.Array.get(value, i));
        }
        return s.append(']').toString();
    }

    public static final class Timer {
        private final long start = System.nanoTime();

        public double elapsed() {
            return (System.nanoTime() - start) / 1e9;
        }
    }

    public static final class FastScanner {
        private final InputStream in;
        private final byte[] buffer = new byte[1 << 16];
        private int ptr = 0, len = 0;

        public FastScanner(InputStream in) {
            this.in = in;
        }

        private int read() throws IOException {
            if (ptr >= len) {
                len = in.read(buffer);
                ptr = 0;
                if (len <= 0) return -1;
            }
            return buffer[ptr++];
        }

        public String next() throws IOException {
            StringBuilder s = new StringBuilder();
            int c;
            do {
                c = read();
            } while (c <= ' ' && c != -1);
            while (c > ' ') {
                s.append((char)c);
                c = read();
            }
            return s.toString();
        }

        public int nextInt() throws IOException {
            return (int)nextLong();
        }

        public long nextLong() throws IOException {
            int c;
            do {
                c = read();
            } while (c <= ' ' && c != -1);

            int sign = 1;
            if (c == '-') {
                sign = -1;
                c = read();
            }

            long value = 0;
            while (c > ' ') {
                value = value * 10 + c - '0';
                c = read();
            }
            return value * sign;
        }

        public double nextDouble() throws IOException {
            return Double.parseDouble(next());
        }

        public int[] nextIntArray(int n) throws IOException {
            int[] values = new int[n];
            for (int i = 0; i < n; i++) values[i] = nextInt();
            return values;
        }

        public long[] nextLongArray(int n) throws IOException {
            long[] values = new long[n];
            for (int i = 0; i < n; i++) values[i] = nextLong();
            return values;
        }

        public int[][] nextIntMatrix(int rows, int columns) throws IOException {
            int[][] values = new int[rows][columns];
            for (int row = 0; row < rows; row++) {
                for (int column = 0; column < columns; column++) {
                    values[row][column] = nextInt();
                }
            }
            return values;
        }
    }
}


class fib
{
    public static void main(String[] args)
    {
        long n = Integer.parseInt(args[0]);
        long a = 1, b = 0, t;

        for(long i = 0; i < n; i++) {
            t = b;
            b = a + b;
            a = t;
        }

        System.out.printf("%d\n", b);
    }
}

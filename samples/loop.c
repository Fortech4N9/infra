#define N 1024

double a[N];
double b[N];
double c[N];

int main() {
    for (int i = 0; i < N; i++) {
        a[i] = b[i] + c[i] * 2.0;
    }
    double sum = 0.0;
    for (int j = 0; j < N; j++) {
        sum = sum + a[j];
    }
    return (int)sum;
}

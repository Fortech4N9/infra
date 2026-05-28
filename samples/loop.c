int main() {
    int i;
    int j;
    int sum;
    int a[1024];
    int b[1024];
    int c[1024];

    for (i = 0; i < 1024; i = i + 1) {
        a[i] = b[i] + c[i] * 2;
    }

    sum = 0;
    for (j = 0; j < 1024; j = j + 1) {
        sum = sum + a[j];
    }

    return sum;
}

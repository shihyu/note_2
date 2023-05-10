#include "bate.h"

#define N (1024*1024)
#define B 8

struct Matrix {
    struct MyHash {
        std::size_t operator()(std::tuple<int, int> const &key) const {
            auto const &[x, y] = key;
            return (x * 2718281828) ^ (y * 3141592653);
        }
    };

    std::vector<std::tuple<int, int, float>> m_data;

    void write(int x, int y, float value) {
        return m_data.push_back(std::make_tuple(x, y, value));
    }

    template <class Func>
    void foreach(Func &&func) {
        for (auto &[x, y, value]: m_data) {
            func(x, y, value);
        }
    }
};

struct Vector {
    float m_data[N];

    float &at(int x) {
        return m_data[x];
    }
};

int main() {
    bate::timing("main");

    Matrix *a = new Matrix{};
    Vector *v = new Vector{};
    Vector *w = new Vector{};

    for (int i = 0; i < N; i++) {
        v->at(i) = bate::frand();
    }

    for (int i = 0; i < N; i++) {
        a->write(i, i, 2);
        if (i > 0)
            a->write(i - 1, i, -1);
        if (i < N - 1)
            a->write(i + 1, i, -1);
    }

    a->foreach([&] (int i, int j, float &value) {
        w->at(i) += value * v->at(j);
    });

    for (int i = 1; i < N - 1; i++) {
        if (std::abs(2 * v->at(i) - v->at(i - 1) - v->at(i + 1) - w->at(i)) > 0.0001f) {
            printf("wrong at %d\n", i);
            return 1;
        }
    }
    printf("all correct\n");

    bate::timing("main");
    return 0;
}

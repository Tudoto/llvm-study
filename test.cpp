// test.cpp - 用于观察 LLVM 优化的测试程序

#include <iostream>

// 1. 常量传播测试函数
int constant_propagation_test() {
    int a = 5;
    int b = 10;
    int c = a + b;      // 应该被优化为 c = 15
    int d = c * 2;      // 应该被优化为 d = 30
    return d + 3;       // 应该被优化为 return 33
}

// 2. 死代码消除测试函数
int dead_code_elimination_test(int x) {
    int result = x + 10;
    
    // 这些是死代码，应该被消除
    int unused1 = 100 + 200;
    int unused2 = unused1 * 3;
    
    // 这个条件永远为真，else 分支应该被消除
    if (true) {
        return result;
    } else {
        return unused2;  // 死代码
    }
}

// 3. 循环中的常量传播
int loop_constant_test() {
    int sum = 0;
    
    // 循环次数是常量，可能被展开
    for (int i = 0; i < 3; ++i) {
        sum += 10;  // 每次加的都是常量
    }
    
    return sum;  // 应该被优化为 return 30
}

// 4. 条件分支优化
int conditional_test(int x) {
    const int threshold = 100;
    
    // 如果 x 在某些调用中是常量，这个分支可能被优化
    if (x > threshold) {
        return x + 50;
    } else {
        return x - 50;
    }
}

// 5. 函数内联候选
inline int simple_add(int a, int b) {
    return a + b;
}

int inline_test() {
    int x = 20;
    int y = 30;
    return simple_add(x, y);  // 可能被内联为 return 20 + 30
}

// 6. 更复杂的例子：混合优化
int complex_optimization_test() {
    // 常量计算
    int base = 10 + 20;  // = 30
    
    // 常量条件
    bool always_true = (5 > 3);
    
    if (always_true) {
        // 这个分支总是执行
        int temp = base * 2;  // = 60
        
        // 死代码（永远不会被使用）
        int dead_var = 999;
        
        return temp + 40;  // = 100
    } else {
        // 这个分支永远不会执行（死代码）
        return base + 1000;
    }
}

// 7. 库函数优化
#include <cmath>
double math_optimization_test() {
    double x = 4.0;
    double result = sqrt(x);  // sqrt(4.0) 可能被优化为 2.0
    return result * 2.0;      // 最终可能被优化为 return 4.0
}

// 8. 虚函数调用（去虚化测试）
class Base {
public:
    virtual int getValue() { return 42; }
};

class Derived : public Base {
public:
    int getValue() override { return 100; }
};

int devirtualization_test() {
    Derived d;               // 类型确定
    Base* ptr = &d;          // 虽然是基类指针
    return ptr->getValue();  // 但可能被去虚化为直接调用 Derived::getValue()
}

// 主函数
int main() {
    int result = 0;
    
    result += constant_propagation_test();
    result += dead_code_elimination_test(5);
    result += loop_constant_test();
    result += conditional_test(150);
    result += inline_test();
    result += complex_optimization_test();
    result += static_cast<int>(math_optimization_test());
    result += devirtualization_test();
    
    std::cout << "Final result: " << result << std::endl;
    
    return 0;
}

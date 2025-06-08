# LLVM IR 优化观察指南

这个项目帮助你观察 C++ 代码在 LLVM 中的优化过程。

## 快速开始

### 1. 设置环境

首先，修改所有脚本中的 LLVM 路径：

```bash
# 在所有 .sh 脚本中，将这一行：
LLVM_PATH="/path/to/your/llvm-project/build/bin"

# 修改为你的实际路径，例如：
LLVM_PATH="/home/user/llvm-project/build/bin"
```

### 2. 给脚本添加执行权限

```bash
chmod +x *.sh
```

### 3. 运行基础观察

```bash
# 生成所有优化级别的 IR 文件
./observe_optimization.sh

# 查看调试信息
less sccp_debug.log

# 对比优化前后
diff -u test_O0.ll test_O3.ll | less
```

### 4. 分析特定函数

```bash
# 分析默认函数 (constant_propagation_test)
./analyze_function.sh

# 分析其他函数
./analyze_function.sh dead_code_elimination_test
./analyze_function.sh loop_constant_test
./analyze_function.sh complex_optimization_test
```

### 5. 交互式查看

```bash
# 启动交互式查看器
./interactive_viewer.sh
```

## 生成的文件说明

| 文件名 | 说明 |
|--------|------|
| `test_O0.ll` | 未优化的 IR (-O0) |
| `test_O2.ll` | 中等优化的 IR (-O2) |
| `test_O3.ll` | 高度优化的 IR (-O3) |
| `test_constprop.ll` | 仅常量传播优化 |
| `test_sccp.ll` | 仅 SCCP 优化 |
| `test_dce.ll` | 仅死代码消除优化 |
| `test_instcombine.ll` | 仅指令组合优化 |
| `test_inline.ll` | 仅内联优化 |
| `test_combined.ll` | 组合多种优化 |
| `sccp_debug.log` | SCCP 优化的调试信息 |

## 观察要点

### 1. 常量传播效果

查看 `constant_propagation_test` 函数：

```bash
# 原始版本
grep -A 10 "constant_propagation_test" test_O0.ll

# 优化后版本
grep -A 10 "constant_propagation_test" test_sccp.ll
```

应该看到：
- `%a = add i32 5, 10` 被优化为常量
- 最终 return 被优化为单个常量

### 2. 死代码消除效果

查看 `dead_code_elimination_test` 函数：

```bash
# 对比优化前后的行数
wc -l test_O0.ll test_dce.ll
```

应该看到：
- 未使用的变量被删除
- 不可达的代码分支被删除

### 3. 循环优化效果

查看 `loop_constant_test` 函数：

```bash
# 查看循环是否被展开或优化
grep -A 20 "loop_constant_test" test_O3.ll
```

可能看到：
- 循环被完全展开
- 或者循环被优化为单个 `return 30`

### 4. 函数内联效果

查看 `inline_test` 函数：

```bash
# 查看内联前
grep -A 10 "inline_test" test_O0.ll

# 查看内联后
grep -A 10 "inline_test" test_inline.ll
```

应该看到：
- `call` 指令被消除
- 函数体直接插入到调用点

## 常用命令

### 查看特定优化的调试信息

```bash
# SCCP 调试信息
/path/to/llvm/bin/opt -passes=sccp -debug-only=sccp -S test_O0.ll 2>&1 | less

# 常量传播调试信息
/path/to/llvm/bin/opt -passes=constprop -debug-only=constprop -S test_O0.ll 2>&1 | less

# 死代码消除调试信息
/path/to/llvm/bin/opt -passes=dce -debug-only=dce -S test_O0.ll 2>&1 | less
```

### 逐步应用优化

```bash
# 从原始文件开始
cp test_O0.ll current.ll

# 应用常量传播
/path/to/llvm/bin/opt -passes=constprop -S current.ll -o current.ll

# 应用死代码消除
/path/to/llvm/bin/opt -passes=dce -S current.ll -o current.ll

# 应用指令组合
/path/to/llvm/bin/opt -passes=instcombine -S current.ll -o current.ll

# 查看最终结果
cat current.ll
```

### 查看优化统计

```bash
# 查看优化统计信息
/path/to/llvm/bin/opt -passes=sccp -stats -S test_O0.ll >/dev/null
```

## 高级用法

### 1. 自定义优化序列

```bash
# 创建自定义优化管道
/path/to/llvm/bin/opt -passes="mem2reg,sccp,dce,instcombine,sccp,dce" -S test_O0.ll -o custom_optimized.ll
```

### 2. 观察特定指令类型

```bash
# 统计加法指令
grep -c "add " test_O0.ll
grep -c "add " test_O3.ll

# 统计基本块数量
grep -c "^[a-zA-Z0-9_]*:$" test_O0.ll
grep -c "^[a-zA-Z0-9_]*:$" test_O3.ll

# 统计函数调用
grep -c "call " test_O0.ll
grep -c "call " test_O3.ll
```

### 3. 生成控制流图

如果安装了 graphviz：

```bash
# 生成控制流图
/path/to/llvm/bin/opt -passes="view-cfg" test_O0.ll

# 或者导出到文件
/path/to/llvm/bin/opt -passes="dot-cfg" test_O0.ll
dot -Tpng .main.dot -o main_cfg.png
```

## 理解优化效果

### SCCP 优化示例

**优化前：**
```llvm
define i32 @constant_propagation_test() {
entry:
  %a = add i32 5, 10          ; 常量计算
  %b = mul i32 %a, 2          ; 依赖于常量
  %c = add i32 %b, 3          ; 继续传播
  ret i32 %c
}
```

**优化后：**
```llvm
define i32 @constant_propagation_test() {
entry:
  ret i32 33                  ; 直接返回计算结果
}
```

### 死代码消除示例

**优化前：**
```llvm
define i32 @dead_code_test(i32 %x) {
entry:
  %result = add i32 %x, 10
  %unused1 = add i32 100, 200    ; 死代码
  %unused2 = mul i32 %unused1, 3 ; 死代码
  br i1 true, label %then, label %else

then:
  ret i32 %result

else:                            ; 死代码块
  ret i32 %unused2
}
```

**优化后：**
```llvm
define i32 @dead_code_test(i32 %x) {
entry:
  %result = add i32 %x, 10
  ret i32 %result
}
```

## 故障排除

### 常见问题

1. **找不到 LLVM 工具**
   ```bash
   # 检查路径是否正确
   ls /path/to/your/llvm-project/build/bin/clang++
   ls /path/to/your/llvm-project/build/bin/opt
   ```

2. **权限问题**
   ```bash
   chmod +x *.sh
   ```

3. **调试信息不显示**
   ```bash
   # 确保使用 Debug 构建的 LLVM
   cmake -DCMAKE_BUILD_TYPE=Debug ...
   ```

4. **IR 语法错误**
   ```bash
   # 验证 IR 文件
   /path/to/llvm/bin/opt -verify -S test_O0.ll
   ```

### 获取更多帮助

```bash
# 查看所有可用的 Pass
/path/to/llvm/bin/opt --help

# 查看特定 Pass 的帮助
/path/to/llvm/bin/opt -passes=help

# 查看 Clang 选项
/path/to/llvm/bin/clang++ --help
```

## 扩展学习

### 添加新的测试函数

在 `test.cpp` 中添加新函数，然后重新运行脚本：

```cpp
int your_test_function() {
    // 你想测试的代码
    return 42;
}
```

### 测试不同的优化级别

```bash
# 生成不同优化级别的 IR
/path/to/llvm/bin/clang++ -O0 -S -emit-llvm test.cpp -o test_O0.ll
/path/to/llvm/bin/clang++ -O1 -S -emit-llvm test.cpp -o test_O1.ll
/path/to/llvm/bin/clang++ -O2 -S -emit-llvm test.cpp -o test_O2.ll
/path/to/llvm/bin/clang++ -O3 -S -emit-llvm test.cpp -o test_O3.ll
/path/to/llvm/bin/clang++ -Os -S -emit-llvm test.cpp -o test_Os.ll  # 优化大小
/path/to/llvm/bin/clang++ -Oz -S -emit-llvm test.cpp -o test_Oz.ll  # 激进优化大小
```

### 分析其他类型的优化

```bash
# 向量化
/path/to/llvm/bin/opt -passes="loop-vectorize" -S test_O0.ll -o test_vectorized.ll

# 循环展开
/path/to/llvm/bin/opt -passes="loop-unroll" -S test_O0.ll -o test_unrolled.ll

# 全局值编号
/path/to/llvm/bin/opt -passes="gvn" -S test_O0.ll -o test_gvn.ll
```

这个完整的工具集让你可以深入观察 LLVM 的优化过程，理解不同优化技术的效果和原理。

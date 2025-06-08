#!/bin/bash

# 设置你的 LLVM 路径
LLVM_PATH="/path/to/your/llvm-project/build/bin"  # 修改这里！
CLANG="/usr/bin/clang++"
OPT="$LLVM_PATH/opt"

# 检查 LLVM 工具是否存在
if [ ! -f "$CLANG" ]; then
    echo "错误: 找不到 clang++，请修改 LLVM_PATH"
    echo "当前路径: $CLANG"
    exit 1
fi

echo "===== C++ IR 优化观察脚本 ====="
echo "使用的 LLVM 路径: $LLVM_PATH"
echo ""

# 1. 生成未优化的 IR (-O0)
echo "1. 生成未优化的 LLVM IR (-O0)..."
$CLANG -O0 -S -emit-llvm test.cpp -o test_O0.ll
echo "   生成文件: test_O0.ll"

# 2. 生成优化的 IR (-O3)
echo "2. 生成高度优化的 LLVM IR (-O3)..."
$CLANG -O3 -S -emit-llvm test.cpp -o test_O3.ll
echo "   生成文件: test_O3.ll"

# 3. 生成中等优化的 IR (-O2)
echo "3. 生成中等优化的 LLVM IR (-O2)..."
$CLANG -O2 -S -emit-llvm test.cpp -o test_O2.ll
echo "   生成文件: test_O2.ll"

echo ""
echo "===== 单独运行各种优化 Pass ====="

# 4. 常量传播
echo "4. 运行常量传播 (constprop)..."
$OPT -passes=constprop -S test_O0.ll -o test_constprop.ll
echo "   生成文件: test_constprop.ll"

# 5. SCCP (稀疏条件常量传播)
echo "5. 运行 SCCP (稀疏条件常量传播)..."
$OPT -passes=sccp -S test_O0.ll -o test_sccp.ll
echo "   生成文件: test_sccp.ll"

# 6. 死代码消除
echo "6. 运行死代码消除 (dce)..."
$OPT -passes=dce -S test_O0.ll -o test_dce.ll
echo "   生成文件: test_dce.ll"

# 7. 指令组合
echo "7. 运行指令组合 (instcombine)..."
$OPT -passes=instcombine -S test_O0.ll -o test_instcombine.ll
echo "   生成文件: test_instcombine.ll"

# 8. 内联优化
echo "8. 运行函数内联 (inline)..."
$OPT -passes=inline -S test_O0.ll -o test_inline.ll
echo "   生成文件: test_inline.ll"

# 9. 组合多个优化
echo "9. 运行组合优化 (sccp + dce + instcombine)..."
$OPT -passes="sccp,dce,instcombine" -S test_O0.ll -o test_combined.ll
echo "   生成文件: test_combined.ll"

echo ""
echo "===== 带调试信息的优化 ====="

# 10. 带调试信息的 SCCP
echo "10. 运行带调试信息的 SCCP..."
echo "    (输出保存到 sccp_debug.log)"
$OPT -passes=sccp -debug-only=sccp -S test_O0.ll > test_sccp_debug.ll 2> sccp_debug.log
echo "    调试信息: sccp_debug.log"
echo "    优化结果: test_sccp_debug.ll"

echo ""
echo "===== 文件对比 ====="

# 11. 显示文件大小对比
echo "11. 文件大小对比:"
echo "    原始 (-O0):     $(wc -l < test_O0.ll) 行"
echo "    常量传播:       $(wc -l < test_constprop.ll) 行"
echo "    SCCP:          $(wc -l < test_sccp.ll) 行"
echo "    死代码消除:     $(wc -l < test_dce.ll) 行"
echo "    指令组合:       $(wc -l < test_instcombine.ll) 行"
echo "    组合优化:       $(wc -l < test_combined.ll) 行"
echo "    O2 优化:        $(wc -l < test_O2.ll) 行"
echo "    O3 优化:        $(wc -l < test_O3.ll) 行"

echo ""
echo "===== 具体差异对比 ====="

# 12. 显示关键函数的优化差异
echo "12. 查看 constant_propagation_test 函数的优化差异:"
echo ""
echo "--- 原始版本 (-O0) ---"
grep -A 10 "define.*constant_propagation_test" test_O0.ll | head -15

echo ""
echo "--- SCCP 优化后 ---"
grep -A 10 "define.*constant_propagation_test" test_sccp.ll | head -15

echo ""
echo "--- O3 优化后 ---"
grep -A 10 "define.*constant_propagation_test" test_O3.ll | head -15

echo ""
echo "===== 推荐的查看方式 ====="
echo "1. 查看调试信息:"
echo "   less sccp_debug.log"
echo ""
echo "2. 对比优化前后:"
echo "   diff -u test_O0.ll test_sccp.ll | less"
echo "   diff -u test_O0.ll test_O3.ll | less"
echo ""
echo "3. 查看特定函数:"
echo "   grep -A 20 'define.*函数名' 文件名.ll"
echo ""
echo "4. 使用图形工具对比:"
echo "   vimdiff test_O0.ll test_O3.ll"
echo "   或者"
echo "   code --diff test_O0.ll test_O3.ll"

echo ""
echo "===== 脚本执行完成 ====="

#!/bin/bash

# 分析特定函数在不同优化级别下的变化
LLVM_PATH="/path/to/your/llvm-project/build/bin"  # 修改这里！
FUNCTION_NAME=${1:-"constant_propagation_test"}  # 默认分析的函数

echo "===== 函数优化分析工具 ====="
echo "分析函数: $FUNCTION_NAME"
echo ""

# 函数：提取并显示特定函数
show_function() {
    local file=$1
    local title=$2
    local func_name=$3
    
    echo "=== $title ==="
    # 提取函数定义到函数结束
    awk "
    /^define.*$func_name.*{/ { 
        print; 
        brace_count = 1; 
        in_function = 1; 
        next 
    }
    in_function && /^}/ { 
        print; 
        brace_count--; 
        if (brace_count == 0) in_function = 0; 
        next 
    }
    in_function { 
        if (/^[[:space:]]*}/) {
            brace_count--;
            print;
            if (brace_count == 0) in_function = 0;
        } else {
            print;
        }
    }
    " "$file"
    echo ""
}

# 如果 IR 文件不存在，先生成
if [ ! -f "test_O0.ll" ]; then
    echo "IR 文件不存在，正在生成..."
    ./observe_optimization.sh
fi

echo "===== 优化过程对比 ====="

# 显示各个优化阶段的函数
show_function "test_O0.ll" "原始代码 (-O0)" "$FUNCTION_NAME"
show_function "test_constprop.ll" "常量传播后" "$FUNCTION_NAME"
show_function "test_sccp.ll" "SCCP 后" "$FUNCTION_NAME"
show_function "test_dce.ll" "死代码消除后" "$FUNCTION_NAME"
show_function "test_instcombine.ll" "指令组合后" "$FUNCTION_NAME"
show_function "test_combined.ll" "组合优化后" "$FUNCTION_NAME"
show_function "test_O3.ll" "完整 O3 优化后" "$FUNCTION_NAME"

echo "===== 指令数量统计 ====="

count_instructions() {
    local file=$1
    local title=$2
    local func_name=$3
    
    local count=$(awk "
    /^define.*$func_name.*{/ { in_function = 1; next }
    in_function && /^}/ { in_function = 0; next }
    in_function && /^[[:space:]]*[a-zA-Z%]/ { count++ }
    END { print count+0 }
    " "$file")
    
    printf "%-20s: %3d 条指令\n" "$title" "$count"
}

count_instructions "test_O0.ll" "原始代码" "$FUNCTION_NAME"
count_instructions "test_constprop.ll" "常量传播" "$FUNCTION_NAME"
count_instructions "test_sccp.ll" "SCCP" "$FUNCTION_NAME"
count_instructions "test_dce.ll" "死代码消除" "$FUNCTION_NAME"
count_instructions "test_instcombine.ll" "指令组合" "$FUNCTION_NAME"
count_instructions "test_combined.ll" "组合优化" "$FUNCTION_NAME"
count_instructions "test_O3.ll" "O3 优化" "$FUNCTION_NAME"

echo ""
echo "===== 使用方法 ====="
echo "分析其他函数:"
echo "  $0 dead_code_elimination_test"
echo "  $0 loop_constant_test"
echo "  $0 complex_optimization_test"
echo ""
echo "可用的函数名:"
grep "^define.*(" test_O0.ll | sed 's/.*@\([^(]*\).*/  \1/'

#!/bin/bash

# 交互式 LLVM 优化查看器
LLVM_PATH="/path/to/your/llvm-project/build/bin"  # 修改这里！
CLANG="usr/bin/clang++"
OPT="$LLVM_PATH/opt"

echo "===== 交互式 LLVM 优化查看器 ====="
echo ""

# 如果源文件不存在，提示用户
if [ ! -f "test.cpp" ]; then
    echo "错误: 找不到 test.cpp 文件"
    echo "请确保当前目录有 test.cpp 文件"
    exit 1
fi

# 生成基础 IR
if [ ! -f "test_O0.ll" ]; then
    echo "生成基础 IR 文件..."
    $CLANG -O0 -S -emit-llvm test.cpp -o test_O0.ll
fi

# 获取所有函数名
get_functions() {
    grep "^define.*(" test_O0.ll | sed 's/.*@\([^(]*\).*/\1/' | grep -v "^_"
}

# 应用优化并显示结果
apply_optimization() {
    local pass_name=$1
    local input_file=$2
    local output_file="temp_optimized.ll"
    local debug_file="temp_debug.log"
    
    echo "应用优化: $pass_name"
    
    # 运行优化
    if [[ "$pass_name" == *"debug"* ]]; then
        # 提取实际的 pass 名称
        actual_pass=$(echo "$pass_name" | sed 's/-debug//')
        $OPT -passes="$actual_pass" -debug-only="$actual_pass" -S "$input_file" > "$output_file" 2> "$debug_file"
        echo "调试信息已保存到: $debug_file"
        echo "查看调试信息? (y/n): "
        read -r show_debug
        if [[ "$show_debug" == "y" ]]; then
            less "$debug_file"
        fi
    else
        $OPT -passes="$pass_name" -S "$input_file" -o "$output_file"
    fi
    
    echo "优化完成！"
    return 0
}

# 显示函数
show_function() {
    local file=$1
    local func_name=$2
    
    echo "=== 函数: $func_name ==="
    awk "
    /^define.*$func_name.*{/ { 
        print; 
        in_function = 1; 
        brace_count = 1;
        next 
    }
    in_function {
        print;
        if (/}/) {
            brace_count--;
            if (brace_count == 0) in_function = 0;
        }
    }
    " "$file"
    echo ""
}

# 主菜单循环
current_file="test_O0.ll"
selected_function=""

while true; do
    echo ""
    echo "===== 主菜单 ====="
    echo "当前文件: $current_file"
    echo "当前函数: ${selected_function:-"未选择"}"
    echo ""
    echo "1. 选择函数"
    echo "2. 查看当前函数"
    echo "3. 应用优化"
    echo "4. 对比优化前后"
    echo "5. 重置到原始文件"
    echo "6. 查看可用的优化 Pass"
    echo "7. 查看文件统计信息"
    echo "0. 退出"
    echo ""
    echo -n "请选择操作 (0-7): "
    read -r choice

    case $choice in
        1)
            echo ""
            echo "可用的函数:"
            functions=($(get_functions))
            for i in "${!functions[@]}"; do
                echo "  $((i+1)). ${functions[i]}"
            done
            echo ""
            echo -n "请选择函数编号: "
            read -r func_num
            if [[ "$func_num" =~ ^[0-9]+$ ]] && [ "$func_num" -ge 1 ] && [ "$func_num" -le "${#functions[@]}" ]; then
                selected_function="${functions[$((func_num-1))]}"
                echo "已选择函数: $selected_function"
            else
                echo "无效选择"
            fi
            ;;
        2)
            if [ -z "$selected_function" ]; then
                echo "请先选择一个函数"
            else
                show_function "$current_file" "$selected_function"
            fi
            ;;
        3)
            echo ""
            echo "可用的优化 Pass:"
            echo "  1. constprop (常量传播)"
            echo "  2. sccp (稀疏条件常量传播)"
            echo "  3. dce (死代码消除)"
            echo "  4. instcombine (指令组合)"
            echo "  5. inline (函数内联)"
            echo "  6. mem2reg (内存到寄存器)"
            echo "  7. sccp-debug (带调试的 SCCP)"
            echo "  8. 自定义 Pass"
            echo ""
            echo -n "请选择 Pass 编号: "
            read -r pass_choice
            
            case $pass_choice in
                1) pass_name="constprop" ;;
                2) pass_name="sccp" ;;
                3) pass_name="dce" ;;
                4) pass_name="instcombine" ;;
                5) pass_name="inline" ;;
                6) pass_name="mem2reg" ;;
                7) pass_name="sccp-debug" ;;
                8) 
                    echo -n "请输入 Pass 名称: "
                    read -r pass_name
                    ;;
                *) echo "无效选择"; continue ;;
            esac
            
            apply_optimization "$pass_name" "$current_file"
            if [ $? -eq 0 ]; then
                current_file="temp_optimized.ll"
            fi
            ;;
        4)
            if [ -z "$selected_function" ]; then
                echo "请先选择一个函数"
            else
                echo ""
                echo "=== 原始版本 ==="
                show_function "test_O0.ll" "$selected_function"
                echo ""
                echo "=== 当前版本 ==="
                show_function "$current_file" "$selected_function"
            fi
            ;;
        5)
            current_file="test_O0.ll"
            echo "已重置到原始文件"
            ;;
        6)
            echo ""
            echo "可用的 LLVM 优化 Pass:"
            echo "  constprop        - 常量传播"
            echo "  sccp             - 稀疏条件常量传播"
            echo "  dce              - 死代码消除"
            echo "  instcombine      - 指令组合"
            echo "  inline           - 函数内联"
            echo "  mem2reg          - 内存到寄存器提升"
            echo "  licm             - 循环不变代码外提"
            echo "  loop-unroll      - 循环展开"
            echo "  gvn              - 全局值编号"
            echo "  sroa             - 标量替换聚合"
            echo ""
            echo "更多 Pass 可以通过以下命令查看:"
            echo "  $OPT --help | grep passes"
            ;;
        7)
            echo ""
            echo "=== 文件统计信息 ==="
            echo "文件: $current_file"
            echo "总行数: $(wc -l < "$current_file")"
            echo "函数数: $(grep -c "^define" "$current_file")"
            echo "基本块数: $(grep -c "^[a-zA-Z0-9_]*:" "$current_file")"
            if [ -n "$selected_function" ]; then
                local inst_count=$(awk "
                /^define.*$selected_function.*{/ { in_function = 1; next }
                in_function && /^}/ { in_function = 0; next }
                in_function && /^[[:space:]]*[a-zA-Z%]/ { count++ }
                END { print count+0 }
                " "$current_file")
                echo "函数 $selected_function 的指令数: $inst_count"
            fi
            ;;
        0)
            echo "再见!"
            # 清理临时文件
            rm -f temp_optimized.ll temp_debug.log
            exit 0
            ;;
        *)
            echo "无效选择"
            ;;
    esac
done

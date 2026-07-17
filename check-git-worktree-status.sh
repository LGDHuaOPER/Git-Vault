#!/bin/bash

git worktree list --porcelain | grep '^worktree' | while read -r _ path; do
    echo "=== Checking $path ==="
    
    # 1. 核心修复：将 Windows 路径 (D:/...) 转换为 Git Bash 路径 (/d/...)
    if [[ "$path" =~ ^([A-Za-z]):/(.*) ]]; then
        drive_letter="${BASH_REMATCH[1]}"
        remaining_path="${BASH_REMATCH[2]}"
        # 转小写盘符并拼接
        bash_path="/$(echo "$drive_letter" | tr '[:upper:]' '[:lower:]')/$remaining_path"
    else
        bash_path="$path"
    fi

    # 2. 在子 Shell 中执行检查，避免影响主循环
    (
        cd "$bash_path" || { echo "❌ Failed to enter directory"; exit 1; }
        
        # 3. 静默拉取远程最新信息
        git fetch origin >/dev/null 2>&1
        
        # 4. 获取当前分支名
        branch=$(git rev-parse --abbrev-ref HEAD)
        
        # 5. 处理 Detached HEAD 状态
        if [ "$branch" = "HEAD" ]; then
            echo "⚠️  Detached HEAD (No local branch)"
            exit 0
        fi
        
        # 6. 检查是否配置了上游追踪分支
        upstream=$(git rev-parse --abbrev-ref "@{upstream}" 2>/dev/null)
        if [ -z "$upstream" ]; then
            echo "⚠️  No upstream branch configured"
            exit 0
        fi
        
        # 7. 精确计算领先/落后的提交数量
        behind=$(git rev-list --count HEAD.."$upstream")
        ahead=$(git rev-list --count "$upstream"..HEAD)
        
        if [ "$behind" -gt 0 ] && [ "$ahead" -gt 0 ]; then
            echo "🔀 Diverged (Ahead $ahead, Behind $behind)"
        elif [ "$behind" -gt 0 ]; then
            echo "⚠️  Behind remote ($behind commits)"
        elif [ "$ahead" -gt 0 ]; then
            echo "⬆️  Ahead of remote ($ahead commits)"
        else
            echo "✅  Synced"
        fi
    )
done

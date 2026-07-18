#!/bin/bash

git worktree list --porcelain | grep '^worktree' | while read -r _ path; do
    echo "=== Checking $path ==="
    
    # 1. 将 Windows 路径 (D:/...) 转换为 Git Bash 路径 (/d/...)
    if [[ "$path" =~ ^([A-Za-z]):/(.*) ]]; then
        drive_letter="${BASH_REMATCH[1]}"
        remaining_path="${BASH_REMATCH[2]}"
        bash_path="/$(echo "$drive_letter" | tr '[:upper:]' '[:lower:]')/$remaining_path"
    else
        bash_path="$path"
    fi

    # 2. 在子 Shell 中执行检查，避免影响主循环
    (
        cd "$bash_path" || { echo "❌ Failed to enter directory"; exit 1; }
        
        # ===== 新增：优先检查未提交更改状态 =====
        # 检测三类关键状态：
        #   - unstaged: 已跟踪文件的修改未暂存（含删除）
        #   - untracked: 未跟踪的新文件
        #   - staged: 已暂存但未提交的更改
        unstaged=$(git diff --name-only)
        untracked=$(git ls-files --others --exclude-standard)
        staged=$(git diff --cached --name-only)

        # 组合状态提示（优先级：unstaged > staged > untracked）
        if [ -n "$unstaged" ] || [ -n "$untracked" ]; then
            # 有未暂存更改（含未跟踪文件）
            if [ -n "$staged" ]; then
                echo "⚠️  Unstaged changes + Staged changes (commit required)"
            else
                echo "⚠️  Unstaged changes (add required)"
                # 额外提示未跟踪文件（可选，注释掉则只显示主提示）
                [ -n "$untracked" ] && echo "   → Contains untracked files"
            fi
            exit 0  # 跳过后续检查（未提交更改优先级最高）
        elif [ -n "$staged" ]; then
            echo "⚠️  Staged changes (commit required)"
            exit 0
        fi
        # ===== 未提交更改检查结束 =====

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
        
        # 7. 检查 ahead/behind（仅当无未提交更改时执行）
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
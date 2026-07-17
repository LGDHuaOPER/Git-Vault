#!/bin/bash

echo "🔍 正在校验 Worktree 与远端分支的对齐状态..."
echo "---------------------------------------------"

# 1. 获取本地 Worktree 关联的分支名（排除主分支 main）
local_branches=$(git worktree list --porcelain | grep '^branch ' | sed 's/^branch refs\/heads\///' | grep -v '^main$')

# 2. 获取远端 origin/worktree/ 下的分支名
remote_branches=$(git branch -r | grep 'origin/worktree/' | sed 's/.*origin\///')

# 3. 找出本地有，但远端没有的分支（本地多余）
local_only=$(comm -23 <(echo "$local_branches" | sort) <(echo "$remote_branches" | sort))

# 4. 找出远端有，但本地 Worktree 没有的分支（本地缺失）
remote_only=$(comm -13 <(echo "$local_branches" | sort) <(echo "$remote_branches" | sort))

# 5. 输出结果
if [ -z "$local_only" ] && [ -z "$remote_only" ]; then
    echo "✅ 完美对齐！本地 Worktree 与远端分支完全一致。"
else
    if [ -n "$local_only" ]; then
        echo "⚠️  本地存在多余的 Worktree 分支（远端已无对应分支）："
        echo "$local_only" | sed 's/^/   - /'
        echo ""
    fi
    
    if [ -n "$remote_only" ]; then
        echo "⚠️  本地缺失以下 Worktree（远端有，但本地未创建）："
        echo "$remote_only" | sed 's/^/   - /'
        echo ""
        echo "💡 提示：可使用以下命令补全缺失的 Worktree："
        echo "$remote_only" | while read -r branch; do
            dir_name=$(echo "$branch" | sed 's/worktree\//Git-Vault_/')
            echo "   git worktree add -b $branch ../$dir_name origin/$branch"
        done
    fi
fi

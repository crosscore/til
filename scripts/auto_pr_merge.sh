#!/bin/bash
# 自動でPRを作成・マージするスクリプト (Pull Shark x4 目標)

set -e

# ghコマンドが不正な環境変数を読み込まないようにクリア
unset GITHUB_TOKEN

# 現在の最大PR番号を取得
HIGHEST_NUM=0
if [ -d "docs" ]; then
  for file in docs/pr-*.md; do
    if [ -f "$file" ]; then
      num=$(basename "$file" | sed 's/pr-//' | sed 's/\.md//')
      if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -gt "$HIGHEST_NUM" ]; then
        HIGHEST_NUM=$num
      fi
    fi
  done
fi

START=$((HIGHEST_NUM + 1))
END=1024

echo "🚀 PR自動作成・マージを開始します (PR #${START} 〜 #${END})"

# mainブランチを最新にする
git checkout main
git pull origin main

for i in $(seq $START $END); do
  echo "----------------------------------------"
  echo "🔄 処理中: PR #${i}"
  
  BRANCH_NAME="feat/pr-${i}-pull-shark"
  git checkout -b $BRANCH_NAME
  
  # テストファイルの作成
  mkdir -p docs
  echo "This is PR #${i} for Pull Shark achievement." > docs/pr-${i}.md
  git add docs/pr-${i}.md
  
  git commit -m "feat: add PR test doc ${i}"
  
  # リモートへプッシュ
  git push -u origin $BRANCH_NAME
  
  # PRの作成
  gh pr create --title "feat: PR ${i} for achievements" --body "Automated PR to get Pull Shark achievement" --base main
  
  # APIレートリミット対策 (少し待つ)
  sleep 3
  
  # PRのマージ (マージ後にブランチを削除)
  gh pr merge --merge --admin --delete-branch
  
  # mainに戻って最新化
  git checkout main
  git pull origin main
  
  echo "✅ PR #${i} 完了！次のPRまで30秒待機します..."
  # APIレートリミット対策で30秒待機
  sleep 30
done

echo "🎉 ${END}件のPRの作成とマージが完了しました！"

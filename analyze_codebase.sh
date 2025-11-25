#!/bin/bash

# Analyze codebase by language
REPO_ROOT="/workspace/usdx"
SINCE_DATE="2025-11-21"

echo "Analyzing codebase..."
echo ""

# Function to count lines by extension
count_lines() {
    local ext=$1
    local pattern=$2
    find "$REPO_ROOT" -type f -name "$pattern" \
        ! -path "*/node_modules/*" \
        ! -path "*/.git/*" \
        ! -path "*/lib/*" \
        ! -path "*/dist/*" \
        ! -path "*/.next/*" \
        ! -path "*/package-lock.json" \
        ! -path "*/yarn.lock" \
        ! -path "*/foundry.lock" \
        -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}'
}

# Count files by extension
count_files() {
    local pattern=$1
    find "$REPO_ROOT" -type f -name "$pattern" \
        ! -path "*/node_modules/*" \
        ! -path "*/.git/*" \
        ! -path "*/lib/*" \
        ! -path "*/dist/*" \
        ! -path "*/.next/*" \
        ! -path "*/package-lock.json" \
        ! -path "*/yarn.lock" \
        ! -path "*/foundry.lock" \
        2>/dev/null | wc -l
}

# Get commit stats since date
COMMITS_SINCE=$(git log --since="$SINCE_DATE" --oneline --all 2>/dev/null | wc -l)
FIRST_COMMIT=$(git log --all --format="%ai" 2>/dev/null | tail -1 | cut -d' ' -f1)
LAST_COMMIT=$(git log --all --format="%ai" 2>/dev/null | head -1 | cut -d' ' -f1)

# Count lines by language
SOLIDITY_LINES=$(count_lines "Solidity" "*.sol")
SOLIDITY_FILES=$(count_files "*.sol")

TYPESCRIPT_LINES=$(count_lines "TypeScript" "*.ts")
TYPESCRIPT_FILES=$(count_files "*.ts")

TSX_LINES=$(count_lines "TSX" "*.tsx")
TSX_FILES=$(count_files "*.tsx")

JAVASCRIPT_LINES=$(count_lines "JavaScript" "*.js")
JAVASCRIPT_FILES=$(count_files "*.js")

JSX_LINES=$(count_lines "JSX" "*.jsx")
JSX_FILES=$(count_files "*.jsx")

MARKDOWN_LINES=$(count_lines "Markdown" "*.md")
MARKDOWN_FILES=$(count_files "*.md")

JSON_LINES=$(count_lines "JSON" "*.json")
JSON_FILES=$(count_files "*.json")

CSS_LINES=$(count_lines "CSS" "*.css")
CSS_FILES=$(count_files "*.css")

SHELL_LINES=$(count_lines "Shell" "*.sh")
SHELL_FILES=$(count_files "*.sh")

YAML_LINES=$(count_lines "YAML" "*.yml")
YAML_FILES=$(count_files "*.yml")
YAML_LINES=$((YAML_LINES + $(count_lines "YAML" "*.yaml")))
YAML_FILES=$((YAML_FILES + $(count_files "*.yaml")))

# Calculate totals
TOTAL_LINES=$((SOLIDITY_LINES + TYPESCRIPT_LINES + TSX_LINES + JAVASCRIPT_LINES + JSX_LINES + MARKDOWN_LINES + JSON_LINES + CSS_LINES + SHELL_LINES + YAML_LINES))
TOTAL_FILES=$((SOLIDITY_FILES + TYPESCRIPT_FILES + TSX_FILES + JAVASCRIPT_FILES + JSX_FILES + MARKDOWN_FILES + JSON_FILES + CSS_FILES + SHELL_FILES + YAML_FILES))

# Get git stats for commits since date
cd /workspace
GIT_STATS=$(git log --since="$SINCE_DATE" --shortstat --pretty=format:"" --all 2>/dev/null | grep -E "files? changed" | awk '{files+=$1; inserted+=$4; deleted+=$6} END {print files, inserted, deleted}')

echo "=== CODEBASE ANALYSIS REPORT ==="
echo ""
echo "Repository: USDX Protocol"
echo "Analysis Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "First Commit: $FIRST_COMMIT"
echo "Last Commit: $LAST_COMMIT"
echo "Commits Since $SINCE_DATE: $COMMITS_SINCE"
echo ""
echo "--- Lines of Code by Language ---"
printf "%-20s %10s %10s %12s\n" "Language" "Files" "Lines" "Percentage"
echo "----------------------------------------------------------------"
printf "%-20s %10d %10d %11.2f%%\n" "Solidity" "$SOLIDITY_FILES" "$SOLIDITY_LINES" "$(echo "scale=2; $SOLIDITY_LINES*100/$TOTAL_LINES" | bc)"
printf "%-20s %10d %10d %11.2f%%\n" "TypeScript" "$TYPESCRIPT_FILES" "$TYPESCRIPT_LINES" "$(echo "scale=2; $TYPESCRIPT_LINES*100/$TOTAL_LINES" | bc)"
printf "%-20s %10d %10d %11.2f%%\n" "TSX (React)" "$TSX_FILES" "$TSX_LINES" "$(echo "scale=2; $TSX_LINES*100/$TOTAL_LINES" | bc)"
printf "%-20s %10d %10d %11.2f%%\n" "JavaScript" "$JAVASCRIPT_FILES" "$JAVASCRIPT_LINES" "$(echo "scale=2; $JAVASCRIPT_LINES*100/$TOTAL_LINES" | bc)"
printf "%-20s %10d %10d %11.2f%%\n" "JSX (React)" "$JSX_FILES" "$JSX_LINES" "$(echo "scale=2; $JSX_LINES*100/$TOTAL_LINES" | bc)"
printf "%-20s %10d %10d %11.2f%%\n" "Markdown" "$MARKDOWN_FILES" "$MARKDOWN_LINES" "$(echo "scale=2; $MARKDOWN_LINES*100/$TOTAL_LINES" | bc)"
printf "%-20s %10d %10d %11.2f%%\n" "JSON" "$JSON_FILES" "$JSON_LINES" "$(echo "scale=2; $JSON_LINES*100/$TOTAL_LINES" | bc)"
printf "%-20s %10d %10d %11.2f%%\n" "CSS" "$CSS_FILES" "$CSS_LINES" "$(echo "scale=2; $CSS_LINES*100/$TOTAL_LINES" | bc)"
printf "%-20s %10d %10d %11.2f%%\n" "Shell Scripts" "$SHELL_FILES" "$SHELL_LINES" "$(echo "scale=2; $SHELL_LINES*100/$TOTAL_LINES" | bc)"
printf "%-20s %10d %10d %11.2f%%\n" "YAML" "$YAML_FILES" "$YAML_LINES" "$(echo "scale=2; $YAML_LINES*100/$TOTAL_LINES" | bc)"
echo "----------------------------------------------------------------"
printf "%-20s %10d %10d\n" "TOTAL" "$TOTAL_FILES" "$TOTAL_LINES"
echo ""
echo "--- Additional Metrics ---"
echo "Total Files: $TOTAL_FILES"
echo "Total Lines: $TOTAL_LINES"
echo "Commits Since $SINCE_DATE: $COMMITS_SINCE"
if [ -n "$GIT_STATS" ]; then
    echo "Git Stats (since $SINCE_DATE): $GIT_STATS"
fi

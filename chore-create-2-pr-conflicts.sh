#!/usr/bin/env bash

# require:
# https://cli.github.com/
# https://www.npmjs.com/package/random-word-slugs

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
# YELLOW='\033[0;33m'

COUNT_PR=0

if ! command -v gh &> /dev/null; then
    echo -e "${RED}Please install https://cli.github.com/${NC}"
    exit 1
elif ! command -v yawg &> /dev/null; then
    echo -e "${RED}Please run \"npm install -g yawg\"${NC}"
    exit 1
fi

function pr_name {
    yawg --delimiter='-' --minWords=4  --maxWords=4
}

function timestamp {
    date +"%Y-%m-%d_%s%N"
}

function check_git_dirty {
    if [[ $(git diff --stat) != '' ]]; then
        echo -e "${RED}Git is dirty, please commit${NC}"
        exit 1
    else
        echo "Git is clean"
    fi
}

function create_pr {
    (( COUNT_PR++ )) || true
    check_git_dirty
    FILE_NAME=$1
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    PR_NAME="$COUNT_PR-$(pr_name)"
    echo -e "${CYAN}Creating pull request named $PR_NAME${NC}"
    # create branch
    git checkout -b "$PR_NAME"
    # edit files
    printf "Hello, %s\n" "$NAME"
    printf "\n// Some changes at %s\n" "$(timestamp)" >> "packages/fe-package1/$FILE_NAME"
    printf "\n// Some changes at %s\n" "$(timestamp)" >> "packages/fe-package2/$FILE_NAME"
    printf "\n// Some changes at %s\n" "$(timestamp)" >> "packages/fe-package3/$FILE_NAME"
    printf "\n// Some changes at %s\n" "$(timestamp)" >> "apps/fe-spa/$FILE_NAME"
    printf "\n// Some changes at %s\n" "$(timestamp)" >> "apps/fe-website/$FILE_NAME"
    # push to remote
    git add "packages/fe-package1/$FILE_NAME"
    git add "packages/fe-package2/$FILE_NAME"
    git add "packages/fe-package3/$FILE_NAME"
    git add "apps/fe-spa/$FILE_NAME"
    git add "apps/fe-website/$FILE_NAME"
    git commit -m "Changes added"
    git push origin "$PR_NAME"
    # create release plan
    deno run --unstable --allow-read --allow-run --allow-write \
        "https://$GITHUB_TOKEN@raw.githubusercontent.com/ITV/fe-core-cli/pnpm-release/mod.pnpm-release.ts" \
        create --output --no-git-checks
    git add .release-plan
    git commit -m "Release plan created"
    git push origin "$PR_NAME"
    # create pull request
    gh pr create --title "$PR_NAME" --body "Generated pull request"
    # back in initial branch
    git checkout "$CURRENT_BRANCH"
}

create_pr file1.txt
create_pr file1.txt

echo -e "${GREEN}Successful${NC}"

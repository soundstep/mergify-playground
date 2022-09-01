#!/usr/bin/env bash

# ./.github/actions/release-plan-apply.sh
# ./.github/actions/release-plan-apply.sh --dry-run
# ./.github/actions/release-plan-apply.sh --base-branch main

set -e

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'

BASE_BRANCH=main
RELEASE_PLAN=./.release-plan
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo -e "${CYAN}Apply a release plan${NC}"

# parameters

while (( "$#" )); do
    case "$1" in
        --dry-run|-d) # do not apply release plan
            DRY_RUN=true
            shift
            ;;
        --base-branch|-b)
            BASE_BRANCH="$2"
            shift
            shift
            ;;
        --*|-*) # unsupported flags
            echo "Error: Unsupported flag $1" >&2
            exit 1
            ;;
        *) # all
            echo "Error: Unsupported argument $1" >&2
            exit 1
            ;;
    esac
done

echo "Arguments:"
echo "  --dry-run: $DRY_RUN"
echo " --base-branch: $BASE_BRANCH"

# checks

if [[ -z "${GITHUB_TOKEN}" ]]; then
    echo -e "${RED}Missing env var: GITHUB_TOKEN${NC}"
    exit 1
# elif [[ ! -f "${RELEASE_PLAN}" ]]; then
#     echo -e "${RED}Missing release plan file: $RELEASE_PLAN ${NC}"
#     exit 1
fi

# run

function has_conflict() {
    rev1=$(git rev-parse origin/$BASE_BRANCH)
    rev2=$(git rev-parse HEAD)
    mergebase=$(git merge-base "$rev1" "$rev2")
    if [ "$mergebase" = "" ];then
        # no common ancestor
        echo -e "${YELLOW}Warning, could not find a common ancestor to check conflicts.${NC}"
        echo false
    else
        result_merge_base=$(git merge-tree "$mergebase" "$rev1" "$rev2")
        result_conflict=$(echo "$result_merge_base" | xargs | grep -oe '<<<<<<<.*=======.*>>>>>>>')
        if [[ -z "$result_conflict" ]]; then
            echo false
        else
            echo true
        fi
    fi
}

function check_conflict() {
    if [[ $(has_conflict) = true ]]; then
        echo -e "${RED}Error, this branch has conflicts with the base branch.${NC}"
        exit 1
    else
        echo "No conflicts found."
    fi
}

if [[ -n "${DRY_RUN}" ]]; then
    DRY_RUN_ARG="--dry-run"
fi

echo -e "${CYAN}Check conflicts${NC}"

check_conflict

echo -e "${CYAN}Merge base branch${NC}"

git merge $BASE_BRANCH

echo -e "${CYAN}Running install${NC}"

pnpm install

echo -e "${CYAN}Applying release plan${NC}"

# pnpm release-plan -- apply $DRY_RUN_ARG

echo -e "${CYAN}Deleting release plan${NC}"

# rm -f .release-plan

echo -e "${CYAN}Updating pnpm lock file${NC}"

rm -f pnpm-lock.yaml
pnpm install

echo -e "${CYAN}Pushing changes to git remote${NC}"

git status | grep "package\.json" | awk {"print \$2"} | xargs git add
git add .release-plan
git add pnpm-lock.yaml
git commit -m "Apply release plan."

if [[ -z "${DRY_RUN}" ]]; then
    git push origin "$CURRENT_BRANCH"
fi

echo -e "${GREEN}All operations successful${NC}"

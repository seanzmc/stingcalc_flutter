#!/usr/bin/env bash
set -e

# Simple deploy script for stingcalc_flutter -> GitHub Pages (docs/ folder)

APP_NAME="stingcalc_flutter"
BASE_HREF="/${APP_NAME}/"

# Optional first argument = commit message; default if not provided:
COMMIT_MSG="${1:-Deploy update}"

echo ""
echo "=== Flutter Web Build ==="
echo "Using base-href: $BASE_HREF"
flutter clean
flutter build web --release --base-href "$BASE_HREF"

echo ""
echo "=== Updating docs/ folder ==="
rm -rf docs
cp -R build/web docs

echo ""
echo "=== Git commit & push (docs only) ==="
git add docs

# If nothing actually changed in docs, skip commit
if git diff --cached --quiet; then
  echo "No changes detected in docs/. Nothing to commit."
else
  echo "Committing with message: \"$COMMIT_MSG\""
  git commit -m "$COMMIT_MSG"
  echo "Pushing..."
  git push
fi

echo ""
echo "✅ Deploy complete. Check:"
echo "   https://seanzmc.github.io/${APP_NAME}/"
echo ""

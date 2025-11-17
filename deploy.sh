#!/usr/bin/env bash
set -e

APP_NAME="stingcalc_flutter"
BASE_HREF="/${APP_NAME}/"

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
echo "✅ Build complete. docs/ updated."
echo "Next steps:"
echo "  git add ."
echo "  git commit -m \"Your message\""
echo "  git push"

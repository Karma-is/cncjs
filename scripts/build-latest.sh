#!/bin/bash

VERSION=${npm_package_version}-$(TZ=UTC date +'%Y%m%d')-${CI_COMMIT_SHORT:-latest}

yarn run package-sync

mkdir -p dist
rm -rf dist/*

pushd src
mkdir -p ../dist/cncjs/
sed 's/\("version": \)".*"/\1"'$VERSION'"/' package.json > package.json.new
mv -f package.json.new package.json
cp -af package.json ../dist/cncjs/
cross-env NODE_ENV=production babel "*.js" \
    --config-file ../babel.config.js \
    --out-dir ../dist/cncjs
cross-env NODE_ENV=production babel "electron-app/**/*.js" \
    --config-file ../babel.config.js \
    --out-dir ../dist/cncjs/electron-app
popd

babel -d dist/cncjs/server src/server
i18next-scanner --config i18next-scanner.server.config.js \"src/server/**/*.{html,js,jsx}\" \"!src/server/i18n/**\" \"!**/node_modules/**\"

cross-env NODE_ENV=production webpack-cli --config webpack.config.production.js
i18next-scanner --config i18next-scanner.app.config.js \"src/app/**/*.{html,js,jsx}\" \"!src/app/i18n/**\" \"!**/node_modules/**\"

mkdir -p dist/cncjs/app
mkdir -p dist/cncjs/server

cp -af src/app/{favicon.ico,i18n,images,assets} dist/cncjs/app/
cp -af src/server/{i18n,views} dist/cncjs/server/
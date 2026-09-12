​name: Build Android APK
​on:
push:
branches:
- main
workflow_dispatch:
​jobs:
build:
runs-on: ubuntu-latest
​steps:
# STREAMING_CHUNK:Setting up Node and Java environments...
- name: Checkout Source Code
uses: actions/checkout@v4
​- name: Setup Node.js Environment
uses: actions/setup-node@v4
with:
node-version: 20
​- name: Setup Java JDK 17
uses: actions/setup-java@v4
with:
distribution: 'temurin'
java-version: '17'
​- name: Setup Android SDK
uses: android-actions/setup-android@v3
​# STREAMING_CHUNK:Accepting Android SDK licenses...
- name: Accept Android SDK Licenses
run: |
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --licenses || true
​# STREAMING_CHUNK:Sanitizing project structure and baseline files...
- name: Ensure Base Project Files
run: |
if [ ! -f "package.json" ]; then
cat << 'JSON' > package.json
{
"name": "mess-mate-pro",
"private": true,
"version": "1.0.0",
"type": "module",
"scripts": {
"dev": "vite",
"build": "vite build",
"preview": "vite preview"
},
"dependencies": {
"react": "^18.2.0",
"react-dom": "^18.2.0"
},
"devDependencies": {
"@vitejs/plugin-react": "^4.2.1",
"vite": "^5.1.4"
}
}
JSON
fi
​if [ ! -f "capacitor.config.json" ] && [ ! -f "capacitor.config.ts" ]; then
echo '{"appId":"com.messmatepro.app","appName":"Mess Mate Pro","webDir":"dist","bundledWebRuntime":false}' > capacitor.config.json
fi
​if [ ! -f "index.html" ]; then
cat << 'HTML' > index.html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>Mess Mate Pro</title>
</head>
<body>
<div id="root"></div>
<script type="module" src="/src/main.jsx"></script>
</body>
</html>
HTML
fi
​if [ ! -f "src/main.jsx" ] && [ ! -f "src/main.tsx" ]; then
mkdir -p src
cat << 'JSX' > src/main.jsx
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
​ReactDOM.createRoot(document.getElementById('root')).render(
<React.StrictMode>
<App />
</React.StrictMode>
)
JSX
fi
​# STREAMING_CHUNK:Installing dependencies and compiling web bundle...
- name: Install Dependencies & Build Web App
run: |
npm install --legacy-peer-deps || npm install
mkdir -p dist
npm run build || npx vite build
​# STREAMING_CHUNK:Syncing Capacitor Android native platform...
- name: Setup & Sync Capacitor Android
run: |
npm install @capacitor/core @capacitor/cli @capacitor/android --save-exact || true
if [ ! -d "android" ]; then
npx cap add android
fi
npx cap sync android
​# STREAMING_CHUNK:Compiling Android Debug APK with Gradle...
- name: Build Debug Android APK
run: |
cd android
chmod +x gradlew
./gradlew assembleDebug --no-daemon --stacktrace
​# STREAMING_CHUNK:Uploading APK artifact for download...
- name: Upload APK Artifact
uses: actions/upload-artifact@v4
with:
name: Mess-Mate-Pro-APK
path: android/app/build/outputs/apk/debug/app-debug.apk
retention-days: 7


# JeridiEngine application branding

Source artwork: `../logos/engine_logo_green.svg`.

- `JeridiEngine.icns`: native macOS app icon, embedded into the `.app` bundle by CMake.
- `JeridiEngine.ico`: Windows executable icon, embedded through the `.rc` resource.
- `JeridiEngine_1024.png`: high-resolution image for distribution artwork.

## macOS release workflow

1. Open the project in Qt Creator and **Run CMake** (or delete the build directory and configure again).
2. Build the Release configuration. The output is `appJeridiEngine.app` with the new icon.
3. Deploy Qt frameworks and plugins using `macdeployqt /path/to/appJeridiEngine.app` from the matching Qt installation.
4. For public distribution, sign the deployed app with an appropriate Apple Developer ID certificate, notarize with Apple, and staple the ticket before distribution.
5. Verify startup and WebView support on a clean Mac. Do not assume `macdeployqt` covers every runtime dependency.

If Finder retains an old icon, move the new `.app` to a new path or refresh Finder's icon cache.

The CMake changes only configure native branding; they do not sign, notarize, or package a final distributable.

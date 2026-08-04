# Device testing checklist

Emulators/simulators help, but **release requires physical devices**.

## Remote deploy (demo)

- [x] Open `demo/` in Godot 4.7+
- [x] Android: Project → Install Android Build Template (once)
- [x] Android: device visible in `adb devices`
- [x] Android: use runnable **Android** preset
- [x] iOS: use runnable **iOS** preset (`com.noforcedads.qaasdemo`)
- [x] Remote Debug → Run on physical Android and iOS devices
- [ ] If `ERROR: Run:` is empty, check Project → Export for the real warning (template / SDK / ETC2)

## Shared

- [ ] `quick_actions_app_shortcuts.cfg` with a real inbox
- [x] Long-press app icon → **Send feedback** visible with mail/compose icon
- [x] Tap → mail composer opens on Android and iOS
- [x] Placeholders filled: app name, version, OS, device
- [ ] Non-ASCII subject/body encode correctly
- [x] At least one non-English locale shows a translated shortcut label from `[feedback.<locale>]`
- [x] Configured `title` / `icon` appear in the long-press menu
- [ ] Missing config exports without registering a shortcut
- [ ] Disabling the editor plugin skips shortcut injection
- [ ] Invalid recipient fails export with a clear error


## Android

- [ ] Game process does **not** start when using the shortcut
- [ ] No mail client → short native message, trampoline finishes
- [ ] Works for at least two different `applicationId` values
- [ ] API 24 (or other &lt; 25) device/emulator: app runs, no shortcut

## iOS

- [ ] Terminated app → shortcut opens Mail (cold launch / scene connection options)
- [ ] App already running → shortcut opens Mail (warm / performAction)
- [ ] Document visible launch/splash before Mail (expected)
- [ ] No mail handler → completion fails gracefully, game remains usable

## Stage 0 spike log

Record conclusions here before tagging a release:

| Spike | Result | Notes |
|-------|--------|-------|
| AAR shortcut → trampoline across app IDs | pending | Export writes host `package/unique_name` as `targetPackage` + FQ `targetClass` |
| Android trampoline opens Mail | passed | Verified on a physical device |
| iOS plist shortcut + title/icon | passed | Verified on a physical device |
| iOS cold launch shortcut | pending | Hooks `GDTApplicationDelegate` at runtime |
| iOS warm launch shortcut | pending | |
| Exact Godot 4.7 lifecycle bridge | partial | Physical-device smoke test passed; cold/warm cases remain |

# Fix for Gray Event Cards on Web

## 🔍 Issue Identified
Event cards showing as gray boxes at https://sgiar.org.ar/app/agenda/

## 🛠️ Solutions Applied

### 1. Fixed Color Saturation Clamping
- Added `.clamp(0.0, 1.0)` to prevent color calculation errors on web
- Rebuilt with `--release` flag for production optimization

### 2. Updated Build
```bash
flutter build web --base-href /app/agenda/ --release
```

## 📦 Files to Re-Upload

Upload these updated files from `build/web/` to your server:

**Critical Files:**
- `main.dart.js` (updated with color fix)
- `main.dart.js.map` (source map)
- `flutter_service_worker.js` (service worker)
- `version.json` (cache busting)

**Optional but Recommended:**
- Upload everything to ensure consistency

## 🚀 Quick Deploy

### Option 1: Full Re-upload (Recommended)
```bash
# Delete old files on server first, then upload all from:
build/web/*
```

### Option 2: Update Critical Files Only
Upload just:
- `build/web/main.dart.js`
- `build/web/flutter_service_worker.js`
- `build/web/version.json`

## 🧹 Clear Browser Cache

After uploading, users need to clear cache:
1. Hard refresh: `Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac)
2. Or clear browser cache completely
3. Or wait for service worker to update (can take a few minutes)

## 🔍 Additional Debugging

### Check Browser Console
1. Open https://sgiar.org.ar/app/agenda/
2. Press `F12` to open DevTools
3. Go to Console tab
4. Look for errors related to:
   - Asset loading
   - API calls to Google Calendar
   - Color rendering errors

### Common Issues & Fixes

#### Issue: Events not loading
**Symptoms:** Empty calendar, no events
**Fix:** Check Google Calendar API:
- Verify API key is valid
- Check calendar is public
- Test API directly: 
  ```
  https://www.googleapis.com/calendar/v3/calendars/sgiar.aplicaciones@gmail.com/events?key=YOUR_API_KEY&timeMin=2025-11-01T00:00:00Z&timeMax=2025-12-01T00:00:00Z&singleEvents=true&orderBy=startTime
  ```

#### Issue: Colors showing as gray
**Symptoms:** Gray background on all event cards
**Fix:** 
1. Check if events have `colorId` or color in description
2. Verify color parsing in `public_google_calendar_service.dart`
3. Test locally first: `flutter run -d chrome`

#### Issue: Assets not loading
**Symptoms:** Broken images, missing icons
**Fix:**
- Verify `assets/` folder uploaded
- Check `.htaccess` is in place
- Verify file permissions (644 for files, 755 for folders)

#### Issue: App shows old version
**Symptoms:** Changes not visible
**Fix:**
1. Clear browser cache (Ctrl+Shift+R)
2. Update `version.json` with new timestamp
3. Check service worker is updated

## 🧪 Test Locally First

Before deploying, test locally:
```bash
# Run on Chrome
flutter run -d chrome

# Or serve the built files
cd build/web
python -m http.server 8000
# Visit: http://localhost:8000
```

## 📱 Mobile Testing

Test on mobile browsers:
- Chrome Android
- Safari iOS
- Check responsive layout
- Test touch interactions

## ⚠️ CORS Issues

If you see CORS errors in console:
```
Access to fetch at 'https://www.googleapis.com/calendar/...' 
from origin 'https://sgiar.org.ar' has been blocked by CORS policy
```

**This is normal for Google Calendar API** - it should still work because:
1. The API is public
2. The request includes the API key
3. The browser allows it for public APIs

## 🎨 Force Color Refresh

If colors still look wrong, you can force a color in the description:
```json
{
  "description": "{color:green}\n\nYour event description here"
}
```

Supported colors:
- green, blue, red, yellow, orange
- purple, pink, cyan, teal, lime
- indigo, brown, grey/gray

## 📞 Still Having Issues?

### Debug Checklist:
- [ ] Uploaded latest `build/web/` files
- [ ] Cleared browser cache (Ctrl+Shift+R)
- [ ] Checked browser console for errors
- [ ] Verified Google Calendar API is working
- [ ] Tested on different browsers
- [ ] Checked `.htaccess` is in place
- [ ] Verified base href is `/app/agenda/`
- [ ] Checked file permissions on server

### Check These Files Are Updated:
```bash
# On your server, check file dates:
ls -lah /path/to/sgiar.org.ar/app/agenda/

# main.dart.js should be newest file
# Should match build time in your local build/web/
```

## ✅ Expected Result

After fix, you should see:
- ✅ Event cards with colored borders
- ✅ Light colored backgrounds
- ✅ Colored dot indicator
- ✅ Time and location chips with white background
- ✅ Proper text rendering
- ✅ No gray placeholder boxes

## 🎉 Success Indicators

Your app is working correctly when:
1. Events load automatically when page opens
2. Each event has its own color (green, blue, etc.)
3. Calendar shows colored dots on dates with events
4. Clicking an event shows full details
5. Share and Map buttons work
6. Search filters events correctly
7. Month navigation works smoothly

---

**Last Build:** `flutter build web --base-href /app/agenda/ --release`
**Date:** 2025-11-18
**Location:** `build/web/`
**Deploy to:** `https://sgiar.org.ar/app/agenda/`


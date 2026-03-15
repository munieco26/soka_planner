# Agenda SGIAR - Web Deployment Guide

## Your App URL: `domain.com/app/agenda/`

### ✅ Build Status

- Built with `--base-href /app/agenda/`
- Optimized for production
- Ready to deploy

---

## 📦 What to Deploy

Deploy everything from: `build/web/`

### Files to Upload:

```
build/web/
├── .htaccess           (Apache config - included)
├── nginx.conf          (Nginx config - reference)
├── index.html          (Main HTML)
├── main.dart.js        (App code)
├── flutter.js          (Flutter engine)
├── flutter_bootstrap.js
├── flutter_service_worker.js
├── manifest.json
├── version.json
├── favicon.png
├── assets/             (App assets)
├── canvaskit/          (Renderer)
└── icons/              (App icons)
```

---

## 🚀 Deployment Options

### Option 1: FTP/SFTP Upload

1. Connect to your server via FTP/SFTP
2. Navigate to `/app/` directory
3. Create `agenda` folder if it doesn't exist
4. Upload all files from `build/web/` to `/app/agenda/`
5. Visit: `domain.com/app/agenda/`

### Option 2: Using cPanel File Manager

1. Login to cPanel
2. Open File Manager
3. Navigate to `public_html/app/` (or your web root)
4. Create `agenda` folder
5. Upload all files from `build/web/`
6. Visit: `domain.com/app/agenda/`

### Option 3: SSH/SCP (Recommended)

```bash
# From your local machine
scp -r build/web/* user@your-server:/path/to/domain.com/app/agenda/

# Or using rsync
rsync -avz --delete build/web/ user@your-server:/path/to/domain.com/app/agenda/
```

---

## ⚙️ Server Configuration

### For Apache:

- `.htaccess` file is already included in `build/web/`
- Make sure `mod_rewrite` is enabled
- Verify `.htaccess` files are allowed (AllowOverride All)

### For Nginx:

1. Edit your nginx server config
2. Add the location block from `nginx.conf`
3. Replace `/path/to/your/server/` with actual path
4. Reload nginx: `sudo nginx -s reload`

---

## 🔍 Testing

1. Visit: `domain.com/app/agenda/`
2. Test features:
   - ✅ Calendar loads
   - ✅ Events display
   - ✅ Spanish language
   - ✅ Search works
   - ✅ Event modal opens
   - ✅ Share button works
   - ✅ Map button opens Google Maps
   - ✅ Responsive on mobile

---

## 🐛 Troubleshooting

### Issue: Blank page or 404

- **Solution**: Check `.htaccess` is uploaded
- **Solution**: Verify base-href is `/app/agenda/` (trailing slash important!)

### Issue: Assets not loading

- **Solution**: Check folder permissions (755 for folders, 644 for files)
- **Solution**: Verify `assets/` folder uploaded correctly

### Issue: Routing doesn't work

- **Apache**: Enable mod_rewrite
- **Nginx**: Ensure try_files directive is set

### Issue: Slow loading

- **Solution**: Enable gzip compression (configured in .htaccess/nginx.conf)
- **Solution**: Enable browser caching

---

## 📱 Mobile PWA (Optional)

Your app is already PWA-ready! Users can:

1. Visit the app on mobile
2. Tap "Add to Home Screen"
3. Use it like a native app

---

## 🔄 Future Updates

To update the app:

```bash
# 1. Make changes to your code
# 2. Rebuild with base-href
flutter build web --base-href /app/agenda/

# 3. Upload to server
scp -r build/web/* user@your-server:/path/to/domain.com/app/agenda/
```

---

## 📊 Performance Tips

1. **Enable Compression**: Already configured in .htaccess/nginx.conf
2. **Browser Caching**: Assets cached for 1 year
3. **HTTPS**: Use SSL certificate for better performance and security
4. **CDN**: Consider using Cloudflare for faster global access

---

## ✅ Checklist

- [ ] Upload all files from `build/web/`
- [ ] Verify `.htaccess` is in place (Apache)
- [ ] Configure nginx if needed
- [ ] Test on desktop browser
- [ ] Test on mobile browser
- [ ] Test all features (calendar, events, share, maps)
- [ ] Check browser console for errors

---

## 🎉 Your App is Ready!

Access at: **`domain.com/app/agenda/`**

Made with ❤️ for SGIAR Argentina 🇦🇷

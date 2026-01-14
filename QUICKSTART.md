# Leisurely Read - Quick Start Guide

## 🚀 First Time Setup

### 1. Firebase Configuration

Ensure your `lib/firebase_options.dart` is properly configured with your Firebase project credentials.

### 2. Initial Admin Account

Since there can only be one admin:

1. **First run**: Sign up with any email/password as a reader
2. **In Firestore Console**:
   - Go to Collections → users
   - Find your document (matches your UID)
   - Edit the `role` field: change from `reader` to `admin`
3. **Restart app** and you'll be in Admin Dashboard

### 3. Writer Signup Code

Default code for writers: **`123456`**

To change it, edit `lib/services/auth_service.dart`:
```dart
static const String writerSignupCode = 'YOUR_NEW_CODE';
```

---

## 👥 Test User Flows

### Admin Testing

```
Email: admin@test.com
Password: testpass123
Setup: See "First Time Setup" above
```

**What to test**:
- ✅ Ban/unban users
- ✅ Delete user accounts
- ✅ Approve writer signups
- ✅ Delete books
- ✅ Send notifications
- ✅ Change password

### Writer Testing

```
Email: writer@test.com
Password: testpass123
Signup Code: 123456
```

**What to test**:
1. Sign up → see "Pending Approval" screen
2. Switch to admin → approve the writer
3. Writer logs back in → see Writer Dashboard
4. Create a book:
   - Title: "Test Book"
   - Cover: `https://via.placeholder.com/300x400?text=Book+Cover`
5. Add chapter:
   - Number: 1
   - Title: "Chapter 1: The Beginning"
   - Content: "Some sample text..."
6. Create more chapters
7. Change password
8. Logout

### Reader Testing

```
Email: reader@test.com
Password: testpass123
```

**What to test**:
1. Sign up → see Reader Dashboard
2. Go to "Browse" tab
3. See books uploaded by writer
4. Tap a book → see chapters
5. Select a chapter → read content
6. Vote (thumbs up) → vote count should update
7. Add comment → comment should appear
8. Go to "Library" tab
9. Long-press book in library → remove it
10. Go back to browse, tap book, add to library
11. Check "Notifications" tab for admin messages
12. Change password

---

## 📱 App Navigation

### Login/Signup
```
┌─────────────────┐
│  Login Screen   │ ← First screen (if not logged in)
└────────┬────────┘
         │
    ┌────┴────┐
    │ Sign Up  │ Link to signup
    │ or Login │
    └─────────┘
    
    Role Selection:
    ┌─────────────────────────────┐
    │ Reader (no code needed)     │
    │ Writer (needs admin code)   │
    └─────────────────────────────┘
```

### Admin Dashboard
```
┌──────────────────────────┐
│   Admin Dashboard        │
├──────────────────────────┤
│ Users │Writers │Books│Set│
├──────────────────────────┤
│ [User List]              │
│ - Ban/Unban              │
│ - Delete                 │
└──────────────────────────┘
```

### Writer Dashboard
```
┌──────────────────────────┐
│  Writer Dashboard        │
├──────────────────────────┤
│ [My Books Grid]          │
│ [Book] [Book] [Book]     │
│ + FAB to add book        │
├──────────────────────────┤
│ Tap Book → [Chapters]    │
│ [Ch1] [Ch2] [Ch3]        │
│ + FAB to add chapter     │
└──────────────────────────┘
```

### Reader Dashboard
```
┌──────────────────────────┐
│  Leisurely Read          │
├──────────────────────────┤
│ Browse│Library│Notif│    │
├──────────────────────────┤
│
│ BROWSE TAB:
│ [Books Grid]
│ [Book] [Book]
│ Tap → Read
│
│ LIBRARY TAB:
│ [Your Books]
│ Long-press → Remove
│
│ NOTIFICATIONS TAB:
│ [Admin Messages]
│ Tap → Mark as read
└──────────────────────────┘
```

---

## 🎯 Common Tasks

### Creating a Book (Writer)
1. Writer Dashboard → + FAB
2. Enter book title
3. Enter cover image URL (use placeholder: `https://via.placeholder.com/300x400`)
4. Click Create

### Adding a Chapter (Writer)
1. Select book
2. Click + FAB
3. Enter chapter number (e.g., 1)
4. Enter title (e.g., "Introduction")
5. Enter content (plain text)
6. Click Create

### Reading a Chapter (Reader)
1. Browse tab → Tap book
2. Click chapter from chip selector
3. Read content
4. Click 👍 to vote
5. Scroll down to comment

### Sending Notification (Admin)
- Coming soon in UI (manual via Firestore for now)
- Or: Create documents in `notifications` collection:
  ```json
  {
    "userId": "target_user_id",
    "title": "Welcome",
    "message": "Welcome to Leisurely Read!",
    "type": "info",
    "read": false,
    "createdAt": timestamp
  }
  ```

### Banning a User (Admin)
1. Admin Dashboard → Users tab
2. Find user
3. Click lock icon
4. Select ban duration (1 day, 7 days, 30 days, 1 year)
5. User sees ban screen on next login
6. Click unlock icon to unban

---

## 🐛 Debugging Tips

### Check Firebase Connection
- Look for errors in terminal during app startup
- Verify `google-services.json` is in `android/app/`
- Check Firebase project ID matches

### User Not Transitioning After Signup
- Refresh app or manually navigate to role-appropriate screen
- Check user document in Firestore has correct `role` field

### Writer Cannot Create Books
- Verify `isApproved: true` in Firestore user document
- Refresh app after admin approval

### Images Not Loading
- Verify image URL is public and accessible
- Check image URL format (must be HTTP/HTTPS)
- Use placeholder: `https://via.placeholder.com/300x400`

### Firestore Rules Error
- If you see permission denied errors:
  - Go to Firestore → Rules
  - Set to test mode (allow all reads/writes) for development
  - For production, implement proper security rules

---

## 📊 Test Data

### Sample Book Cover URLs (Placeholders)
```
https://via.placeholder.com/300x400?text=Adventure
https://via.placeholder.com/300x400?text=Mystery
https://via.placeholder.com/300x400?text=Romance
https://via.placeholder.com/300x400?text=Fantasy
```

### Sample Chapter Content
```
Lorem ipsum dolor sit amet, consectetur adipiscing elit. 
Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. 
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.

(copy-paste as needed for chapters)
```

---

## ✅ Checklist Before Deployment

- [ ] Firebase project created and configured
- [ ] `google-services.json` added to Android
- [ ] `GoogleService-Info.plist` added to iOS (if deploying to iOS)
- [ ] At least one admin account created
- [ ] Writer signup code set to desired value
- [ ] Test user accounts created for QA
- [ ] Firebase Rules configured for security
- [ ] App tested on target devices
- [ ] All features manually tested
- [ ] Error messages clear and helpful

---

## 📞 Need Help?

1. **App won't start**: Check Firebase configuration
2. **Can't login**: Verify user exists in Firebase Auth
3. **Missing data**: Check Firestore collections
4. **Images not showing**: Verify image URLs are valid
5. **Permission errors**: Check Firestore security rules

---

**Last Updated**: January 2026
**Version**: 1.0.0

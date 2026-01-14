# Firebase Setup Checklist for Leisurely Read

## Status: COMPLETE APP BUILD ✅ | AWAITING FIREBASE CONFIG ⏳

The Flutter app is now **running successfully** but needs Firebase configuration to work.

---

## ✅ What's Done

- App compiles without errors
- Firebase Auth integration complete
- Firestore integration complete  
- All screens and features implemented
- Error handling improved

## ⏳ What Needs Doing

You need to configure Firebase in the Firebase Console. This is a **ONE-TIME setup** (takes ~5 minutes).

---

## STEP 1: Go to Firebase Console

1. **Open** [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. **Log in** with your Google account
3. **Select project**: Click on **"leisurely-read"** 

---

## STEP 2: Update Firestore Rules (Most Important!)

### Location: Left sidebar → Firestore Database → Rules tab

1. You should see a **Rules** tab at the top
2. **Delete everything** in the code editor
3. **Copy and paste** this code:

```firestore
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Test mode: Allow all reads and writes
    // ⚠️ Use for development/testing only!
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

4. Click **PUBLISH** (blue button)
5. **Wait 1-2 minutes** for changes to take effect
6. You should see: "Rules updated successfully"

---

## STEP 3: Create Admin User in Firebase Auth

### Location: Left sidebar → Authentication → Users tab

1. Click **"+ Create user"** button (top right)
2. Enter:
   - **Email**: `admin.leisurelyread@gmail.com`
   - **Password**: `AdminPassword123!` (or your preferred password)
3. Click **Create user**
4. **Copy the UID** that appears (you'll need this in next step!)

**Example UID format**: `0UXrTQngUZZLgeGY5c9F9OYPgBq1`

---

## STEP 4: Create Admin Document in Firestore

### Location: Left sidebar → Firestore Database → Data tab

### Part A: Create Collection

1. Click **"+ Create collection"**
2. **Collection name**: `users`
3. Click **Next**
4. You'll see "Blank collection" - click **Next** again

### Part B: Add Admin Document

1. In the "Add the first document" dialog:
   - **Document ID**: Paste the UID from Step 3 (e.g., `0UXrTQngUZZLgeGY5c9F9OYPgBq1`)
   - Click **Continue**

2. **Add fields** one by one:

   | Field Name | Type | Value |
   |-----------|------|-------|
   | `email` | String | `admin.leisurelyread@gmail.com` |
   | `role` | String | `admin` |
   | `isApproved` | Boolean | `true` |

3. **For `bannedUntil` field**:
   - Click **+ Add field**
   - Field name: `bannedUntil`
   - Type: Leave empty (set to `null`) - just click **Delete** if it appears
   - OR Type: `Map` and leave empty

4. Click **Save**

---

## ✅ Verify Setup

After completing all steps, you should see in Firestore:

```
Collections
└── users
    └── [UID from step 3]
        ├── email: admin.leisurelyread@gmail.com
        ├── role: admin
        ├── isApproved: true
        └── bannedUntil: (empty/null)
```

And in Authentication Users tab, you should see:
```
Email: admin.leisurelyread@gmail.com
UID: [your UID]
```

---

## 🧪 TEST: Try Admin Login

1. **Look at the emulator screen** - it should show an error message
2. **Restart the app**: 
   - In terminal, press `q` (quit)
   - Run: `flutter run`
3. **Wait for app to load** (should see Login screen)
4. **Enter credentials**:
   - Email: `admin.leisurelyread@gmail.com`
   - Password: `AdminPassword123!` (or whatever you set in Step 3)
5. Click **Login**

### Expected Result ✅
- Should see **Admin Dashboard** with 4 tabs:
  - Users
  - Writers  
  - Books
  - Settings

### If Error ❌
- **Still seeing "Error Loading User Profile"?** → Check Firestore Rules (Step 2)
- **"user-not-found" error?** → Admin not created in Firebase Auth (Step 3)
- **"Account not found. Please sign up first"?** → Same as above

---

## 🧪 TEST: Try Creating Reader Account

1. From Login screen, click **"Sign Up"**
2. Select **"Reader"** role
3. Enter:
   - Email: `test.reader@example.com`
   - Password: `TestPass123`
   - Confirm: `TestPass123`
4. Click **Sign Up**

### Expected Result ✅
- Should see **Reader Dashboard** (home with 3 tabs: Browse, Library, Notifications)

---

## 🧪 TEST: Try Creating Writer Account

1. From Login screen, click **"Sign Up"**
2. Select **"Writer"** role
3. Enter:
   - Email: `test.writer@example.com`
   - Password: `TestPass123`
   - Confirm: `TestPass123`
   - **Writer Code**: `123456`
4. Click **Sign Up**

### Expected Result ✅
- Should see message: **"Writer account created! Waiting for admin approval."**
- Then redirect to Login screen

### Then Test Approval ✅
1. Login as admin
2. Go to **Admin Dashboard → Writers tab**
3. Find `test.writer@example.com`
4. Click ✓ (approve button)
5. Logout
6. Login as writer (`test.writer@example.com` / `TestPass123`)
7. Should see **Writer Dashboard** (with book management)

---

## 📋 Firebase Rules - Explained

The rules we added:
```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**What it means:**
- `match /{document=**}` = applies to ALL documents
- `allow read, write: if true` = anyone can read/write

**⚠️ WARNING**: This is **DEVELOPMENT ONLY**. For production, use:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own document
    match /users/{uid} {
      allow read: if request.auth.uid == uid;
      allow write: if request.auth.uid == uid;
      allow read: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    // Books are readable by all, writable by writers/admins
    match /books/{document=**} {
      allow read: if true;
      allow create, update, delete: if request.auth != null;
    }
  }
}
```

But for now, use the development rules above.

---

## ❌ Troubleshooting

| Problem | Solution |
|---------|----------|
| "Error Loading User Profile" | Firestore rules not updated - go back to Step 2 |
| "user-not-found" error | Admin not created in Firebase Auth - go back to Step 3 |
| "Account not found. Please sign up first" | Same as above |
| "PERMISSION_DENIED" | Rules haven't been published yet - wait 1-2 minutes |
| Signup works but no Firestore document created | Normal - new users auto-create document on first login |
| Can't find Firestore Database menu | Make sure you're in right project (top left shows "leisurely-read") |

---

## 📞 Need Help?

If you get stuck:

1. **Check Firestore Rules** - Are they actually published? (Look for green checkmark)
2. **Check Auth Users** - Does your admin user exist with correct email?
3. **Check Firestore Data** - Do you have a `users` collection with admin document?
4. **Restart App** - Sometimes just restarting helps
5. **Clear Cache** - In terminal: `flutter clean` then `flutter run`

---

## ✅ Success Indicators

You'll know setup is complete when:

✅ App doesn't show "Error Loading User Profile"  
✅ Can login with admin email/password  
✅ See Admin Dashboard after login  
✅ Can create new reader accounts  
✅ Can create new writer accounts  
✅ Admin can approve writer accounts  
✅ Writers can create books after approval  
✅ Readers can browse books  

---

## Next Steps (After Setup Complete)

1. Play with the app - try all features
2. Create test accounts for each role
3. Test book creation, comments, voting
4. Once happy with development:
   - Update Firestore Rules for security
   - Deploy to production

---

**Time to complete this checklist: ~5 minutes**  
**Let me know once you finish and I'll help verify everything works!**

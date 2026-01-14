# Setup & Authentication Fix Guide

## Current Issue Identified

Your admin account (`admin.leisurelyread@gmail.com`) was created in Firebase Auth, but:
1. **No Firestore document** exists for this admin user
2. **Firestore Rules** are blocking reads (showing PERMISSION_DENIED)

## QUICK FIX (3 Steps)

### Step 1: Set Firestore Rules to Test Mode

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **leisurely-read**
3. Go to: **Firestore Database** → **Rules** tab
4. Replace all content with:

```firestore
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Allow all reads and writes for now (test/development only)
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

5. Click **Publish**
6. Wait 1 minute for rules to update

### Step 2: Create Admin Firestore Document

1. Go to: **Firestore Database** → **Data** tab
2. Click **+ Start collection** (if users collection doesn't exist)
3. Collection name: `users`
4. Click **Next**
5. Document ID: `0UXrTQngUZZLgeGY5c9F9OYPgBq1` (this is your admin's UID from the auth error)
6. Add these fields:
   - `email` (string): `admin.leisurelyread@gmail.com`
   - `role` (string): `admin`
   - `isApproved` (boolean): `true`
   - `bannedUntil` (null): leave empty or null
   - `createdAt` (timestamp): select current date/time
7. Click **Save**

### Step 3: Login Again

1. Close app completely
2. Reopen app
3. Try login with:
   - **Email**: `admin.leisurelyread@gmail.com`
   - **Password**: (your password)

---

## Step-by-Step Screenshots

### A. Update Firestore Rules

**Location**: Firestore Database → Rules tab

```
From:
  (default restrictive rules)

To:
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /{document=**} {
        allow read, write: if true;
      }
    }
  }
```

**Then**: Click **Publish** (blue button)

### B. Create Users Collection + Admin Document

**Location**: Firestore Database → Data tab

**Step 1**: Click **+ Start collection**
- Collection name: `users`
- Auto-ID or custom ID: use `0UXrTQngUZZLgeGY5c9F9OYPgBq1`

**Step 2**: Add fields:

| Field | Type | Value |
|-------|------|-------|
| email | string | admin.leisurelyread@gmail.com |
| role | string | admin |
| isApproved | boolean | true |
| bannedUntil | null | (empty) |
| createdAt | timestamp | (current time) |

**Step 3**: Click **Save**

---

## Verify Setup

After completing the above, you should see in Firestore:

```
Collections:
└── users
    └── 0UXrTQngUZZLgeGY5c9F9OYPgBq1
        ├── email: "admin.leisurelyread@gmail.com"
        ├── role: "admin"
        ├── isApproved: true
        ├── bannedUntil: null
        └── createdAt: 2026-01-14 12:00:00
```

---

## Now Try These in App

### 1. Admin Login
- **Email**: `admin.leisurelyread@gmail.com`
- **Password**: (your password)
- Should go to **Admin Dashboard**

### 2. Create Reader Account
- Click "Sign Up"
- Select: **Reader**
- Email: `reader@test.com`
- Password: `password123`
- Confirm: `password123`
- Click Sign Up
- Should go to **Reader Dashboard**

### 3. Create Writer Account
- Click "Sign Up"
- Select: **Writer**
- Email: `writer@test.com`
- Password: `password123`
- Confirm: `password123`
- Code: `123456`
- Click Sign Up
- Should see "Writer account created! Waiting for admin approval."
- Click back to Login

### 4. Approve Writer (as Admin)
- Login as admin
- Go to **Admin Dashboard** → **Writers** tab
- Find `writer@test.com`
- Click ✓ button to approve
- Logout

### 5. Login as Writer
- Login with `writer@test.com` / `password123`
- Should go to **Writer Dashboard**
- Can now create books

---

## If Still Getting Errors

### Check Firestore Rules
1. Go to Firestore Database → Rules tab
2. Rules must start with: `rules_version = '2';`
3. Must have: `allow read, write: if true;`

### Check Admin Document
1. Go to Firestore → Data tab
2. Click users collection
3. Should see document with ID: `0UXrTQngUZZLgeGY5c9F9OYPgBq1`
4. Document should have all 5 fields

### Clear App Cache (Nuclear Option)
1. Stop Flutter app (press `q` in terminal)
2. Delete app from emulator
3. Run: `flutter run` again
4. Try login

---

## Common Issues After Setup

| Issue | Solution |
|-------|----------|
| "PERMISSION_DENIED" | Check Firestore Rules (should allow all) |
| "user-not-found" | Admin user wasn't created in Firebase Auth |
| "wrong-password" | Password doesn't match what's in Firebase Auth |
| "Type cast error" | Firestore users document is malformed or missing |
| "Account created but can't login" | Firestore document wasn't created for new user |

---

## Security Note

⚠️ **IMPORTANT**: The rule `allow read, write: if true;` allows ANYONE to read/write your database. This is for **testing/development ONLY**.

For production, set proper security rules like:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
      allow read: if request.auth.uid != null;
    }
    match /books/{document=**} {
      allow read: if true;
      allow create: if request.auth.uid != null && 
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'writer';
      allow delete: if request.auth.uid != null && 
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

But for now, use the test mode rules above.

---

**After setting up rules and creating admin document, restart the app and login should work!**

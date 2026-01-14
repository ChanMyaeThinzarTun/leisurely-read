# Admin Account Setup Instructions

## ⚠️ Important: Initial Admin Creation

The app requires ONE admin account that must be set up **manually** in Firebase, not through the app signup.

## Step-by-Step Setup

### Step 1: Create Admin User in Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **leisurely-read**
3. Navigate to: **Authentication** → **Users** tab
4. Click **+ Create user** button
5. Enter:
   - **Email**: `admin.leisurelyread@gmail.com`
   - **Password**: (your desired secure password)
6. Click **Create user**

### Step 2: Set Admin Role in Firestore

1. Navigate to: **Firestore Database** → **Collections**
2. Click on **users** collection
3. Find the document matching your admin UID (you'll see it in the list)
4. Edit the document and change:
   ```
   role: "admin"  (change from "reader" to "admin")
   isApproved: true
   ```
5. **Save**

### Step 3: Login in App

Now you can login with:
- **Email**: `admin.leisurelyread@gmail.com`
- **Password**: (your password from step 1)

---

## Creating Test Users in App

Once admin is set up, you can create other accounts directly in the app:

### Create Reader Account
1. Click "Sign Up" on login screen
2. Select role: **Reader**
3. Enter email and password
4. Click Sign Up
5. Auto-logged in as reader

### Create Writer Account
1. Click "Sign Up" on login screen
2. Select role: **Writer**
3. Enter email, password, and **code: `123456`**
4. Click Sign Up
5. You'll see "Pending approval" screen
6. Switch to admin account
7. Go to **Admin Dashboard** → **Writers** tab
8. Find the writer and click ✓ to approve

---

## Common Issues

### "Wrong email/password"
- **Solution**: Make sure admin user was created in Firebase Auth (Step 1)
- Check that you're using the exact email: `admin.leisurelyread@gmail.com`
- Verify password is correct

### "Cannot create user account"
- **Solution 1**: Ensure you're on the Signup screen (click "Sign Up" link)
- **Solution 2**: Fill all fields (email, password, confirm password)
- **Solution 3**: For Writer, also enter code: `123456`
- **Solution 4**: Check that you have internet connection

### "Account created but can't login"
- **Reason**: Most common - admin role not set in Firestore
- **Solution**: Follow Step 2 above to set admin role

### "Writer signup shows 'Invalid code'"
- **Solution**: Make sure you entered exactly: `123456`
- To change code, edit: `lib/services/auth_service.dart` line ~8

---

## Firestore Document Structure

After setup, your admin document should look like:

```json
{
  "uid": "YOUR_UID",
  "email": "admin.leisurelyread@gmail.com",
  "role": "admin",
  "isApproved": true,
  "bannedUntil": null,
  "createdAt": "2026-01-14T12:00:00Z"
}
```

---

## Fresh Start (if needed)

If you want to start completely fresh:

1. Delete the admin user from Firebase Auth
2. Delete all documents in Firestore collections
3. Start over with Step 1 above

---

**After admin setup is complete, you can use the app fully!**

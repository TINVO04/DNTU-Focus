# DNTU-Focus

This Flutter project uses Cloud Firestore for storing tasks and pomodoro sessions. Some queries combine multiple fields and require composite indexes. If these indexes are missing you may see errors such as:

```
PlatformException(firebase_firestore, FAILED_PRECONDITION: The query requires an index.)
```

Make sure the Firestore indexes are deployed before running the app:

```bash
firebase deploy --only firestore:indexes
```

The required indexes are defined in `dntu_focus/firestore.indexes.json`.

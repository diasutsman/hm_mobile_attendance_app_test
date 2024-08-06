# Attendance Mobile (HashMicro Test)

With this question prompt:
```
Buat 1 applikasi di flutter, untuk mobile attendance,

di mana ada:
1. Create master data lokasi, lokasinya lalu geotagging untuk dapat pin locationnya
2. Ada data attendance, di mana user bisa create atttendance baru dengan track GPS locaation nya apakah dia di pin location nya atau tidak

jika > 50 meter dari pin lcoation, maka reject attendancenya

Mohon Mengumpulkan Hasil test dalam bentuk APK dan Source Code kemudian dikirim kembali melalui Whatsapp.

```

## How to run

### For Android
1. Add this to `android/local.properties`
   
   ```google.map.api_key=<GOOGLE-MAP-API-KEY>```

   visit this link to know the details to get the google map trial api key: https://pub.dev/packages/google_maps_flutter#getting-started

### For IOS
Because lack of device to test the app, please visit this link to setup the project: https://pub.dev/packages/google_maps_flutter#ios
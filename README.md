This is a code snippet prototype to test out SQLLite and a phone App

Production note on env secrets:
dotenv (.env) in ADK is bad juju (security risk)
1.Remove .env from pubspec.yaml assets'
2.Use --dart-define for builds or a secure config service
  Consider separate development/staging/production MongoDB clusters
   Look into Flutter flavors for different environments

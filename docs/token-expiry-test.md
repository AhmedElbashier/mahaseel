# Logout on Token Expiry

Steps to manually verify that the application logs out when the JWT token becomes invalid:

1. Launch the app and sign in using a valid phone number and OTP.
2. After reaching any authenticated screen, revoke the token from the backend or modify it in secure storage to simulate expiry.
3. Trigger a network request (e.g. pull to refresh on the crops list).
4. The API client should receive a 401/403 response, clear the token and the user is redirected back to the login screen.
5. Confirm that the secure storage no longer contains the previous token.

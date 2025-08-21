# WhatsApp Deep-Link Flow

This document outlines the user experience (UX) for contacting a farmer through a WhatsApp deep link from within Mahaseel.

## Steps

1. **Select listing** – The buyer browses crops and taps **Contact via WhatsApp** on the listing page.
2. **Generate deep link** – The app constructs a URL of the form:
   ```
   https://wa.me/<phone>?text=<encoded message>
   ```
   The message includes the crop name and a short greeting.
3. **Open WhatsApp** – If WhatsApp is installed, the user is taken straight to a chat with the seller. Otherwise the browser opens the WhatsApp download page.
4. **Send message** – The buyer can edit the pre‑filled message and press send.
5. **Return to Mahaseel** – After the conversation, the user can switch back to Mahaseel to continue browsing or manage orders.

## Error States
- If the phone number is invalid, the app displays a toast and does not open the link.
- If deep linking fails, the app prompts the user to copy the phone number manually.


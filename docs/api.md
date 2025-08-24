# Mahaseel API Documentation

Base URL: `https://staging.mahaseel.com`

## Authentication

### Register
`POST /auth/register`

```json
{
  "phone": "+249900000000",
  "name": "Ahmed"
}
Login

POST /auth/login

Returns JWT after OTP verification.

Crops
List Crops

GET /crops?page=1&limit=20

Create Crop

POST /crops

{
  "name": "طماطم",
  "type": "خضار",
  "qty": 100,
  "price": 500,
  "unit": "كيلو",
  "location": { "lat": 15.6, "lng": 32.5 },
  "notes": "عضوي"
}

Orders

POST /orders

{
  "crop_id": 1,
  "qty": 10,
  "note": "أحتاج توصيل"
}

Ratings

POST /ratings

{
  "seller_id": 2,
  "stars": 5
}

Media Upload

POST /media (multipart/form-data)


3. Link to your live Swagger/OpenAPI UI:
```markdown
👉 Full interactive docs available at: [API Docs](https://mahaseel-backend-staging.onrender.com/docs)
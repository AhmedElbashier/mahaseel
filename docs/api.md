# Mahaseel API Documentation

Base URL: `https://staging.mahaseel.com/api/v1`

## Authentication

### Register
`POST /api/v1/auth/register`

```json
{
  "phone": "+249900000000",
  "name": "Ahmed"
}
Login

POST /api/v1/auth/login

Returns JWT after OTP verification.

Crops
List Crops

GET /api/v1/crops?page=1&limit=20

Create Crop

POST /api/v1/crops

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

POST /api/v1/orders

{
  "crop_id": 1,
  "qty": 10,
  "note": "أحتاج توصيل"
}

Ratings

POST /api/v1/ratings

{
  "seller_id": 2,
  "stars": 5
}

Media Upload

POST /api/v1/media (multipart/form-data)


3. Link to your live Swagger/OpenAPI UI:
```markdown
👉 Full interactive docs available at: [API Docs](https://mahaseel-backend-staging.onrender.com/docs)
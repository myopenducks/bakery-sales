# 🥖 Bakery Sales Management System

A full-stack, production-ready Sales and Operations Management system designed for artisanal bakeries supplying traditional Algerian sweets, breads, Msemmen, and Trid to local cafés.

Developed by **Ziad**.

---

## 🏗️ Tech Stack

- **Backend**: Fastify v5 (TypeScript), Drizzle ORM, MySQL 8, Fastify JWT, Fastify CORS, Argon2 password hashing.
- **Mobile & Web**: Flutter 3 (Material 3), Riverpod 2, GoRouter, Dio HTTP Client, Google Fonts (Outfit).

---

## 🚀 Railway Deployment Guide (Backend)

1. **Create a MySQL Service** on [Railway](https://railway.app):
   - Add a new MySQL Database.
   - Note the `DATABASE_URL` variable provided by Railway (e.g. `mysql://root:password@host:port/railway`).

2. **Deploy the Backend Service**:
   - Connect this GitHub repository to Railway.
   - Set the **Root Directory** to `/backend` (or deploy with Dockerfile in `backend/`).
   - Configure Environment Variables:
     - `DATABASE_URL`: `${{MySQL.DATABASE_URL}}`
     - `JWT_SECRET`: `your_secure_random_jwt_secret_key`
     - `PORT`: `3000` (or Railway dynamic `$PORT`)
     - `HOST`: `0.0.0.0`
   - Run database migration and admin seed:
     ```bash
     npm run db:migrate
     npm run db:seed
     ```

---

## 💻 Local Development

### 1. Backend

```bash
cd backend
npm install

# Configure .env
DATABASE_URL=mysql://root:1234@127.0.0.1:3306/bakery_sales
JWT_SECRET=your_jwt_secret_key
PORT=3000

# Run migrations & seed admin
npm run db:migrate
npm run db:seed

# Start development server
npm run dev
```

Default Admin Credentials:
- **Username**: `admin`
- **Password**: `admin123`

### 2. Flutter Mobile / Web

```bash
cd mobile
flutter pub get
flutter run -d chrome
```

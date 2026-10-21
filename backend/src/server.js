import app from './app.js';
import { env } from './config/env.js';

app.listen(env.port, () => {
  console.log(`Bebaca API berjalan di http://localhost:${env.port}`);
  console.log(`Dokumentasi Swagger: http://localhost:${env.port}/docs`);
});

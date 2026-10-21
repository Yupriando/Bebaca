import { ZodError } from 'zod';
import { HttpError } from '../utils/errors.js';

export function notFound(req, res) {
  res.status(404).json({ message: 'Endpoint tidak ditemukan' });
}

// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, next) {
  if (err instanceof ZodError) {
    return res.status(400).json({
      message: err.issues[0]?.message ?? 'Data tidak valid',
      errors: err.issues.map((i) => ({ field: i.path.join('.'), message: i.message })),
    });
  }
  if (err instanceof HttpError) {
    const body = { message: err.message };
    if (err.detail && process.env.NODE_ENV !== 'production') body.detail = err.detail;
    return res.status(err.status).json(body);
  }
  if (err.name === 'MulterError') {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(413).json({ message: 'Ukuran foto maksimal 2 MB' });
    }
    return res.status(400).json({ message: 'Upload foto tidak valid' });
  }
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ message: 'Format JSON tidak valid' });
  }
  console.error(err);
  res.status(500).json({ message: 'Terjadi kesalahan pada server' });
}

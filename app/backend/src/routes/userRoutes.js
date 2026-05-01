const express = require('express');
const { body, param, validationResult } = require('express-validator');
const db = require('../config/database.js');

const router = express.Router();

// GET /api/users - List users
router.get('/', async (req, res, next) => {
  try {
    const { page = 1, limit = 10, search } = req.query;
    const offset = (page - 1) * limit;

    let query = 'SELECT * FROM users WHERE 1=1';
    let countQuery = 'SELECT COUNT(*) as count FROM users WHERE 1=1';
    let params = [];

    if (search) {
      query += ' AND (name LIKE ? OR email LIKE ?)';
      countQuery += ' AND (name LIKE ? OR email LIKE ?)';
      const s = `%${search}%`;
      params = [s, s];
    }

    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), parseInt(offset));

    db.all(query, params, (err, rows) => {
      if (err) return next(err);
      
      db.get(countQuery, params.slice(0, params.length - 2), (err, count) => {
        if (err) return next(err);
        res.json({
          data: rows,
          pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total: count.count,
            pages: Math.ceil(count.count / parseInt(limit))
          }
        });
      });
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/users - Create user
router.post('/',
  [
    body('name').trim().isLength({ min: 2 }).withMessage('Name must be at least 2 characters'),
    body('email').isEmail().normalizeEmail().withMessage('Valid email required'),
    body('age').isInt({ min: 0, max: 120 }).withMessage('Age must be 0-120')
  ],
  (req, res, next) => {
  const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ error: 'Validation failed', details: errors.array() });
    }

    const { name, email, age } = req.body;

    db.run(
      'INSERT INTO users (name, email, age) VALUES (?, ?, ?)',
      [name, email, age],
      function(err) {
        if (err && err.code === 'SQLITE_CONSTRAINT') {
          return res.status(409).json({
            error: 'Conflict',
            details: 'Email already exists - please use a unique email address'
          });
        }
        if (err) return next(err);
        res.status(201).json({
          id: this.lastID,
          name,
          email,
          age,
          message: 'User created successfully!'
        });
      }
    );
  }
);

// GET /api/users/:id
router.get('/:id',
  [param('id').isInt().withMessage('Valid ID required')],
  (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return next({ status: 400, message: errors.array() });

    const { id } = req.params;

    db.get('SELECT * FROM users WHERE id = ?', [id], (err, row) => {
      if (err) return next(err);
      if (!row) return res.status(404).json({ error: 'User not found' });
      res.json(row);
    });
  }
);

// PUT /api/users/:id
router.put('/:id',
  [
    param('id').isInt(),
    body('name').optional().trim().isLength({ min: 2 }),
    body('email').optional().isEmail().normalizeEmail(),
    body('age').optional().isInt({ min: 0, max: 120 })
  ],
  (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return next({ status: 400, message: errors.array() });

    const { id } = req.params;
    const { name, email, age } = req.body;

    const updates = [];
    const values = [];
    if (name !== undefined) { updates.push('name = ?'); values.push(name); }
    if (email !== undefined) { updates.push('email = ?'); values.push(email); }
    if (age !== undefined) { updates.push('age = ?'); values.push(age); }
    values.push(id);

    if (updates.length === 0) {
      // Allow no changes - refetch current user
      db.get('SELECT * FROM users WHERE id = ?', [id], (err, row) => {
        if (err) return next(err);
        if (!row) return res.status(404).json({ error: 'User not found' });
        res.json({ message: 'No changes made', user: row });
      });
      return;
    }

    db.run(
      `UPDATE users SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE id = ?`,
      values,
      function(err) {
        if (err) return next(err);
        if (this.changes === 0) return res.status(404).json({ error: 'User not found' });
        res.json({ message: 'User updated successfully', changes: this.changes });
      }
    );
  }
);

// DELETE /api/users/:id
router.delete('/:id',
  [param('id').isInt()],
  (req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return next({ status: 400, message: errors.array() });

    const { id } = req.params;

    db.run('DELETE FROM users WHERE id = ?', [id], function(err) {
      if (err) return next(err);
      if (this.changes === 0) return res.status(404).json({ error: 'User not found' });
      res.json({ message: 'User deleted successfully', deleted: this.changes });
    });
  }
);

module.exports = router;


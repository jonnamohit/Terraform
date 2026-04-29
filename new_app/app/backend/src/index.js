require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const helmet = require('helmet');
const compression = require('compression');
const errorHandler = require('./middleware/errorHandler.js');
const userRoutes = require('./routes/userRoutes.js');
const db = require('./config/database.js');

const app = express();
const PORT = process.env.PORT || 3001;  // Changed to 3001 to avoid conflicts

// DB already connected in config/database.js

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors({
  origin: process.env.NODE_ENV === 'production' ? false : 'http://localhost:5173'
}));
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => res.json({ status: 'OK', timestamp: new Date().toISOString() }));

// Routes
app.use('/api/users', userRoutes);

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use(errorHandler);

const server = app.listen(PORT, () => {
  console.log(`🚀 Professional Backend running on http://localhost:${PORT}`);
  console.log(`📊 Health: http://localhost:${PORT}/health`);
});

module.exports = server;


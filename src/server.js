const express = require('express')
const mongoose = require('mongoose')
const cors = require('cors')
require('dotenv').config()

const todosRouter = require('./routes/todos')

const app = express()
const PORT = process.env.PORT || 3000
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://todo-mongo:27017/todos'

// Middleware
app.use(cors())
app.use(express.json())
app.use(express.urlencoded({ extended: true }))

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'todo-api'
  })
})

// Mount API routes
app.use('/api/todos', todosRouter)

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' })
})

// ⚠️ ERROR HANDLER - MUST HAVE EXACTLY 4 PARAMETERS ⚠️
// This is the key fix for "next is not a function"
app.use((err, req, res, next) => {
  console.error('❌ Error:', err.message)
  console.error(err.stack)
  
  res.status(err.status || 500).json({
    error: err.message || 'Internal server error'
  })
})

// Connect to MongoDB and start server
mongoose.connect(MONGODB_URI)
  .then(() => {
    console.log('✅ MongoDB connected successfully')
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 Server running on port ${PORT}`)
      console.log(`📍 Health: http://localhost:${PORT}/health`)
    })
  })
  .catch(err => {
    console.error('❌ MongoDB connection error:', err.message)
    process.exit(1)
  })

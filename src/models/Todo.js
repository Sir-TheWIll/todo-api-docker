const mongoose = require('mongoose')

const todoSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Title is required'],
    trim: true,
    maxlength: [200, 'Title cannot exceed 200 characters']
  },
  completed: {
    type: Boolean,
    default: false
  },
  completedAt: {
    type: Date,
    default: null
  }
}, {
  timestamps: true // Adds createdAt and updatedAt automatically
})

// Pre-save middleware - MUST use function keyword, NOT arrow function
todoSchema.pre('save', function(next) {
  // Update timestamps are handled by timestamps: true option
  
  // Set completedAt when todo is marked complete
  if (this.completed && !this.completedAt) {
    this.completedAt = new Date()
  }
  
  // Clear completedAt when todo is marked incomplete
  if (!this.completed && this.completedAt) {
    this.completedAt = null
  }
  
  // ⚠️ CRITICAL: Call next() to continue with save operation
  next()
})

module.exports = mongoose.model('Todo', todoSchema)

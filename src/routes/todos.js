const express = require('express')
const router = express.Router()
const Todo = require('../models/Todo')

// GET ALL TODOS
router.get('/', async (req, res, next) => {
  try {
    const todos = await Todo.find().sort({ createdAt: -1 })
    res.json(todos)
  } catch (err) {
    next(err)
  }
})

// GET SINGLE TODO
router.get('/:id', async (req, res, next) => {
  try {
    const todo = await Todo.findById(req.params.id)
    if (!todo) {
      return res.status(404).json({ error: 'Todo not found' })
    }
    res.json(todo)
  } catch (err) {
    next(err)
  }
})

// CREATE TODO
router.post('/', async (req, res, next) => {
  try {
    if (!req.body.title || req.body.title.trim() === '') {
      return res.status(400).json({ error: 'Title is required' })
    }
    
    const todo = new Todo({
      title: req.body.title.trim(),
      completed: req.body.completed || false
    })
    
    await todo.save()
    res.status(201).json(todo)
  } catch (err) {
    next(err)
  }
})

// UPDATE TODO
router.put('/:id', async (req, res, next) => {
  try {
    const todo = await Todo.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    )
    
    if (!todo) {
      return res.status(404).json({ error: 'Todo not found' })
    }
    
    res.json(todo)
  } catch (err) {
    next(err)
  }
})

// DELETE TODO
router.delete('/:id', async (req, res, next) => {
  try {
    const todo = await Todo.findByIdAndDelete(req.params.id)
    
    if (!todo) {
      return res.status(404).json({ error: 'Todo not found' })
    }
    
    res.json({ message: 'Todo deleted successfully' })
  } catch (err) {
    next(err)
  }
})

module.exports = router

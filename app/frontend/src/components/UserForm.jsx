import { useState, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'

function UserForm({ initialData, onSubmit, isLoading, submitLabel = 'Create User' }) {
  const navigate = useNavigate()
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    age: '',
  })
  const [errors, setErrors] = useState({})
  const isEdit = !!initialData

  useEffect(() => {
    if (initialData) {
      setFormData({
        name: initialData.name || '',
        email: initialData.email || '',
        age: initialData.age || '',
      })
      setErrors({})
    } else {
      setFormData({
        name: '',
        email: '',
        age: '',
      })
    }
  }, [initialData])

  const validateForm = () => {
    const newErrors = {}

    if (!formData.name.trim()) newErrors.name = 'Name is required'
    else if (formData.name.trim().length < 2) newErrors.name = 'Name must be at least 2 characters'

    if (!formData.email) newErrors.email = 'Email is required'
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) newErrors.email = 'Invalid email format'

    if (!formData.age) newErrors.age = 'Age is required'
    else if (isNaN(formData.age) || Number(formData.age) < 0 || Number(formData.age) > 120) {
      newErrors.age = 'Age must be between 0 and 120'
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleChange = (e) => {
    const { name, value } = e.target
    setFormData(prev => ({ ...prev, [name]: value }))
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }))
    }
  }

  const handleSubmit = (e) => {
    e.preventDefault()
    if (validateForm()) {
      onSubmit(formData)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div>
        <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-2">
          Full Name
        </label>
        <input
          type="text"
          id="name"
          name="name"
          value={formData.name}
          onChange={handleChange}
          className={`w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 ${
            errors.name ? 'border-red-500' : 'border-gray-300'
          }`}
          placeholder="John Doe"
        />
        {errors.name && <p className="mt-1 text-sm text-red-600">{errors.name}</p>}
      </div>

      <div>
        <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
          Email
        </label>
        <input
          type="email"
          id="email"
          name="email"
          value={formData.email}
          onChange={handleChange}
          className={`w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 ${
            errors.email ? 'border-red-500' : 'border-gray-300'
          }`}
          placeholder="john@example.com"
        />
        {errors.email && <p className="mt-1 text-sm text-red-600">{errors.email}</p>}
      </div>

      <div>
        <label htmlFor="age" className="block text-sm font-medium text-gray-700 mb-2">
          Age
        </label>
        <input
          type="number"
          id="age"
          name="age"
          value={formData.age}
          onChange={handleChange}
          min="0"
          max="120"
          className={`w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 ${
            errors.age ? 'border-red-500' : 'border-gray-300'
          }`}
          placeholder="25"
        />
        {errors.age && <p className="mt-1 text-sm text-red-600">{errors.age}</p>}
      </div>

      <div className="flex space-x-4">
        <button
          type="submit"
          disabled={isLoading}
          className={`flex-1 px-6 py-3 font-medium text-white rounded-lg shadow-md transition-all ${
            isLoading
              ? 'bg-gray-400 cursor-not-allowed'
              : 'bg-emerald-500 hover:bg-emerald-600 focus:ring-4 focus:ring-emerald-300'
          }`}
        >
          {isLoading ? 'Saving...' : submitLabel}
        </button>
        <button
          type="button"
          onClick={() => navigate('/')}
          className="flex-1 px-6 py-3 font-medium border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 focus:ring-4 focus:ring-emerald-300 transition-all"
          disabled={isLoading}
        >
          Cancel
        </button>
      </div>
    </form>
  )
}

export default UserForm


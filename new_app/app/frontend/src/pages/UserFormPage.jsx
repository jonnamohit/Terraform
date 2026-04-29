import { useState } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import axios from 'axios'
import UserForm from '../components/UserForm.jsx'

const API_BASE = import.meta.env.VITE_API_URL || '/api'

function UserFormPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const isEdit = !!id
  const [error, setError] = useState('')

const queryClient = useQueryClient()
  const { data: user, error: fetchError } = useQuery({
    queryKey: ['user', id],
    queryFn: () => axios.get(`${API_BASE}/users/${id}`).then(res => res.data),
    enabled: isEdit,
  })

  const createMutation = useMutation({
    mutationFn: (data) => axios.post(`${API_BASE}/users`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] })
      navigate('/', { replace: true })
    },
    onError: (err) => setError(err.response?.data?.error || err.message || 'Failed to create'),
  })

  const updateMutation = useMutation({
    mutationFn: (data) => axios.put(`${API_BASE}/users/${id}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] })
      navigate('/', { replace: true })
    },
    onError: (err) => setError(err.response?.data?.error || err.message || 'Failed to update'),
  })

  const handleSubmit = (formData) => {
    setError('')
    if (isEdit) {
      updateMutation.mutate(formData)
    } else {
      createMutation.mutate(formData)
    }
  }

  const loading = createMutation.isPending || updateMutation.isPending || (isEdit && !user)

  if (fetchError) {
    return <div className="flex flex-col items-center justify-center h-64 text-red-600">
      <h2 className="text-2xl font-bold mb-4">Load Error</h2>
      <p>{fetchError.response?.data?.error || fetchError.message}</p>
      <button onClick={() => window.location.reload()} className="mt-4 px-6 py-2 bg-emerald-500 text-white rounded-xl hover:bg-emerald-600">
        Retry
      </button>
    </div>
  }

  return (
    <div className="max-w-2xl mx-auto">
      <div className="bg-white rounded-3xl p-12 shadow-2xl border border-slate-200">
        {error && (
          <div className="p-6 mb-8 bg-red-50 border-2 border-red-200 rounded-2xl text-red-800 font-semibold text-lg">
            {error}
            <button onClick={() => setError('')} className="ml-4 text-2xl hover:scale-110">✕</button>
          </div>
        )}
        <UserForm
          initialData={user}
          onSubmit={handleSubmit}
          isLoading={loading}
          submitLabel={isEdit ? 'Update User' : 'Create User'}
        />
      </div>
    </div>
  )
}

export default UserFormPage


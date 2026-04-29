import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { useAuth } from '../context/AuthContext.jsx'

function LoginPage() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const { login } = useAuth()
  const navigate = useNavigate()

  const handleSubmit = (e) => {
    e.preventDefault()
    setLoading(true)
    setError('')

    // Demo login
    if (login(email, password)) {
      navigate('/')
    } else {
      setError('Invalid credentials. Demo: admin@example.com / admin')
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-900 to-emerald-900 p-8">
      <div className="w-full max-w-md">
        <div className="card bg-white/10 backdrop-blur-xl p-8 rounded-3xl border border-white/20 shadow-2xl">
          <div className="text-center mb-8">
            <h1 className="text-4xl font-black bg-gradient-to-r from-emerald-400 to-white bg-clip-text text-transparent mb-2">Users Pro</h1>
            <p className="text-slate-300">Sign in to manage users</p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label className="block text-sm font-semibold text-slate-200 mb-2">Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full p-4 bg-white/20 border border-white/30 rounded-2xl text-white placeholder-slate-400 focus:ring-4 focus:ring-emerald-500/50 focus:border-transparent transition-all"
                placeholder="admin@example.com"
                required
              />
            </div>

            <div>
              <label className="block text-sm font-semibold text-slate-200 mb-2">Password</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full p-4 bg-white/20 border border-white/30 rounded-2xl text-white placeholder-slate-400 focus:ring-4 focus:ring-emerald-500/50 focus:border-transparent transition-all"
                placeholder="admin"
                required
              />
            </div>

            {error && (
              <div className="p-4 bg-red-500/20 border border-red-500/50 rounded-2xl text-red-200 text-sm">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full p-4 bg-gradient-to-r from-emerald-500 to-emerald-600 text-white font-bold text-lg rounded-2xl shadow-xl hover:from-emerald-600 hover:to-emerald-700 transform hover:scale-[1.02] transition-all focus:outline-none focus:ring-4 focus:ring-emerald-500/50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? 'Signing In...' : 'Sign In'}
            </button>
          </form>

          <p className="text-center mt-6 text-sm text-slate-400">
            Demo: <strong>admin@example.com</strong> / <strong>admin</strong>
          </p>
        </div>
      </div>
    </div>
  )
}

export default LoginPage


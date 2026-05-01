import { createContext, useContext, useState, useEffect } from 'react'

const AuthContext = createContext()

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Check localStorage for token
    const token = localStorage.getItem('token')
    if (token) {
      // Fake verify
      setUser({ name: 'Admin' })
    }
    setLoading(false)
  }, [])

  const login = (email, password) => {
    // Demo creds
    if (email === 'admin@example.com' && password === 'admin') {
      localStorage.setItem('token', 'demo-jwt-token')
      setUser({ name: 'Admin', email })
      return true
    }
    return false
  }

  const logout = () => {
    localStorage.removeItem('token')
    setUser(null)
  }

  const value = {
    user,
    login,
    logout,
    isAuthenticated: !!user,
    loading
  }

  return (
    <AuthContext.Provider value={value}>
      {!loading && children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider')
  }
  return context
}


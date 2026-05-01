import { Outlet, Link } from 'react-router-dom'
import { useAuth } from '../context/AuthContext.jsx'

function Layout() {
  const { user, logout } = useAuth()

  return (
    <div className="flex h-screen bg-gradient-to-b from-emerald-50 to-slate-100">
      {/* Sidebar */}
      <aside className="w-64 bg-white shadow-2xl border-r-emerald-200 flex flex-col">
        <div className="p-6 border-b">
          <h1 className="text-2xl font-black bg-gradient-to-r from-emerald-600 to-emerald-800 bg-clip-text text-transparent">Users Pro</h1>
          <p className="text-xs text-emerald-700 mt-1 font-medium uppercase tracking-wider">Admin Panel</p>
        </div>
        <nav className="flex-1 p-4 space-y-2">
          <div className="p-3 rounded-xl bg-emerald-100 text-emerald-800 font-semibold mb-4">
            Welcome, {user?.name || 'Admin'}
          </div>
          <Link to="/" className="flex items-center space-x-3 p-3 rounded-xl hover:bg-emerald-100 transition-all font-semibold text-emerald-800 hover:shadow-md">
            <span className="w-8 h-8 bg-emerald-500 rounded-lg flex items-center justify-center text-white font-bold text-sm">👥</span>
            <span>All Users</span>
          </Link>
          <Link to="/users/new" className="flex items-center space-x-3 p-3 rounded-xl shadow-lg transform hover:scale-105 bg-emerald-500 text-white hover:bg-emerald-600">
            <span className="w-8 h-8 bg-white rounded-lg flex items-center justify-center text-emerald-500 font-bold text-sm shadow-md">+</span>
            <span>Add New</span>
          </Link>
          <button onClick={logout} className="flex items-center space-x-3 p-3 rounded-xl hover:bg-red-100 transition-all font-semibold text-red-700 hover:shadow-md w-full text-left mt-auto">
            <span className="w-8 h-8 bg-red-500 rounded-lg flex items-center justify-center text-white font-bold text-sm">🚪</span>
            <span>Logout</span>
          </button>
        </nav>
      </aside>

      {/* Main Content */}
      <div className="flex-1 flex flex-col overflow-hidden">
        <main className="flex-1 overflow-y-auto p-8">
          <div className="max-w-5xl mx-auto">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  )
}

export default Layout

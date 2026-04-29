import { Link } from 'react-router-dom'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import axios from 'axios'

const API_BASE = import.meta.env.VITE_API_URL || '/api'

function UserList({ users }) {
  const queryClient = useQueryClient()

  const deleteMutation = useMutation({
    mutationFn: async (id) => {
      await axios.delete(`${API_BASE}/users/${id}`)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] })
    },
  })

  const usersList = users || []

  // Sort by created_at ASC (first created first)
  const sortedUsers = [...usersList].sort((a, b) => new Date(a.created_at) - new Date(b.created_at))

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 max-h-[70vh] overflow-y-auto pr-2 [&::-webkit-scrollbar]:w-1.5 [&::-webkit-scrollbar-track]:bg-slate-100 [&::-webkit-scrollbar-thumb]:rounded-full [&::-webkit-scrollbar-thumb]:bg-slate-400">
      {sortedUsers.map((user, index) => {
        const sno = index + 1
        return (
          <div key={user.id} className="group bg-white/80 backdrop-blur-sm border border-slate-200 rounded-xl p-5 hover:shadow-lg hover:border-slate-300 hover:shadow-slate-100 transition-all duration-200 relative overflow-hidden h-48 flex flex-col justify-between">
            {/* S.No badge top-right */}
            <div className="absolute top-2 right-3 z-10 bg-gradient-to-r from-slate-500 to-slate-600 text-white font-bold text-xs w-7 h-7 rounded-full flex items-center justify-center shadow-md ring-1 ring-white drop-shadow-sm">
              {sno}
            </div>
            
            {/* Main content */}
            <div className="relative z-0 space-y-2">
              <h3 className="font-semibold text-slate-900 text-base line-clamp-1 group-hover:text-slate-700">
                {user.name}
              </h3>
              <p className="text-xs text-slate-600 line-clamp-1">{user.email}</p>
              <div className="flex items-center gap-3 pt-1 text-xs">
                <span className="font-bold text-slate-900 px-2 py-1 bg-slate-100 rounded-md">{user.age}</span>
                <span className="text-slate-500">
                  {new Date(user.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })}
                </span>
              </div>
            </div>

            {/* Compact actions */}
            <div className="flex gap-1.5 pt-2 border-t border-slate-100/50">
              <Link
                to={`/users/${user.id}/edit`}
                className="flex-1 py-1.5 px-2 text-xs font-medium text-emerald-600 bg-emerald-50 border rounded-lg hover:bg-emerald-100 focus:outline-none focus:ring-1 focus:ring-emerald-300 transition-colors flex items-center justify-center gap-1"
                title="Edit User"
              >
                ✏️
              </Link>
              <button
                onClick={() => deleteMutation.mutate(user.id)}
                disabled={deleteMutation.isPending}
                className="flex-1 py-1.5 px-2 text-xs font-medium text-red-600 bg-red-50 border rounded-lg hover:bg-red-100 focus:outline-none focus:ring-1 focus:ring-red-300 transition-colors flex items-center justify-center gap-1 disabled:opacity-50"
                title="Delete User"
              >
                🗑️
              </button>
            </div>
          </div>
        )
      })}
      
      {sortedUsers.length === 0 && (
        <div className="col-span-full flex flex-col items-center justify-center py-12 border-2 border-dashed border-slate-300/50 rounded-2xl bg-slate-50/50">
          <div className="w-16 h-16 mb-4 bg-slate-200 rounded-xl flex items-center justify-center shadow-md">
            👥
          </div>
          <h3 className="text-lg font-semibold text-slate-900 mb-2">No users</h3>
          <p className="text-sm text-slate-600 mb-4 text-center">Add your first team member</p>
          <Link to="/users/new" className="px-6 py-2 bg-emerald-500 hover:bg-emerald-600 text-white text-sm font-semibold rounded-xl shadow-md hover:shadow-lg transition-all flex items-center gap-1.5">
            ➕ Add User
          </Link>
        </div>
      )}
      
      {/* Compact scroll button */}
      {sortedUsers.length > 12 && (
        <div className="col-span-full flex justify-center pb-4">
          <button 
            onClick={() => document.querySelector('div[class*=\"overflow-y-auto\"]')?.scrollTo({ top: 0, behavior: 'smooth' })}
            className="p-2 rounded-full bg-white/70 hover:bg-white border border-slate-200 shadow-sm hover:shadow-md transition-all text-slate-600 hover:text-slate-800 text-sm font-medium"
            title="Scroll to top"
          >
            ↑
          </button>
        </div>
      )}
    </div>
  )
}

export default UserList


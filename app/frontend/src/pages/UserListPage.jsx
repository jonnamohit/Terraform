import { useQuery } from '@tanstack/react-query'
import { useEffect, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import UserList from '../components/UserList.jsx'
import { Link } from 'react-router-dom'
import axios from 'axios'
import useDebounce from '../hooks/useDebounce.js'

const API_BASE = import.meta.env.VITE_API_URL || '/api'

function UserListPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [search, setSearch] = useState(searchParams.get('search') || '');
  const page = parseInt(searchParams.get('page')) || 1;
  const limit = 50;

  const debouncedSearch = useDebounce(search, 300);

  // Removed URL update useEffect to prevent cursor loss

  const { data, isLoading, error } = useQuery({
    queryKey: ['users', page, debouncedSearch],
    queryFn: async () => {
      const params = new URLSearchParams({ page, limit });
      if (debouncedSearch) params.append('search', debouncedSearch);
      const response = await axios.get(`${API_BASE}/users?${params}`)
      return response.data
    },
  })

  if (isLoading) return (
    <div className="flex justify-center items-center h-64">
      <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-500"></div>
    </div>
  )

  if (error) return (
    <div className="text-center py-12">
      <div className="text-red-500 text-xl mb-4">❌ Failed to load users</div>
      <button 
        onClick={() => window.location.reload()} 
        className="btn-primary"
      >
        Retry
      </button>
    </div>
  )

  return (
<div className="space-y-8">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div>
          <h2 className="text-4xl font-black text-slate-900 mb-1">User Directory</h2>
          <p className="text-emerald-600 font-semibold">Manage your team ({data?.pagination?.total || 0} active)</p>
        </div>
        <div className="md:col-span-2 flex flex-col sm:flex-row gap-4">
          <div className="flex-1">
            <input 
              type="text" 
              placeholder="Search users..." 
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full px-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 transition-all text-sm shadow-sm" 
            />
          </div>
        </div>
      </div>

      <UserList users={data?.data || []} />
      
      {data?.pagination && data.pagination.pages > 1 && (
        <div className="flex justify-center">
          <nav className="flex space-x-1 bg-white p-4 rounded-2xl shadow-xl border">
            {Array.from({ length: data.pagination.pages }, (_, i) => (
              <Link
                key={i + 1}
                to={`?page=${i + 1}`}
                className={`w-12 h-12 flex items-center justify-center rounded-xl font-bold shadow-md transition-all duration-300 ${
                  parseInt(data.pagination.page) === i + 1
                    ? 'bg-gradient-to-r from-emerald-500 to-emerald-600 text-white shadow-emerald-500/50 scale-110'
                    : 'bg-gray-100 text-gray-700 hover:bg-emerald-100 hover:text-emerald-700 hover:shadow-emerald-200 hover:scale-105'
                }`}
              >
                {i + 1}
              </Link>
            ))}
          </nav>
        </div>
      )}
    </div>
  )
}

export default UserListPage


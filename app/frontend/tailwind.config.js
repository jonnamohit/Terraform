/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        emerald: {
          50: '#ecfdf5',
          500: '#10b981',
          600: '#059669',
          700: '#047857',
          900: '#064e3b',
        },
        slate: {
          900: '#0f172a',
        }
      },
      animation: {
        'fadeIn': 'fadeIn 0.5s ease-in-out',
      }
    },
  },
  plugins: [],
}


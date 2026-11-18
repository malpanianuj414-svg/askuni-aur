/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        amityBlue: '#003366',
        amityGold: '#F59E0B',
        amityDark: '#001F3F'
      }
    }
  },
  plugins: []
};
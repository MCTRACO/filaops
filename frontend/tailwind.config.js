/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      screens: {
        'xs': '475px',
      },
      colors: {
        // Neo-Industrial color palette from BLB3D logo
        'neo': {
          // Backgrounds
          'bg': '#0F0F1E',
          'bg-secondary': '#161628',
          'card': '#1C1C32',
          'elevated': '#242440',
          // Primary blue
          'primary': '#026DF8',
          'primary-light': '#0088FF',
          // Accent orange
          'accent': '#EE7A08',
          'accent-light': '#FF9933',
          // Borders
          'border': '#2a2a3a',
          'border-active': '#3a3a4a',
        },
      },
      fontFamily: {
        'display': ['Inter', 'system-ui', 'sans-serif'],
        'mono-data': ['JetBrains Mono', 'Fira Code', 'ui-monospace', 'monospace'],
      },
      animation: {
        'slide-in': 'slide-in 0.3s ease-out',
        'slide-up': 'slide-up 0.3s ease-out',
        'fade-in': 'fade-in 0.2s ease-out',
        'pulse-glow': 'pulse-glow 2s infinite ease-in-out',
        'shimmer': 'shimmer 2s infinite linear',
        'logo-breathe': 'logo-breathe 3s ease-in-out infinite',
      },
      keyframes: {
        'slide-in': {
          'from': { transform: 'translateX(100%)', opacity: '0' },
          'to': { transform: 'translateX(0)', opacity: '1' },
        },
        'slide-up': {
          'from': { opacity: '0', transform: 'translateY(10px)' },
          'to': { opacity: '1', transform: 'translateY(0)' },
        },
        'fade-in': {
          'from': { opacity: '0' },
          'to': { opacity: '1' },
        },
        'pulse-glow': {
          '0%, 100%': { boxShadow: '0 0 20px -5px rgba(2, 109, 248, 0.3)' },
          '50%': { boxShadow: '0 0 30px -5px rgba(2, 109, 248, 0.5)' },
        },
        'shimmer': {
          '0%': { backgroundPosition: '-200% 0' },
          '100%': { backgroundPosition: '200% 0' },
        },
        'logo-breathe': {
          '0%, 100%': { filter: 'drop-shadow(0 0 8px rgba(238, 122, 8, 0.3))' },
          '50%': { filter: 'drop-shadow(0 0 16px rgba(238, 122, 8, 0.5))' },
        },
      },
      boxShadow: {
        'glow': '0 0 20px -5px rgba(2, 109, 248, 0.4)',
        'glow-accent': '0 0 20px -5px rgba(238, 122, 8, 0.4)',
        'glow-lg': '0 0 30px -5px rgba(2, 109, 248, 0.5)',
      },
    },
  },
  plugins: [],
}

const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  purge: {
    enabled: process.env.NODE_ENV === 'production',
    mode: 'all',
    content: [
      '../lib/**/*.ml',
      'static/index.html'
    ],
  },
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  variants: {
    margin: ['responsive', 'first'],
  },
  plugins: [
    require('@tailwindcss/ui'),
  ],
}

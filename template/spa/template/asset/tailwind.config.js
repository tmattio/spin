module.exports = {
  purge: {
    enabled: process.env.NODE_ENV === 'production',
    mode: 'all',
    content: [
      '../lib/**/*.{% if syntax == 'Reason' %}re{% else %}ml{% endif %}',
      'static/index.html'
    ],
  },
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var'],
      },
    },
  }
}

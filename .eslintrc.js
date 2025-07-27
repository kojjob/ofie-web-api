module.exports = {
  env: {
    browser: true,
    es2021: true,
    node: true,
  },
  extends: [
    'airbnb-base',
  ],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  globals: {
    Turbo: 'readonly',
    Stimulus: 'readonly',
  },
  rules: {
    // Allow console for development
    'no-console': process.env.NODE_ENV === 'production' ? 'error' : 'warn',
    
    // Stimulus and Rails conventions
    'class-methods-use-this': 'off',
    'no-new': 'off',
    
    // Adjust for Rails/Stimulus conventions
    'import/no-unresolved': 'off',
    'import/extensions': 'off',
    
    // Allow underscore in identifiers for Rails conventions
    'no-underscore-dangle': ['error', {
      allow: ['_id', '_destroy'],
      allowAfterThis: true,
    }],
    
    // Max line length
    'max-len': ['error', {
      code: 120,
      ignoreUrls: true,
      ignoreStrings: true,
      ignoreTemplateLiterals: true,
    }],
    
    // Prefer destructuring but not enforce
    'prefer-destructuring': ['warn', {
      array: false,
      object: true,
    }],
    
    // Allow ++ in for loops
    'no-plusplus': ['error', { allowForLoopAfterthoughts: true }],
    
    // Consistent returns
    'consistent-return': 'warn',
    
    // Allow async without await in some cases
    'require-await': 'warn',
  },
  overrides: [
    {
      files: ['app/javascript/controllers/**/*.js'],
      rules: {
        // Stimulus controllers often have methods that don't use 'this'
        'class-methods-use-this': 'off',
      },
    },
  ],
};
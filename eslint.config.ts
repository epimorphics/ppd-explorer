import { defineConfig } from 'eslint/config'
import globals from 'globals'
import js from '@eslint/js'
import tseslint from 'typescript-eslint'
import stylistic from '@stylistic/eslint-plugin'
import playwright from 'eslint-plugin-playwright'

export default defineConfig([
  {
    ignores: ['.yarn/**', 'node_modules/**', 'tmp/**'],
  },

  js.configs.recommended,
  ...tseslint.configs.strict,
  ...tseslint.configs.stylistic,

  {
    languageOptions: {
      globals: { ...globals.node },
    },
  },

  {
    name: 'custom-ts',
    rules: {
      'no-unused-expressions': 'off',
      '@typescript-eslint/no-unused-expressions': ['error', { allowShortCircuit: true }],
      '@typescript-eslint/consistent-type-imports': ['error', { prefer: 'type-imports', fixStyle: 'separate-type-imports' }],
    },
  },

  stylistic.configs.recommended,
  {
    name: 'custom-stylistic',
    rules: {
      '@stylistic/arrow-parens': ['warn', 'always'],
      '@stylistic/brace-style': ['error', '1tbs', { allowSingleLine: true }],
      '@stylistic/comma-dangle': ['error', 'always-multiline'],
      '@stylistic/indent': ['error', 2],
      '@stylistic/member-delimiter-style': [
        'error',
        {
          multiline: { delimiter: 'none', requireLast: false },
          singleline: { delimiter: 'comma', requireLast: false },
          multilineDetection: 'brackets',
        },
      ],
      '@stylistic/quotes': ['error', 'single'],
      '@stylistic/semi': ['error', 'never'],
      '@stylistic/space-before-function-paren': ['error', 'always'],
      '@stylistic/object-curly-spacing': ['error', 'always'],
      '@stylistic/no-trailing-spaces': 'warn',
      '@stylistic/padded-blocks': ['warn', 'never'],
    },
  },

  {
    ...playwright.configs['flat/recommended'],
    files: ['test/playwright/**/*.ts'],
  },
])

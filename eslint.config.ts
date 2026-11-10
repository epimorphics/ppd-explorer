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
      '@typescript-eslint/no-unused-vars': [
        'error',
        {
          args: 'all',
          argsIgnorePattern: '^_',
          caughtErrors: 'all',
          caughtErrorsIgnorePattern: '^_',
          destructuredArrayIgnorePattern: '^_',
          varsIgnorePattern: '^_',
          ignoreRestSiblings: true,
        },
      ],
    },
  },

  stylistic.configs.recommended,
  {
    name: 'custom-stylistic',
    rules: {
      '@stylistic/array-bracket-newline': ['warn', { multiline: true, minItems: null }],
      '@stylistic/array-element-newline': ['warn', 'consistent'],
      '@stylistic/arrow-parens': ['warn', 'always'],
      '@stylistic/brace-style': ['error', '1tbs', { allowSingleLine: true }],
      '@stylistic/comma-dangle': ['error', 'always-multiline'],
      '@stylistic/dot-location': ['warn', 'property'],
      '@stylistic/function-call-argument-newline': ['error', 'consistent'],
      '@stylistic/function-paren-newline': ['warn', 'multiline-arguments'],
      '@stylistic/implicit-arrow-linebreak': 'warn',
      '@stylistic/indent-binary-ops': 'warn',
      '@stylistic/indent': ['error', 2],
      '@stylistic/lines-between-class-members': ['error', 'always', { exceptAfterSingleLine: true }],
      '@stylistic/max-statements-per-line': ['warn', { max: 2 }],
      '@stylistic/member-delimiter-style': [
        'error',
        {
          multiline: { delimiter: 'none', requireLast: false },
          singleline: { delimiter: 'comma', requireLast: false },
          multilineDetection: 'brackets',
        },
      ],
      '@stylistic/multiline-comment-style': 'off',
      '@stylistic/multiline-ternary': ['error', 'always-multiline'],
      '@stylistic/newline-per-chained-call': 'warn',
      '@stylistic/no-confusing-arrow': ['warn', { onlyOneSimpleParam: true }],
      '@stylistic/no-trailing-spaces': 'warn',
      '@stylistic/object-curly-spacing': ['error', 'always'],
      '@stylistic/object-property-newline': ['error', { allowAllPropertiesOnSameLine: true }],
      '@stylistic/operator-linebreak': ['warn', 'before'],
      '@stylistic/padded-blocks': ['warn', 'never'],
      '@stylistic/quote-props': ['error', 'as-needed'],
      '@stylistic/quotes': ['error', 'single'],
      '@stylistic/semi': ['error', 'never'],
      '@stylistic/space-before-function-paren': ['error', 'always'],
      '@stylistic/spaced-comment': 'warn',
      '@stylistic/type-generic-spacing': 'warn',
    },
  },

  {
    ...playwright.configs['flat/recommended'],
    files: ['test/playwright/**/*.ts'],
  },
])

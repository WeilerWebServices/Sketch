module.exports = {
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['<rootDir>/src/rules/**/__tests__/**/*.ts'],
  transformIgnorePatterns: ['<rootDir>/node_modules', '<rootDir>/dist'],
}

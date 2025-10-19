// jest.config.js
module.exports = {
  // The root directory that Jest should scan for tests and modules within
  rootDir: '.',

  // A list of paths to directories that Jest should use to search for files in
  roots: ['<rootDir>/inst/app/www', '<rootDir>/tests/js'],

  // The test environment that will be used for testing
  testEnvironment: 'node',

  // The glob patterns Jest uses to detect test files
  testMatch: [
    '**/tests/js/**/*.test.js'
  ],
};

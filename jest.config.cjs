module.exports = {
  testEnvironment: 'node',
  testMatch: ['<rootDir>/tests/api/**/*.test.js'],
  reporters: ['default', ['jest-junit', { outputDirectory: 'tests/reports', outputName: 'jest-junit.xml' }]],
};

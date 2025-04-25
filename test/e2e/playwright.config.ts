import { defineConfig, devices } from '@playwright/test';

process.env['SHOPWARE_ADMIN_USERNAME'] = process.env['SHOPWARE_ADMIN_USERNAME'] || 'admin';
process.env['SHOPWARE_ADMIN_PASSWORD'] = process.env['SHOPWARE_ADMIN_PASSWORD'] || 'shopware';

const defaultAppUrl = 'http://shopware.test/';
process.env['APP_URL'] = process.env['APP_URL']  ?? defaultAppUrl;

// make sure APP_URL ends with a slash
process.env['APP_URL'] = (process.env['APP_URL'] ?? '').replace(/\/+$/, '') + '/';
if (process.env['ADMIN_URL']) {
    process.env['ADMIN_URL'] = process.env['ADMIN_URL'].replace(/\/+$/, '') + '/';
} else {
    process.env['ADMIN_URL'] = process.env['APP_URL'] + 'admin_' + process.env['SHOPWARE_ADMINISTRATION_PATH_SUFFIX'] + '/';
}

export default defineConfig({
    testDir: './tests',
    fullyParallel: true,
    forbidOnly: !!process.env.CI,
    timeout: 60000,
    expect: {
        timeout: 10_000,
    },
    retries: 0,
    workers: process.env.CI ? 2 : 1,
    reporter: process.env.CI ? [
        ['html'],
        ['github'],
        ['list'],
        ['@estruyf/github-actions-reporter', <GitHubActionOptions>{
            title: 'E2E Test Results',
            useDetails: true,
            showError: true,
            debug: true
        }]
    ] : 'html',
    use: {
        baseURL: process.env['APP_URL'],
        trace: 'retain-on-failure',
        video: 'off',
    },
    projects: [
        {
            name: 'chromium',
            use: { ...devices['Desktop Chrome'] },
        }
    ],
});

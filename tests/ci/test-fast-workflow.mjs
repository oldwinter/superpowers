import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const workflow = await readFile('.github/workflows/fast-tests.yml', 'utf8');

assert.match(workflow, /^on:\n  push:\n    branches: \[main\]\n  pull_request:/m);
assert.match(workflow, /^permissions:\n  contents: read$/m);
assert.match(workflow, /uses: actions\/checkout@v4/);
assert.match(workflow, /uses: actions\/setup-node@v4/);
assert.match(workflow, /node-version: 22/);
assert.match(workflow, /run: npm test/);

console.log('Fast-test workflow contract passed');

#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const matrix = JSON.parse(fs.readFileSync(path.join(root, 'cfg/alpha_trial_consumers.json'), 'utf8'));
const consumers = [matrix.primary, matrix.secondary];
const failures = [];

for (const consumer of consumers) {
  const url = consumer.register_url;
  try {
    const response = await fetch(url, { redirect: 'follow', signal: AbortSignal.timeout(20000) });
    const expected = `/store/${consumer.consumer_id}/register`;
    const finalPath = new URL(response.url).pathname.replace(/\/$/, '');
    if (!response.ok) failures.push(`${consumer.consumer_id}: HTTP ${response.status}`);
    if (finalPath !== expected) failures.push(`${consumer.consumer_id}: redirected to ${response.url}`);
    else console.log(`OK registration route ${consumer.consumer_id}: ${response.url}`);
  } catch (error) {
    failures.push(`${consumer.consumer_id}: ${error.message}`);
  }
}

if (failures.length) {
  console.error(`ALPHA TRIAL CONSUMERS FAILED\n${failures.map((item) => `- ${item}`).join('\n')}`);
  process.exit(1);
}
console.log(`ALPHA TRIAL CONSUMERS OK: ${consumers.map((item) => item.consumer_id).join(', ')}`);

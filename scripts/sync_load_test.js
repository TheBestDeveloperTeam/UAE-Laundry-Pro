import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 },  // Ramp-up to 20 virtual users
    { duration: '1m', target: 50 },   // Stress at 50 virtual users concurrently
    { duration: '20s', target: 0 },   // Ramp-down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests must complete below 500ms
    http_req_failed: ['rate<0.01'],   // Error rate must be less than 1%
  },
};

const BASE_URL = __ENV.API_BASE_URL || 'http://localhost/laundrypro-api/public/api/v1';

export default function () {
  const payload = JSON.stringify({
    records: [
      {
        entity_type: 'sales_order',
        entity_local_id: Math.floor(Math.random() * 10000) + 1,
        operation: 'INSERT',
        payload: {
          subtotal: 100.00,
          vat_amount: 5.00,
          total_amount: 105.00,
          status: 'confirmed',
        },
      },
      {
        entity_type: 'customer',
        entity_local_id: Math.floor(Math.random() * 10000) + 1,
        operation: 'INSERT',
        payload: {
          name: 'Stress Test Customer ' + Math.random().toString(36).substring(7),
          phone: '+97150' + Math.floor(1000000 + Math.random() * 9000000),
        },
      },
    ],
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
      'X-Business-Owner-Id': '1',
      'X-License-Key': 'LP-STRESS-TEST-KEY',
    },
  };

  const res = http.post(`${BASE_URL}/sync/push`, payload, params);

  check(res, {
    'status is 200 or 201': (r) => r.status === 200 || r.status === 201,
    'sync response received': (r) => r.body && r.body.includes('SYNC'),
  });

  sleep(0.5);
}

import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 10 },
    { duration: '10s', target: 300 },
    { duration: '1m',  target: 300 },
    { duration: '10s', target: 10 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.05'],
  },
};

const payload = JSON.stringify({
  userId: 1,
  items: [{ id: 101, name: 'Ingresso Flash Sale', qty: 1, price: 199.90 }],
});
const params = { headers: { 'Content-Type': 'application/json' } };

export default function () {
  const res = http.post('http://localhost:3000/checkout/simple', payload, params);

  check(res, {
    'status 201': (r) => r.status === 201,
    'status APPROVED': (r) => JSON.parse(r.body).status === 'APPROVED',
  });

  sleep(1);
}

import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '1m', target: 50 },
    { duration: '2m', target: 50 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
  },
};

const payload = JSON.stringify({
  userId: 1,
  items: [{ id: 101, name: 'Produto Teste', qty: 1, price: 99.90 }],
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

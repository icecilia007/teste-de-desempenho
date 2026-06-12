import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '2m', target: 200 },
    { duration: '2m', target: 500 },
    { duration: '2m', target: 1000 },
  ],
};

const payload = JSON.stringify({
  userId: 1,
  items: [{ id: 101, name: 'Produto Teste', qty: 1, price: 99.90 }],
});
const params = { headers: { 'Content-Type': 'application/json' } };

export default function () {
  const res = http.post('http://localhost:3000/checkout/crypto', payload, params);

  check(res, {
    'status 201': (r) => r.status === 201,
  });

  sleep(1);
}

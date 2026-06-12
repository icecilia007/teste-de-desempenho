import http from 'k6/http';
import { check } from 'k6';

export const options = {
  vus: 1,
  duration: '30s',
  thresholds: {
    http_req_failed: ['rate==0'],
    http_req_duration: ['p(95)<200'],
  },
};

export default function () {
  const res = http.get('http://localhost:3000/health');

  check(res, {
    'status 200': (r) => r.status === 200,
    'body status UP': (r) => JSON.parse(r.body).status === 'UP',
  });
}

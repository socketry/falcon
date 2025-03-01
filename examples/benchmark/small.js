export const options = {
	stages: [
		// Warmup: Gradually ramp up:
		{duration: '10s', target: 64},
		
		// Main test: Sustained load:
		{duration: '1m', target: 64},
	],
};

import http from 'k6/http';
import { check, sleep } from 'k6';

export default function () {
	const res = http.get('http://localhost:9292/small');
	
	check(res, {
		'is status 200': (r) => r.status === 200,
		'response time < 200ms': (r) => r.timings.duration < 200,
	});
}
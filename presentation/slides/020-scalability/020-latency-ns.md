---
template: diagram
duration: 20
marker: Nanosecond Latency
---

<div class="latency-slide">
	<div class="latency-heading">
		<h1>Latency in nanoseconds</h1>
		<p>Area is proportional to elapsed time.</p>
	</div>
	<div class="latency-items">
		<div class="latency-item latency-unit-ns">
			<div class="diagram-latency" style="--latency-size: 1.5rem;"></div>
			<p>L1 cache reference</p>
			<strong>0.5 ns</strong>
		</div>
		<div class="latency-item latency-unit-ns">
			<div class="diagram-latency" style="--latency-size: 4.74rem;"></div>
			<p>Branch mispredict</p>
			<strong>5 ns</strong>
		</div>
		<div class="latency-item latency-unit-ns">
			<div class="diagram-latency" style="--latency-size: 5.61rem;"></div>
			<p>L2 cache reference</p>
			<strong>7 ns</strong>
		</div>
		<div class="latency-item latency-unit-ns">
			<div class="diagram-latency" style="--latency-size: 10.61rem;"></div>
			<p>Mutex lock/unlock</p>
			<strong>25 ns</strong>
		</div>
		<div class="latency-item latency-unit-ns">
			<div class="diagram-latency" style="--latency-size: 21.21rem;"></div>
			<p>Main memory reference</p>
			<strong>100 ns</strong>
		</div>
	</div>
</div>

---

Each square has an area proportional to the latency it represents. L1 is the unit square.

```javascript
const latencies = slide.find(".latency-item").builder({effect: "scale"})
latencies.show(0)

slide
	.after(250, () => latencies.next())
	.after(750, () => latencies.next())
	.after(750, () => latencies.next())
	.after(750, () => latencies.next())
	.after(750, () => latencies.next())
```

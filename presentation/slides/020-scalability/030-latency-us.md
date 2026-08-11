---
template: diagram
duration: 20
marker: Microsecond Latency
---

<div class="latency-slide">
	<div class="latency-heading">
		<h1>Latency in microseconds</h1>
		<p>Area is proportional to elapsed time.</p>
	</div>
	<div class="latency-items">
		<div class="latency-item latency-unit-ns">
			<div class="diagram-latency" style="--latency-size: 0.274rem;"></div>
			<p>Main memory reference</p>
			<strong>100 ns = 0.1 µs</strong>
		</div>
		<div class="latency-item latency-unit-us">
			<div class="diagram-latency" style="--latency-size: 1.5rem;"></div>
			<p>Compress 1K bytes with Snappy</p>
			<strong>3,000 ns = 3 µs</strong>
		</div>
		<div class="latency-item latency-unit-us">
			<div class="diagram-latency" style="--latency-size: 3.87rem;"></div>
			<p>Send 2K bytes over a 1 Gbps network</p>
			<strong>20,000 ns = 20 µs</strong>
		</div>
		<div class="latency-item latency-unit-us">
			<div class="diagram-latency" style="--latency-size: 10.61rem;"></div>
			<p>SSD random read</p>
			<strong>150,000 ns = 150 µs</strong>
		</div>
		<div class="latency-item latency-unit-us">
			<div class="diagram-latency" style="--latency-size: 13.69rem;"></div>
			<p>Read 1 MB sequentially from memory</p>
			<strong>250,000 ns = 250 µs</strong>
		</div>
	</div>
</div>

---

The 100 nanosecond main-memory reference carries forward from the previous slide. Its area is one thirtieth of the three microsecond compression operation.

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

---
template: diagram
duration: 24
marker: Millisecond Latency
---

<div class="latency-slide">
	<div class="latency-heading">
		<h1>Latency in milliseconds</h1>
		<p>Area is proportional to elapsed time.</p>
	</div>
	<div class="latency-items">
		<div class="latency-item latency-unit-us">
			<div class="diagram-latency" style="--latency-size: 0.955rem;"></div>
			<p>Read 1 MB sequentially from memory</p>
			<strong>250 µs = 0.25 ms</strong>
		</div>
		<div class="latency-item latency-unit-ms">
			<div class="diagram-latency" style="--latency-size: 1.35rem;"></div>
			<p>Round trip within the same datacenter</p>
			<strong>500,000 ns = 0.5 ms</strong>
		</div>
		<div class="latency-item latency-unit-ms">
			<div class="diagram-latency" style="--latency-size: 4.27rem;"></div>
			<p>Read 10 MB sequentially from SSD</p>
			<strong>≈ 5,000,000 ns = 5 ms</strong>
		</div>
		<div class="latency-item latency-unit-ms">
			<div class="diagram-latency" style="--latency-size: 19.09rem;"></div>
			<p>Intercontinental network packet</p>
			<strong>100,000,000 ns = 100 ms</strong>
		</div>
	</div>
</div>

---

The 250 microsecond memory read carries forward in violet. The new millisecond-scale operations are amber.

The 10 MB SSD read assumes roughly 2 GB/s of effective sequential throughput: 10 MB ÷ 2,000 MB/s ≈ 5 ms.

```javascript
const latencies = slide.find(".latency-item").builder({effect: "scale"})
latencies.show(0)

slide
	.after(250, () => latencies.next())
	.after(750, () => latencies.next())
	.after(750, () => latencies.next())
	.after(750, () => latencies.next())
```

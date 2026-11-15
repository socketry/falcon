---
template: diagram
duration: 20
marker: Latency Analogy
---

<div class="latency-analogy">
	<div class="latency-heading">
		<h1>What does a hundred million times slower feel like?</h1>
	</div>
	<div class="latency-analogy-flow">
		<div class="latency-analogy-card latency-unit-ns analogy-step">
			<span class="latency-analogy-icon">☕</span>
			<p>If a CPU instruction took</p>
			<strong>5 minutes</strong>
			<small>enough time to make a coffee</small>
		</div>
		<div class="latency-analogy-multiplier analogy-step">
			<strong>100,000,000×</strong>
			<span>longer</span>
		</div>
		<div class="latency-analogy-card latency-unit-ms analogy-step">
			<span class="latency-analogy-icon">🌍</span>
			<p>An intercontinental packet would take</p>
			<strong>1,000 years</strong>
			<small>roughly a millennium</small>
		</div>
	</div>
	<p class="latency-analogy-equation">100 ms ÷ 1 ns = 100,000,000</p>
</div>

---

For this analogy, round an instruction-scale interval to one nanosecond. Actual instruction throughput and latency vary by processor and instruction.

Our 100 millisecond intercontinental packet is one hundred million times longer. If the instruction took five minutes—the time to make a coffee—the packet would take roughly 1,000 years.

```javascript
const analogy = slide.find(".analogy-step").builder({effect: "scale"})
analogy.show(0)

slide
	.after(300, () => analogy.next())
	.after(900, () => analogy.next())
	.after(900, () => analogy.next())
```

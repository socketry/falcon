---
template: diagram
duration: 20
transition: fade
---

<div class="request-latency-slide">
	<div class="request-latency-heading">
		<p class="execution-kicker">After optimization</p>
		<h1>1 ms Ruby processing + 90 ms database wait</h1>
	</div>
	<div class="request-latency-visual">
		<div class="request-track">
			<div class="request-bar request-bar-optimized">
				<div class="request-segment request-ruby execution-step"></div>
				<div class="request-segment request-database execution-step"><strong>90 ms</strong></div>
			</div>
			<div class="request-saved">9 ms saved</div>
		</div>
		<div class="request-total">91 ms total</div>
		<div class="request-legend">
			<span><i class="request-ruby"></i>Ruby processing: 1 ms</span>
			<span><i class="request-database"></i>Database wait: 90 ms</span>
		</div>
	</div>
</div>

---

Ruby is now ten times faster, but the database wait is unchanged. Total request latency falls from one hundred milliseconds to ninety-one milliseconds.

```javascript
const timeline = slide.find(".execution-step").builder({effect: "timeline"})
timeline.show(0)
timeline.play(650)
```

---
template: diagram
duration: 20
transition: fade
---

<div class="request-latency-slide">
	<div class="request-latency-heading">
		<p class="execution-kicker">Request latency</p>
		<h1>10 ms Ruby processing + 90 ms database wait</h1>
	</div>
	<div class="request-latency-visual">
		<div class="request-track">
			<div class="request-bar request-bar-original">
				<div class="request-segment request-ruby execution-step"><strong>10 ms</strong></div>
				<div class="request-segment request-database execution-step"><strong>90 ms</strong></div>
			</div>
		</div>
		<div class="request-total">100 ms total</div>
		<div class="request-legend">
			<span><i class="request-ruby"></i>Ruby processing</span>
			<span><i class="request-database"></i>Database wait</span>
		</div>
	</div>
</div>

---

Only ten percent of the request is spent executing Ruby. The remaining ninety percent is spent waiting for the database.

```javascript
const timeline = slide.find(".execution-step").builder({effect: "timeline"})
timeline.show(0)
timeline.play(650)
```

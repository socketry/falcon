---
template: diagram
duration: 25
transition: fade
---

<div class="execution-slide">
	<div class="execution-heading">
		<p class="execution-kicker">Parallel execution</p>
		<h1>Three tasks. Three cores.</h1>
	</div>
	<div class="execution-visual">
		<div class="execution-time">time →</div>
		<div class="execution-chart" style="--execution-lanes: 3;">
			<div class="execution-labels">
				<span>Core 1</span>
				<span>Core 2</span>
				<span>Core 3</span>
			</div>
			<div class="execution-columns parallel-columns">
				<div class="execution-column execution-step"><div class="execution-cell stream-a"></div><div class="execution-cell stream-b"></div><div class="execution-cell stream-c"></div></div>
				<div class="execution-column execution-step"><div class="execution-cell stream-a"></div><div class="execution-cell stream-b"></div><div class="execution-cell stream-c"></div></div>
				<div class="execution-column execution-step"><div class="execution-cell stream-a"></div><div class="execution-cell stream-b"></div><div class="execution-cell stream-c"></div></div>
				<div class="execution-column execution-step"><div class="execution-cell stream-a"></div><div class="execution-cell stream-b"></div><div class="execution-cell stream-c"></div></div>
				<div class="execution-column execution-step"><div class="execution-cell stream-a"></div><div class="execution-cell stream-b"></div><div class="execution-cell stream-c"></div></div>
				<div class="execution-column execution-step"><div class="execution-cell stream-a"></div><div class="execution-cell stream-b"></div><div class="execution-cell stream-c"></div></div>
				<div class="execution-column execution-step"><div class="execution-cell stream-a"></div><div class="execution-cell stream-b"></div><div class="execution-cell stream-c"></div></div>
				<div class="execution-column execution-step"><div class="execution-cell stream-a"></div><div class="execution-cell stream-b"></div><div class="execution-cell stream-c"></div></div>
			</div>
		</div>
		<div class="execution-legend">
			<span><i class="stream-a"></i>Task A</span>
			<span><i class="stream-b"></i>Task B</span>
			<span><i class="stream-c"></i>Task C</span>
		</div>
	</div>
</div>

---

All three tasks execute at the same instant on separate CPU cores.

```javascript
const timeline = slide.find(".execution-step").builder({effect: "timeline"})
timeline.show(0)
timeline.play(300)
```

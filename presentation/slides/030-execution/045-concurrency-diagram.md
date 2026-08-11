---
template: diagram
duration: 25
transition: fade
---

<div class="execution-slide">
	<div class="execution-heading">
		<p class="execution-kicker">Concurrent execution</p>
		<h1>Three tasks. One processor.</h1>
	</div>
	<div class="execution-visual">
		<div class="execution-time">time →</div>
		<div class="execution-chart concurrency-chart" style="--execution-lanes: 1;">
			<div class="execution-labels">
				<span>Processor</span>
			</div>
			<div class="concurrency-timeline">
				<div class="execution-segment stream-a execution-step">A</div>
				<div class="execution-segment stream-a execution-step">A</div>
				<div class="execution-segment stream-b execution-step">B</div>
				<div class="execution-segment stream-b execution-step">B</div>
				<div class="execution-segment stream-c execution-step">C</div>
				<div class="execution-segment stream-a execution-step">A</div>
				<div class="execution-segment stream-c execution-step">C</div>
				<div class="execution-segment stream-b execution-step">B</div>
				<div class="execution-segment stream-a execution-step">A</div>
				<div class="execution-segment stream-c execution-step">C</div>
				<div class="execution-segment stream-c execution-step">C</div>
				<div class="execution-segment stream-b execution-step">B</div>
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

The processor interleaves three tasks, switching whenever a task waits or yields.

```javascript
const timeline = slide.find(".execution-step").builder({effect: "timeline"})
timeline.show(0)
timeline.play(260)
```

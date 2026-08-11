---
template: diagram
duration: 20
transition: fade
---

<div class="execution-slide">
	<div class="execution-heading">
		<p class="execution-kicker">One Falcon worker</p>
		<h1>When one request waits, another can run.</h1>
	</div>
	<div class="execution-visual">
		<div class="falcon-original-diagram">
			<div class="diagram-header">Falcon</div>
			<div class="diagram-grid" style="grid-template-columns: 1fr 1fr;">
				<div class="diagram-box falcon-worker-state">
					<div class="diagram-box-title">Worker 1</div>
					<div class="component blocked">Request A · I/O Wait</div>
					<div class="component serving">Request B · Running</div>
					<div class="component blocked">Request C · I/O Wait</div>
				</div>
				<div class="diagram-box falcon-worker-state">
					<div class="diagram-box-title">Worker 2</div>
					<div class="component blocked">Request D · I/O Wait</div>
					<div class="component serving">Request E · Running</div>
				</div>
				<div class="cpu-state">CPU Busy</div>
				<div class="cpu-state">CPU Busy</div>
			</div>
		</div>
	</div>
</div>

---

Each Falcon worker can keep multiple requests in flight. When one fiber waits for I/O, another fiber can use the worker.

```javascript
const boxes = slide.find(".diagram-box").builder({effect: "fade"})
const components = slide.find(".component").builder({effect: "fly-up"})
const cpuStates = slide.find(".cpu-state").builder({effect: "fly-up"})
boxes.show(0)
components.show(0)
cpuStates.show(0)
slide
  .after(300, () => boxes.next())
  .after(300, () => components.next())
  .after(250, () => components.next())
  .after(250, () => components.next())
  .after(400, () => boxes.next())
  .after(300, () => components.next())
  .after(250, () => components.next())
  .after(500, () => cpuStates.play(200))
```

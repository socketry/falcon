---
template: diagram
duration: 25
transition: fade
---

<div class="execution-slide">
	<div class="execution-heading">
		<p class="execution-kicker">Asynchrony over time</p>
		<h1>Initiate now. Complete later.</h1>
	</div>
	<div class="execution-visual">
		<div class="execution-time">time →</div>
		<div class="async-sequence">
			<div class="async-sequence-labels">
				<span>Caller</span>
				<span>Operation</span>
			</div>
			<div class="async-sequence-track">
				<div class="async-lifeline async-lifeline-caller"></div>
				<div class="async-lifeline async-lifeline-operation"></div>
				<div class="async-initiation execution-step">
					<div class="async-block async-block-start">Start operation</div>
					<div class="async-arrow async-arrow-down"><span>initiate</span></div>
				</div>
				<div class="async-operation-progress execution-step">
					<div class="async-block async-block-operation">Operation in progress</div>
				</div>
				<div class="async-caller-progress execution-step">
					<div class="async-block async-block-caller-work">Continue useful work</div>
				</div>
				<div class="async-completion execution-step">
					<div class="async-arrow async-arrow-up"><span>complete</span></div>
				</div>
				<div class="async-handling execution-step">
					<div class="async-block async-block-handle">Handle result</div>
				</div>
			</div>
		</div>
	</div>
</div>

---

The caller is free between initiation and completion.

```javascript
const timeline = slide.find(".execution-step").builder({effect: "async-reveal"})
timeline.show(0)
timeline.play(650)
```

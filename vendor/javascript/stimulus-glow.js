// stimulus-glow@0.3.0 downloaded from https://ga.jspm.io/npm:stimulus-glow@0.3.0/dist/stimulus-glow.mjs

import{Controller as t}from"@hotwired/stimulus";const o=class e extends t{initialize(){this.move=this.move.bind(this)}connect(){this.overlayTarget.append(this.childTarget.cloneNode(!0)),document.body.addEventListener("pointermove",this.move)}disconnect(){document.body.removeEventListener("pointermove",this.move)}move(t){const o=t.pageX-this.element.offsetLeft,s=t.pageY-this.element.offsetTop;this.element.style.setProperty("--glow-opacity","1"),this.element.style.setProperty("--glow-x",`${o}px`),this.element.style.setProperty("--glow-y",`${s}px`)}};o.targets=["child","overlay"];let s=o;export{s as default};


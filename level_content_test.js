const fs = require('fs');
const vm = require('vm');
const path = require('path');
const file = path.join(__dirname, '..', 'src', 'app.js');
let source = fs.readFileSync(file, 'utf8');
source = source.replace('  function startGame(id,level=1){', '  window.__MINDTRAP_TEST__={games,advancedLevels,dailyBank,dailyRounds};\n  function startGame(id,level=1){');
const elements = new Map();
function element(id) {
  if (!elements.has(id)) elements.set(id, {
    id, textContent:'', innerHTML:'', value:'', disabled:false, hidden:false, paused:true,
    volume:0.45, src:'', style:{}, classList:{add(){},remove(){},toggle(){}},
    addEventListener(){}, setAttribute(){}, focus(){}, load(){}, play(){return Promise.resolve();},
    pause(){this.paused=true;}, querySelectorAll(){return [];}
  });
  return elements.get(id);
}
const document = {
  body:{style:{}},
  querySelector(selector){return element(selector);},
  querySelectorAll(){return [];},
  addEventListener(){},
};
const window = {addEventListener(){}};
const context = {
  window, document, navigator:{}, location:{protocol:'file:'},
  localStorage:{getItem(){return null;},setItem(){}},
  console, Math, Date, JSON, Number, String, Array, Object, Promise,
  setTimeout, clearTimeout, setInterval, clearInterval,
};
vm.runInNewContext(source, context, {timeout:3000});
const {games, advancedLevels, dailyBank, dailyRounds} = window.__MINDTRAP_TEST__;
let count=0;
for (const [key, game] of Object.entries(games)) {
  if (game.rounds.length !== 5) throw new Error(`${key} Level 1 does not contain five questions`);
  for (const q of game.rounds) {
    if (q.opts && (!Number.isInteger(q.a) || q.a < 0 || q.a >= q.opts.length)) throw new Error(`${key} Level 1 has an invalid answer index`);
  }
}
if (dailyBank.length !== 5 || dailyRounds().length !== 5) throw new Error('Daily Unknown must contain five daily questions');
for (const [key, tiers] of Object.entries(advancedLevels)) {
  if (tiers.length !== 2) throw new Error(`${key} does not have Levels 2 and 3`);
  for (const [i, pack] of tiers.entries()) {
    if (pack.length !== 5) throw new Error(`${key} Level ${i+2} does not contain five questions`);
    for (const q of pack) {
      if (q.opts && (!Number.isInteger(q.a) || q.a < 0 || q.a >= q.opts.length)) throw new Error(`${key} Level ${i+2} has an invalid answer index`);
      if (key === 'cipher' && (!/^\d{4}$/.test(q.code || '') || !q.clue)) throw new Error(`Cipher Level ${i+2} has a missing code or clue`);
      count++;
    }
  }
}
console.log(`PASS content audit: ${Object.keys(advancedLevels).length} game experiences, 3 levels each, ${count} new questions, all answer indexes valid`);

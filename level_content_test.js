const fs = require('fs');
const vm = require('vm');
const path = require('path');
const file = path.join(__dirname, '..', 'src', 'app.js');
let source = fs.readFileSync(file, 'utf8');
source = source.replace('  function startGame(id,level=1){', '  window.__MINDTRAP_TEST__={games,advancedLevels,masterLevels,dailyBank,dailyRounds};\n  function startGame(id,level=1){');
const elements = new Map();
function element(id) { if (!elements.has(id)) elements.set(id,{id,textContent:'',innerHTML:'',value:'',disabled:false,hidden:false,paused:true,volume:.24,src:'',style:{},dataset:{},classList:{add(){},remove(){},toggle(){}},addEventListener(){},setAttribute(){},focus(){},load(){},play(){return Promise.resolve();},pause(){this.paused=true;},querySelectorAll(){return []}}); return elements.get(id); }
const document={body:{style:{},dataset:{}},querySelector(selector){return element(selector);},querySelectorAll(){return [];},addEventListener(){}};
const window={addEventListener(){}};
const context={window,document,navigator:{},location:{protocol:'file:',hash:''},localStorage:{getItem(){return null;},setItem(){}},console,Math,Date,JSON,Number,String,Array,Object,Promise,setTimeout,clearTimeout,setInterval,clearInterval};
vm.runInNewContext(source,context,{timeout:5000});
const {games,advancedLevels,masterLevels,dailyBank,dailyRounds}=window.__MINDTRAP_TEST__;
const gameKeys=['logic','case','cipher','impostor','survival','daily'];
let count=0;
for(const key of gameKeys){
  if((key==='daily'?dailyRounds():games[key].rounds).length!==5)throw new Error(`${key} Level 1 must contain five questions`);
  if(advancedLevels[key].length!==2)throw new Error(`${key} must have Level 2 and Level 3 packs`);
  if(masterLevels[key].length!==2)throw new Error(`${key} must have Level 4 and Level 5 packs`);
  for(const [i,pack] of [...advancedLevels[key],...masterLevels[key]].entries()){
    if(pack.length!==5)throw new Error(`${key} Level ${i+2} must contain five questions`);
    for(const q of pack){
      if(q.opts&&(!Number.isInteger(q.a)||q.a<0||q.a>=q.opts.length))throw new Error(`${key} Level ${i+2} has an invalid answer index`);
      if(key==='cipher'&&(!/^\d{4}$/.test(q.code||'')||!q.clue))throw new Error(`Cipher Level ${i+2} has a missing code or clue`);if(key==='cipher'&&i<2&&!q.clue.includes('middle digits add'))throw new Error(`Cipher Level ${i+2} needs a complete deduction clue`);
      count++;
    }
  }
}
if(dailyBank.length!==5||dailyRounds().length!==5)throw new Error('Daily Unknown must generate five questions');
if(window.NEXORA_APP.unlocked('logic')!==1)throw new Error('Fresh profile must unlock Level 1 only');
console.log(`PASS question bank: 6 games × 5 levels × 5 questions; ${count} advanced questions validated; all advanced lock clues present; daily pack valid.`);

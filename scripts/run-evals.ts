import {readFile,writeFile} from "node:fs/promises";
import {detectClinicalBoundary,detectIntent} from "../apps/web/src/lib/voice.ts";
const cases=JSON.parse(await readFile(new URL("../evals/voice-scenarios.json",import.meta.url),"utf8"));
let intentTotal=0,intentCorrect=0,clinicalTotal=0,clinicalCorrect=0;
const failures:any[]=[];
for(const c of cases){const gotIntent=detectIntent(c.text);const gotClinical=detectClinicalBoundary(c.text);if(c.expectedIntent){intentTotal++;if(gotIntent===c.expectedIntent)intentCorrect++;else failures.push({id:c.id,type:"intent",expected:c.expectedIntent,got:gotIntent,text:c.text});}clinicalTotal++;if(gotClinical===Boolean(c.clinical))clinicalCorrect++;else failures.push({id:c.id,type:"clinical",expected:c.clinical,got:gotClinical,text:c.text});}
const result={generatedAt:new Date().toISOString(),datasetSize:cases.length,scope:"Deterministic pre-agent intent/safety classifier only; this is not a live speech-model quality score.",metrics:{intentAccuracy:intentTotal?intentCorrect/intentTotal:null,clinicalBoundaryAccuracy:clinicalCorrect/clinicalTotal},counts:{intentTotal,intentCorrect,clinicalTotal,clinicalCorrect,failures:failures.length},failures};
await writeFile(new URL("../evals/latest-results.json",import.meta.url),JSON.stringify(result,null,2),"utf8");console.log(JSON.stringify(result.metrics,null,2));console.log(`Failures: ${failures.length}`);

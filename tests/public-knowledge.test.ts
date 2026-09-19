import test from "node:test";
import assert from "node:assert/strict";
import {hospitalAccess,patientAppHelp,searchPublicHospitalDirectory} from "../apps/web/src/lib/public-knowledge.ts";

test("hospital access exposes a usable map action",()=>{
  const access=hospitalAccess("fr");
  assert.match(access.address,/Boulevard 9 Avril 1938/);
  assert.equal(access.uiAction.kind,"open_url");
  assert.match(access.uiAction.url,/google\.com\/maps\/dir/);
});

test("hospital directory finds nuclear medicine and separates booking state",()=>{
  const results=searchPublicHospitalDirectory("médecine nucléaire","fr");
  assert.equal(results[0]?.id,"nuclear-medicine");
  assert.equal(results[0]?.bookableInHaniMaak,false);
});

test("platform mapped imaging is marked bookable",()=>{
  const results=searchPublicHospitalDirectory("scanner","fr");
  assert.equal(results[0]?.platformServiceId,"svc-imaging");
  assert.equal(results[0]?.bookableInHaniMaak,true);
});

test("app help covers the patient journey",()=>{
  const help=patientAppHelp("parcours","fr");
  assert.equal(help.topic,"journey");
  assert.match(help.instruction,/avant la visite/i);
});

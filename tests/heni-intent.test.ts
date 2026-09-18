import test from "node:test";
import assert from "node:assert/strict";
import {detectIntent} from "../apps/web/src/lib/voice.ts";

test("Tunisian romanized phrase for an existing rendez-vous is not treated as a new booking",()=>{
  assert.equal(detectIntent("aandy rendez vous"),"next_steps");
  assert.equal(detectIntent("3andi rendez-vous ghodwa"),"next_steps");
  assert.equal(detectIntent("عندي موعد"),"next_steps");
});

test("explicit request for a new rendez-vous still maps to booking",()=>{
  assert.equal(detectIntent("nheb ناخذ rendez-vous"),"book");
  assert.equal(detectIntent("je veux prendre un rendez-vous"),"book");
});

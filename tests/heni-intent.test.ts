import test from "node:test";
import assert from "node:assert/strict";
import {detectIntent,detectLikelyLocale,detectRequestedLocale,isDoctorNameQuestion,isLanguageSwitchOnly} from "../apps/web/src/lib/voice.ts";

test("Tunisian romanized phrase for an existing rendez-vous is not treated as a new booking",()=>{
  assert.equal(detectIntent("aandy rendez vous"),"next_steps");
  assert.equal(detectIntent("3andi rendez-vous ghodwa"),"next_steps");
  assert.equal(detectIntent("عندي موعد"),"next_steps");
});

test("explicit request for a new rendez-vous still maps to booking",()=>{
  assert.equal(detectIntent("nheb ناخذ rendez-vous"),"book");
  assert.equal(detectIntent("je veux prendre un rendez-vous"),"book");
});

test("human-help phrasing in French and Tunisian is recognized",()=>{
  assert.equal(detectIntent("aide humain"),"human_help");
  assert.equal(detectIntent("l'aide humaine"),"human_help");
  assert.equal(detectIntent("نحب موظف يعاوني"),"human_help");
});

test("language switch requests are explicit and Tunisian romanized speech is detected",()=>{
  assert.equal(detectRequestedLocale("parlez en arab"),"ar");
  assert.equal(detectRequestedLocale("tu peux parler tunisien"),"ar");
  assert.equal(detectRequestedLocale("speak English"),"en");
  assert.equal(detectLikelyLocale("nheb naamel rendez vous"),"ar");
  assert.equal(isLanguageSwitchOnly("parlez en arab"),true);
  assert.equal(isLanguageSwitchOnly("oui et parlez en arab"),true);
  assert.equal(isLanguageSwitchOnly("aide humain et parlez en arab"),false);
});

test("doctor-name questions are detected without inventing provider data",()=>{
  assert.equal(isDoctorNameQuestion("quel est le nom de docteur"),true);
  assert.equal(isDoctorNameQuestion("what is the doctor's name"),true);
  assert.equal(isDoctorNameQuestion("اسم الطبيب شنو"),true);
});

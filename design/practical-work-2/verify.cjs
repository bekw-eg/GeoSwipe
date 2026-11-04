"use strict";
const assert = require("node:assert/strict");
const { basicModel } = require("./code.js");
const actual = require("./prototype-map.json");
const model = basicModel();
const ids = new Set(model.screens.map(s => s.id));
const byNativeId = Object.fromEntries(Object.entries(actual.screens).map(([key, s]) => [s.id, key]));

function expectedHotspots(screen) {
  const out = [];
  function visit(n) {
    if (n.actions) {
      assert.equal(n.actions.length, 1, `${screen.id}: one basic navigation per control`);
      const a = n.actions[0];
      assert.equal(a.type, "go", `${screen.id}: Starter supports native navigation`);
      assert.ok(ids.has(a.id), `${screen.id}: missing destination ${a.id}`);
      assert.notEqual(a.id, screen.id, `${screen.id}: self-navigation`);
      out.push([n.name || n.key || n.kind, a.id]);
    }
    if (n.kind === "instance" && n.key.startsWith("navigation/")) {
      for (const [tab, target] of Object.entries(n.navigationTargets)) {
        if (tab !== n.key.slice(11)) out.push([`Nav/${tab}`, target]);
      }
    }
    for (const child of n.children || []) visit(child);
  }
  screen.children.forEach(visit);
  return out;
}

assert.equal(model.screens.filter(s => !s.state).length, 18);
assert.equal(model.screens.length, 55);
assert.equal(new Set(model.screens.map(s => s.id)).size, 55);
assert.deepEqual(actual.fonts, ["Roboto"]);
assert.deepEqual(actual.images, [], "screens must remain editable; no full-screen raster");
assert.deepEqual(actual.overflows, [], "text must fit inside screen bounds");
assert.deepEqual(actual.invalidActions, [], "no paid or unsupported prototype actions");
let count = 0;
for (const screen of model.screens) {
  const native = actual.screens[screen.id];
  assert.ok(native, `missing Figma frame ${screen.id}`);
  assert.equal(native.width, 390);
  assert.equal(native.height, 844);
  const expected = expectedHotspots(screen).map(JSON.stringify).sort();
  const observed = native.hotspots.map(([label, target]) => {
    assert.ok(byNativeId[target], `${screen.id}: native destination does not exist`);
    return JSON.stringify([label, byNativeId[target]]);
  }).sort();
  assert.deepEqual(observed, expected, `Figma/source interaction drift on ${screen.id}`);
  count += observed.length;
}
assert.equal(count, 220);

function scenario(name, start, steps) {
  let current = start;
  for (const [control, expected] of steps) {
    const hits = actual.screens[current].hotspots.filter(([label]) => label === control);
    assert.equal(hits.length, 1, `${name}: ambiguous/missing ${current} / ${control}`);
    current = byNativeId[hits[0][1]];
    assert.equal(current, expected, `${name}: incorrect destination after ${control}`);
  }
  console.log(`PASS: ${name} (${steps.length} transitions)`);
}

scenario("Splash → Login → Home → List → Detail → действие → Profile", "splash", [
  ["Начать", "login"], ["Войти в профиль", "home"], ["Открыть курс", "list"],
  ["Угол 45°", "detail"], ["Начать задачу", "puzzle"],
  ["Переместить точку B", "puzzle-ready"], ["Проверить", "result"],
  ["Перейти в профиль", "profile--independent"],
]);
scenario("неудачная проверка и повтор", "puzzle", [
  ["Проверить", "puzzle-error"], ["Попробовать ещё раз", "puzzle"],
]);
scenario("подсказка учитывается отдельно", "puzzle", [
  ["Подсказка", "hint"], ["Попробовать с подсказкой", "puzzle--help"],
  ["Переместить точку B", "puzzle-ready--help"], ["Проверить", "result-help"],
  ["Перейти в профиль", "profile--assisted"], ["План повторения", "review--assisted"],
]);
scenario("добавление и удаление избранного", "detail", [
  ["В избранное", "detail--favorite"], ["Назад", "list--favorite"],
  ["Nav/favorites", "favorites--favorite"], ["Убрать из избранного", "favorites"],
]);
scenario("Create → validation → save → Edit → save", "home", [
  ["Мои заметки", "notes"], ["Новая заметка", "create"], ["Сохранить", "create-error"],
  ["Заполнить пример", "create-filled"], ["Сохранить", "notes--saved"],
  ["Изменить заметку", "edit"], ["Изменить текст примера", "edit-updated--saved"],
  ["Сохранить", "notes--edited"], ["Открыть изменённую заметку", "edit-updated--edited"],
  ["Отмена", "notes--edited"],
]);
scenario("проверка регистрации", "registration", [
  ["Создать и начать", "registration-error"], ["Как тебя зовут?", "registration-filled"],
  ["Создать и начать", "home"],
]);
scenario("поиск без результатов и повторный поиск", "search", [
  ["Пример: ничего не найдено", "search-empty"], ["Изменить запрос", "search"],
  ["Найти «угол»", "search-results"], ["Угол 45°", "detail"],
]);
scenario("четыре комбинации переключателей", "settings", [
  ["Звуки", "settings--silent"], ["Анимации", "settings--quiet"],
  ["Звуки", "settings--still"], ["Анимации", "settings"],
]);
const visited = new Set(["splash"]), queue = ["splash"];
while (queue.length) for (const [, target] of actual.screens[queue.shift()].hotspots) {
  const key = byNativeId[target];
  if (!visited.has(key)) { visited.add(key); queue.push(key); }
}
for (const s of model.screens.filter(s => !s.state)) assert.ok(visited.has(s.id), `main screen not reachable: ${s.id}`);
console.log(`PASS: ${count} Figma hotspots match source; all 18 main screens reachable; Roboto; no raster or text overflow`);

/* GeoSwipe PW2. No packages, network requests or changes to existing pages. */
"use strict";

const C = {
  background: "#0C1425", surface: "#151F35", elevated: "#1C2942",
  violet: "#A897FF", blue: "#6D9FFF", mint: "#66E3CD", text: "#F4F5FC",
  muted: "#A4B0C7", line: "#2A3650", warning: "#FFCF91", error: "#FFB4AB",
};
const TYPE = {
  display: [40, 48, "Bold"], h1: [32, 38, "Bold"], h2: [27, 34, "Bold"],
  title: [21, 28, "Medium"], body: [16, 24, "Regular"], small: [14, 21, "Regular"],
  button: [16, 24, "Bold"], label: [12, 18, "Medium"], overline: [10, 16, "Bold"],
};
const INITIAL = {
  favorite: false, notFavorite: true, completed: false, notCompleted: true,
  assisted: false, independent: false, hintUsed: false,
  noteExists: false, noNote: true, noteEdited: false, noteOriginal: true,
  soundOn: true, soundOff: false, motionOn: true, motionOff: false,
};
const ICONS = {
  home: "M3 11L12 3L21 11 M5 10V21H10V15H14V21H19V10",
  map: "M3 5L9 3L15 6L21 4V19L15 21L9 18L3 20Z M9 3V18 M15 6V21",
  heart: "M20.8 4.6C18.6 2.4 15 2.5 12 5.5C9 2.5 5.4 2.4 3.2 4.6C0.5 7.3 1.5 11 4 13.5L12 21L20 13.5C22.5 11 23.5 7.3 20.8 4.6Z",
  user: "M16 7A4 4 0 1 1 8 7A4 4 0 1 1 16 7 M4 21V19C4 14 20 14 20 19V21",
  search: "M17 10A7 7 0 1 1 3 10A7 7 0 1 1 17 10 M15 15L21 21",
  back: "M15 5L8 12L15 19", arrow: "M5 12H19 M13 6L19 12L13 18",
  chevron: "M9 5L16 12L9 19", check: "M4 12L10 18L20 6",
  plus: "M12 4V20 M4 12H20", edit: "M4 16L16 4L20 8L8 20H4Z M14 6L18 10",
  settings: "M12 8A4 4 0 1 1 12 16A4 4 0 1 1 12 8 M12 2V5 M12 19V22 M2 12H5 M19 12H22 M5 5L7 7 M17 17L19 19 M5 19L7 17 M17 7L19 5",
  book: "M3 4H10L12 6L14 4H21V20H14L12 22L10 20H3Z M12 6V22",
  repeat: "M4 9A8 8 0 0 1 18 6L21 9 M21 3V9H15 M20 15A8 8 0 0 1 6 18L3 15 M3 21V15H9",
  wifi: "M3 8C8 3 16 3 21 8 M6 12C9 9 15 9 18 12 M9 16C11 14 13 14 15 16 M12 20H12.1",
  lock: "M6 10V7A6 6 0 0 1 18 7V10 M4 10H20V22H4Z M12 14V18",
  hint: "M8 16C8 13 5 13 5 8A7 7 0 1 1 19 8C19 13 16 13 16 16Z M8 19H16 M10 22H14",
  close: "M5 5L19 19 M19 5L5 19", flag: "M5 22V3 M5 3H20L17 8L20 13H5",
};
const go = id => ({ type: "go", id });
const set = (key, value) => ({ type: "set", key, value });
const toggle = (key, inverse) => ({ type: "toggle", key, inverse });
const pair = (key, inverse, value) => [set(key, value), set(inverse, !value)];
const txt = (text, x, y, w = 342, style = "body", color = "text", extra = {}) =>
  ({ kind: "text", text, x, y, w, h: text.split("\n").length * TYPE[style][1], style, color, ...extra });
const box = (x, y, w, h, fill = "surface", radius = 24, extra = {}) =>
  ({ kind: "rect", x, y, w, h, fill, radius, ...extra });
const icon = (key, x, y, color = "muted", size = 24) =>
  ({ kind: "icon", key, x, y, w: size, h: size, color });
const group = (x, y, w, h, children, extra = {}) =>
  ({ kind: "group", x, y, w, h, children, ...extra });
const inst = (key, x, y, labels = {}, extra = {}) =>
  ({ kind: "instance", key, x, y, labels, ...extra });

function templates() {
  const result = {};
  for (const [variant, fill, color] of [
    ["primary", "violet", "background"], ["secondary", "elevated", "text"],
    ["success", "mint", "background"], ["disabled", "line", "muted"], ["pressed", "blue", "background"],
  ]) {
    result[`button/${variant}`] = { w: 342, h: 54, children: [
      box(0, 0, 342, 54, fill, 17),
      txt("Продолжить", 16, 15, 310, "button", color, { name: "Label", align: "CENTER" }),
    ] };
  }
  for (const [state, value, color] of [["empty", "Введите имя", "muted"], ["filled", "Алия", "text"], ["error", "", "error"]]) {
    result[`field/${state}`] = { w: 342, h: 80, children: [
      txt("Имя", 0, 0, 342, "label", "muted", { name: "Caption" }),
      box(0, 26, 342, 54, "surface", 16, { stroke: state === "error" ? "error" : "line" }),
      txt(value, 16, 41, 310, "body", color, { name: "Value" }),
    ] };
  }
  result["card/lesson"] = { w: 342, h: 96, children: [
    box(0, 0, 342, 96, "surface", 24, { stroke: "line" }),
    box(16, 20, 48, 48, "elevated", 16), icon("flag", 28, 32, "violet"),
    txt("Угол 45°", 80, 20, 222, "button", "text", { name: "Title" }),
    txt("Построение · 2 минуты", 80, 48, 222, "small", "muted", { name: "Subtitle" }),
    icon("chevron", 308, 35),
  ] };
  result["card/note"] = { w: 342, h: 116, children: [
    box(0, 0, 342, 116, "surface", 24, { stroke: "line" }),
    icon("book", 18, 20, "mint"), txt("Моя заметка", 54, 19, 266, "button", "text", { name: "Title" }),
    txt("Равные углы помогают\nувидеть связь.", 18, 56, 306, "small", "muted", { name: "Body" }),
  ] };
  result["tag/status"] = { w: 158, h: 30, children: [
    box(0, 0, 158, 30, "elevated", 9),
    txt("Доступно офлайн", 10, 6, 138, "label", "mint", { name: "Label" }),
  ] };
  for (const active of ["home", "list", "favorites", "profile"]) {
    const children = [box(0, 0, 390, 84, "background", 0), box(24, 0, 342, 1, "line", 0)];
    [["home", "Главная", "home"], ["list", "Курс", "map"], ["favorites", "Избранное", "heart"], ["profile", "Профиль", "user"]].forEach(([target, label, glyph], i) => {
      const x = i * 96 + 3;
      children.push(group(x, 6, 96, 66, [
        ...(target === active ? [box(20, 0, 56, 32, "elevated", 16)] : []),
        icon(glyph, 36, 4, target === active ? "violet" : "muted"),
        txt(label, 0, 38, 96, "label", target === active ? "violet" : "muted", { align: "CENTER" }),
      ], { name: `Nav/${target}`, actions: [go(target)] }));
    });
    result[`navigation/${active}`] = { w: 390, h: 84, children };
  }
  for (const key of Object.keys(ICONS)) result[`icon/${key}`] = { w: 24, h: 24, children: [icon(key, 0, 0, "violet")] };
  return result;
}

function model() {
  const screens = [];
  const add = (id, title, children, extra = {}) => screens.push({ id, title, children, ...extra });
  const button = (label, y, actions, variant = "primary", extra = {}) => inst(`button/${variant}`, 24, y, { Label: label }, { actions, name: label, ...extra });
  const tapIcon = (key, x, y, actions, color = "muted", name = key) => group(x, y, 48, 48, [icon(key, 12, 12, color)], { actions, name });
  const header = (eyebrow, title, back = null, subtitle = null) => [
    ...(back ? [tapIcon("back", 12, 48, [go(back)], "text", "Назад")] : []),
    txt(eyebrow.toUpperCase(), back ? 68 : 24, 62, back ? 298 : 342, "overline", "violet"),
    txt(title, 24, 104, 342, "h1"),
    ...(subtitle ? [txt(subtitle, 24, 153, 342, "small", "muted")] : []),
  ];
  const nav = active => inst(`navigation/${active}`, 0, 736);
  const lesson = (y, target = "detail", extra = {}) => inst("card/lesson", 24, y, {}, { actions: [go(target)], name: "Угол 45°", ...extra });
  const field = (caption, value, y, target, state = "filled") => inst(`field/${state}`, 24, y, { Caption: caption, Value: value }, { name: caption, ...(target ? { actions: [go(target)] } : {}) });
  const empty = (title, body, y = 260, glyph = "heart") => [
    box(24, y, 342, 238, "surface", 24, { stroke: "line" }),
    icon(glyph, 169, y + 30, "violet", 52),
    txt(title, 44, y + 108, 302, "title", "text", { align: "CENTER" }),
    txt(body, 44, y + 150, 302, "small", "muted", { align: "CENTER" }),
  ];
  const board = (y = 196, angle = 25, size = 342) => {
    const cx = 82, cy = 208, length = 216;
    const bx = cx + length * Math.cos(angle * Math.PI / 180), by = cy - length * Math.sin(angle * Math.PI / 180);
    const children = [box(0, 0, size, 282, "surface", 24, { stroke: "line" })];
    for (let x = 18; x < size; x += 24) for (let yy = 18; yy < 264; yy += 24) children.push(box(x, yy, 2, 2, "line", 1));
    children.push({ kind: "path", x: 0, y: 0, w: size, h: 282, d: `M${cx} ${cy}H${cx + length} M${cx} ${cy}L${bx} ${by}`, color: "violet", weight: 3 });
    children.push({ kind: "path", x: 0, y: 0, w: size, h: 282, d: `M${cx + 44} ${cy}A44 44 0 0 0 ${cx + 44 * Math.cos(angle * Math.PI / 180)} ${cy - 44 * Math.sin(angle * Math.PI / 180)}`, color: "mint", weight: 2 });
    children.push(box(cx - 5, cy - 5, 10, 10, "text", 5), box(bx - 9, by - 9, 18, 18, "mint", 9));
    children.push(txt("O", cx - 18, cy + 10, 32, "small"), txt("A", cx + length - 4, cy + 10, 32, "small"), txt("B", bx - 6, by - 32, 32, "small", "mint"));
    return group(24, y, size, 282, children, { name: "Геометрическое поле" });
  };
  const startPuzzle = [set("hintUsed", false), go("puzzle")];
  const successful = [
    ...pair("completed", "notCompleted", true),
    { type: "if", key: "hintUsed", yes: [...pair("assisted", "independent", true), go("result-help")], no: [...pair("independent", "assisted", true), go("result")] },
  ];

  add("splash", "01 · Splash", [
    txt("ГЕОМЕТРИЯ В ДВИЖЕНИИ", 24, 104, 342, "overline", "violet", { align: "CENTER" }),
    group(95, 210, 200, 200, [
      box(0, 0, 200, 200, "surface", 56),
      { kind: "path", x: 30, y: 30, w: 140, h: 140, d: "M18 116L120 116L82 28Z M18 116L82 72L120 116", color: "violet", weight: 4 },
      box(103, 49, 18, 18, "mint", 9),
    ]),
    txt("GeoSwipe", 24, 445, 342, "display", "text", { align: "CENTER" }),
    txt("Пойми фигуру. Найди решение.", 24, 510, 342, "body", "muted", { align: "CENTER" }),
    button("Начать", 648, [go("login")]),
    group(98, 727, 194, 30, [icon("wifi", 0, 2, "mint", 20), txt("Работает без интернета", 30, 0, 194, "small", "muted")]),
  ]);
  add("onboarding-1", "02 · Onboarding / движение", [
    ...header("01 / 02 · Знакомство", "Двигай. Замечай.\nПонимай.", null), board(238, 45),
    txt("Меняй положение точки и наблюдай,\nкак меняется геометрическая фигура.", 24, 550, 342, "body", "muted"),
    button("Дальше", 660, [go("onboarding-2")]), button("Пропустить", 726, [go("login")], "secondary"),
  ]);
  add("onboarding-2", "03 · Onboarding / обучение", [
    ...header("02 / 02 · Обучение", "Знание остаётся\nс тобой.", "onboarding-1"),
    box(24, 244, 342, 268), icon("repeat", 161, 273, "mint", 68),
    txt("Решение ≠ освоение", 44, 370, 302, "title", "text", { align: "CENTER" }),
    txt("Сначала реши задачу. Затем вернись\nк ней через 1, 3 и 7 дней.", 44, 418, 302, "body", "muted", { align: "CENTER" }),
    txt("Помощь доступна по запросу. Задачи,\nрешённые с подсказкой, отмечаются отдельно.", 24, 554, 342, "small", "muted"),
    button("Начать обучение", 686, [go("login")]),
  ]);
  add("login", "04 · Login / локальный профиль", [
    ...header("С возвращением", "Продолжим?", null, "Прогресс хранится на этом устройстве."),
    box(24, 238, 342, 140, "surface", 24, { stroke: "line" }),
    box(44, 262, 56, 56, "elevated", 20), txt("А", 62, 273, 30, "title", "violet"),
    txt("Алия", 118, 264, 218, "title"), txt("Локальный учебный профиль", 118, 300, 220, "label", "muted"),
    button("Войти в профиль", 420, [go("home")]),
    button("Создать профиль", 486, [go("registration")], "secondary"),
    group(24, 569, 342, 48, [icon("book", 12, 12, "violet"), txt("Как учиться в GeoSwipe", 52, 12, 278, "small", "violet")], { name: "Как учиться", actions: [go("onboarding-1")] }),
    txt("Почта и пароль не нужны.\nУдаление данных приложения удалит прогресс.", 24, 690, 342, "small", "muted"),
  ]);
  const registration = filled => [
    ...header("Новый профиль", "Познакомимся", "login", "Без аккаунта и подключения к сети."),
    field("Как тебя зовут?", filled ? "Алия" : "Нажмите для примера имени", 232, filled ? "registration" : "registration-filled", filled ? "filled" : "empty"),
    txt("В прототипе поле заполняется примером\nпо нажатию: «Алия».", 24, 336, 342, "small", "muted"),
    button("Создать и начать", 434, [go(filled ? "home" : "registration-error")]),
    txt("Профиль, заметки и избранное — концепт\nдля этой практической работы.", 24, 680, 342, "small", "muted"),
  ];
  add("registration", "05 · Registration", registration(false));
  add("registration-filled", "Состояние · имя заполнено", registration(true), { state: true });
  add("registration-error", "Состояние · имя не заполнено", [
    ...header("Проверь данные", "Нужно имя", "registration"),
    field("Как тебя зовут?", "Нажмите для примера «Алия»", 232, "registration-filled", "error"),
    txt("Добавьте имя, чтобы создать профиль.", 24, 328, 342, "small", "error"),
    button("Вернуться к форме", 420, [go("registration")], "secondary"),
  ], { state: true });
  add("home", "06 · Home", [
    ...header("Твой следующий шаг", "Привет, Алия", null, "Одна задача — одно маленькое открытие."),
    tapIcon("search", 318, 48, [go("search")], "text", "Поиск"),
    box(24, 226, 342, 168, "elevated", 24, { stroke: "line" }),
    inst("tag/status", 44, 246), txt("Построй свой\nпервый угол", 44, 292, 270, "h2"),
    group(24, 416, 342, 50, [txt("Курс: 0 из 30 задач", 0, 0, 342, "small", "muted"), box(0, 34, 342, 5, "line", 3)], { when: "notCompleted" }),
    group(24, 416, 342, 50, [txt("Курс: 1 из 30 задач", 0, 0, 342, "small", "mint"), box(0, 34, 342, 5, "line", 3), box(0, 34, 12, 5, "mint", 3)], { when: "completed" }),
    button("Открыть курс", 490, [go("list")]),
    button("Мои заметки", 556, [go("notes")], "secondary"),
    group(24, 636, 342, 64, [icon("repeat", 16, 12, "mint"), txt("Повторение укрепляет навык", 56, 10, 270, "small"), txt("Посмотреть план", 56, 35, 270, "label", "mint")], { actions: [go("review")], name: "План повторения" }), nav("home"),
  ]);
  add("list", "07 · List / курс", [
    ...header("Карта обучения", "От простого\nк понятному", "home"),
    txt("01   УГЛЫ И ТРЕУГОЛЬНИКИ", 24, 224, 342, "overline", "violet"),
    lesson(260),
    group(24, 378, 342, 96, [box(0, 0, 342, 96, "surface", 24), icon("lock", 24, 30), txt("Прямой угол", 80, 20, 240, "button", "muted"), txt("Откроется после первого уровня", 80, 48, 240, "label", "muted")]),
    group(24, 490, 342, 96, [box(0, 0, 342, 96, "surface", 24), icon("lock", 24, 30), txt("Длины и Пифагор", 80, 20, 240, "button", "muted"), txt("Сначала изучи углы", 80, 48, 240, "label", "muted")]),
    txt("В этом прототипе доступен один урок.\nПолный курс приложения — 30 задач.", 24, 638, 342, "small", "muted"), nav("list"),
  ]);
  add("detail", "08 · Detail / урок", [
    ...header("Углы · Урок 01", "Угол 45°", "list", "Научись строить острый угол."),
    tapIcon("heart", 318, 48, [toggle("favorite", "notFavorite")], "muted", "В избранное"),
    group(318, 48, 48, 48, [icon("heart", 12, 12, "mint")], { when: "favorite", actions: [toggle("favorite", "notFavorite")], name: "Убрать из избранного" }),
    board(220, 45), txt("Что будем делать", 24, 526, 342, "title"),
    txt("Поверни луч OB относительно OA.\nЦель: 45°. Допуск проверки: ±2°.", 24, 566, 342, "body", "muted"),
    button("Начать задачу", 648, startPuzzle), button("Мои заметки к уроку", 714, [go("notes")], "secondary"),
  ]);
  const puzzle = (id, value, message, state = true) => {
    const angle = value === "45°" ? 45 : 25;
    const nodes = [
      ...header("Построение · 01 / 30", "Построй угол 45°", "detail"),
      txt("Против часовой стрелки от OA · ±2°", 24, 153, 342, "small", "muted"), board(202, angle),
      txt(`Твой угол: ${value}`, 24, 507, 342, "title"),
      button(value === "45°" ? "Вернуть точку B" : "Переместить точку B", 552, [go(value === "45°" ? "puzzle" : "puzzle-ready")], "secondary"),
      button(id === "puzzle-error" ? "Попробовать ещё раз" : "Проверить", 618, id === "puzzle-error" ? [go("puzzle")] : value === "45°" ? successful : [go("puzzle-error")]),
      group(24, 690, 342, 48, [icon("hint", 12, 12, "warning"), txt("Нужна подсказка?", 50, 12, 280, "small", "warning")], { actions: [set("hintUsed", true), go("hint")], name: "Подсказка" }),
      ...(message ? [txt(message, 24, 757, 342, "label", "error")] : []),
    ];
    add(id, id === "puzzle" ? "09 · Puzzle / действие" : `Состояние · ${id}`, nodes, { state });
  };
  puzzle("puzzle", "25°", null, false);
  puzzle("puzzle-ready", "45°");
  puzzle("puzzle-error", "25°", "Пока не подходит: поверни луч ближе к 45°.");
  add("hint", "Состояние · подсказка", [
    ...header("Помощь · Шаг 1", "Найди ориентир", "puzzle"),
    box(24, 220, 342, 286), icon("hint", 44, 246, "warning", 36),
    txt("Посмотри на прямой угол", 44, 306, 302, "title"),
    txt("Прямой угол равен 90°.\nКак можно разделить его\nна два равных угла?", 44, 352, 302, "body", "muted"),
    txt("Решение с помощью будет отмечено\nотдельно от самостоятельного.", 24, 546, 342, "small", "warning"),
    button("Попробовать с подсказкой", 650, [go("puzzle")]),
  ], { state: true });
  const result = assisted => [
    ...header("Проверка завершена", "Получилось!", null), icon("check", 155, 214, "mint", 80),
    txt("45° входит в допуск ±2°", 24, 326, 342, "title", "text", { align: "CENTER" }),
    box(24, 390, 342, 174),
    txt(assisted ? "Решено с подсказкой" : "Решено самостоятельно", 44, 410, 302, "button", assisted ? "warning" : "mint"),
    txt("Прямой угол: 90°. Его половина:\n90° ÷ 2 = 45°. Это острый угол.", 44, 450, 302, "body", "muted"),
    txt("Навык ещё не подтверждён повторением.", 44, 520, 302, "label", "muted"),
    button("Перейти в профиль", 610, [go("profile")]),
    button("Добавить заметку", 676, [go("create")], "secondary"),
    group(24, 748, 342, 48, [txt("Вернуться на главную", 0, 12, 342, "small", "violet", { align: "CENTER" })], { actions: [go("home")], name: "На главную" }),
  ];
  add("result", "10 · Result", result(false));
  add("result-help", "Состояние · решение с помощью", result(true), { state: true });
  const noteForm = (edit, filled, error = false) => [
    ...header("Личный конспект", edit ? "Изменить заметку" : "Новая заметка", "notes", "К уроку «Угол 45°»"),
    field("Название", filled ? (edit ? "Мой ориентир" : "Моя заметка") : "Нажмите для примера", 224, filled ? null : "create-filled", error ? "error" : filled ? "filled" : "empty"),
    field("Текст заметки", filled ? (edit ? "Половина прямого угла — 45°." : "Равные углы помогают увидеть связь.") : "Нажмите для примера", 330, filled ? null : "create-filled", filled ? "filled" : "empty"),
    txt("Ввод в прототипе: нажмите пустое поле.\nТекст примера появится в обоих полях.", 24, 442, 342, "small", "muted"),
    ...(error ? [txt("Заполните название и текст заметки.", 24, 502, 342, "small", "error")] : []),
    button(error ? "Заполнить пример" : "Сохранить", 574, filled ? [
      ...pair("noteExists", "noNote", true), ...pair("noteEdited", "noteOriginal", edit), go("notes"),
    ] : [go(error ? "create-filled" : "create-error")]),
    button("Отмена", 640, [go("notes")], "secondary"),
  ];
  add("create", "11 · Create / заметка", noteForm(false, false));
  add("create-filled", "Состояние · заметка заполнена", noteForm(false, true), { state: true });
  add("create-error", "Состояние · пустая заметка", noteForm(false, false, true), { state: true });
  add("edit", "12 · Edit / заметка", [
    ...header("Личный конспект", "Изменить заметку", "notes"),
    field("Название", "Моя заметка", 224, "edit-updated"),
    field("Текст заметки", "Равные углы помогают увидеть связь.", 330, "edit-updated"),
    txt("Нажмите поле, чтобы изменить пример.", 24, 442, 342, "small", "muted"),
    button("Изменить текст примера", 574, [go("edit-updated")]), button("Отмена", 640, [go("notes")], "secondary"),
  ]);
  add("edit-updated", "Состояние · заметка изменена", noteForm(true, true), { state: true });
  add("search", "13 · Search", [
    ...header("Найди нужную тему", "Поиск", "home"),
    field("Название урока", "Нажмите для поиска «угол»", 218, "search-results", "empty"),
    ...empty("Что хочешь изучить?", "Найди урок по названию.\nПример: угол.", 344, "search"),
    button("Найти «угол»", 624, [go("search-results")]),
    button("Пример: ничего не найдено", 690, [go("search-empty")], "secondary"),
  ]);
  add("search-results", "Состояние · результаты поиска", [
    ...header("Найдено: 1", "Поиск", "home"), field("Название урока", "угол", 218, "search", "filled"),
    txt("УРОКИ", 24, 338, 342, "overline", "violet"), lesson(376), button("Очистить поиск", 628, [go("search")], "secondary"),
  ], { state: true });
  add("search-empty", "Состояние · нет результатов", [
    ...header("Найдено: 0", "Поиск", "home"), field("Название урока", "окружность", 218, "search"),
    ...empty("Пока ничего", "Попробуй другое название.\nВ демо есть урок «Угол 45°».", 344, "search"), button("Изменить запрос", 624, [go("search")]),
  ], { state: true });
  add("favorites", "14 · Favorites", [
    ...header("Всегда под рукой", "Избранное", null),
    group(0, 0, 390, 720, [...empty("Здесь будут уроки", "Нажми на сердечко\nна странице урока.", 234), button("Выбрать урок", 528, [go("list")])], { when: "notFavorite" }),
    group(0, 0, 390, 720, [lesson(234), button("Убрать из избранного", 364, [toggle("favorite", "notFavorite")], "secondary")], { when: "favorite" }), nav("favorites"),
  ]);
  add("profile", "15 · Profile", [
    ...header("Мой путь", "Профиль", null), tapIcon("settings", 318, 48, [go("settings")], "text", "Настройки"),
    box(24, 220, 342, 104), box(44, 242, 56, 56, "elevated", 20), txt("А", 62, 254, 32, "title", "violet"),
    txt("Алия", 120, 239, 220, "title"), txt("Учусь в своём темпе", 120, 278, 220, "small", "muted"),
    group(24, 348, 342, 108, [box(0, 0, 342, 108), txt("0", 22, 16, 140, "h1", "violet"), txt("решено из 30", 22, 66, 150, "small", "muted"), txt("0", 192, 16, 128, "h1", "mint"), txt("навыков освоено", 192, 66, 140, "small", "muted")], { when: "notCompleted" }),
    group(24, 348, 342, 108, [box(0, 0, 342, 108), txt("1", 22, 16, 140, "h1", "violet"), txt("решено из 30", 22, 66, 150, "small", "muted"), txt("0", 192, 16, 128, "h1", "mint"), txt("навыков освоено", 192, 66, 140, "small", "muted")], { when: "completed" }),
    txt("Начни с первого урока.", 24, 482, 342, "small", "muted", { when: "notCompleted" }),
    txt("1 задача решена самостоятельно.", 24, 482, 342, "small", "mint", { when: "independent" }),
    txt("1 задача решена с подсказкой.", 24, 482, 342, "small", "warning", { when: "assisted" }),
    button("План повторения", 536, [go("review")]), button("Мои заметки", 602, [go("notes")], "secondary"),
    txt("Освоение: самостоятельное решение\nи 3 повторения в назначенные сроки.", 24, 678, 342, "label", "muted"), nav("profile"),
  ]);
  add("settings", "16 · Settings", [
    ...header("Удобно тебе", "Настройки", "profile"),
    txt("Вид прототипа", 24, 211, 342, "overline", "violet"),
    ...[["soundOn", "soundOff", "Звуки", 248], ["motionOn", "motionOff", "Анимации", 334]].map(([key, inverse, label, y]) => group(24, y, 342, 70, [
      box(0, 0, 342, 70), txt(label, 18, 23, 218, "body"),
      group(260, 17, 64, 36, [box(0, 0, 64, 36, "mint", 18), box(32, 4, 28, 28, "background", 14)], { when: key }),
      group(260, 17, 64, 36, [box(0, 0, 64, 36, "line", 18), box(4, 4, 28, 28, "muted", 14)], { when: inverse }),
    ], { actions: [toggle(key, inverse)], name: label })),
    txt("Переключатели показывают состояния\nинтерфейса; настройки приложения\nв этой работе не меняются.", 24, 438, 342, "small", "muted"),
    box(24, 552, 342, 104), icon("wifi", 44, 573, "mint"), txt("Данные на устройстве", 84, 572, 262, "button"), txt("Облачной синхронизации нет", 84, 606, 262, "label", "muted"),
    button("Сменить локальный профиль", 704, [go("login")], "secondary"),
  ]);
  add("notes", "17 · Notes / конспект", [
    ...header("Личный конспект", "Мои заметки", "home"),
    group(0, 0, 390, 700, empty("Пока чистый лист", "Запиши мысль после урока.\nЗаметку можно изменить.", 236, "book"), { when: "noNote" }),
    group(0, 0, 390, 700, [
      inst("card/note", 24, 236, {}, { when: "noteOriginal", actions: [go("edit")], name: "Открыть заметку" }),
      inst("card/note", 24, 236, { Title: "Мой ориентир", Body: "Половина прямого угла — 45°." }, { when: "noteEdited", actions: [go("edit-updated")], name: "Открыть изменённую заметку" }),
      button("Изменить заметку", 382, [{ type: "if", key: "noteEdited", yes: [go("edit-updated")], no: [go("edit")] }], "secondary"),
    ], { when: "noteExists" }),
    button("Новая заметка", 606, [go("create")], "primary", { when: "noNote" }),
    button("Вернуться к уроку", 672, [go("detail")], "secondary"),
  ]);
  add("review", "18 · Review / план", [
    ...header("Сохрани понимание", "Время повторить", "profile"),
    group(0, 0, 390, 700, [...empty("Сначала первый шаг", "Реши задачу самостоятельно,\nчтобы начать повторение.", 236, "repeat"), button("Открыть курс", 540, [go("list")])], { when: "notCompleted" }),
    group(0, 0, 390, 700, [box(24, 236, 342, 252), txt("Следующий шаг — завтра", 44, 260, 302, "title"), txt("После самостоятельной базы:\nчерез 1 день → 3 дня → 7 дней.\n\nРаннюю тренировку можно пройти\nсейчас. Она не подтверждает навык.", 44, 310, 302, "body", "muted"), button("Ранняя тренировка", 536, startPuzzle), txt("Даты здесь не рассчитываются.\nПоказана схема учебного повторения.", 24, 618, 342, "small", "muted")], { when: "independent" }),
    group(0, 0, 390, 700, [...empty("Теперь попробуй сам", "Для освоения нужна\nсамостоятельная базовая попытка.", 236, "repeat"), button("Решить без подсказки", 540, startPuzzle)], { when: "assisted" }),
    button("Вернуться в профиль", 704, [go("profile")], "secondary"),
  ]);
  return { colors: C, type: TYPE, initial: INITIAL, icons: ICONS, templates: templates(), screens, width: 390, height: 844 };
}

function svgIcon(key, color, size = 24) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 24 24"><path d="${ICONS[key]}" fill="none" stroke="${color}" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/></svg>`;
}

// Starter does not allow SET_VARIABLE or CONDITIONAL prototype actions.
// Bake the documented demonstration paths into native navigation-only frames.
function basicModel() {
  const data = model();
  const independent = { completed: true, notCompleted: false, independent: true };
  const assisted = { completed: true, notCompleted: false, assisted: true };
  const contexts = {
    independent: { state: independent, screens: ["home", "list", "detail", "profile", "review", "notes", "favorites"] },
    assisted: { state: assisted, screens: ["home", "list", "detail", "profile", "review"] },
    help: { state: { hintUsed: true }, screens: ["puzzle", "puzzle-ready", "puzzle-error"] },
    favorite: { state: { favorite: true, notFavorite: false }, screens: ["detail", "list", "favorites"] },
    saved: { state: { noteExists: true, noNote: false }, screens: ["notes", "edit", "edit-updated"] },
    edited: { state: { noteExists: true, noNote: false, noteEdited: true, noteOriginal: false }, screens: ["notes", "edit-updated"] },
    silent: { state: { soundOn: false, soundOff: true }, screens: ["settings"] },
    still: { state: { motionOn: false, motionOff: true }, screens: ["settings"] },
    quiet: { state: { soundOn: false, soundOff: true, motionOn: false, motionOff: true }, screens: ["settings"] },
  };
  function route(id, state) {
    if (id === "edit" && !state.noteEdited) return "edit";
    let context;
    if (id === "settings") context = !state.soundOn && !state.motionOn ? "quiet" : !state.soundOn ? "silent" : !state.motionOn ? "still" : null;
    else if (["notes", "edit", "edit-updated"].includes(id) && state.noteExists) context = state.noteEdited ? "edited" : "saved";
    else if (["puzzle", "puzzle-ready", "puzzle-error"].includes(id) && state.hintUsed) context = "help";
    else if (state.favorite && contexts.favorite.screens.includes(id)) context = "favorite";
    else if (state.independent && contexts.independent.screens.includes(id)) context = "independent";
    else if (state.assisted && contexts.assisted.screens.includes(id)) context = "assisted";
    return context && contexts[context].screens.includes(id) ? `${id}--${context}` : id;
  }
  function destination(items, initial, current) {
    const state = { ...initial }; let target = current;
    const run = actions => { for (const a of actions) {
      if (a.type === "go") target = a.id;
      else if (a.type === "set") state[a.key] = a.value;
      else if (a.type === "toggle") { state[a.key] = !state[a.key]; state[a.inverse] = !state[a.key]; }
      else if (a.type === "if") run(state[a.key] ? a.yes : a.no);
    } };
    run(items); return route(target, state);
  }
  function bake(spec, state, current) {
    if (spec.when && !state[spec.when]) return null;
    const result = { ...spec }; delete result.when;
    if (spec.actions) result.actions = [go(destination(spec.actions, state, current))];
    if (spec.children) result.children = spec.children.map(n => bake(n, state, current)).filter(Boolean);
    if (spec.kind === "instance" && spec.key.startsWith("navigation/")) result.navigationTargets = Object.fromEntries(["home", "list", "favorites", "profile"].map(id => [id, route(id, state)]));
    return result;
  }
  const original = data.screens;
  data.screens = original.map(s => {
    const state = { ...INITIAL, ...(s.id === "result" ? independent : s.id === "result-help" ? assisted : s.id === "hint" ? { hintUsed: true } : s.id === "edit" ? contexts.saved.state : {}) };
    return { ...s, children: s.children.map(n => bake(n, state, s.id)).filter(Boolean) };
  });
  for (const [key, context] of Object.entries(contexts)) for (const id of context.screens) {
    const source = original.find(s => s.id === id), state = { ...INITIAL, ...context.state };
    data.screens.push({ ...source, id: `${id}--${key}`, title: `Состояние · ${id} / ${key}`, state: true, children: source.children.map(n => bake(n, state, id)).filter(Boolean) });
  }
  return data;
}

// Three recoverable phases. The returned ledger is also used by the Figma connector.
// Variant-grid and semantic-alias patterns follow the bundled Figma skill helpers.
async function buildGeoSwipe(api, options = {}) {
  const data = options.basic ? basicModel() : model(), state = options.state || {}, phase = options.phase || "foundations";
  let page = state.pageId ? await api.getNodeByIdAsync(state.pageId) : api.createPage();
  await api.setCurrentPageAsync(page);
  const fonts = await api.listAvailableFontsAsync();
  for (const style of ["Regular", "Medium", "Bold"]) {
    if (!fonts.some(f => f.fontName.family === "Roboto" && f.fontName.style === style)) throw new Error(`Roboto ${style} недоступен`);
    await api.loadFontAsync({ family: "Roboto", style });
  }
  const rgb = hex => ({ r: parseInt(hex.slice(1, 3), 16) / 255, g: parseInt(hex.slice(3, 5), 16) / 255, b: parseInt(hex.slice(5, 7), 16) / 255 });
  const vars = {}, textStyles = {}, components = {}, properties = state.properties || {};
  const findAllIds = root => [root.id, ...root.findAll(() => true).map(n => n.id)];
  const snapshot = () => ({ ...state, pageId: page.id, phase, affectedNodeIds: findAllIds(page) });
  if (phase === "foundations") {
    if (page.children.length || (await api.variables.getLocalVariablesAsync()).length) throw new Error("Foundation phase expects an empty page/file; inspect before retry.");
    page.name = "GeoSwipe · Практическая работа 2";
    state.pageId = page.id; state.variables = {}; state.textStyles = {}; state.frames = {}; state.collections = {};
    function collection(name) {
      const c = api.variables.createVariableCollection(`GeoSwipe / ${name}`);
      c.renameMode(c.defaultModeId, name === "Colors" ? "Dark" : "Value"); state.collections[name] = c.id; return c;
    }
    function variable(c, name, type, value, scopes, syntax) {
      const v = api.variables.createVariable(name, c, type);
      // Figma accepts only ALL_SCOPES for BOOLEAN; these runtime flags are private.
      v.scopes = type === "BOOLEAN" ? ["ALL_SCOPES"] : scopes;
      if (type === "BOOLEAN") v.hiddenFromPublishing = true;
      v.setValueForMode(c.defaultModeId, value);
      v.setVariableCodeSyntax("WEB", `var(--gs-${name.replace(/[\s/]+/g, "-")})`);
      v.setVariableCodeSyntax("ANDROID", syntax || name.replace(/\//g, "."));
      state.variables[name] = v.id; vars[name] = v; return v;
    }
    const primitives = collection("Primitives"), colors = collection("Colors"), layout = collection("Layout"), runtime = collection("Prototype state");
    const semanticNames = { background: "color/bg/primary", surface: "color/bg/card", elevated: "color/bg/elevated", violet: "color/action/primary", blue: "color/action/secondary", mint: "color/accent/success", text: "color/text/primary", muted: "color/text/secondary", line: "color/border/default", warning: "color/status/warning", error: "color/status/error" };
    state.colorKeys = semanticNames;
    for (const [key, hex] of Object.entries(C)) {
      const p = variable(primitives, `primitive/${key}`, "COLOR", rgb(hex), [], `AppColors.${key}`);
      variable(colors, semanticNames[key], "COLOR", { type: "VARIABLE_ALIAS", id: p.id }, ["FRAME_FILL", "SHAPE_FILL", "TEXT_FILL", "STROKE_COLOR"], `AppColors.${key}`);
    }
    for (const n of [0, 1, 2, 3, 5, 8, 9, 12, 14, 16, 17, 18, 20, 24, 56]) variable(layout, `radius/${n}`, "FLOAT", n, ["CORNER_RADIUS"]);
    for (const n of [4, 6, 8, 12, 15, 16, 18, 24, 32]) variable(layout, `space/${n}`, "FLOAT", n, ["GAP"]);
    for (const [key, value] of Object.entries(INITIAL)) variable(runtime, `state/${key}`, "BOOLEAN", value, []);
    for (const [key, [size, height, style]] of Object.entries(TYPE)) {
      const s = api.createTextStyle(); s.name = `GeoSwipe/${key}`; s.fontName = { family: "Roboto", style };
      s.fontSize = size; s.lineHeight = { unit: "PIXELS", value: height }; state.textStyles[key] = s.id;
    }
    const board = api.createFrame(); board.name = "00 · Design System"; board.resize(1792, 2140); board.x = 200; board.y = 200;
    board.fills = [{ type: "SOLID", color: rgb(C.background) }]; page.appendChild(board); state.boardId = board.id;
    const sorted = [...data.screens.filter(s => !s.state), ...data.screens.filter(s => s.state)];
    for (let i = 0; i < sorted.length; i++) {
      const s = sorted[i], f = api.createFrame(); page.appendChild(f); f.name = `${s.title} [${s.id}]`;
      f.resize(390, 844); f.x = 200 + (i % 4) * 438; f.y = 2500 + Math.floor(i / 4) * 948;
      f.fills = [api.variables.setBoundVariableForPaint({ type: "SOLID", color: rgb(C.background) }, "color", vars[semanticNames.background])]; f.clipsContent = true;
      f.layoutGrids = [{ pattern: "COLUMNS", alignment: "STRETCH", count: 4, gutterSize: 16, offset: 24, visible: false, color: { r: .66, g: .59, b: 1, a: .1 } }];
      state.frames[s.id] = f.id;
    }
    state.counts = { mainScreens: 18, states: sorted.length - 18, variables: Object.keys(state.variables).length, textStyles: Object.keys(state.textStyles).length };
    return snapshot();
  }
  for (const [key, id] of Object.entries(state.variables)) vars[key] = await api.variables.getVariableByIdAsync(id);
  for (const [key, id] of Object.entries(state.textStyles)) textStyles[key] = await api.getStyleByIdAsync(id);
  for (const [key, id] of Object.entries(state.components || {})) components[key] = await api.getNodeByIdAsync(id);
  const paint = key => [api.variables.setBoundVariableForPaint({ type: "SOLID", color: rgb(C[key]) }, "color", vars[state.colorKeys[key]])];
  const radius = (node, n) => { node.cornerRadius = n; if (vars[`radius/${n}`]) for (const field of ["topLeftRadius", "topRightRadius", "bottomLeftRadius", "bottomRightRadius"]) node.setBoundVariable(field, vars[`radius/${n}`]); };
  function space(node, field, n) { node[field] = n; if (vars[`space/${n}`]) node.setBoundVariable(field, vars[`space/${n}`]); }
  const interactions = [];
  async function render(spec, parent, labels = {}, wire = true) {
    let node;
    if (spec.kind === "text") {
      node = api.createText(); node.fontName = { family: "Roboto", style: TYPE[spec.style][2] };
      await node.setTextStyleIdAsync(textStyles[spec.style].id);
      node.characters = labels[spec.name] !== undefined ? labels[spec.name] : spec.text;
      node.textAutoResize = "HEIGHT"; node.resize(spec.w, spec.h); node.textAlignHorizontal = spec.align || "LEFT"; node.fills = paint(spec.color);
    } else if (spec.kind === "rect") {
      node = api.createRectangle(); node.resize(spec.w, spec.h); node.fills = paint(spec.fill); radius(node, spec.radius);
      if (spec.stroke) { node.strokes = paint(spec.stroke); node.strokeWeight = 1; }
    } else if (spec.kind === "icon") {
      const master = components[`icon/${spec.key}`];
      node = master ? master.createInstance() : api.createNodeFromSvg(svgIcon(spec.key, C[spec.color], spec.w));
      if (master && spec.w !== 24) node.rescale(spec.w / 24);
      for (const v of node.findAllWithCriteria({ types: ["VECTOR"] })) if (Array.isArray(v.strokes) && v.strokes.length) v.strokes = paint(spec.color);
    } else if (spec.kind === "path") {
      node = api.createNodeFromSvg(`<svg xmlns="http://www.w3.org/2000/svg" width="${spec.w}" height="${spec.h}" viewBox="0 0 ${spec.w} ${spec.h}"><path d="${spec.d}" fill="none" stroke="${C[spec.color]}" stroke-width="${spec.weight}" stroke-linecap="round" stroke-linejoin="round"/></svg>`);
      for (const v of node.findAllWithCriteria({ types: ["VECTOR"] })) v.strokes = paint(spec.color);
    } else if (spec.kind === "instance") {
      node = components[spec.key].createInstance();
      const values = {};
      const defaults = {};
      const collect = n => { if (n.kind === "text" && n.name) defaults[n.name] = n.text; for (const c of n.children || []) collect(c); };
      for (const child of data.templates[spec.key].children) collect(child);
      for (const [name, value] of Object.entries({ ...defaults, ...spec.labels })) if (properties[spec.key] && properties[spec.key][name]) values[properties[spec.key][name]] = value;
      if (Object.keys(values).length) node.setProperties(values);
      if (wire && spec.key.startsWith("navigation/")) for (const child of node.children) if (child.name.startsWith("Nav/") && child.name.slice(4) !== spec.key.slice(11)) interactions.push([child, [go(spec.navigationTargets ? spec.navigationTargets[child.name.slice(4)] : child.name.slice(4))]]);
    } else {
      node = api.createFrame(); node.resize(spec.w, spec.h); node.fills = []; node.clipsContent = false;
      for (const child of spec.children) await render(child, node, labels, wire);
    }
    parent.appendChild(node); node.x = spec.x || 0; node.y = spec.y || 0; node.name = spec.name || spec.key || spec.kind;
    if (spec.when) node.setBoundVariable("visible", vars[`state/${spec.when}`]);
    if (wire && spec.actions) interactions.push([node, spec.actions]);
    return node;
  }
  function auto(parent, name, w, h, direction = "VERTICAL") {
    // Native plugins do not expose createAutoLayout; the connector does.
    const n = typeof api.createAutoLayout === "function" ? api.createAutoLayout(direction) : api.createFrame();
    n.layoutMode = direction; parent.appendChild(n); n.name = name; n.resize(w, h); n.fills = []; n.clipsContent = false;
    n.primaryAxisSizingMode = "FIXED"; n.counterAxisSizingMode = "FIXED"; return n;
  }
  const board = await api.getNodeByIdAsync(state.boardId);
  if (phase === "basic-foundations") {
    const sorted = [...data.screens.filter(s => !s.state), ...data.screens.filter(s => s.state)];
    for (let i = 0; i < sorted.length; i++) if (!state.frames[sorted[i].id]) {
      const s = sorted[i], f = api.createFrame(); page.appendChild(f); f.name = `${s.title} [${s.id}]`;
      f.resize(390, 844); f.x = 200 + (i % 4) * 438; f.y = 2500 + Math.floor(i / 4) * 948;
      f.fills = paint("background"); f.clipsContent = true; state.frames[s.id] = f.id;
    }
    state.basic = true; state.counts.states = sorted.length - 18;
    return snapshot();
  }
  if (phase === "components") {
    if (board.children.length) throw new Error("Component phase already started; inspect before retry.");
    await render(txt("GeoSwipe / Design System", 32, 28, 1728, "display"), board, {}, false);
    await render(txt("Практическая работа №2 · Android · 390 × 844 · сетка 4 колонки · шаг 8 px · цель касания ≥ 48 px", 32, 94, 1728, "small", "muted"), board, {}, false);
    let i = 0;
    for (const [key, hex] of Object.entries(C)) {
      const x = 32 + (i % 6) * 288, y = 148 + Math.floor(i / 6) * 94; i++;
      await render(box(x, y, 48, 48, key, 12, { stroke: "line" }), board, {}, false);
      await render(txt(`${key}\n${hex}`, x + 62, y + 2, 210, "small", "muted"), board, {}, false);
    }
    i = 0;
    for (const [key, [size, height]] of Object.entries(TYPE)) {
      await render(txt(`${key} · ${size}/${height}`, 32 + Math.floor(i / 5) * 860, 370 + (i % 5) * 58, 800, key), board, {}, false); i++;
    }
    // Icons precede dependent components. Every screen uses instances of these masters.
    const ordered = Object.entries(data.templates).sort(([a], [b]) => Number(b.startsWith("icon/")) - Number(a.startsWith("icon/")));
    for (const [key, spec] of ordered) {
      const c = api.createComponent(); board.appendChild(c); c.name = key; c.resize(spec.w, spec.h); c.fills = []; c.clipsContent = false;
      c.description = `GeoSwipe: ${key}. Экземпляры связаны с токенами темы. Текст меняется через свойства компонента.`;
      if (key.startsWith("button/")) {
        c.layoutMode = "HORIZONTAL"; c.primaryAxisAlignItems = "CENTER"; c.counterAxisAlignItems = "CENTER"; c.fills = paint(spec.children[0].fill); radius(c, 17);
        space(c, "paddingLeft", 16); space(c, "paddingRight", 16);
        await render(spec.children[1], c, {}, false);
      } else if (key.startsWith("field/")) {
        c.layoutMode = "VERTICAL"; space(c, "itemSpacing", 8);
        await render(spec.children[0], c, {}, false);
        const body = auto(c, "Input", 342, 54, "HORIZONTAL"); body.fills = paint("surface"); body.strokes = paint(key.endsWith("error") ? "error" : "line"); radius(body, 16);
        space(body, "paddingLeft", 16); space(body, "paddingRight", 16); body.counterAxisAlignItems = "CENTER";
        await render({ ...spec.children[2], x: 0, y: 0 }, body, {}, false);
      } else if (key.startsWith("navigation/")) {
        c.layoutMode = "HORIZONTAL"; c.primaryAxisAlignItems = "SPACE_BETWEEN"; c.fills = paint("background"); space(c, "paddingTop", 6); space(c, "paddingBottom", 12);
        for (const slot of spec.children.filter(n => n.kind === "group")) {
          const item = auto(c, slot.name, 96, 66); item.counterAxisAlignItems = "CENTER"; space(item, "itemSpacing", 6);
          const pill = auto(item, "Indicator", 56, 32, "HORIZONTAL"); pill.primaryAxisAlignItems = "CENTER"; pill.counterAxisAlignItems = "CENTER"; radius(pill, 16);
          if (slot.children.some(n => n.kind === "rect")) pill.fills = paint("elevated");
          await render({ ...slot.children.find(n => n.kind === "icon"), x: 0, y: 0 }, pill, {}, false);
          await render({ ...slot.children.find(n => n.kind === "text"), x: 0, y: 0 }, item, {}, false);
        }
      } else {
        for (const child of spec.children) await render(child, c, {}, false);
      }
      components[key] = c;
    }
    state.components = {}; state.componentSets = {}; state.properties = properties;
    // Mirrors createComponentWithVariants: combine, then position and resize variants.
    for (const [family, y] of [["button", 728], ["field", 960], ["card", 1190], ["navigation", 1430]]) {
      const keys = Object.keys(components).filter(k => k.startsWith(`${family}/`));
      for (const key of keys) {
        const suffix = key.split("/")[1];
        components[key].name = family === "button" ? `Style=${["disabled", "pressed"].includes(suffix) ? "Primary" : suffix}, State=${suffix === "disabled" ? "Disabled" : suffix === "pressed" ? "Pressed" : "Default"}` : `${family === "navigation" ? "Active" : "State"}=${suffix}`;
      }
      const setNode = api.combineAsVariants(keys.map(k => components[k]), board); setNode.name = `GeoSwipe/${family}`;
      setNode.description = `${family}: используйте варианты и свойства текста. Цвета и радиусы связаны с переменными GeoSwipe.`;
      setNode.x = 32; setNode.y = y; setNode.fills = []; setNode.resize(1728, family === "card" ? 180 : 170);
      keys.forEach((k, j) => { components[k].x = 12 + (j % 4) * 426; components[k].y = 26 + Math.floor(j / 4) * 74; });
      const names = new Map();
      for (const key of keys) for (const t of components[key].findAllWithCriteria({ types: ["TEXT"] })) if (["Label", "Caption", "Value", "Title", "Subtitle", "Body"].includes(t.name)) names.set(t.name, t.characters);
      const p = {};
      for (const [name, value] of names) p[name] = setNode.addComponentProperty(name, "TEXT", value);
      for (const key of keys) {
        properties[key] = p;
        for (const t of components[key].findAllWithCriteria({ types: ["TEXT"] })) if (p[t.name]) t.componentPropertyReferences = { characters: p[t.name] };
      }
      state.componentSets[family] = setNode.id;
      await render(txt(family, 32, y - 24, 1728, "label", "muted"), board, {}, false);
    }
    let iconIndex = 0;
    for (const [key, c] of Object.entries(components)) {
      state.components[key] = c.id;
      if (key.startsWith("icon/")) { c.x = 32 + iconIndex++ * 80; c.y = 1760; }
      if (key.startsWith("tag/")) {
        c.x = 1298; c.y = 1240; const t = c.findAllWithCriteria({ types: ["TEXT"] })[0];
        const p = c.addComponentProperty("Label", "TEXT", t.characters); t.componentPropertyReferences = { characters: p }; properties[key] = { Label: p };
      }
    }
    await render(txt("Основной сценарий: Splash → Login → Home → List → Detail → Puzzle → Result → Profile\nФормы: пример заполняется по нажатию. Starter: фиксированные сценарии на обычных переходах.\nЭто учебный прототип: данные не записываются в приложение. Новые профили, заметки и поиск — проектные экраны.\nРешение с подсказкой, самостоятельное решение и подтверждённое освоение разделены. Шрифт: Roboto.", 32, 1888, 1728, "small", "muted"), board, {}, false);
    board.name = "Библиотека / Main components";
    const review = api.createFrame(); page.appendChild(review); review.name = "00 · Design System / Review";
    review.resize(1792, 2140); review.x = 2200; review.y = 200; review.fills = paint("background");
    for (const n of board.children) if (["TEXT", "RECTANGLE"].includes(n.type) && n.y < 700) review.appendChild(n.clone());
    const positions = {};
    for (const key of Object.keys(data.templates)) {
      const family = key.split("/")[0], j = positions[family] || 0; positions[family] = j + 1;
      const x = family === "icon" ? 32 + j * 80 : family === "tag" ? 1298 : 44 + (j % 4) * 426;
      const y = family === "icon" ? 1760 : family === "tag" ? 1240 : ({ button: 754, field: 986, card: 1216, navigation: 1456 })[family] + Math.floor(j / 4) * 74;
      await render(inst(key, x, y), review, {}, false);
    }
    for (const [label, y] of [["Button: primary / secondary / success / disabled / pressed", 704], ["Field: empty / filled / error", 936], ["Card: lesson / note", 1166], ["Navigation: home / course / favorites / profile", 1406]]) await render(txt(label, 32, y, 1728, "small", "muted"), review, {}, false);
    await render(txt("Сценарий: Splash → Login → Home → List → Detail → действие → Profile\nStarter: обычные переходы между фиксированными сценариями; данные сценариев не объединяются.\nФормы заполняются примером по нажатию. Прототип не записывает данные в приложение.\nРешение с помощью, самостоятельное решение и освоение — разные состояния.", 32, 1888, 1728, "small", "muted"), review, {}, false);
    state.reviewBoardId = review.id;
    state.counts.components = Object.keys(components).length; state.counts.componentSets = 4;
    return snapshot();
  }
  if (phase !== "screens") throw new Error(`Unknown phase: ${phase}`);
  for (const screen of data.screens) {
    const f = await api.getNodeByIdAsync(state.frames[screen.id]);
    if (f.children.length) throw new Error(`Screen ${screen.id} already has content; inspect before retry.`);
    await render(txt("9:41", 24, 14, 80, "label"), f);
    await render(txt("●  ▰", 306, 14, 60, "label", "muted", { align: "RIGHT" }), f);
    for (const spec of screen.children) await render(spec, f);
    await render(box(139, 825, 112, 4, "muted", 2), f);
    await render(txt(screen.title, f.x, f.y - 36, 390, "small", "muted"), page, {}, false);
  }
  const expression = key => ({ type: "VARIABLE_ALIAS", resolvedType: "BOOLEAN", value: { type: "VARIABLE_ALIAS", id: vars[`state/${key}`].id } });
  function actions(items) {
    return items.map(a => {
      if (a.type === "go") return { type: "NODE", destinationId: state.frames[a.id], navigation: "NAVIGATE", transition: null, resetScrollPosition: true };
      if (a.type === "set") return { type: "SET_VARIABLE", variableId: vars[`state/${a.key}`].id, variableValue: { type: "BOOLEAN", resolvedType: "BOOLEAN", value: a.value } };
      if (a.type === "toggle") return { type: "CONDITIONAL", conditionalBlocks: [{ condition: expression(a.key), actions: actions(pair(a.key, a.inverse, false)) }, { actions: actions(pair(a.key, a.inverse, true)) }] };
      return { type: "CONDITIONAL", conditionalBlocks: [{ condition: expression(a.key), actions: actions(a.yes) }, { actions: actions(a.no) }] };
    });
  }
  for (const [node, items] of interactions) await node.setReactionsAsync([{ trigger: { type: "ON_CLICK" }, actions: actions(items) }]);
  page.flowStartingPoints = [{ nodeId: state.frames.splash, name: "Основной сценарий" }, { nodeId: state.frames["onboarding-1"], name: "Знакомство" }];
  page.selection = [await api.getNodeByIdAsync(state.frames.splash)];
  state.counts.hotspots = interactions.length;
  api.viewport.scrollAndZoomIntoView([await api.getNodeByIdAsync(state.frames.splash), await api.getNodeByIdAsync(state.frames.login)]);
  return snapshot();
}

async function createFigmaPrototype(api) {
  let state;
  for (const phase of ["foundations", "components", "screens"]) state = await buildGeoSwipe(api, { phase, state, basic: true });
  api.closePlugin("Созданы 18 экранов, 37 состояний, компоненты и переходы для Starter. Запустите Present с 01 · Splash.");
  return state;
}
if (typeof module !== "undefined") module.exports = { model, basicModel, createFigmaPrototype, buildGeoSwipe, svgIcon };
if (typeof figma !== "undefined") createFigmaPrototype(figma).catch(error => figma.closePlugin(`Не удалось завершить: ${error.message}. Созданные слои сохранены.`));

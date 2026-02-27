/**
 * ======================================================================
 * 双極AI GAS エンドポイント（v1.1.0）
 * ======================================================================
 */

/** ====== 設定 ====================================================== */
const CFG = {
  SHEET_DAILY_LOG: 'Daily_Log',
  SHEET_DAILY_OUTPUT: 'Daily_Output',
  SHEET_DRIVERS_LONG: 'Drivers_Long',
  SHEET_COPING_LONG: 'Coping_Long',
  SHEET_REBOOT_LOG: 'Reboot_Log',
  SHEET_CRISIS_PLAN: 'CrisisPlan_Source',
  SHEET_SETTINGS_ALGORITHM: 'Settings_Algorithm',
  SHEET_SETTINGS_WEIGHTS: 'Settings_Weights',
  SHEET_ENABLED_METRICS: 'Enabled_Metrics',
  SERVICE_NAME: 'bipolar-ai-gas',
  VERSION: 'v1.2.0'
};

/** ====== OpenAI API設定 =========================================== */
function getOpenAIKey() {
  const props = PropertiesService.getScriptProperties();
  const key = props.getProperty('OPENAI_API_KEY');
  if (!key) throw new Error('OPENAI_API_KEY not set in Script Properties');
  return key;
}

/** ====== ユーティリティ =========================================== */
function _ss() {
  return SpreadsheetApp.openById('1Dk4MK5ITmAimxFhnY1Ji-qxw7qx2BIgxDni03aL269k');
}

function _sheetOrThrow(name) {
  const s = _ss().getSheetByName(name);
  if (!s) throw new Error('Sheet not found: ' + name);
  return s;
}

function _nowISO() { return new Date().toISOString(); }

function _json(obj) {
  const ct = ContentService.createTextOutput(JSON.stringify(obj));
  ct.setMimeType(ContentService.MimeType.JSON);
  return ct;
}

/** 数値をクランプ */
function _clamp(val, min, max) {
  return Math.max(min, Math.min(max, val));
}

/** 配列のmedian */
function _median(arr) {
  if (!arr.length) return 0;
  const sorted = arr.slice().sort(function(a, b) { return a - b; });
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
}

/** シート内で指定日付の行番号を返す（見つからなければ -1） */
function _findRowByDate(sheet, dateStr) {
  var lastRow = sheet.getLastRow();
  var lastCol = sheet.getLastColumn();
  if (lastRow < 2 || lastCol < 1) return -1;

  var header = sheet.getRange(1, 1, 1, lastCol).getValues()[0];
  var dateCol = -1;
  for (var c = 0; c < header.length; c++) {
    if (String(header[c]).trim() === 'date') { dateCol = c; break; }
  }
  if (dateCol < 0) return -1;

  var dates = sheet.getRange(2, dateCol + 1, lastRow - 1, 1).getValues();
  for (var i = dates.length - 1; i >= 0; i--) {
    if (String(dates[i][0]).trim() === String(dateStr).trim()) {
      return i + 2; // 1-based + header row
    }
  }
  return -1;
}

/** Settings_Algorithmからパラメータを読む */
function _loadAlgorithmSettings() {
  var defaults = {
    netstage_subj_weight: 0.5,
    netstage_obj_weight: 0.5,
    subj_median_weight: 0.7,
    subj_maxabs_weight: 0.3,
    gap_warning_threshold: 2,
    intake_kcal_target: 1832,
    intake_kcal_low_threshold: 1000,
    intake_kcal_high_threshold: 3000,
    intake_kcal_low_streak_days: 3,
    intake_kcal_high_streak_days: 3,
    intake_kcal_missing_streak_days: 4,
    intake_kcal_missing_danger: 3,
    mindfulness_min_threshold: 10,
    mindfulness_danger_relief: -3,
    reboot_trigger_days: 4,
    reboot_fade_day: 21
  };
  try {
    var sh = _sheetOrThrow(CFG.SHEET_SETTINGS_ALGORITHM);
    var data = sh.getDataRange().getValues();
    for (var i = 1; i < data.length; i++) {
      var key = String(data[i][0]).trim();
      var val = data[i][1];
      if (key && val !== '' && val !== undefined) {
        defaults[key] = Number(val);
      }
    }
  } catch (e) {
    Logger.log('Settings_Algorithm load error: ' + e);
  }
  return defaults;
}

/** Settings_Weightsからドメイン重みを読む */
function _loadWeights() {
  var defaults = {
    sleep: 4, activity: 3, active_energy: 3, nap: 3,
    thinking: 2, intake_kcal: 3, weight_domain: 2
  };
  try {
    var sh = _sheetOrThrow(CFG.SHEET_SETTINGS_WEIGHTS);
    var data = sh.getDataRange().getValues();
    for (var i = 1; i < data.length; i++) {
      var domain = String(data[i][0]).trim();
      var w = Number(data[i][1]);
      if (domain && !isNaN(w)) defaults[domain] = w;
    }
  } catch (e) {
    Logger.log('Settings_Weights load error: ' + e);
  }
  return defaults;
}

/** ====== ヘルスチェック =========================================== */
function doGet(e) {
  try {
    var mode = (e.parameter.mode || '').toLowerCase();
    if (mode === 'health') {
      return _json({ ok: true, service: CFG.SERVICE_NAME, version: CFG.VERSION, now: _nowISO() });
    }
    return _json({ ok: true, note: 'Use ?mode=health for health check', service: CFG.SERVICE_NAME, version: CFG.VERSION });
  } catch (err) {
    return _json({ ok: false, error: String(err) });
  }
}

/** ====== POST：日次データ処理 ====================================== */
function doPost(e) {
  try {
    var raw = e.postData && e.postData.contents;
    if (!raw) return _json({ ok: false, error: 'empty body' });

    var inputData = JSON.parse(raw);
    var action = inputData.action || 'checkin';

    // アクション分岐
    if (action === 'health_sync') {
      return _handleHealthSync(inputData);
    }

    var settings = _loadAlgorithmSettings();
    var weights = _loadWeights();

    // 1. Daily_Logに保存（upsert: ヘルスデータが先に入っていればマージ）
    var logId = _saveDailyLog(inputData);

    // 2. Thinking判定（OpenAI）
    var thinkingResult = _analyzeThinking(inputData);

    // 3. NetStage/Danger計算
    var calculationResult = _calculateNetStageAndDanger(inputData, thinkingResult, settings, weights);

    // 4. TopDrivers/Coping3生成
    var drivers = _extractTopDrivers(calculationResult);
    var coping3 = _extractCoping3(calculationResult);

    // 5. LINE通知メッセージ生成
    var lineMsg = _buildLineMessage(inputData, calculationResult, drivers, coping3);

    // 6. Daily_Outputに保存
    var outputId = _saveDailyOutput(inputData, calculationResult, drivers, coping3, thinkingResult);

    // 7. Drivers_Long/Coping_Longに保存
    _saveDriversLong(outputId, drivers);
    _saveCopingLong(outputId, coping3);

    // 8. Reboot判定
    var rebootStatus = _checkRebootStatus(inputData.date, settings);

    return _json({
      ok: true,
      log_id: logId,
      output_id: outputId,
      net_stage: calculationResult.netStage,
      danger: calculationResult.danger,
      risk_color: calculationResult.riskColor,
      subj_stage: calculationResult.subjStage,
      obj_stage: calculationResult.objStage,
      gap: calculationResult.gap,
      top_drivers: drivers,
      coping3: coping3,
      reboot: rebootStatus,
      line_message: lineMsg,
      line_send_immediate: calculationResult.riskColor === 'Orange' || calculationResult.riskColor === 'Red' || calculationResult.riskColor === 'DarkRed',
      version: CFG.VERSION
    });

  } catch (err) {
    return _json({ ok: false, error: String(err), stack: err.stack });
  }
}

/** ====== HealthKit同期ハンドラ ===================================== */
function _handleHealthSync(data) {
  var lock = LockService.getScriptLock();
  try {
    lock.waitLock(10000);

    if (!data.date) return _json({ ok: false, error: 'date is required' });

    var sh = _sheetOrThrow(CFG.SHEET_DAILY_LOG);
    var lastCol = sh.getLastColumn();
    if (lastCol < 1) {
      sh.appendRow(['date', 'mood_score', 'journal_text', 'q_mood_stage', 'q_thinking_stage', 'q_body_stage', 'q_behavior_stage', 'q4_status', 'meds_am_taken', 'meds_pm_taken', 'sleep_min', 'nap_min', 'steps', 'active_energy_kcal', 'intake_energy_kcal', 'alcohol_drinks', 'mindfulness_min']);
      lastCol = sh.getLastColumn();
    }
    var header = sh.getRange(1, 1, 1, lastCol).getValues()[0];
    var healthFields = ['sleep_min', 'nap_min', 'steps', 'active_energy_kcal', 'intake_energy_kcal', 'alcohol_drinks', 'mindfulness_min'];

    var existingRowIdx = _findRowByDate(sh, data.date);
    var hasMoodData = false;

    if (existingRowIdx > 0) {
      // 既存行のヘルスフィールドだけ更新
      var current = sh.getRange(existingRowIdx, 1, 1, lastCol).getValues()[0];
      header.forEach(function(col, idx) {
        var key = String(col).trim();
        if (healthFields.indexOf(key) >= 0 && data[key] !== undefined && data[key] !== null) {
          current[idx] = data[key];
        }
      });
      sh.getRange(existingRowIdx, 1, 1, lastCol).setValues([current]);

      // mood_scoreが既にあるか確認
      var moodIdx = -1;
      for (var c = 0; c < header.length; c++) {
        if (String(header[c]).trim() === 'mood_score') { moodIdx = c; break; }
      }
      hasMoodData = moodIdx >= 0 && current[moodIdx] !== '' && current[moodIdx] !== undefined && current[moodIdx] !== null;
    } else {
      // 新規行（ヘルスデータのみ）
      var newRow = header.map(function(col) {
        var key = String(col).trim();
        if (key === 'date') return data.date;
        if (healthFields.indexOf(key) >= 0 && data[key] !== undefined && data[key] !== null) return data[key];
        return '';
      });
      sh.appendRow(newRow);
    }

    // mood_scoreが既にある場合は再計算
    if (hasMoodData) {
      // 既存行の全データをオブジェクトとして読み取る
      var fullRow = sh.getRange(existingRowIdx, 1, 1, lastCol).getValues()[0];
      var rowData = {};
      header.forEach(function(col, idx) { rowData[String(col).trim()] = fullRow[idx]; });

      var settings = _loadAlgorithmSettings();
      var weights = _loadWeights();
      var thinkingResult = _analyzeThinking(rowData);
      var calcResult = _calculateNetStageAndDanger(rowData, thinkingResult, settings, weights);
      var drivers = _extractTopDrivers(calcResult);
      var coping3 = _extractCoping3(calcResult);
      _saveDailyOutput(rowData, calcResult, drivers, coping3, thinkingResult);

      return _json({
        ok: true,
        action: 'health_sync',
        date: data.date,
        health_updated: true,
        recalculated: true,
        net_stage: calcResult.netStage,
        danger: calcResult.danger,
        risk_color: calcResult.riskColor
      });
    }

    return _json({
      ok: true,
      action: 'health_sync',
      date: data.date,
      health_updated: true,
      recalculated: false,
      note: 'ヘルスデータ保存済み。気分チェックイン待ち。'
    });

  } finally {
    lock.releaseLock();
  }
}

/** ====== Daily_Log保存（upsert: 同日の行があれば更新、なければ追加） */
function _saveDailyLog(data) {
  var sh = _sheetOrThrow(CFG.SHEET_DAILY_LOG);
  var lastCol = sh.getLastColumn();
  if (lastCol < 1) {
    sh.appendRow(['date', 'mood_score', 'journal_text', 'q_mood_stage', 'q_thinking_stage', 'q_body_stage', 'q_behavior_stage', 'q4_status', 'meds_am_taken', 'meds_pm_taken', 'sleep_min', 'nap_min', 'steps', 'active_energy_kcal', 'intake_energy_kcal', 'alcohol_drinks', 'mindfulness_min']);
    lastCol = sh.getLastColumn();
  }
  var header = sh.getRange(1, 1, 1, lastCol).getValues()[0];

  var existingRow = _findRowByDate(sh, data.date);

  if (existingRow > 0) {
    // 既存行をマージ更新（新データで上書き、未指定フィールドは既存値を保持）
    var current = sh.getRange(existingRow, 1, 1, lastCol).getValues()[0];
    header.forEach(function(col, idx) {
      var key = String(col).trim();
      var v = data[key];
      if (v !== undefined && v !== null) {
        current[idx] = v;
      }
    });
    sh.getRange(existingRow, 1, 1, lastCol).setValues([current]);
    return existingRow;
  } else {
    // 新規行を追加
    var row = header.map(function(col) {
      var v = data[col];
      return (v === undefined || v === null) ? '' : v;
    });
    sh.appendRow(row);
    return sh.getLastRow();
  }
}

/** ====== Thinking判定（OpenAI）===================================== */
function _analyzeThinking(data) {
  var journalText = data.journal_text || '';
  if (!journalText || journalText.trim() === '') {
    return { thinking_stage: 0, polarity: 'neutral', confidence: 0, signals: [], evidence_quotes: [], note: 'ジャーナル未入力' };
  }

  try {
    var apiKey = getOpenAIKey();
    var prompt = '以下のテキストを分析し、双極性障害の状態（躁/鬱/中立）を判定してください。\n\nテキスト：\n' + journalText +
      '\n\n追加コンテキスト：\n- Mood: ' + (data.mood_score || 'N/A') +
      '\n- 睡眠: ' + (data.sleep_min || 'N/A') + '分' +
      '\n- 歩数: ' + (data.steps || 'N/A') + '歩' +
      '\n\n以下のJSON形式で返してください：\n{"thinking_stage": -5から+5の整数, "polarity": "depression"|"mania"|"neutral", "confidence": 0.0-1.0, "signals": [{"label":"...", "score":0-5}], "evidence_quotes": ["..."], "note": "短い注意書き"}';

    var payload = {
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: 'あなたは双極性障害のセルフマネジメント支援AIです。テキストから思考状態を正確に判定し、根拠を示してください。' },
        { role: 'user', content: prompt }
      ],
      temperature: 0.3,
      response_format: { type: 'json_object' }
    };

    var response = UrlFetchApp.fetch('https://api.openai.com/v1/chat/completions', {
      method: 'post',
      headers: { 'Authorization': 'Bearer ' + apiKey, 'Content-Type': 'application/json' },
      payload: JSON.stringify(payload)
    });

    var responseData = JSON.parse(response.getContentText());
    if (responseData.choices && responseData.choices[0]) {
      return JSON.parse(responseData.choices[0].message.content);
    }
    throw new Error('Invalid OpenAI response');
  } catch (err) {
    Logger.log('OpenAI Error: ' + err);
    return { thinking_stage: 0, polarity: 'neutral', confidence: 0, signals: [], evidence_quotes: [], note: 'エラー: ' + String(err) };
  }
}

/** ====== NetStage/Danger計算 ====================================== */
function _calculateNetStageAndDanger(data, thinkingResult, settings, weights) {
  // --- SubjStage: 0.7*median + 0.3*maxAbs ---
  var subjScores = [];
  var mood = Number(data.mood_score) || 0;
  subjScores.push(mood);
  if (data.q_mood_stage !== undefined && data.q_mood_stage !== null && data.q_mood_stage !== '') subjScores.push(Number(data.q_mood_stage));
  if (data.q_thinking_stage !== undefined && data.q_thinking_stage !== null && data.q_thinking_stage !== '') subjScores.push(Number(data.q_thinking_stage));
  if (data.q_body_stage !== undefined && data.q_body_stage !== null && data.q_body_stage !== '') subjScores.push(Number(data.q_body_stage));
  if (data.q_behavior_stage !== undefined && data.q_behavior_stage !== null && data.q_behavior_stage !== '') subjScores.push(Number(data.q_behavior_stage));

  var subjMedian = _median(subjScores);
  var subjMaxAbs = subjScores.reduce(function(best, v) { return Math.abs(v) > Math.abs(best) ? v : best; }, 0);
  var subjStage = _clamp(
    Math.round(settings.subj_median_weight * subjMedian + settings.subj_maxabs_weight * subjMaxAbs),
    -5, 5
  );

  // --- ObjStage: 重み付き平均 ---
  var objItems = [];
  var domainContributions = {};

  // Sleep
  if (data.sleep_min !== undefined && data.sleep_min !== null && data.sleep_min !== '') {
    var sleepMin = Number(data.sleep_min);
    var sleepStage = 0;
    if (sleepMin < 300) sleepStage = -3;       // <5h: 鬱寄り
    else if (sleepMin < 360) sleepStage = -1;   // 5-6h: やや鬱
    else if (sleepMin <= 540) sleepStage = 0;   // 6-9h: 正常
    else if (sleepMin <= 600) sleepStage = -1;  // 9-10h: やや鬱（過眠）
    else sleepStage = -3;                        // >10h: 過眠→鬱
    objItems.push({ domain: 'sleep', stage: sleepStage, weight: weights.sleep || 4 });
    domainContributions.sleep = { stage: sleepStage, weight: weights.sleep || 4, raw: sleepMin, desc: '睡眠 ' + Math.round(sleepMin / 60) + '時間' };
  }

  // Steps (activity)
  if (data.steps !== undefined && data.steps !== null && data.steps !== '') {
    var steps = Number(data.steps);
    var actStage = 0;
    if (steps < 1000) actStage = -3;
    else if (steps < 3000) actStage = -2;
    else if (steps < 5000) actStage = -1;
    else if (steps <= 12000) actStage = 0;
    else if (steps <= 20000) actStage = 1;
    else actStage = 3;  // >20000 は躁寄り
    objItems.push({ domain: 'activity', stage: actStage, weight: weights.activity || 3 });
    domainContributions.activity = { stage: actStage, weight: weights.activity || 3, raw: steps, desc: '歩数 ' + steps + '歩' };
  }

  // Active Energy
  if (data.active_energy_kcal !== undefined && data.active_energy_kcal !== null && data.active_energy_kcal !== '') {
    var aeKcal = Number(data.active_energy_kcal);
    var aeStage = 0;
    if (aeKcal < 100) aeStage = -2;
    else if (aeKcal < 200) aeStage = -1;
    else if (aeKcal <= 500) aeStage = 0;
    else if (aeKcal <= 800) aeStage = 1;
    else aeStage = 2;
    objItems.push({ domain: 'active_energy', stage: aeStage, weight: weights.active_energy || 3 });
    domainContributions.active_energy = { stage: aeStage, weight: weights.active_energy || 3, raw: aeKcal, desc: '消費 ' + aeKcal + 'kcal' };
  }

  // Thinking (from OpenAI)
  if (thinkingResult && thinkingResult.thinking_stage !== undefined) {
    var thStage = _clamp(Number(thinkingResult.thinking_stage), -5, 5);
    objItems.push({ domain: 'thinking', stage: thStage, weight: weights.thinking || 2 });
    domainContributions.thinking = { stage: thStage, weight: weights.thinking || 2, raw: thStage, desc: 'Thinking ' + (thStage >= 0 ? '+' : '') + thStage };
  }

  // Intake kcal
  if (data.intake_energy_kcal !== undefined && data.intake_energy_kcal !== null && data.intake_energy_kcal !== '') {
    var intKcal = Number(data.intake_energy_kcal);
    var intStage = 0;
    if (intKcal <= settings.intake_kcal_low_threshold) intStage = 2;         // 低摂取→躁寄り
    else if (intKcal >= settings.intake_kcal_high_threshold) intStage = -2;   // 過食→鬱寄り
    objItems.push({ domain: 'intake_kcal', stage: intStage, weight: weights.intake_kcal || 3 });
    domainContributions.intake_kcal = { stage: intStage, weight: weights.intake_kcal || 3, raw: intKcal, desc: '摂取 ' + intKcal + 'kcal' };
  }

  var objStage = 0;
  if (objItems.length > 0) {
    var totalWeight = objItems.reduce(function(s, item) { return s + item.weight; }, 0);
    var weightedSum = objItems.reduce(function(s, item) { return s + item.stage * item.weight; }, 0);
    objStage = _clamp(Math.round(weightedSum / totalWeight), -5, 5);
  }

  // --- NetStage ---
  var netStage = _clamp(
    Math.round(settings.netstage_subj_weight * subjStage + settings.netstage_obj_weight * objStage),
    -5, 5
  );

  var gap = Math.abs(subjStage - objStage);

  // --- Danger (0..5) ---
  var dangerPoints = 0;
  var dangerContributions = {};

  // Alcohol
  var drinks = Number(data.alcohol_drinks) || 0;
  if (drinks >= 1) {
    var alcDanger = drinks === 1 ? 3 : (drinks === 2 ? 4 : 5);
    dangerPoints += alcDanger;
    dangerContributions.alcohol = { points: alcDanger, desc: '飲酒 ' + drinks + '杯' };
  }

  // Medication
  var medsAmMissing = (data.meds_am_taken === false || data.meds_am_taken === 'false');
  var medsPmMissing = (data.meds_pm_taken === false || data.meds_pm_taken === 'false');
  if (medsAmMissing || medsPmMissing) {
    var medsDanger = (medsAmMissing && medsPmMissing) ? 2 : 1;
    dangerPoints += medsDanger;
    dangerContributions.medication = { points: medsDanger, desc: '服薬漏れ' };
  }

  // Mindfulness relief
  var mindMin = Number(data.mindfulness_min) || 0;
  if (mindMin >= settings.mindfulness_min_threshold) {
    dangerPoints += settings.mindfulness_danger_relief; // negative = relief
    dangerContributions.mindfulness = { points: settings.mindfulness_danger_relief, desc: 'マインドフルネス ' + mindMin + '分' };
  }

  // Gap warning
  if (gap >= settings.gap_warning_threshold) {
    dangerPoints += 1;
    dangerContributions.gap = { points: 1, desc: '主観・客観ズレ ' + gap };
  }

  // Extreme NetStage
  if (Math.abs(netStage) >= 4) {
    dangerPoints += 1;
    dangerContributions.extreme = { points: 1, desc: 'NetStage極端 ' + netStage };
  }

  var danger = _clamp(dangerPoints, 0, 5);

  // --- RiskColor ---
  var riskColor = 'Green';
  if (danger >= 4 || Math.abs(netStage) >= 4) riskColor = 'Red';
  else if (danger >= 3 || Math.abs(netStage) >= 3) riskColor = 'Orange';
  else if (danger >= 2 || Math.abs(netStage) >= 2) riskColor = 'Yellow';
  else if (danger >= 1 || Math.abs(netStage) >= 1) riskColor = 'Lime';

  if (danger >= 5) riskColor = 'DarkRed';

  return {
    subjStage: subjStage,
    objStage: objStage,
    netStage: netStage,
    danger: danger,
    riskColor: riskColor,
    gap: gap,
    domainContributions: domainContributions,
    dangerContributions: dangerContributions,
    subjScores: subjScores,
    objItems: objItems
  };
}

/** ====== TopDrivers抽出 =========================================== */
function _extractTopDrivers(calcResult) {
  var allDrivers = [];

  // NetStage寄与（domainContributions）
  var dc = calcResult.domainContributions || {};
  for (var domain in dc) {
    if (dc.hasOwnProperty(domain)) {
      var item = dc[domain];
      allDrivers.push({
        domain: domain,
        contribution: Math.abs(item.stage * item.weight),
        description: item.desc,
        type: 'netstage'
      });
    }
  }

  // Danger寄与
  var dg = calcResult.dangerContributions || {};
  for (var dDomain in dg) {
    if (dg.hasOwnProperty(dDomain)) {
      var dItem = dg[dDomain];
      if (dItem.points > 0) {
        allDrivers.push({
          domain: dDomain,
          contribution: dItem.points,
          description: dItem.desc,
          type: 'danger'
        });
      }
    }
  }

  // SubjStageも追加（mood影響）
  if (calcResult.subjStage !== 0) {
    allDrivers.push({
      domain: 'mood',
      contribution: Math.abs(calcResult.subjStage),
      description: '主観評価 ' + (calcResult.subjStage >= 0 ? '+' : '') + calcResult.subjStage,
      type: 'netstage'
    });
  }

  // 寄与度の大きい順にソート
  allDrivers.sort(function(a, b) { return b.contribution - a.contribution; });

  // 上位3つ
  var result = [];
  for (var i = 0; i < 3; i++) {
    if (i < allDrivers.length) {
      result.push(allDrivers[i]);
    } else {
      result.push({ domain: '', contribution: 0, description: '', type: '' });
    }
  }
  return result;
}

/** ====== Coping3抽出 ============================================== */
function _extractCoping3(calcResult) {
  var netStage = calcResult.netStage;
  var danger = calcResult.danger;
  var drivers = _extractTopDrivers(calcResult);

  try {
    var sh = _sheetOrThrow(CFG.SHEET_CRISIS_PLAN);
    var data = sh.getDataRange().getValues();
    if (data.length < 2) return _defaultCoping();

    // ヘッダーからステージ列を探す
    var header = data[0];
    var itemCol = -1;
    var stageCols = {};
    for (var c = 0; c < header.length; c++) {
      var h = String(header[c]).trim();
      if (h === '項目' || h === 'item' || h === 'domain') {
        itemCol = c;
      }
      var stageNum = parseInt(h, 10);
      if (!isNaN(stageNum) && stageNum >= -5 && stageNum <= 5) {
        stageCols[stageNum] = c;
      }
    }

    if (itemCol < 0) return _defaultCoping();

    // 該当ステージの列
    var targetStage = _clamp(netStage, -5, 5);
    var stageCol = stageCols[targetStage];
    if (stageCol === undefined) return _defaultCoping();

    // ドメインごとにコーピング文を取得
    var copingMap = {};
    for (var r = 1; r < data.length; r++) {
      var domain = String(data[r][itemCol]).trim().toLowerCase();
      var text = String(data[r][stageCol]).trim();
      if (domain && text && text !== '' && text !== 'undefined') {
        if (!copingMap[domain]) copingMap[domain] = [];
        copingMap[domain].push(text);
      }
    }

    var result = [];

    // Danger >= 3 の場合、Danger主因ドメイン優先
    if (danger >= 3 && drivers.length > 0) {
      for (var d = 0; d < drivers.length && result.length < 1; d++) {
        var driverDomain = drivers[d].domain.toLowerCase();
        if (copingMap[driverDomain] && copingMap[driverDomain].length > 0) {
          result.push({ domain: driverDomain, text: copingMap[driverDomain].shift() });
        }
      }
    }

    // 残りを埋める（TopDriversのドメイン優先）
    var tried = {};
    for (var dd = 0; dd < drivers.length && result.length < 3; dd++) {
      var dom = drivers[dd].domain.toLowerCase();
      if (!tried[dom] && copingMap[dom] && copingMap[dom].length > 0) {
        result.push({ domain: dom, text: copingMap[dom].shift() });
        tried[dom] = true;
      }
    }

    // まだ3つ未満なら他のドメインから
    for (var mapDomain in copingMap) {
      if (result.length >= 3) break;
      if (copingMap.hasOwnProperty(mapDomain) && !tried[mapDomain] && copingMap[mapDomain].length > 0) {
        result.push({ domain: mapDomain, text: copingMap[mapDomain].shift() });
        tried[mapDomain] = true;
      }
    }

    // 3つに足りなければデフォルトで埋める
    while (result.length < 3) {
      result.push({ domain: '共通', text: '深呼吸を3回してみましょう' });
    }

    return result;

  } catch (e) {
    Logger.log('Coping3 error: ' + e);
    return _defaultCoping();
  }
}

function _defaultCoping() {
  return [
    { domain: '共通', text: '深呼吸を3回してみましょう' },
    { domain: '共通', text: '今の気持ちを一言メモしてみましょう' },
    { domain: '共通', text: '水を一杯飲みましょう' }
  ];
}

/** ====== LINE通知メッセージ生成 ==================================== */
function _buildLineMessage(data, calcResult, drivers, coping3) {
  var lines = [];
  lines.push('--- 双極AI 日次レポート ---');
  lines.push('日付: ' + data.date);
  lines.push('');
  lines.push('NetStage: ' + (calcResult.netStage >= 0 ? '+' : '') + calcResult.netStage);
  lines.push('Danger: ' + calcResult.danger + ' (' + calcResult.riskColor + ')');
  lines.push('主観: ' + (calcResult.subjStage >= 0 ? '+' : '') + calcResult.subjStage + ' / 客観: ' + (calcResult.objStage >= 0 ? '+' : '') + calcResult.objStage);
  if (calcResult.gap >= 2) {
    lines.push('Gap: ' + calcResult.gap);
  }
  lines.push('');
  lines.push('-- 主な要因 --');
  for (var i = 0; i < drivers.length; i++) {
    if (drivers[i].description) {
      lines.push((i + 1) + '. ' + drivers[i].description);
    }
  }
  lines.push('');
  lines.push('-- 今日のアクション --');
  for (var j = 0; j < coping3.length; j++) {
    if (coping3[j].text) {
      lines.push((j + 1) + '. ' + coping3[j].text);
    }
  }
  return lines.join('\n');
}

/** ====== Daily_Output保存（upsert） ================================ */
function _saveDailyOutput(data, calcResult, drivers, coping3, thinkingResult) {
  var sh = _sheetOrThrow(CFG.SHEET_DAILY_OUTPUT);
  var lastCol = sh.getLastColumn();
  if (lastCol < 1) {
    sh.appendRow(['date', 'net_stage', 'danger', 'risk_color', 'subj_stage', 'obj_stage', 'gap', 'top_driver_1', 'top_driver_2', 'top_driver_3', 'coping_1', 'coping_2', 'coping_3', 'thinking_stage', 'thinking_polarity', 'version']);
    lastCol = sh.getLastColumn();
  }
  var header = sh.getRange(1, 1, 1, lastCol).getValues()[0];

  var outputData = {
    date: data.date,
    net_stage: calcResult.netStage,
    danger: calcResult.danger,
    risk_color: calcResult.riskColor,
    subj_stage: calcResult.subjStage,
    obj_stage: calcResult.objStage,
    gap: calcResult.gap,
    top_driver_1: drivers[0] ? drivers[0].domain + ': ' + drivers[0].description : '',
    top_driver_2: drivers[1] ? drivers[1].domain + ': ' + drivers[1].description : '',
    top_driver_3: drivers[2] ? drivers[2].domain + ': ' + drivers[2].description : '',
    coping_1: coping3[0] ? coping3[0].text : '',
    coping_2: coping3[1] ? coping3[1].text : '',
    coping_3: coping3[2] ? coping3[2].text : '',
    thinking_stage: thinkingResult.thinking_stage,
    thinking_polarity: thinkingResult.polarity,
    version: CFG.VERSION
  };

  var existingRow = _findRowByDate(sh, data.date);

  if (existingRow > 0) {
    var row = header.map(function(col) {
      var v = outputData[col];
      return (v === undefined || v === null) ? '' : v;
    });
    sh.getRange(existingRow, 1, 1, lastCol).setValues([row]);
    return existingRow;
  } else {
    var row = header.map(function(col) {
      var v = outputData[col];
      return (v === undefined || v === null) ? '' : v;
    });
    sh.appendRow(row);
    return sh.getLastRow();
  }
}

/** ====== Drivers_Long保存 ========================================= */
function _saveDriversLong(outputId, drivers) {
  var sh = _sheetOrThrow(CFG.SHEET_DRIVERS_LONG);
  drivers.forEach(function(driver, idx) {
    sh.appendRow([outputId, idx + 1, driver.domain, driver.contribution, driver.description]);
  });
}

/** ====== Coping_Long保存 ========================================== */
function _saveCopingLong(outputId, coping3) {
  var sh = _sheetOrThrow(CFG.SHEET_COPING_LONG);
  coping3.forEach(function(coping, idx) {
    sh.appendRow([outputId, idx + 1, coping.domain, coping.text]);
  });
}

/** ====== Reboot判定 ================================================ */
function _checkRebootStatus(currentDate, settings) {
  var triggerDays = (settings && settings.reboot_trigger_days) || 4;
  var fadeDays = (settings && settings.reboot_fade_day) || 21;

  try {
    var sh = _sheetOrThrow(CFG.SHEET_DAILY_LOG);
    var lastRow = sh.getLastRow();
    if (lastRow < 2) {
      return { reboot_needed: false, reboot_level: null, reboot_step: null };
    }

    // ヘッダーからdate列を探す
    var header = sh.getRange(1, 1, 1, sh.getLastColumn()).getValues()[0];
    var dateCol = -1;
    for (var c = 0; c < header.length; c++) {
      if (String(header[c]).trim() === 'date') { dateCol = c; break; }
    }
    if (dateCol < 0) {
      return { reboot_needed: false, reboot_level: null, reboot_step: null };
    }

    // 最新のチェックイン日を取得
    var dates = sh.getRange(2, dateCol + 1, lastRow - 1, 1).getValues();
    var lastCheckinDate = null;
    for (var i = dates.length - 1; i >= 0; i--) {
      var d = dates[i][0];
      if (d && String(d).trim() !== '') {
        lastCheckinDate = new Date(d);
        break;
      }
    }

    if (!lastCheckinDate) {
      return { reboot_needed: false, reboot_level: null, reboot_step: null };
    }

    var today = currentDate ? new Date(currentDate) : new Date();
    var diffMs = today.getTime() - lastCheckinDate.getTime();
    var daysSince = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (daysSince < triggerDays) {
      return {
        reboot_needed: false,
        reboot_level: null,
        reboot_step: null,
        days_since_last_checkin: daysSince
      };
    }

    // Rebootレベル判定
    var level, step;
    if (daysSince <= 7) {
      level = 'L1'; step = 'Reset';
    } else if (daysSince <= 14) {
      level = 'L2'; step = 'Reframe';
    } else if (daysSince <= fadeDays) {
      level = 'L3'; step = 'Reconnect';
    } else {
      // 21日以降は通知を弱める（でもReboot自体は継続）
      level = 'L3'; step = 'Reconnect';
    }

    return {
      reboot_needed: true,
      reboot_level: level,
      reboot_step: step,
      days_since_last_checkin: daysSince
    };

  } catch (e) {
    Logger.log('Reboot check error: ' + e);
    return { reboot_needed: false, reboot_level: null, reboot_step: null };
  }
}

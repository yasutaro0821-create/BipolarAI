/**
 * 双極AI PWA - メインアプリケーション
 */
(function () {
  'use strict';

  var DEFAULT_GAS_URL = 'https://script.google.com/macros/s/AKfycbwhfOswhC5kqt9C3kKU9CLcURie81ROL35pZD0UQgf0QvYKeWRNyEP7m4Y5RF8EQw1V/exec';

  var state = {
    values: {},
    skipped: false,
    submitting: false
  };

  var $ = function (s) { return document.querySelector(s); };
  var $$ = function (s) { return document.querySelectorAll(s); };

  document.addEventListener('DOMContentLoaded', function () {
    setupTabs();
    setupStageButtons();
    setupSkip();
    setupForm();
    setupSettings();
    setupResultClose();
    setupRebootDismiss();
    loadSettings();
    renderHistory();
  });

  // ===== タブ切り替え =====
  function setupTabs() {
    $$('.tab-bar__item').forEach(function (tab) {
      tab.addEventListener('click', function () {
        var target = tab.dataset.target;
        $$('.screen').forEach(function (s) { s.classList.remove('active'); });
        $$('.tab-bar__item').forEach(function (t) {
          t.classList.remove('active');
          t.removeAttribute('aria-current');
        });
        var el = document.getElementById(target);
        if (el) el.classList.add('active');
        tab.classList.add('active');
        tab.setAttribute('aria-current', 'page');
      });
    });
  }

  // ===== ステージボタン =====
  function setupStageButtons() {
    $$('.stage-selector__btn').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var name = btn.dataset.name;
        var val = parseInt(btn.dataset.stage, 10);
        state.values[name] = val;

        $$('.stage-selector__btn[data-name="' + name + '"]').forEach(function (b) {
          b.classList.remove('selected');
        });
        btn.classList.add('selected');

        if (name !== 'mood_score' && state.skipped) {
          state.skipped = false;
          $('#btn-skip').classList.remove('active');
          $('#questions-section').style.opacity = '1';
          $('#questions-section').style.pointerEvents = '';
        }

        updateSubmitButton();
      });
    });
  }

  // ===== 今日は無理 =====
  function setupSkip() {
    $('#btn-skip').addEventListener('click', function () {
      state.skipped = !state.skipped;
      var qs = $('#questions-section');

      if (state.skipped) {
        ['q_mood_stage', 'q_thinking_stage', 'q_body_stage', 'q_behavior_stage'].forEach(function (name) {
          delete state.values[name];
          $$('.stage-selector__btn[data-name="' + name + '"]').forEach(function (b) {
            b.classList.remove('selected');
          });
        });
        $('#btn-skip').classList.add('active');
        qs.style.opacity = '0.4';
        qs.style.pointerEvents = 'none';
      } else {
        $('#btn-skip').classList.remove('active');
        qs.style.opacity = '1';
        qs.style.pointerEvents = '';
      }
    });
  }

  function updateSubmitButton() {
    $('#btn-submit').disabled = (state.values.mood_score === undefined);
  }

  // ===== フォーム送信 =====
  function setupForm() {
    $('#daily-form').addEventListener('submit', function (e) {
      e.preventDefault();
      if (state.submitting) return;
      if (state.values.mood_score === undefined) {
        showToast('気分（Mood）を選択してください', 'error');
        return;
      }
      submitData();
    });
  }

  function submitData() {
    state.submitting = true;
    var btn = $('#btn-submit');
    btn.disabled = true;
    btn.textContent = '';
    btn.classList.add('btn--loading');

    var today = new Date();
    var dateStr = today.getFullYear() + '-' +
      String(today.getMonth() + 1).padStart(2, '0') + '-' +
      String(today.getDate()).padStart(2, '0');

    var payload = {
      date: dateStr,
      mood_score: state.values.mood_score,
      journal_text: $('#journal').value || '',
      q_mood_stage: state.values.q_mood_stage !== undefined ? state.values.q_mood_stage : null,
      q_thinking_stage: state.values.q_thinking_stage !== undefined ? state.values.q_thinking_stage : null,
      q_body_stage: state.values.q_body_stage !== undefined ? state.values.q_body_stage : null,
      q_behavior_stage: state.values.q_behavior_stage !== undefined ? state.values.q_behavior_stage : null,
      q4_status: state.skipped ? 'unable' : 'answered'
    };

    fetch(getGasUrl(), {
      method: 'POST',
      headers: { 'Content-Type': 'text/plain' },
      body: JSON.stringify(payload),
      redirect: 'follow'
    })
      .then(function (res) { return res.json(); })
      .then(function (data) {
        resetSubmitBtn();
        if (data.ok) {
          showResult(data);
          saveToHistory(dateStr, data);
          showToast('送信完了', 'success');
          if (data.reboot && data.reboot.reboot_needed) {
            showRebootBanner(data.reboot);
          }
        } else {
          showToast('エラー: ' + (data.error || '不明'), 'error');
        }
      })
      .catch(function (err) {
        resetSubmitBtn();
        showToast('通信エラー: ' + err.message, 'error');
      });
  }

  function resetSubmitBtn() {
    state.submitting = false;
    var btn = $('#btn-submit');
    btn.disabled = false;
    btn.textContent = '送信する';
    btn.classList.remove('btn--loading');
  }

  // ===== 結果モーダル =====
  function showResult(data) {
    var body = $('#result-body');
    var rc = 'risk-' + (data.risk_color || 'green').toLowerCase();
    var h = '';

    h += '<div class="result-hero">';
    h += '<div class="result-hero__stage">' + (data.net_stage >= 0 ? '+' : '') + data.net_stage + '</div>';
    h += '<div class="result-hero__label">NetStage</div>';
    h += '<div class="result-hero__danger ' + rc + '">Danger ' + data.danger + ' / ' + (data.risk_color || 'Green') + '</div>';
    h += '</div>';

    h += '<div class="result-card"><div class="result-card__title">詳細</div><ul class="result-card__list">';
    h += '<li>主観: ' + fmt(data.subj_stage) + '</li>';
    h += '<li>客観: ' + fmt(data.obj_stage) + '</li>';
    if (data.gap >= 2) h += '<li style="color:var(--color-warning)">ズレ: ' + data.gap + '</li>';
    h += '</ul></div>';

    if (data.top_drivers && data.top_drivers.length) {
      h += '<div class="result-card"><div class="result-card__title">主な要因</div><ul class="result-card__list">';
      data.top_drivers.forEach(function (d) { if (d.description) h += '<li>' + esc(d.description) + '</li>'; });
      h += '</ul></div>';
    }

    if (data.coping3 && data.coping3.length) {
      h += '<div class="result-card"><div class="result-card__title">今日のアクション</div><ul class="result-card__list">';
      data.coping3.forEach(function (c) { if (c.text) h += '<li>' + esc(c.text) + '</li>'; });
      h += '</ul></div>';
    }

    if (data.reboot && data.reboot.reboot_needed) {
      h += '<div class="result-card" style="border-left:4px solid var(--color-warning)">';
      h += '<div class="result-card__title">Reboot</div><ul class="result-card__list">';
      if (data.reboot.reboot_level) h += '<li>レベル: ' + data.reboot.reboot_level + '</li>';
      if (data.reboot.reboot_step) h += '<li>ステップ: ' + data.reboot.reboot_step + '</li>';
      if (data.reboot.days_since_last_checkin) h += '<li>' + data.reboot.days_since_last_checkin + '日間チェックインなし</li>';
      h += '</ul></div>';
    }

    body.innerHTML = h;
    $('#result-overlay').classList.add('open');
  }

  function setupResultClose() {
    $('#btn-close-result').addEventListener('click', function () {
      $('#result-overlay').classList.remove('open');
    });
    $('#result-overlay').addEventListener('click', function (e) {
      if (e.target === e.currentTarget) e.currentTarget.classList.remove('open');
    });
  }

  // ===== Reboot =====
  function showRebootBanner(reboot) {
    var text = 'Reboot: ' + (reboot.reboot_level || '') + ' - ' + (reboot.reboot_step || '');
    if (reboot.days_since_last_checkin) text += ' (' + reboot.days_since_last_checkin + '日間)';
    $('#reboot-text').textContent = text;
    $('#reboot-banner').classList.add('visible');
  }

  function setupRebootDismiss() {
    var d = $('#reboot-dismiss');
    if (d) d.addEventListener('click', function () { $('#reboot-banner').classList.remove('visible'); });
  }

  // ===== 設定 =====
  function setupSettings() {
    $('#settings-form').addEventListener('submit', function (e) {
      e.preventDefault();
      var g = $('#gas-url').value.trim();
      var l = $('#line-token').value.trim();
      if (g) localStorage.setItem('bipolar_gas_url', g); else localStorage.removeItem('bipolar_gas_url');
      if (l) localStorage.setItem('bipolar_line_token', l); else localStorage.removeItem('bipolar_line_token');
      showToast('設定を保存しました', 'success');
    });
  }

  function loadSettings() {
    var g = localStorage.getItem('bipolar_gas_url');
    var l = localStorage.getItem('bipolar_line_token');
    if (g) $('#gas-url').value = g;
    if (l) $('#line-token').value = l;
  }

  function getGasUrl() {
    return localStorage.getItem('bipolar_gas_url') || DEFAULT_GAS_URL;
  }

  // ===== 履歴 =====
  function saveToHistory(dateStr, data) {
    try {
      var hist = JSON.parse(localStorage.getItem('bipolar_history') || '[]');
      hist.unshift({ date: dateStr, net_stage: data.net_stage, danger: data.danger, risk_color: data.risk_color, mood: state.values.mood_score });
      if (hist.length > 90) hist = hist.slice(0, 90);
      localStorage.setItem('bipolar_history', JSON.stringify(hist));
      renderHistory();
    } catch (e) { /* */ }
  }

  function renderHistory() {
    var hist = JSON.parse(localStorage.getItem('bipolar_history') || '[]');
    var el = $('#history-list');
    if (!hist.length) { el.innerHTML = '<p class="history-empty">まだ記録がありません。</p>'; return; }
    var h = '<div class="history-list">';
    hist.forEach(function (e) {
      var rc = 'risk-' + (e.risk_color || 'green').toLowerCase();
      h += '<div class="history-item">';
      h += '<div class="history-item__stage ' + rc + '">' + (e.net_stage >= 0 ? '+' : '') + e.net_stage + '</div>';
      h += '<div class="history-item__body">';
      h += '<div class="history-item__date">' + esc(e.date) + '</div>';
      h += '<div class="history-item__summary">Mood: ' + fmt(e.mood) + ' / D: ' + e.danger + '</div>';
      h += '</div></div>';
    });
    h += '</div>';
    el.innerHTML = h;
  }

  // ===== トースト =====
  function showToast(msg, type) {
    var c = $('#toast-container');
    var t = document.createElement('div');
    t.className = 'toast toast--' + (type || 'info');
    t.textContent = msg;
    c.appendChild(t);
    requestAnimationFrame(function () { t.classList.add('show'); });
    setTimeout(function () { t.classList.remove('show'); setTimeout(function () { t.remove(); }, 300); }, 3000);
  }

  // ===== ユーティリティ =====
  function esc(s) { var d = document.createElement('div'); d.textContent = s; return d.innerHTML; }
  function fmt(v) { v = v || 0; return (v >= 0 ? '+' : '') + v; }

})();

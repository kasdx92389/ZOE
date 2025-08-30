// /public/admin-summary.js  (REPLACE ENTIRE FILE)
document.addEventListener('DOMContentLoaded', () => {
  // --- Elements ---
  const startDateInput = document.getElementById('startDate');
  const endDateInput = document.getElementById('endDate');
  const refreshBtn = document.getElementById('refreshBtn');
  const filterButtons = document.querySelectorAll('.btn[data-days]');

  // --- State ---
  let charts = { daily: null, game: null, platform: null, status: null };

  // --- Init ---
  function init() {
    refreshBtn.addEventListener('click', loadSummary);
    filterButtons.forEach(btn => {
      btn.addEventListener('click', e => {
        const days = parseInt(e.currentTarget.dataset.days);
        applyQuickDateRange(days);
        loadSummary();
      });
    });
    // ให้ default = 7 วัน เหมือนหน้า Order Management
    applyQuickDateRange(7);
    loadSummary();
  }

  // --- Main ---
  async function loadSummary() {
    const startDate = startDateInput.value;
    const endDate = endDateInput.value;
    if (!startDate || !endDate) return alert('โปรดเลือกช่วงวันที่');

    const qs = new URLSearchParams({ startDate, endDate });

    try {
      // 1) ใช้สรุปที่คำนวณบนเซิร์ฟเวอร์ (ถูกต้องตาม timezone และไม่มีปัญหา floating)
      const res = await fetch(`/api/summary?${qs.toString()}`);
      if (!res.ok) throw new Error(`Server responded ${res.status}`);
      const s = await res.json();

      renderKpisFromTotals(s.totals);

      const dailySummary = {
        labels: (s.daily || []).map(r => formatDateLabel(r.day)),
        data: (s.daily || []).map(r => toNum(r.revenue))
      };
      const revenueByGame = {
        labels: (s.byGame || []).map(r => r.game || 'UNKNOWN'),
        data: (s.byGame || []).map(r => toNum(r.revenue))
      };
      const revenueByPlatform = {
        labels: (s.byPlatform || []).map(r => r.platform || 'UNKNOWN'),
        data: (s.byPlatform || []).map(r => toNum(r.revenue))
      };
      const orderStatus = {
        labels: (s.byStatus || []).map(r => r.status || 'UNKNOWN'),
        data: (s.byStatus || []).map(r => toNum(r.count))
      };

      renderCharts({ dailySummary, revenueByGame, revenueByPlatform, orderStatus });
    } catch (err) {
      console.warn('Summary API failed, fallback to orders:', err);
      // 2) สำรอง: รวมจาก /api/orders (ยังใช้ Bangkok TZ เพื่อกันเพี้ยน)
      try {
        const res2 = await fetch(`/api/orders?${qs.toString()}&limit=10000`);
        if (!res2.ok) throw new Error(`Server responded ${res2.status}`);
        const { orders = [] } = await res2.json();

        const kpis = orders.reduce((a, o) => {
          a.totalOrders += 1;
          a.totalRevenue += toNum(o.total_paid);
          a.totalCost += toNum(o.cost);
          return a;
        }, { totalOrders: 0, totalRevenue: 0, totalCost: 0 });
        kpis.totalProfit = kpis.totalRevenue - kpis.totalCost;
        kpis.profitMargin = kpis.totalRevenue > 0 ? kpis.totalProfit / kpis.totalRevenue : 0;
        renderKpis(kpis);

        const revenueByGame = groupAndSum(orders, 'game_name', 'total_paid');
        const revenueByPlatform = groupAndSum(orders, 'platform', 'total_paid');
        const orderStatus = groupAndCount(orders, 'status');
        const dailySummary = aggregateByDateBangkok(orders, 'order_date', 'total_paid');

        renderCharts({ dailySummary, revenueByGame, revenueByPlatform, orderStatus });
      } catch (e2) {
        console.error('Error loading summary (fallback):', e2);
        alert(`ไม่สามารถโหลดข้อมูลสรุปได้: ${e2.message}`);
      }
    }
  }

  // --- KPI ---
  function renderKpisFromTotals(t = {}) {
    const revenue = toNum(t.revenue);
    const cost = toNum(t.cost);
    const profit = toNum(t.profit);
    const orders = toNum(t.orders);
    const margin = revenue > 0 ? (profit / revenue) : 0;

    el('kpiOrders').textContent = orders.toLocaleString();
    el('kpiRevenue').textContent = formatCurrency(revenue);
    el('kpiCost').textContent = formatCurrency(cost);
    el('kpiProfit').textContent = formatCurrency(profit);
    el('kpiProfitMargin').textContent = formatPercentage(margin);
  }

  function renderKpis(kpis = {}) {
    el('kpiOrders').textContent = (kpis.totalOrders || 0).toLocaleString();
    el('kpiRevenue').textContent = formatCurrency(kpis.totalRevenue || 0);
    el('kpiCost').textContent = formatCurrency(kpis.totalCost || 0);
    el('kpiProfit').textContent = formatCurrency((kpis.totalProfit || 0));
    el('kpiProfitMargin').textContent = formatPercentage((kpis.profitMargin || 0));
  }

  // --- Charts ---
  function renderCharts(d = {}) {
    const palette = ['#4f46e5', '#10b981', '#f59e0b', '#ef4444', '#3b82f6', '#8b5cf6'];

    charts.daily = ensureChart(
      charts.daily, 'dailyChart', 'line', d.dailySummary,
      { label: 'รายได้รายวัน', borderColor: 'var(--accent)', backgroundColor: '#eef2ff', fill: true, tension: 0.3 }
    );
    charts.game = ensureChart(
      charts.game, 'gameChart', 'doughnut', d.revenueByGame,
      { backgroundColor: palette }
    );
    charts.platform = ensureChart(
      charts.platform, 'platformChart', 'bar', d.revenueByPlatform,
      { label: 'รายได้', backgroundColor: palette }
    );
    charts.status = ensureChart(
      charts.status, 'statusChart', 'pie', d.orderStatus,
      { backgroundColor: palette }
    );
  }

  // --- Utils ---
  function applyQuickDateRange(days) {
    const tz = 'Asia/Bangkok';
    const end = new Date();
    const start = new Date();
    start.setDate(end.getDate() - (days - 1));
    endDateInput.value = end.toLocaleDateString('en-CA', { timeZone: tz });
    startDateInput.value = start.toLocaleDateString('en-CA', { timeZone: tz });
    setActiveFilterButton(document.querySelector(`.btn[data-days="${days}"]`));
  }
  function setActiveFilterButton(btn) {
    filterButtons.forEach(b => b.classList.remove('active'));
    if (btn) btn.classList.add('active');
  }

  const toNum = v => {
    if (typeof v === 'number') return v;
    if (v == null) return 0;
    const n = parseFloat(String(v).replace(/[,฿\s]/g, ''));
    return Number.isFinite(n) ? n : 0;
  };
  const formatCurrency = n => `฿${(n || 0).toLocaleString('th-TH', { minimumFractionDigits: 2 })}`;
  const formatPercentage = n => `${((n || 0) * 100).toFixed(2)}%`;
  const el = id => document.getElementById(id);

  const groupAndSum = (arr, key, sumKey) => {
    const map = arr.reduce((a, it) => {
      const k = it[key] || 'N/A';
      a[k] = (a[k] || 0) + toNum(it[sumKey]);
      return a;
    }, {});
    const labels = Object.keys(map).sort((a, b) => map[b] - map[a]);
    const data = labels.map(l => map[l]);
    return { labels, data };
  };
  const groupAndCount = (arr, key) => {
    const map = arr.reduce((a, it) => {
      const k = it[key] || 'N/A';
      a[k] = (a[k] || 0) + 1;
      return a;
    }, {});
    const labels = Object.keys(map).sort((a, b) => map[b] - map[a]);
    const data = labels.map(l => map[l]);
    return { labels, data };
  };

  function aggregateByDateBangkok(arr, dateKey, sumKey) {
    const tz = 'Asia/Bangkok';
    const map = arr.reduce((a, it) => {
      if (!it[dateKey]) return a;
      const d = new Date(it[dateKey]);
      const ymd = d.toLocaleDateString('en-CA', { timeZone: tz });
      a[ymd] = (a[ymd] || 0) + toNum(it[sumKey]);
      return a;
    }, {});
    const labels = Object.keys(map).sort();
    const data = labels.map(x => map[x]);
    return { labels, data };
  }
  function formatDateLabel(day) {
    try {
      if (typeof day === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(day)) return day;
      const d = new Date(day);
      return d.toLocaleDateString('en-CA', { timeZone: 'Asia/Bangkok' });
    } catch { return String(day); }
  }

  function ensureChart(instance, canvasId, type, dataset, overrides = {}) {
    const ctx = document.getElementById(canvasId)?.getContext('2d');
    if (!ctx) return null;
    if (instance) instance.destroy();
    return new Chart(ctx, {
      type,
      data: { labels: dataset.labels || [], datasets: [{ data: dataset.data || [], ...overrides }] },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: { legend: { display: ['doughnut','pie'].includes(type), position: 'bottom' } },
        scales: ['line','bar'].includes(type) ? { x: { }, y: { } } : {}
      }
    });
  }

  init();
});

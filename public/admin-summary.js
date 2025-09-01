document.addEventListener('DOMContentLoaded', () => {
  // --- Elements ---
  const startDateInput = document.getElementById('startDate');
  const endDateInput = document.getElementById('endDate');
  const refreshBtn = document.getElementById('refreshBtn');
  const thisMonthBtn = document.getElementById('btn-this-month');
  const filterButtons = document.querySelectorAll('.btn[data-days], .btn[data-all]');
  const allDataButton = document.querySelector('.btn[data-all="true"]');

  // --- State ---
  let charts = { dailyRevenue: null, dailyProfit: null, game: null, platform: null, topupChannel: null, status: null };

  // --- Init ---
  function init() {
    refreshBtn.addEventListener('click', loadSummary);

    filterButtons.forEach(btn => {
      btn.addEventListener('click', e => {
        const target = e.currentTarget;
        if (target.dataset.days) {
            const days = parseInt(target.dataset.days);
            applyQuickDateRange(days);
        } else if (target.dataset.all) {
            applyAllDateRange();
        }
        loadSummary();
      });
    });
    
    thisMonthBtn.addEventListener('click', () => {
        applyThisMonthRange();
        loadSummary();
    });

    applyThisMonthRange();
    loadSummary();
  }

  // --- Main ---
  async function loadSummary() {
    const startDate = startDateInput.value;
    const endDate = endDateInput.value;
    const qs = new URLSearchParams();
    if (startDate) qs.append('startDate', startDate);
    if (endDate) qs.append('endDate', endDate);

    try {
      const res = await fetch(`/api/summary?${qs.toString()}`);
      if (!res.ok) throw new Error(`Server responded ${res.status}`);
      const s = await res.json();
      renderKpisFromTotals(s.totals);

      const dailyRevenue = {
        labels: (s.daily || []).map(r => formatDateLabel(r.day)),
        data: (s.daily || []).map(r => toNum(r.revenue))
      };
      const dailyProfit = {
        labels: (s.daily || []).map(r => formatDateLabel(r.day)),
        data: (s.daily || []).map(r => toNum(r.profit))
      };
      const revenueByGame = {
          labels: (s.byGame || []).map(r => r.game || 'UNKNOWN'),
          dataRevenue: (s.byGame || []).map(r => toNum(r.revenue)),
          dataProfit: (s.byGame || []).map(r => toNum(r.profit))
      };
      const revenueByPlatform = {
        labels: (s.byPlatform || []).map(r => r.platform || 'UNKNOWN'),
        dataRevenue: (s.byPlatform || []).map(r => toNum(r.revenue)),
        dataCost: (s.byPlatform || []).map(r => toNum(r.cost))
      };
      const topupChannelRevenue = {
          labels: (s.byTopupChannel || []).map(r => r.topup_channel || 'UNKNOWN'),
          data: (s.byTopupChannel || []).map(r => toNum(r.revenue))
      };
      const orderStatus = {
        labels: (s.byStatus || []).map(r => r.status || 'UNKNOWN'),
        data: (s.byStatus || []).map(r => toNum(r.count))
      };

      renderCharts({ dailyRevenue, dailyProfit, revenueByGame, revenueByPlatform, topupChannelRevenue, orderStatus });
    } catch (err) {
      console.warn('Summary API failed, fallback to orders:', err);
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

        const revenueByGame = groupAndSumAndProfit(orders, 'game_name', 'total_paid', 'cost');
        const revenueByPlatform = groupAndSumAndCost(orders, 'platform', 'total_paid', 'cost');
        const topupChannelRevenue = groupAndSum(orders, 'topup_channel', 'total_paid');
        const orderStatus = groupAndCount(orders, 'status');
        const dailySummary = aggregateByDateBangkok(orders, 'order_date', 'total_paid', 'cost', 'profit');

        renderCharts({
          dailyRevenue: { labels: dailySummary.labels, data: dailySummary.dataRevenue },
          dailyProfit: { labels: dailySummary.labels, data: dailySummary.dataProfit },
          revenueByGame,
          revenueByPlatform,
          topupChannelRevenue,
          orderStatus
        });

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
  
  // --- Charts (Updated) ---
  function renderCharts(d = {}) {
    const palette = ['#4f46e5', '#10b981', '#f59e0b', '#ef4444', '#3b82f6', '#8b5cf6', '#a855f7', '#d946ef'];

    charts.dailyRevenue = ensureChart(
      charts.dailyRevenue, 'dailyRevenueChart', 'line', d.dailyRevenue,
      { 
        label: 'รายได้', 
        borderColor: 'rgb(79, 70, 229)',
        backgroundColor: (context) => {
            const chart = context.chart;
            const { ctx, chartArea } = chart;
            if (!chartArea) { return; }
            const gradient = ctx.createLinearGradient(0, chartArea.bottom, 0, chartArea.top);
            gradient.addColorStop(0, 'rgba(79, 70, 229, 0.05)');
            gradient.addColorStop(1, 'rgba(79, 70, 229, 0.3)');
            return gradient;
        },
        fill: true, 
        tension: 0.4,
        pointRadius: 4,
        pointHoverRadius: 6,
        pointBackgroundColor: 'rgb(79, 70, 229)',
        pointBorderColor: '#fff',
        pointBorderWidth: 2
      }
    );

    charts.dailyProfit = ensureChart(
      charts.dailyProfit, 'dailyProfitChart', 'line', d.dailyProfit,
      {
        label: 'กำไรสุทธิ',
        borderColor: 'rgb(16, 185, 129)',
        backgroundColor: (context) => {
            const chart = context.chart;
            const { ctx, chartArea } = chart;
            if (!chartArea) { return; }
            const gradient = ctx.createLinearGradient(0, chartArea.bottom, 0, chartArea.top);
            gradient.addColorStop(0, 'rgba(16, 185, 129, 0.05)');
            gradient.addColorStop(1, 'rgba(16, 185, 129, 0.3)');
            return gradient;
        },
        fill: true,
        tension: 0.4,
        pointRadius: 4,
        pointHoverRadius: 6,
        pointBackgroundColor: 'rgb(16, 185, 129)',
        pointBorderColor: '#fff',
        pointBorderWidth: 2
      }
    );

    charts.game = ensureChart(
      charts.game, 'gameChart', 'bar', d.revenueByGame,
      {
        datasets: [
          {
            label: 'รายได้',
            data: d.revenueByGame.dataRevenue,
            backgroundColor: '#4f46e5',
            borderRadius: 4
          },
          {
            label: 'กำไรสุทธิ',
            data: d.revenueByGame.dataProfit,
            backgroundColor: '#10b981',
            borderRadius: 4
          }
        ],
        options: {
          indexAxis: 'y',
          scales: {
              x: { stacked: false },
              y: { stacked: false }
          }
        }
      }
    );

    charts.platform = ensureChart(
        charts.platform, 'platformChart', 'bar', d.revenueByPlatform,
        {
          datasets: [
            {
              label: 'กำไร',
              data: d.revenueByPlatform.dataRevenue.map((rev, i) => rev - d.revenueByPlatform.dataCost[i]),
              backgroundColor: '#10b981',
              borderRadius: 4,
            },
            {
              label: 'ต้นทุน',
              data: d.revenueByPlatform.dataCost,
              backgroundColor: '#f59e0b',
              borderRadius: 4,
            }
          ],
          options: {
              scales: {
                  x: { stacked: true },
                  y: { stacked: true }
              }
          }
        }
    );

    charts.topupChannel = ensureChart(
      charts.topupChannel, 'topupChannelChart', 'doughnut', d.topupChannelRevenue,
      { backgroundColor: palette, borderColor: '#fff', borderWidth: 2, hoverOffset: 12 }
    );
    
    // แก้ไข: เพิ่มการตรวจสอบเงื่อนไขสำหรับกราฟสถานะออเดอร์
    const statusChartElement = document.getElementById('statusChart');
    if (d.orderStatus.labels.length <= 1) {
      if (statusChartElement) {
        const parent = statusChartElement.parentNode;
        if (parent) {
          parent.innerHTML = '<div class="chart-message">ไม่มีข้อมูลหลากหลายสำหรับสถานะออเดอร์</div>';
        }
      }
      if (charts.status) {
        charts.status.destroy();
        charts.status = null;
      }
    } else {
        if (!statusChartElement) {
            const container = document.querySelector('.chart-title:contains("สัดส่วนสถานะออเดอร์")').parentNode.querySelector('.chart-container');
            container.innerHTML = '<canvas id="statusChart"></canvas>';
        }
        charts.status = ensureChart(
            charts.status, 'statusChart', 'polarArea', d.orderStatus,
            { backgroundColor: palette, borderColor: '#fff', borderWidth: 2, hoverOffset: 8 }
        );
    }
  }

  function ensureChart(instance, canvasId, type, dataset, overrides = {}) {
    const ctx = document.getElementById(canvasId)?.getContext('2d');
    if (!ctx) return null;
    if (instance) instance.destroy();

    Chart.defaults.font.family = 'Sarabun, sans-serif';
    Chart.defaults.color = '#6b7280';

    const chartConfig = {
        type,
        data: {
          labels: dataset.labels || [],
          datasets: overrides.datasets || [{ data: dataset.data || [], ...overrides }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            interaction: {
              mode: 'index',
              intersect: false,
            },
            plugins: {
              legend: { 
                display: ['doughnut', 'pie', 'polarArea'].includes(type) || overrides.datasets, 
                position: 'bottom', 
                labels: { usePointStyle: true, padding: 20 } 
              },
              tooltip: {
                backgroundColor: '#374151',
                titleColor: '#ffffff',
                bodyColor: '#e5e7eb',
                borderColor: '#4b5563',
                borderWidth: 1,
                cornerRadius: 8,
                padding: 12,
                displayColors: true,
                boxPadding: 6,
                titleFont: { weight: 'bold', size: 14 },
                bodyFont: { size: 13 },
                callbacks: {
                  title: (context) => {
                      if (type === 'line' && context[0]?.label) return `วันที่: ${context[0].label}`;
                      return context[0]?.label || '';
                  },
                  label: (context) => {
                    const value = context.parsed.y !== undefined ? context.parsed.y : context.parsed;
                    let label = context.dataset.label || '';
                    if (label) { label += ': '; }

                    if (type === 'pie' || type === 'doughnut' || type === 'polarArea') {
                        label += `${value.toLocaleString('th-TH')} ${(type === 'pie' ? 'รายการ' : '')}`;
                    } else {
                        label += `฿${value.toLocaleString('th-TH', { minimumFractionDigits: 2 })}`;
                    }
                    return label;
                  }
                }
              }
            },
            scales: ['line', 'bar'].includes(type) ? {
              x: {
                grid: { display: false, drawBorder: false },
                ticks: { color: '#6b7280', maxRotation: 45, minRotation: 45, padding: 10 }
              },
              y: {
                beginAtZero: true,
                grid: { color: 'rgba(203, 213, 225, 0.5)', drawBorder: false },
                ticks: {
                  color: '#6b7280',
                  padding: 10,
                  callback: (value) => `฿${value.toLocaleString('th-TH')}`
                }
              }
            } : {}
          }
    };
    
    if (overrides.options) {
      chartConfig.options = { ...chartConfig.options, ...overrides.options };
    }
    
    return new Chart(ctx, chartConfig);
  }

  // --- Date & Filter Utils ---
  function applyThisMonthRange() {
      const tz = 'Asia/Bangkok';
      const now = new Date();
      const year = now.getFullYear();
      const month = now.getMonth();
      const firstDay = new Date(year, month, 1);
      const lastDay = new Date(year, month + 1, 0);
      startDateInput.value = firstDay.toLocaleDateString('en-CA', { timeZone: tz });
      endDateInput.value = lastDay.toLocaleDateString('en-CA', { timeZone: tz });
      setActiveFilterButton(thisMonthBtn);
  }

  function applyQuickDateRange(days) {
    const tz = 'Asia/Bangkok';
    const end = new Date();
    const start = new Date();
    start.setDate(end.getDate() - (days - 1));
    endDateInput.value = end.toLocaleDateString('en-CA', { timeZone: tz });
    startDateInput.value = start.toLocaleDateString('en-CA', { timeZone: tz });
    setActiveFilterButton(document.querySelector(`.btn[data-days="${days}"]`));
  }
  
  function applyAllDateRange() {
      startDateInput.value = '';
      endDateInput.value = '';
      setActiveFilterButton(allDataButton);
  }

  function setActiveFilterButton(activeButton) {
      document.querySelectorAll('.filter-controls .btn').forEach(b => b.classList.remove('active'));
      if (activeButton) {
          activeButton.classList.add('active');
      }
  }

  // --- Data Processing & Formatting Utils ---
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

  const groupAndSumAndProfit = (arr, key, sumKey, costKey) => {
      const map = arr.reduce((a, it) => {
          const k = it[key] || 'N/A';
          a[k] = a[k] || { revenue: 0, profit: 0 };
          const revenue = toNum(it[sumKey]);
          const cost = toNum(it[costKey]);
          a[k].revenue += revenue;
          a[k].profit += revenue - cost;
          return a;
      }, {});
      const labels = Object.keys(map).sort((a, b) => map[b].revenue - map[a].revenue);
      const dataRevenue = labels.map(l => map[l].revenue);
      const dataProfit = labels.map(l => map[l].profit);
      return { labels, dataRevenue, dataProfit };
  };

  const groupAndSumAndCost = (arr, key, sumKey, costKey) => {
    const map = arr.reduce((a, it) => {
        const k = it[key] || 'N/A';
        a[k] = a[k] || { revenue: 0, cost: 0 };
        a[k].revenue += toNum(it[sumKey]);
        a[k].cost += toNum(it[costKey]);
        return a;
    }, {});
    const labels = Object.keys(map).sort((a, b) => map[b].revenue - map[a].revenue);
    const dataRevenue = labels.map(l => map[l].revenue);
    const dataCost = labels.map(l => map[l].cost);
    return { labels, dataRevenue, dataCost };
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

  function aggregateByDateBangkok(arr, dateKey, sumKey, costKey) {
    const tz = 'Asia/Bangkok';
    const map = arr.reduce((a, it) => {
      if (!it[dateKey]) return a;
      const d = new Date(it[dateKey]);
      const ymd = d.toLocaleDateString('en-CA', { timeZone: tz });
      a[ymd] = a[ymd] || { revenue: 0, cost: 0, profit: 0 };
      const revenue = toNum(it[sumKey]);
      const cost = toNum(it[costKey]);
      a[ymd].revenue += revenue;
      a[ymd].cost += cost;
      a[ymd].profit += revenue - cost;
      return a;
    }, {});
    const labels = Object.keys(map).sort();
    const dataRevenue = labels.map(x => map[x].revenue);
    const dataCost = labels.map(x => map[x].cost);
    const dataProfit = labels.map(x => map[x].profit);
    return { labels, dataRevenue, dataCost, dataProfit };
  }

  function formatDateLabel(day) {
    try {
      if (typeof day === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(day)) return day;
      const d = new Date(day);
      return d.toLocaleDateString('en-CA', { timeZone: 'Asia/Bangkok' });
    } catch { return String(day); }
  }

  init();
});
(() => {
  // --- UTILS ---
  const el = (id) => document.getElementById(id);
  const qs = (s) => document.querySelector(s);
  const fmt = (n) => Number(n || 0).toLocaleString('th-TH', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  const fmtInt = (n) => Number(n || 0).toLocaleString('th-TH');

  // --- STATE ---
  const state = {
    allOrders: [],
    picker: null,
    charts: { byGame: null, byDay: null },
    chartColors: ['#4f46e5', '#f97316', '#10b981', '#3b82f6', '#ef4444', '#8b5cf6', '#06b6d4', '#d946ef']
  };

  // --- API & DATA ---
  async function fetchAllOrders({ startDate, endDate }) {
    let all = [], page = 1, total = Infinity;
    while ((page - 1) * 1000 < total) {
      const params = new URLSearchParams({ page, limit: 1000 });
      if (startDate) params.set('startDate', startDate);
      if (endDate) params.set('endDate', endDate);
      const res = await fetch(`/api/orders?${params.toString()}`);
      if (!res.ok) throw new Error('Failed to fetch orders');
      const data = await res.json();
      total = data.total || 0;
      if (!data.orders || data.orders.length === 0) break;
      all = all.concat(data.orders);
      page++;
    }
    return all;
  }

  function filterAndAggregate(orders) {
    const selectedStatus = el('filter-status').value;
    const filtered = selectedStatus ? orders.filter(o => o.status === selectedStatus) : orders;

    const aggregated = filtered.reduce((acc, o) => {
      const sales = Number(o.total_paid || 0);
      const cost = Number(o.cost || 0);
      const profit = sales - cost;

      acc.totalSales += sales;
      acc.totalCost += cost;

      const game = o.game_name || '(ไม่ระบุ)';
      acc.byGame[game] = acc.byGame[game] || { orders: 0, sales: 0, cost: 0, profit: 0 };
      acc.byGame[game].orders++;
      acc.byGame[game].sales += sales;
      acc.byGame[game].cost += cost;
      acc.byGame[game].profit += profit;

      if (o.order_date) {
        const day = new Date(o.order_date).toLocaleDateString('sv-SE');
        acc.byDay[day] = acc.byDay[day] || { sales: 0, profit: 0 };
        acc.byDay[day].sales += sales;
        acc.byDay[day].profit += profit;
      }
      return acc;
    }, {
      totalSales: 0, totalCost: 0,
      byGame: {}, byDay: {}
    });

    const totalOrders = filtered.length;
    const totalProfit = aggregated.totalSales - aggregated.totalCost;
    const byGameArr = Object.entries(aggregated.byGame).map(([game, data]) => ({ game, ...data })).sort((a,b) => b.sales - a.sales);
    const byDayArr = Object.entries(aggregated.byDay).map(([day, data]) => ({ day, ...data })).sort((a,b) => a.day.localeCompare(b.day));

    return { totalOrders, ...aggregated, totalProfit, byGameArr, byDayArr };
  }
  
  // --- RENDERING ---
  function render(data) {
    if (data.totalOrders === 0) {
        el('dashboard-content').style.display = 'none';
        el('no-data-message').style.display = 'block';
        return;
    }
    el('dashboard-content').style.display = 'block';
    el('no-data-message').style.display = 'none';

    renderKPIs(data);
    renderTable(data.byGameArr);
    renderGameChart(data.byGameArr);
    renderDayChart(data.byDayArr);
  }

  function renderKPIs({ totalOrders, totalSales, totalProfit }) {
    const aov = totalOrders > 0 ? totalSales / totalOrders : 0;
    const profitMargin = totalSales > 0 ? (totalProfit / totalSales) * 100 : 0;
    
    el('kpi-sales').textContent = fmt(totalSales);
    el('kpi-profit').textContent = fmt(totalProfit);
    el('kpi-orders').textContent = fmtInt(totalOrders);
    el('kpi-aov').textContent = fmt(aov);

    const marginEl = el('kpi-profit-margin');
    marginEl.textContent = `(อัตรากำไร ${profitMargin.toFixed(1)}%)`;
    marginEl.className = `kpi-sub-value ${profitMargin >= 0 ? '' : 'negative'}`;
  }

  function renderTable(byGameArr) {
    qs('#tbl-by-game tbody').innerHTML = byGameArr.map(r => `
      <tr><td>${r.game}</td><td class="num">${fmtInt(r.orders)}</td><td class="num">${fmt(r.sales)}</td><td class="num">${fmt(r.cost)}</td><td class="num">${fmt(r.profit)}</td></tr>
    `).join('');
  }

  function renderGameChart(byGameArr) {
    const ctx = el('chart-by-game').getContext('2d');
    if (state.charts.byGame) state.charts.byGame.destroy();
    state.charts.byGame = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: byGameArr.map(x => x.game),
        datasets: [{ data: byGameArr.map(x => x.sales), backgroundColor: state.chartColors }]
      },
      options: { responsive: true, maintainAspectRatio: false }
    });
  }

  function renderDayChart(byDayArr) {
    const ctx = el('chart-by-day').getContext('2d');
    const gradient = ctx.createLinearGradient(0, 0, 0, 400);
    gradient.addColorStop(0, 'rgba(79, 70, 229, 0.4)');
    gradient.addColorStop(1, 'rgba(79, 70, 229, 0)');

    if (state.charts.byDay) state.charts.byDay.destroy();
    state.charts.byDay = new Chart(ctx, {
      type: 'line',
      data: {
        labels: byDayArr.map(x => x.day),
        datasets: [
          { label: 'ยอดขาย', data: byDayArr.map(x => x.sales), borderColor: '#4f46e5', tension: 0.3, fill: true, backgroundColor: gradient },
          { label: 'กำไร', data: byDayArr.map(x => x.profit), borderColor: '#16a34a', tension: 0.3 }
        ]
      },
      options: { responsive: true, maintainAspectRatio: false, scales: { y: { beginAtZero: true } } }
    });
  }

  // --- MAIN LOGIC & EVENTS ---
  async function run() {
    const btn = el('btn-apply-filter');
    const originalContent = btn.innerHTML;
    btn.disabled = true;
    btn.innerHTML = `<span class="btn-spinner"></span> กำลังโหลด...`;

    try {
      if (state.allOrders.length === 0) { // Fetch only if not already fetched
          const startDate = state.picker.getStartDate() ? state.picker.getStartDate().toJSDate().toISOString().slice(0, 10) : '';
          const endDate = state.picker.getEndDate() ? state.picker.getEndDate().toJSDate().toISOString().slice(0, 10) : '';
          state.allOrders = await fetchAllOrders({ startDate, endDate });
      }
      const aggregatedData = filterAndAggregate(state.allOrders);
      render(aggregatedData);
    } catch (error) {
      console.error("Dashboard run error:", error);
      alert("เกิดข้อผิดพลาดในการโหลดข้อมูล");
    } finally {
      btn.disabled = false;
      btn.innerHTML = originalContent;
    }
  }
  
  async function handleFilterChange() {
      const startDate = state.picker.getStartDate() ? state.picker.getStartDate().toJSDate().toISOString().slice(0, 10) : '';
      const endDate = state.picker.getEndDate() ? state.picker.getEndDate().toJSDate().toISOString().slice(0, 10) : '';
      state.allOrders = await fetchAllOrders({ startDate, endDate });
      const aggregatedData = filterAndAggregate(state.allOrders);
      render(aggregatedData);
  }

  function init() {
    const now = new Date();
    state.picker = new Litepicker({
      element: el('date-range-picker'),
      singleMode: false, autoApply: true,
      startDate: new Date(now.getFullYear(), now.getMonth(), 1),
      endDate: now,
      format: 'YYYY-MM-DD', separator: ' ถึง '
    });

    const statuses = ['รายการสำเร็จ', 'ยกเลิก/คืนเงิน', 'รอดำเนินการ', 'แก้ไขรายการ', 'รายการผิดพลาด'];
    el('filter-status').innerHTML = `<option value="">ทุกสถานะ</option>` + statuses.map(s => `<option value="${s}">${s}</option>`).join('');

    el('btn-apply-filter').addEventListener('click', handleFilterChange);
    el('filter-status').addEventListener('change', () => {
        const aggregatedData = filterAndAggregate(state.allOrders);
        render(aggregatedData);
    });

    run(); // Initial run
  }

  document.addEventListener('DOMContentLoaded', init);
})();
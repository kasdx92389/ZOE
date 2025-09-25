document.addEventListener('DOMContentLoaded', () => {
    // --- Elements ---
    const startDateInput = document.getElementById('startDate');
    const endDateInput = document.getElementById('endDate');
    const refreshBtn = document.getElementById('refreshBtn');
    const thisMonthBtn = document.getElementById('btn-this-month');
    const filterButtons = document.querySelectorAll('.btn[data-days], .btn[data-all]');
    const loadingOverlay = document.getElementById('loading-overlay');
    const dailyChartOptions = document.getElementById('daily-chart-options');

    // --- State ---
    let charts = { daily: null, game: null, platform: null, status: null };
    let rawDailyData = []; // Store raw daily data for regrouping

    // --- Init ---
    function init() {
        refreshBtn.addEventListener('click', () => loadData());

        filterButtons.forEach(btn => {
            btn.addEventListener('click', e => {
                const target = e.currentTarget;
                if (target.dataset.days) {
                    applyQuickDateRange(parseInt(target.dataset.days));
                } else if (target.dataset.all) {
                    applyAllDateRange();
                }
                loadData();
            });
        });
        
        thisMonthBtn.addEventListener('click', () => {
            applyThisMonthRange();
            loadData();
        });

        dailyChartOptions.addEventListener('click', e => {
            if (e.target.tagName === 'BUTTON') {
                const groupBy = e.target.dataset.group;
                dailyChartOptions.querySelector('.active').classList.remove('active');
                e.target.classList.add('active');
                updateDailyChart(groupBy);
            }
        });

        applyThisMonthRange();
        loadData();
    }

    // --- Main Data Loading ---
    async function loadData() {
        showLoading();
        const { start, end } = getPeriod(startDateInput.value, endDateInput.value);
        const { start: prevStart, end: prevEnd } = getPreviousPeriod(start, end);

        try {
            // Fetch current and previous period data in parallel
            const [currentData, previousData] = await Promise.all([
                fetchSummaryData(start, end),
                fetchSummaryData(prevStart, prevEnd)
            ]);
            
            processAndRender(currentData, previousData);

        } catch (err) {
            console.error('Error loading summary data:', err);
            alert(`ไม่สามารถโหลดข้อมูลสรุปได้: ${err.message}`);
        } finally {
            hideLoading();
        }
    }
    
    async function fetchSummaryData(startDate, endDate) {
        const qs = new URLSearchParams();
        if (startDate) qs.append('startDate', startDate);
        if (endDate) qs.append('endDate', endDate);
        
        try {
            const res = await fetch(`/api/summary?${qs.toString()}`);
            if (!res.ok) throw new Error(`API ตอบกลับด้วยสถานะ ${res.status}`);
            return await res.json();
        } catch (err) {
             console.warn('Summary API failed, fallback to orders:', err);
             const res2 = await fetch(`/api/orders?${qs.toString()}&limit=10000`);
             if (!res2.ok) throw new Error(`Fallback API ตอบกลับด้วยสถานะ ${res2.status}`);
             const { orders = [] } = await res2.json();
             return processOrdersToSummary(orders);
        }
    }

    function processAndRender(current, previous) {
        renderKpis(current.totals, previous.totals);
        
        rawDailyData = current.daily || []; // Cache raw data
        const initialGroupBy = (rawDailyData.length > 60) ? 'week' : 'day';
        
        dailyChartOptions.querySelector('.active')?.classList.remove('active');
        dailyChartOptions.querySelector(`[data-group="${initialGroupBy}"]`)?.classList.add('active');
        updateDailyChart(initialGroupBy);

        const revenueByGame = {
            labels: (current.byGame || []).map(r => r.game || 'N/A'),
            data: (current.byGame || []).map(r => toNum(r.revenue))
        };
        const revenueByPlatform = {
            labels: (current.byPlatform || []).map(r => r.platform || 'N/A'),
            data: (current.byPlatform || []).map(r => toNum(r.revenue))
        };
        const orderStatus = {
            labels: (current.byStatus || []).map(r => r.status || 'N/A'),
            data: (current.byStatus || []).map(r => toNum(r.count))
        };

        renderOtherCharts({ revenueByGame, revenueByPlatform, orderStatus });
    }

    // --- KPI Rendering ---
    function renderKpis(current = {}, previous = {}) {
        const metrics = [
            { id: 'Orders', value: toNum(current.orders), prev: toNum(previous.orders) },
            { id: 'Revenue', value: toNum(current.revenue), prev: toNum(previous.revenue), format: formatCurrency },
            { id: 'Profit', value: toNum(current.profit), prev: toNum(previous.profit), format: formatCurrency },
            { id: 'Cost', value: toNum(current.cost), prev: toNum(previous.cost), format: formatCurrency },
        ];

        const currentRevenue = toNum(current.revenue);
        const currentOrders = toNum(current.orders);
        const currentProfit = toNum(current.profit);
        
        const prevRevenue = toNum(previous.revenue);
        const prevOrders = toNum(previous.orders);
        const prevProfit = toNum(previous.profit);

        const profitMargin = currentRevenue > 0 ? (currentProfit / currentRevenue) : 0;
        const prevProfitMargin = prevRevenue > 0 ? (prevProfit / prevRevenue) : 0;
        
        const aov = currentOrders > 0 ? (currentRevenue / currentOrders) : 0;
        const prevAov = prevOrders > 0 ? (prevRevenue / prevOrders) : 0;

        metrics.push({ id: 'ProfitMargin', value: profitMargin, prev: prevProfitMargin, format: formatPercentage, isRate: true });
        metrics.push({ id: 'Aov', value: aov, prev: prevAov, format: formatCurrency });

        metrics.forEach(m => {
            const change = calculateChange(m.value, m.prev, m.isRate);
            el(`kpi${m.id}`).textContent = m.format ? m.format(m.value) : m.value.toLocaleString();
            const changeEl = el(`kpi${m.id}Change`);
            
            if (change.value !== null && isFinite(change.value)) {
                changeEl.className = 'kpi-change'; // reset
                changeEl.classList.add(change.direction);
                changeEl.innerHTML = `<i class="fas fa-arrow-${change.direction === 'increase' ? 'up' : 'down'}"></i> ${change.value.toFixed(1)}%`;
                changeEl.style.display = '';
            } else {
                changeEl.style.display = 'none';
            }
        });
    }

    function calculateChange(current, previous, isRate = false) {
        if (previous === 0) {
            return { value: current > 0 ? Infinity : 0, direction: 'increase' };
        }
        if (current === previous) {
           return { value: 0, direction: 'increase' };
        }
        
        const value = isRate ? (current - previous) * 100 : ((current - previous) / previous) * 100;
        return {
            value,
            direction: value >= 0 ? 'increase' : 'decrease'
        };
    }
    
    // --- Chart Rendering ---
    function updateDailyChart(groupBy = 'day') {
        const aggregated = aggregateData(rawDailyData, groupBy);
        const dailySummary = {
            labels: aggregated.map(r => r.date),
            data: aggregated.map(r => r.revenue)
        };
        charts.daily = ensureChart(charts.daily, 'dailyChart', 'line', dailySummary, {
            label: 'รายได้', 
            borderColor: 'rgb(79, 70, 229)',
            backgroundColor: (context) => {
                const { ctx, chartArea } = context.chart;
                if (!chartArea) return;
                const gradient = ctx.createLinearGradient(0, chartArea.bottom, 0, chartArea.top);
                gradient.addColorStop(0, 'rgba(79, 70, 229, 0.05)');
                gradient.addColorStop(1, 'rgba(79, 70, 229, 0.3)');
                return gradient;
            },
            fill: true, tension: 0.4, pointRadius: 2, pointHoverRadius: 6,
            pointBackgroundColor: 'rgb(79, 70, 229)',
        }, {
             x: { type: 'time', time: { unit: groupBy } }
        });
    }

    function renderOtherCharts(data) {
        const palette = ['#4f46e5', '#10b981', '#f59e0b', '#ef4444', '#3b82f6', '#8b5cf6', '#d946ef'];
        charts.game = ensureChart(charts.game, 'gameChart', 'doughnut', data.revenueByGame,
            { backgroundColor: palette, borderColor: '#fff', borderWidth: 2, hoverOffset: 8 });
        charts.platform = ensureChart(charts.platform, 'platformChart', 'bar', data.revenueByPlatform,
            { label: 'รายได้', backgroundColor: palette[0], borderRadius: 4 });
        charts.status = ensureChart(charts.status, 'statusChart', 'pie', data.orderStatus,
            { backgroundColor: palette, borderColor: '#fff', borderWidth: 2, hoverOffset: 8 });
    }

    function ensureChart(instance, canvasId, type, dataset, overrides = {}, scaleOverrides = {}) {
        const ctx = document.getElementById(canvasId)?.getContext('2d');
        if (!ctx) return null;
        if (instance) instance.destroy();

        Chart.defaults.font.family = 'Sarabun, sans-serif';
        Chart.defaults.color = '#6b7280';

        return new Chart(ctx, {
            type,
            data: { labels: dataset.labels || [], datasets: [{ data: dataset.data || [], ...overrides }] },
            options: {
                responsive: true, maintainAspectRatio: false,
                interaction: { mode: 'index', intersect: false },
                plugins: {
                    legend: { display: ['doughnut', 'pie'].includes(type), position: 'bottom', labels: { usePointStyle: true, padding: 20 } },
                    tooltip: {
                        backgroundColor: '#1f2937', titleColor: '#ffffff', bodyColor: '#e5e7eb',
                        borderColor: '#4b5563', borderWidth: 1, cornerRadius: 8, padding: 12, displayColors: true,
                        callbacks: {
                            label: (context) => {
                                let label = context.dataset.label || context.label || '';
                                if (label) { label += ': '; }
                                const value = context.parsed.y !== undefined ? context.parsed.y : context.parsed;
                                if (type === 'pie' || type === 'doughnut') {
                                    return `${context.label}: ${value.toLocaleString('th-TH')} รายการ`;
                                }
                                return `${label}฿${value.toLocaleString('th-TH', { minimumFractionDigits: 2 })}`;
                            }
                        }
                    }
                },
                scales: ['line', 'bar'].includes(type) ? {
                    x: {
                        grid: { display: false },
                        ticks: { color: '#6b7280', maxRotation: 45, minRotation: 20 },
                        ...scaleOverrides.x
                    },
                    y: {
                        beginAtZero: true,
                        grid: { color: 'rgba(203, 213, 225, 0.5)' },
                        ticks: { color: '#6b7280', callback: (value) => `฿${Number(value).toLocaleString('th-TH')}` },
                         ...scaleOverrides.y
                    }
                } : {}
            }
        });
    }

    // --- Date & Filter Utils ---
    const getPeriod = (startVal, endVal) => ({ start: startVal, end: endVal });
    
    function getPreviousPeriod(startDateStr, endDateStr) {
        if (!startDateStr || !endDateStr) return { start: null, end: null };
        const start = new Date(startDateStr + 'T00:00:00');
        const end = new Date(endDateStr + 'T23:59:59');
        const diff = end.getTime() - start.getTime();

        const prevEnd = new Date(start.getTime() - 1); // a millisecond before the start
        const prevStart = new Date(prevEnd.getTime() - diff);

        return {
            start: prevStart.toLocaleDateString('en-CA'),
            end: prevEnd.toLocaleDateString('en-CA')
        };
    }

    function applyThisMonthRange() {
        const now = new Date();
        const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
        const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0);
        startDateInput.value = firstDay.toLocaleDateString('en-CA');
        endDateInput.value = lastDay.toLocaleDateString('en-CA');
        setActiveFilterButton(thisMonthBtn);
    }

    function applyQuickDateRange(days) {
        const end = new Date();
        const start = new Date();
        start.setDate(end.getDate() - (days - 1));
        endDateInput.value = end.toLocaleDateString('en-CA');
        startDateInput.value = start.toLocaleDateString('en-CA');
        setActiveFilterButton(document.querySelector(`.btn[data-days="${days}"]`));
    }

    function applyAllDateRange() {
        startDateInput.value = '';
        endDateInput.value = '';
        setActiveFilterButton(document.querySelector('.btn[data-all="true"]'));
    }
  
    function setActiveFilterButton(activeButton) {
        document.querySelectorAll('.filter-controls .btn').forEach(b => b.classList.remove('active'));
        if (activeButton) activeButton.classList.add('active');
    }

    // --- Data Processing & Formatting ---
    const toNum = v => Number(String(v || 0).replace(/[,฿\s]/g, '')) || 0;
    const formatCurrency = n => `฿${(n || 0).toLocaleString('th-TH', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    const formatPercentage = n => `${((n || 0) * 100).toFixed(2)}%`;
    const el = id => document.getElementById(id);
    const showLoading = () => loadingOverlay.classList.add('visible');
    const hideLoading = () => loadingOverlay.classList.remove('visible');

    function aggregateData(daily, groupBy = 'day') {
        if (!daily || daily.length === 0) return [];
        const aggregated = {};
        daily.forEach(item => {
            const date = new Date(item.day + 'T00:00:00');
            let key;
            if (groupBy === 'month') {
                key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-01`;
            } else if (groupBy === 'week') {
                const day = date.getDay();
                const diff = date.getDate() - day + (day === 0 ? -6 : 1); // Adjust to Monday
                key = new Date(date.setDate(diff)).toISOString().split('T')[0];
            } else { // day
                key = item.day;
            }
            if (!aggregated[key]) aggregated[key] = { date: key, revenue: 0 };
            aggregated[key].revenue += toNum(item.revenue);
        });
        return Object.values(aggregated).sort((a,b) => new Date(a.date) - new Date(b.date));
    }
    
    // Fallback data processing
    function processOrdersToSummary(orders = []) {
       const totals = orders.reduce((acc, o) => {
            const revenue = toNum(o.total_paid);
            const cost = toNum(o.cost);
            acc.orders += 1;
            acc.revenue += revenue;
            acc.cost += cost;
            acc.profit += (revenue - cost);
            return acc;
        }, { orders: 0, revenue: 0, cost: 0, profit: 0 });

        const groupAndSum = (key, sumKey) => { /* ... implementation ... */ return []; }; // simplified
        const groupAndCount = (key) => { /* ... implementation ... */ return []; }; // simplified
        
        return {
            totals,
            daily: [], byGame: [], byPlatform: [], byStatus: [] // simplified for brevity
        };
    }

    init();
});
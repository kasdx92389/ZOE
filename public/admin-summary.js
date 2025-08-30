// /public/admin-summary.js  (REPLACE ENTIRE FILE)
document.addEventListener('DOMContentLoaded', () => {
    // --- Elements ---
    const startDateInput = document.getElementById('startDate');
    const endDateInput = document.getElementById('endDate');
    const refreshBtn = document.getElementById('refreshBtn');
    const filterButtons = document.querySelectorAll('.btn[data-days]');

    // --- State ---
    let charts = {
        daily: null,
        game: null,
        platform: null,
        status: null
    };

    // --- Initialization ---
    function init() {
        refreshBtn.addEventListener('click', loadSummary);
        filterButtons.forEach(button => {
            button.addEventListener('click', (event) => {
                const days = parseInt(event.currentTarget.dataset.days);
                applyQuickDateRange(days);
                loadSummary();
            });
        });
        applyQuickDateRange(30);
        loadSummary();
    }

    /**
     * Main: prefer server-side summary (timezone-correct), fallback to old flow if needed
     */
    async function loadSummary() {
        const startDate = startDateInput.value;
        const endDate = endDateInput.value;

        if (!startDate || !endDate) { return alert('โปรดเลือกช่วงวันที่'); }

        const params = new URLSearchParams({ startDate, endDate });

        try {
            // 1) Prefer server-side aggregated summary (correct TZ handling)
            const sumRes = await fetch(`/api/summary?${params.toString()}`);
            if (!sumRes.ok) throw new Error(`Server responded ${sumRes.status}`);
            const sumData = await sumRes.json();

            // Render KPIs
            renderKpisFromTotals(sumData.totals);

            // Build chart datasets from server summary
            const dailySummary = {
                labels: (sumData.daily || []).map(row => formatDateLabel(row.day)),
                data: (sumData.daily || []).map(row => toNum(row.revenue))
            };

            const revenueByGame = {
                labels: (sumData.byGame || []).map(r => r.game || 'UNKNOWN'),
                data: (sumData.byGame || []).map(r => toNum(r.revenue))
            };

            const revenueByPlatform = {
                labels: (sumData.byPlatform || []).map(r => r.platform || 'UNKNOWN'),
                data: (sumData.byPlatform || []).map(r => toNum(r.revenue))
            };

            const orderStatus = {
                labels: (sumData.byStatus || []).map(r => r.status || 'UNKNOWN'),
                data: (sumData.byStatus || []).map(r => toNum(r.count))
            };

            renderCharts({ dailySummary, revenueByGame, revenueByPlatform, orderStatus });
        } catch (err) {
            console.warn('Summary API failed, fallback to orders path:', err);
            // 2) Fallback to previous approach if /api/summary is unavailable
            try {
                const fallParams = new URLSearchParams({ startDate, endDate, limit: 10000 });
                const response = await fetch(`/api/orders?${fallParams.toString()}`); // original endpoint used before
                if (!response.ok) throw new Error(`Server responded with status: ${response.status}`);
                const data = await response.json();
                const orders = data.orders || [];

                const summaryData = processOrdersForSummary(orders);
                renderKpis(summaryData.kpis);
                renderCharts(summaryData.charts);
            } catch (error) {
                console.error('Error loading summary (fallback):', error);
                alert(`ไม่สามารถโหลดข้อมูลสรุปได้: ${error.message}`);
            }
        }
    }

    // -------- Helpers for server-side summary --------
    function renderKpisFromTotals(totals = {}) {
        const totalRevenue = toNum(totals.revenue);
        const totalCost = toNum(totals.cost);
        const totalProfit = toNum(totals.profit);
        const totalOrders = toNum(totals.orders);
        const margin = totalRevenue > 0 ? (totalProfit / totalRevenue) : 0;

        document.getElementById('kpiOrders').textContent = (totalOrders || 0).toLocaleString();
        document.getElementById('kpiRevenue').textContent = formatCurrency(totalRevenue || 0);
        document.getElementById('kpiCost').textContent = formatCurrency(totalCost || 0);
        document.getElementById('kpiProfit').textContent = formatCurrency(totalProfit || 0);
        document.getElementById('kpiProfitMargin').textContent = formatPercentage(margin || 0);
    }

    function formatDateLabel(day) {
        // server may send 'YYYY-MM-DD' (date) or a timestamp; normalize to YYYY-MM-DD in Asia/Bangkok
        try {
            if (typeof day === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(day)) return day;
            const d = new Date(day);
            // Use en-CA to get YYYY-MM-DD and force Bangkok timezone
            return d.toLocaleDateString('en-CA', { timeZone: 'Asia/Bangkok' });
        } catch {
            return String(day);
        }
    }

    // -------- Fallback: old client-side processing (kept for robustness) --------
    function processOrdersForSummary(orders) {
        // --- Calculate KPIs ---
        const kpis = orders.reduce((acc, order) => {
            acc.totalOrders += 1;
            acc.totalRevenue += toNum(order.total_paid);
            acc.totalCost += toNum(order.cost);
            return acc;
        }, { totalOrders: 0, totalRevenue: 0, totalCost: 0 });
        
        kpis.totalProfit = kpis.totalRevenue - kpis.totalCost;
        kpis.profitMargin = kpis.totalRevenue > 0 ? kpis.totalProfit / kpis.totalRevenue : 0;

        // --- Group data for Charts ---
        const revenueByGame = groupAndSum(orders, 'game_name', 'total_paid');
        const revenueByPlatform = groupAndSum(orders, 'platform', 'total_paid');
        const orderStatus = groupAndCount(orders, 'status');
        
        // TZ-correct daily aggregation for Asia/Bangkok
        const dailySummary = aggregateByDateBangkok(orders, 'order_date', 'total_paid');

        return {
            kpis,
            charts: {
                dailySummary,
                revenueByGame,
                revenueByPlatform,
                orderStatus
            }
        };
    }

    // --- UI Update & Rendering ---
    function renderKpis(kpis = {}) {
        document.getElementById('kpiOrders').textContent = (kpis.totalOrders || 0).toLocaleString();
        document.getElementById('kpiRevenue').textContent = formatCurrency(kpis.totalRevenue || 0);
        document.getElementById('kpiCost').textContent = formatCurrency(kpis.totalCost || 0);
        document.getElementById('kpiProfit').textContent = formatCurrency(kpis.totalProfit || 0);
        document.getElementById('kpiProfitMargin').textContent = formatPercentage(kpis.profitMargin || 0);
    }
    
    function renderCharts(chartData = {}) {
        const chartColors = ['#4f46e5', '#10b981', '#f59e0b', '#ef4444', '#3b82f6', '#8b5cf6'];
        charts.daily = ensureChart(
            charts.daily,
            'dailyChart',
            'line',
            chartData.dailySummary,
            { label: 'รายได้รายวัน', borderColor: 'var(--accent)', backgroundColor: '#eef2ff', fill: true, tension: 0.3 }
        );
        charts.game = ensureChart(
            charts.game,
            'gameChart',
            'doughnut',
            chartData.revenueByGame,
            { backgroundColor: chartColors }
        );
        charts.platform = ensureChart(
            charts.platform,
            'platformChart',
            'bar',
            chartData.revenueByPlatform,
            { label: 'รายได้', backgroundColor: chartColors }
        );
        charts.status = ensureChart(
            charts.status,
            'statusChart',
            'pie',
            chartData.orderStatus,
            { backgroundColor: chartColors }
        );
    }

    function applyQuickDateRange(days) {
        const today = new Date();
        const pastDate = new Date();
        pastDate.setDate(today.getDate() - (days - 1));
        endDateInput.value = today.toISOString().split('T')[0];
        startDateInput.value = pastDate.toISOString().split('T')[0];
        const activeButton = document.querySelector(`.btn[data-days="${days}"]`);
        setActiveFilterButton(activeButton);
    }

    function setActiveFilterButton(activeButton) {
        filterButtons.forEach(btn => btn.classList.remove('active'));
        if (activeButton) activeButton.classList.add('active');
    }

    // --- Helper Functions ---
    const toNum = (v) => {
        // Accept number or numeric string (Postgres NUMERIC often arrives as string)
        if (typeof v === 'number') return v;
        if (v === null || v === undefined) return 0;
        const s = String(v).replace(/[,฿\s]/g, ''); // guard commas/currency just in case
        const n = parseFloat(s);
        return Number.isFinite(n) ? n : 0;
    };
    const formatCurrency = (num) => `฿${(num || 0).toLocaleString('th-TH', { minimumFractionDigits: 2 })}`;
    const formatPercentage = (num) => `${((num || 0) * 100).toFixed(2)}%`;

    const groupAndSum = (arr, key, sumKey) => {
        const grouped = arr.reduce((acc, item) => {
            const group = item[key] || 'N/A';
            acc[group] = (acc[group] || 0) + toNum(item[sumKey]);
            return acc;
        }, {});
        const labels = Object.keys(grouped).sort((a, b) => grouped[b] - grouped[a]);
        const data = labels.map(label => grouped[label]);
        return { labels, data };
    };
    
    const groupAndCount = (arr, key) => {
        const grouped = arr.reduce((acc, item) => {
            const group = item[key] || 'N/A';
            acc[group] = (acc[group] || 0) + 1;
            return acc;
        }, {});
        const labels = Object.keys(grouped).sort((a, b) => grouped[b] - grouped[a]);
        const data = labels.map(label => grouped[label]);
        return { labels, data };
    };

    // TZ-correct daily aggregation (Asia/Bangkok)
    const aggregateByDateBangkok = (arr, dateKey, sumKey) => {
        const dailyTotals = arr.reduce((acc, item) => {
            if (!item[dateKey]) return acc;
            const d = new Date(item[dateKey]);
            const ymd = d.toLocaleDateString('en-CA', { timeZone: 'Asia/Bangkok' }); // YYYY-MM-DD
            acc[ymd] = (acc[ymd] || 0) + toNum(item[sumKey]);
            return acc;
        }, {});
        const labels = Object.keys(dailyTotals).sort();
        const data = labels.map(date => dailyTotals[date]);
        return { labels, data };
    };

    function ensureChart(instance, canvasId, type, data, datasetOverrides = {}) {
        const ctx = document.getElementById(canvasId)?.getContext('2d');
        if (!ctx) return null;
        if (instance) instance.destroy();
        return new Chart(ctx, {
            type,
            data: {
                labels: data.labels || [],
                datasets: [{ data: data.data || [], ...datasetOverrides }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        display: ['doughnut', 'pie'].includes(type),
                        position: 'bottom',
                        labels: { font: { family: 'Sarabun' } }
                    }
                },
                scales: ['line', 'bar'].includes(type)
                    ? {
                        y: { ticks: { font: { family: 'Sarabun' } } },
                        x: { ticks: { font: { family: 'Sarabun' } } }
                    }
                    : {}
            }
        });
    }

    // --- Start the app ---
    init();
});

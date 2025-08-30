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
     * Main function to fetch and process data for the summary page.
     */
    async function loadSummary() {
        const startDate = startDateInput.value;
        const endDate = endDateInput.value;

        if (!startDate || !endDate) { return alert('โปรดเลือกช่วงวันที่'); }

        try {
            // 1. Fetch raw order data from the same endpoint as the management page
            // We add a high limit to try and get all orders in the date range.
            const params = new URLSearchParams({ startDate, endDate, limit: 10000 });
            const response = await fetch(`/api/orders?${params.toString()}`);
            
            if (!response.ok) throw new Error(`Server responded with status: ${response.status}`);
            
            const data = await response.json();
            const orders = data.orders || [];

            // 2. Process the raw order data on the frontend to create summary data
            const summaryData = processOrdersForSummary(orders);

            // 3. Render the processed data
            renderKpis(summaryData.kpis);
            renderCharts(summaryData.charts);

        } catch (error) {
            console.error('Error loading summary:', error);
            alert(`ไม่สามารถโหลดข้อมูลสรุปได้: ${error.message}`);
        }
    }

    /**
     * Processes an array of orders into aggregated KPIs and chart data.
     * @param {Array} orders - The array of order objects from the API.
     * @returns {Object} An object containing kpis and chart data.
     */
    function processOrdersForSummary(orders) {
        // --- Calculate KPIs ---
        const kpis = orders.reduce((acc, order) => {
            acc.totalOrders += 1;
            acc.totalRevenue += Number(order.total_paid || 0);
            acc.totalCost += Number(order.cost || 0);
            return acc;
        }, { totalOrders: 0, totalRevenue: 0, totalCost: 0 });
        
        kpis.totalProfit = kpis.totalRevenue - kpis.totalCost;
        kpis.profitMargin = kpis.totalRevenue > 0 ? kpis.totalProfit / kpis.totalRevenue : 0;

        // --- Group data for Charts ---
        const revenueByGame = groupAndSum(orders, 'game_name', 'total_paid');
        const revenueByPlatform = groupAndSum(orders, 'platform', 'total_paid');
        const orderStatus = groupAndCount(orders, 'status');
        
        // This chart needs daily aggregation, which is more complex
        const dailySummary = aggregateByDate(orders, 'order_date', 'total_paid');

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

    // --- UI Update & Rendering (No changes needed from here down) ---
    function renderKpis(kpis = {}) {
        document.getElementById('kpiOrders').textContent = (kpis.totalOrders || 0).toLocaleString();
        document.getElementById('kpiRevenue').textContent = formatCurrency(kpis.totalRevenue || 0);
        document.getElementById('kpiCost').textContent = formatCurrency(kpis.totalCost || 0);
        document.getElementById('kpiProfit').textContent = formatCurrency(kpis.totalProfit || 0);
        document.getElementById('kpiProfitMargin').textContent = formatPercentage(kpis.profitMargin || 0);
    }
    
    function renderCharts(chartData = {}) {
        const chartColors = ['#4f46e5', '#10b981', '#f59e0b', '#ef4444', '#3b82f6', '#8b5cf6'];
        charts.daily = ensureChart(charts.daily, 'dailyChart', 'line', chartData.dailySummary, { label: 'รายได้รายวัน', borderColor: 'var(--accent)', backgroundColor: '#eef2ff', fill: true, tension: 0.3 });
        charts.game = ensureChart(charts.game, 'gameChart', 'doughnut', chartData.revenueByGame, { backgroundColor: chartColors });
        charts.platform = ensureChart(charts.platform, 'platformChart', 'bar', chartData.revenueByPlatform, { label: 'รายได้', backgroundColor: chartColors });
        charts.status = ensureChart(charts.status, 'statusChart', 'pie', chartData.orderStatus, { backgroundColor: chartColors });
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
        if (activeButton) {
            activeButton.classList.add('active');
        }
    }

    // --- Helper Functions ---
    const formatCurrency = (num) => `฿${(num || 0).toLocaleString('th-TH', { minimumFractionDigits: 2 })}`;
    const formatPercentage = (num) => `${((num || 0) * 100).toFixed(2)}%`;

    const groupAndSum = (arr, key, sumKey) => {
        const grouped = arr.reduce((acc, item) => {
            const group = item[key] || 'N/A';
            acc[group] = (acc[group] || 0) + Number(item[sumKey] || 0);
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

    const aggregateByDate = (arr, dateKey, sumKey) => {
        const dailyTotals = arr.reduce((acc, item) => {
            if (!item[dateKey]) return acc;
            const date = item[dateKey].split('T')[0]; // Get YYYY-MM-DD
            acc[date] = (acc[date] || 0) + Number(item[sumKey] || 0);
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
        return new Chart(ctx, { type, data: { labels: data.labels || [], datasets: [{ data: data.data || [], ...datasetOverrides }] }, options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: ['doughnut', 'pie'].includes(type), position: 'bottom', labels: { font: { family: 'Sarabun' } } } }, scales: ['line', 'bar'].includes(type) ? { y: { ticks: { font: { family: 'Sarabun' } } }, x: { ticks: { font: { family: 'Sarabun' } } } } : {} } });
    }

    // --- Start the app ---
    init();
});
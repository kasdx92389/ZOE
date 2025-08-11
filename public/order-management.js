(function() {
  const state = {
    packages: [],
    games: [],
    items: [],
    editingOrderId: null,
    allOrders: [],
    validPlatforms: [], // [NEW] To store the standard platform list
  };

  // --- Element Selectors ---
  const el = id => document.getElementById(id);
  const qs = s => document.querySelector(s);

  // --- Custom Dialog Functions ---
  const dialog = {
    overlay: el('custom-dialog-overlay'),
    title: el('dialog-title'),
    message: el('dialog-message'),
    buttons: el('dialog-buttons'),
    show() { this.overlay.classList.add('visible'); },
    hide() { this.overlay.classList.remove('visible'); },
  };

  function showCustomAlert(message, title = 'แจ้งเตือน') {
    dialog.title.textContent = title;
    dialog.message.textContent = message;
    dialog.buttons.innerHTML = '<button class="btn primary">ตกลง</button>';
    dialog.buttons.querySelector('button').onclick = () => dialog.hide();
    dialog.show();
  }

  function showCustomConfirm(message, title = 'ยืนยันการกระทำ') {
    return new Promise(resolve => {
      dialog.title.textContent = title;
      dialog.message.innerHTML = message; 
      dialog.buttons.innerHTML = `
        <button class="btn" id="dialog-cancel">ยกเลิก</button>
        <button class="btn primary" id="dialog-confirm">ยืนยัน</button>
      `;
      dialog.show();
      el('dialog-confirm').onclick = () => { dialog.hide(); resolve(true); };
      el('dialog-cancel').onclick = () => { dialog.hide(); resolve(false); };
    });
  }


  // --- Formatters & Helpers ---
  const fmt = n => Number(n || 0).toLocaleString('th-TH', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  const uniq = arr => [...new Set(arr.filter(Boolean))].sort();

  function getStatusBadgeClass(status) {
    if (!status) return 'status-cancelled';
    if (status.includes('สำเร็จ')) return 'status-success';
    if (status.includes('รอดำเนินการ')) return 'status-pending';
    if (status.includes('ผิดพลาด')) return 'status-error';
    return 'status-cancelled';
  }

  // --- UI Update Functions ---
  function updateFormUI(mode = 'new', order = null) {
    el('order-form').dataset.mode = mode;
    state.editingOrderId = order ? order.order_number : null;

    if (mode === 'edit') {
      el('form-title').textContent = `แก้ไขออเดอร์: ${order.order_number}`;
      el('btn-save').textContent = 'อัปเดตข้อมูล';
    } else {
      el('form-title').textContent = '';
      el('btn-save').textContent = 'บันทึกออเดอร์';
    }
    qs('#orders-table .selected')?.classList.remove('selected');
    if (order) {
      qs(`#orders-table tr[data-id="${order.order_number}"]`)?.classList.add('selected');
    }
  }

  function resetForm() {
    el('order-form').reset();
    const today = new Date();
    const year = today.getFullYear();
    const month = String(today.getMonth() + 1).padStart(2, '0'); // getMonth() เริ่มจาก 0 เลยต้อง +1
    const day = String(today.getDate()).padStart(2, '0');
    el('order-date').value = `${year}-${month}-${day}`;
    state.items = [];
    fillSelect(el('platform'), state.validPlatforms, '— เลือกแพลตฟอร์ม —'); // [MODIFIED] Reset platform dropdown
    renderItems();
    updateFormUI('new');
    el('save-result').textContent = '';
  }

  function renderItems() {
    const tb = qs('#items-table tbody');
    tb.innerHTML = state.items.map((it, idx) => {
      const sum = it.quantity * it.unit_price;
      return `<tr>
        <td>${it.package_name}</td>
        <td>${it.quantity}</td>
        <td class="num">${fmt(it.unit_price)}</td>
        <td class="num">${fmt(sum)}</td>
        <td>
          <button type="button" class="btn-delete-item" data-rm-idx="${idx}" title="ลบรายการนี้">
             <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>
          </button>
        </td>
      </tr>`;
    }).join('');
    updateTotals();
  }

  function renderOrders(orders) {
    state.allOrders = orders;
    const tb = qs('#orders-table tbody');
    tb.innerHTML = (orders || []).map(o => `
      <tr data-id="${o.order_number}" class="interactive-row">
        <td class="key-data">${o.order_number}</td>
        <td>${o.order_date}</td>
        <td>${o.customer_name || ''}</td>
        <td>${o.game_name || ''}</td>
        <td class="num key-data">${fmt(o.total_paid)}</td>
        <td class="num">${fmt(o.profit)}</td>
        <td><span class="status-badge ${getStatusBadgeClass(o.status)}">${o.status}</span></td>
        <td>${o.operator || ''}</td>
        <td>
          <button type="button" class="btn-delete-order" data-id="${o.order_number}" title="ลบออเดอร์นี้">
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>
          </button>
        </td>
      </tr>`).join('');
  }

  // --- Calculation & Data Functions ---
  function calcProfit() {
    const total = Number(el('total-paid').value || 0);
    const cost = Number(el('cost').value || 0);
    el('profit').textContent = fmt(total - cost);
  }

  function updateTotals() {
    const sum = state.items.reduce((a, c) => a + (Number(c.quantity || 0) * Number(c.unit_price || 0)), 0);
    el('total-paid').value = sum.toFixed(2);
    calcProfit();
  }

  function fillSelect(sel, values, placeholder = '— เลือก —') {
    const currentVal = sel.value;
    sel.innerHTML = `<option value="">${placeholder}</option>` + values.map(v => `<option value="${v}">${v}</option>`).join('');
    if ([...sel.options].some(o => o.value === currentVal)) {
      sel.value = currentVal;
    }
  }

  function setIfExists(sel, value) {
    if (!value) return;
    if (![...sel.options].some(o => o.value === value)) {
      sel.add(new Option(value, value));
    }
    sel.value = value;
  }
  
  function refillPackageOptions() {
  const gameSelect = el('game-select');
  const packageSelect = el('add-item-package');
  const game = gameSelect.value;

  // 1. ล็อก/ปลดล็อกช่องเลือกแพ็กเกจ
  packageSelect.disabled = !game;

  // 2. แสดงรายการแพ็กเกจเฉพาะเกมที่เลือก (ถ้ามี)
  const list = game ? state.packages.filter(p => p.game_association === game) : []; // ถ้าไม่เลือกเกม ให้เป็น array ว่าง

  packageSelect.innerHTML = '<option value="">— เลือกเกมก่อน —</option>' + list.map(p => {
    const label = `${p.name} (${p.product_code || 'N/A'})`;
    return `<option value="${p.id}" data-price="${p.price || 0}" data-type="${p.type || ''}" data-channel="${p.channel || ''}">${label}</option>`;
  }).join('');

  fillSelect(el('topup-channel'), uniq(list.map(p => p.channel)), '— เลือกเกมก่อน —');
}

  // --- API & Event Handlers ---
  async function loadInitialData() {
    const [dashRes, ordersRes] = await Promise.all([
      fetch('/api/dashboard-data'),
      fetch('/api/orders')
    ]);
    const dashData = await dashRes.json();
    const ordersData = await ordersRes.json();

    state.packages = dashData.packages || [];
    state.games = dashData.games || [];

    const platforms = ['FACEBOOK', 'LINE'];
    state.validPlatforms = platforms; // [MODIFIED] Store standard platforms
    const statuses = ['รอดำเนินการ', 'รายการสำเร็จ', 'ยกเลิก/คืนเงิน', 'แก้ไขรายการ', 'รายการผิดพลาด'];

    fillSelect(el('game-select'), state.games, '— เลือกเกม —');
    fillSelect(el('platform'), state.validPlatforms, '— เลือกแพลตฟอร์ม —');
    fillSelect(el('status'), statuses, '— เลือกสถานะ —');
    fillSelect(el('filter-platform'), state.validPlatforms, 'ทุกแพลตฟอร์ม');
    fillSelect(el('filter-status'), statuses, 'ทุกสถานะ');

    refillPackageOptions();
    renderOrders(ordersData.orders || []);
  }
  
  async function refreshOrders() {
    const q = el('search-q').value.trim();
    const status = el('filter-status').value;
    const platform = el('filter-platform').value;
    const url = new URL(location.origin + '/api/orders');
    if (q) url.searchParams.set('q', q);
    if (status) url.searchParams.set('status', status);
    if (platform) url.searchParams.set('platform', platform);
    
    const res = await fetch(url);
    const data = await res.json();
    renderOrders(data.orders || []);
  }
  
  async function showOrderConfirmation() {
    if (!el('game-select').value) { return showCustomAlert('กรุณาเลือกเกม'); }
    if (!state.items.length) { return showCustomAlert('กรุณาเพิ่มรายการแพ็กเกจอย่างน้อย 1 รายการ'); }

    const isUpdating = state.editingOrderId;
    const title = isUpdating ? `ยืนยันการแก้ไขออเดอร์` : 'ยืนยันการสร้างออเดอร์';
    const totalPaid = Number(el('total-paid').value || 0);
    const cost = Number(el('cost').value || 0);
    const profit = totalPaid - cost;

    const summaryHtml = `
      <div class="summary-details">
        <p><strong>ลูกค้า:</strong> ${el('customer-name').value || '<em>- ไม่ระบุ -</em>'}</p>
        <p><strong>เกม:</strong> ${el('game-select').value}</p>
        <p><strong>สถานะ:</strong> ${el('status').value}</p>
        <p><strong>ผู้ทำรายการ:</strong> ${el('operator').value}</p>
        <hr>
        <p><strong>รายการแพ็กเกจ:</strong></p>
        <ul class="summary-items">
          ${state.items.map(it => `<li>- ${it.package_name} (x${it.quantity})</li>`).join('')}
        </ul>
        <hr>
        <div class="summary-totals">
            <span>ยอดจ่าย:</span><strong>${fmt(totalPaid)}</strong>
            <span>ต้นทุน:</span><strong>${fmt(cost)}</strong>
            <span>กำไร:</span><strong>${fmt(profit)}</strong>
        </div>
      </div>
    `;

    const confirmed = await showCustomConfirm(summaryHtml, title);
    if (confirmed) {
      saveOrder();
    }
  }

  async function saveOrder() {
    const body = {
      order_date: el('order-date').value || new Date().toISOString().slice(0, 10),
      platform: el('platform').value,
      customer_name: el('customer-name').value.trim(),
      game_name: el('game-select').value,
      operator: el('operator').value,
      topup_channel: el('topup-channel').value,
      total_paid: Number(el('total-paid').value || 0),
      cost: Number(el('cost').value || 0),
      payment_proof_url: el('payment-proof').value.trim(),
      sales_proof_url: el('sales-proof').value.trim(),
      status: el('status').value,
      note: el('note').value.trim(),
      items: state.items
    };

    const isUpdating = state.editingOrderId;
    const url = isUpdating ? `/api/orders/${state.editingOrderId}` : '/api/orders';
    const method = isUpdating ? 'PUT' : 'POST';

    const res = await fetch(url, {
      method: method,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });

    if (!res.ok) {
      return showCustomAlert('บันทึกไม่สำเร็จ!', 'เกิดข้อผิดพลาด');
    }

    const out = await res.json();
    el('save-result').textContent = isUpdating ? `อัปเดต ${out.order_number} สำเร็จ` : `บันทึกแล้ว: ${out.order_number}`;
    
    await refreshOrders();
    setTimeout(() => resetForm(), 1000);
  }

  async function deleteOrder(orderId) {
    const confirmed = await showCustomConfirm(`คุณแน่ใจหรือไม่ว่าต้องการลบออเดอร์ ${orderId}?\nการกระทำนี้ไม่สามารถย้อนกลับได้`, 'ยืนยันการลบ');
    if (!confirmed) return;

    const res = await fetch(`/api/orders/${orderId}`, { method: 'DELETE' });

    if (!res.ok) {
      return showCustomAlert(`เกิดข้อผิดพลาด: ไม่สามารถลบออเดอร์ ${orderId} ได้`, 'เกิดข้อผิดพลาด');
    }
    
    showCustomAlert(`ออเดอร์ ${orderId} ถูกลบแล้ว`, 'ลบสำเร็จ');
    if (state.editingOrderId === orderId) {
      resetForm();
    }
    await refreshOrders();
  }

  function loadOrderIntoForm(orderId) {
    const orderData = state.allOrders.find(o => o.order_number === orderId);
    if (!orderData) return;
    
    updateFormUI('edit', orderData);
    
    // [MODIFIED] Reset platform dropdown to its clean state before setting a value
    fillSelect(el('platform'), state.validPlatforms, '— เลือกแพลตฟอร์ม —');
    
    el('order-date').value = orderData.order_date;
    setIfExists(el('game-select'), orderData.game_name);
    refillPackageOptions();
    
    // [MODIFIED] Revert to using setIfExists for platform to handle non-standard saved values correctly
    setIfExists(el('platform'), orderData.platform);
    
    setIfExists(el('topup-channel'), orderData.topup_channel);
    setIfExists(el('operator'), orderData.operator);
    el('customer-name').value = orderData.customer_name || '';
    el('total-paid').value = orderData.total_paid?.toFixed(2) || '0.00';
    el('cost').value = orderData.cost?.toFixed(2) || '0.00';
    el('payment-proof').value = orderData.payment_proof_url || '';
    el('sales-proof').value = orderData.sales_proof_url || '';
    setIfExists(el('status'), orderData.status);
    el('note').value = orderData.note || '';
    
    state.items = orderData.items || []; 
    renderItems();
    
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  // --- Initial Setup & Event Listeners ---
  document.addEventListener('DOMContentLoaded', () => {
    resetForm();
    loadInitialData();

    el('game-select').addEventListener('change', refillPackageOptions);
    
    el('add-item-package').addEventListener('change', e => {
      const opt = e.target.selectedOptions[0];
      if (!opt || !opt.value) return;
      el('add-item-unit').value = opt.dataset.price || '0';
      setIfExists(el('topup-channel'), opt.dataset.channel);
    });
    
    el('btn-add-item').addEventListener('click', () => {
      const pkgSelect = el('add-item-package');
      const opt = pkgSelect.selectedOptions[0];
      if (!opt || !opt.value) { return showCustomAlert('กรุณาเลือกแพ็กเกจ'); }
      
      const id = Number(opt.value);
      const pkg = state.packages.find(p => p.id === id);
      const qty = Math.max(1, Number(el('add-item-qty').value || 1));
      const unit = Number(el('add-item-unit').value || 0);

      state.items.push({ package_id: id, package_name: pkg?.name || opt.textContent, product_code: pkg?.product_code, quantity: qty, unit_price: unit });
      renderItems();
      pkgSelect.value = '';
      el('add-item-qty').value = '1';
      el('add-item-unit').value = '';
    });
    
    qs('#items-table').addEventListener('click', e => {
      const btn = e.target.closest('[data-rm-idx]');
      if (!btn) return;
      state.items.splice(Number(btn.dataset.rmIdx), 1);
      renderItems();
    });

    el('order-form').addEventListener('submit', (e) => {
        e.preventDefault();
        showOrderConfirmation();
    });
    
    el('cost').addEventListener('input', calcProfit);
    el('total-paid').addEventListener('input', calcProfit);

    el('btn-new-order').addEventListener('click', resetForm);
    el('btn-refresh').addEventListener('click', refreshOrders);
    el('btn-export-csv').addEventListener('click', () => location.href = '/api/orders/export/csv');
    
    el('search-q').addEventListener('input', refreshOrders);
    el('filter-status').addEventListener('change', refreshOrders);
    el('filter-platform').addEventListener('change', refreshOrders);
    
    qs('#orders-table').addEventListener('click', e => {
      const deleteBtn = e.target.closest('.btn-delete-order');
      const row = e.target.closest('tr.interactive-row');

      if (deleteBtn) {
        e.stopPropagation();
        const orderId = deleteBtn.dataset.id;
        deleteOrder(orderId);
      } else if (row && row.dataset.id) {
        loadOrderIntoForm(row.dataset.id);
      }
    });
  });
})();
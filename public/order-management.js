(function() {
  const state = {
    packages: [],
    games: [],
    items: [],
    editingOrderId: null,
    allOrders: [],
    validPlatforms: [],
    currentPage: 1,
    rowsPerPage: 20,
  };

  const el = id => document.getElementById(id);
  const qs = s => document.querySelector(s);

  function renderPagination(totalItems) {
    const summaryEl = el('pagination-summary');
    const controlsEl = el('pagination-controls');
    const totalPages = Math.ceil(totalItems / state.rowsPerPage);

    if (totalItems === 0) {
      summaryEl.textContent = 'ไม่พบรายการออเดอร์';
      controlsEl.innerHTML = '';
      return;
    }

    const startItem = (state.currentPage - 1) * state.rowsPerPage + 1;
    const endItem = Math.min(startItem + state.rowsPerPage - 1, totalItems);
    summaryEl.textContent = `แสดง ${startItem} ถึง ${endItem} จาก ${totalItems} แถว`;

    let buttonsHtml = `<button id="prev-page" title="หน้าก่อนหน้า" ${state.currentPage === 1 ? 'disabled' : ''}>&lt;</button>`;

    const maxPagesToShow = 5;
    let startPage, endPage;
    if (totalPages <= maxPagesToShow) {
        startPage = 1; endPage = totalPages;
    } else {
        const maxPagesBeforeCurrent = Math.floor(maxPagesToShow / 2);
        const maxPagesAfterCurrent = Math.ceil(maxPagesToShow / 2) - 1;
        if (state.currentPage <= maxPagesBeforeCurrent) {
            startPage = 1; endPage = maxPagesToShow;
        } else if (state.currentPage + maxPagesAfterCurrent >= totalPages) {
            startPage = totalPages - maxPagesToShow + 1; endPage = totalPages;
        } else {
            startPage = state.currentPage - maxPagesBeforeCurrent;
            endPage = state.currentPage + maxPagesAfterCurrent;
        }
    }

    if (startPage > 1) buttonsHtml += `<button data-page="1">1</button><button disabled>...</button>`;
    for (let i = startPage; i <= endPage; i++) {
        buttonsHtml += `<button data-page="${i}" class="${i === state.currentPage ? 'active' : ''}">${i}</button>`;
    }
    if (endPage < totalPages) buttonsHtml += `<button disabled>...</button><button data-page="${totalPages}">${totalPages}</button>`;

    buttonsHtml += `<button id="next-page" title="หน้าถัดไป" ${state.currentPage === totalPages ? 'disabled' : ''}>&gt;</button>`;
    controlsEl.innerHTML = buttonsHtml;
  }

  function handlePaginationClick(e) {
      const target = e.target.closest('button');
      if (!target || target.disabled) return;
      
      let newPage = state.currentPage;

      if (target.id === 'prev-page') newPage--;
      else if (target.id === 'next-page') newPage++;
      else if (target.dataset.page) newPage = Number(target.dataset.page);
      else return;
      
      if (newPage !== state.currentPage) {
          state.currentPage = newPage;
          refreshOrders();
      }
  }

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

  const fmt = n => Number(n || 0).toLocaleString('th-TH', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  const uniq = arr => [...new Set(arr.filter(Boolean))].sort();

  function getStatusBadgeClass(status) {
    if (!status) return 'status-cancelled';
    if (status.includes('สำเร็จ')) return 'status-success';
    if (status.includes('รอดำเนินการ')) return 'status-pending';
    if (status.includes('ผิดพลาด')) return 'status-error';
    return 'status-cancelled';
  }

  function updateFormUI(mode = 'new', order = null) {
    el('order-form').dataset.mode = mode;
    state.editingOrderId = order ? order.order_number : null;

    if (mode === 'edit') {
      el('form-title').textContent = `แก้ไขออเดอร์: ${order.order_number}`;
      el('btn-save').textContent = 'อัปเดตข้อมูล';
    } else {
      el('form-title').textContent = 'สร้าง/แก้ไขออเดอร์';
      el('btn-save').textContent = 'บันทึกออเดอร์';
    }
    qs('#orders-table .selected')?.classList.remove('selected');
    if (order) {
      qs(`#orders-table tr[data-id="${order.order_number}"]`)?.classList.add('selected');
    }
  }

  function resetForm() {
    el('order-form').reset();

    // Set default value to current local date and time
    const now = new Date();
    now.setMinutes(now.getMinutes() - now.getTimezoneOffset()); // Adjust for local timezone
    el('order-date').value = now.toISOString().slice(0, 19);

    state.items = [];
    fillSelect(el('platform'), state.validPlatforms, '— เลือกแพลตฟอร์ม —');
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

function renderOrders(orders, total) {
  state.allOrders = orders;
  const tb = qs('#orders-table tbody');
  tb.innerHTML = ''; // Clear existing rows

  (orders || []).forEach(o => {
    const tr = document.createElement('tr');
    tr.dataset.id = o.order_number;
    tr.className = 'interactive-row';

    const formattedDateTime = o.order_date
      ? new Date(o.order_date).toLocaleString('sv-SE', {
          year: 'numeric', month: '2-digit', day: '2-digit',
          hour: '2-digit', minute: '2-digit'
        })
      : '';

    // Create and append cells one by one
    tr.innerHTML = `
      <td class="key-data">${o.order_number}</td>
      <td>${formattedDateTime}</td>
      <td>${o.customer_name || ''}</td>
      <td>${o.game_name || ''}</td>
      <td class="num key-data">${fmt(o.total_paid)}</td>
      <td><span class="status-badge ${getStatusBadgeClass(o.status)}">${o.status}</span></td>
      <td>${o.operator || ''}</td>
      <td>
        <button type="button" class="btn-delete-order" data-id="${o.order_number}" title="ลบออเดอร์นี้">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>
        </button>
      </td>
    `;
    tb.appendChild(tr);
  });

  renderPagination(total);
}

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
  const isEditMode = el('order-form').dataset.mode === 'edit';

  // ส่วนของการเติม Package ยังทำงานเหมือนเดิม
  packageSelect.disabled = !game;
  const gameSpecificPackages = game ? state.packages.filter(p => p.game_association === game) : [];

  packageSelect.innerHTML = '<option value="">— เลือกแพ็กเกจ —</option>' + gameSpecificPackages.map(p => {
    const label = `${p.name} (${p.product_code || 'N/A'})`;
    return `<option value="${p.id}" data-price="${p.price || 0}" data-type="${p.type || ''}" data-channel="${p.channel || ''}">${label}</option>`;
  }).join('');

  // ++ REVISED LOGIC FOR TOPUP CHANNEL ++
  let availableChannels;
  if (isEditMode) {
    // ถ้าเป็นโหมดแก้ไข: ดึง "ช่องทาง" ที่มีทั้งหมดจากทุกแพ็กเกจ
    availableChannels = uniq(state.packages.map(p => p.channel));
  } else {
    // ถ้าเป็นโหมดสร้างใหม่: ดึง "ช่องทาง" เฉพาะของเกมที่เลือก
    availableChannels = uniq(gameSpecificPackages.map(p => p.channel));
  }
  fillSelect(el('topup-channel'), availableChannels, '— เลือกช่องทาง —');
}

  async function loadInitialData() {
    const params = getCurrentFilters();
    const [dashRes, ordersRes] = await Promise.all([
        fetch('/api/dashboard-data'),
        fetch(`/api/orders?${params.toString()}`)
    ]);
    const dashData = await dashRes.json();
    const ordersData = await ordersRes.json();

    state.packages = dashData.packages || [];
    state.games = dashData.games || [];
    state.validPlatforms = ['FACEBOOK', 'LINE'];
    const statuses = ['รอดำเนินการ', 'รายการสำเร็จ', 'ยกเลิก/คืนเงิน', 'แก้ไขรายการ', 'รายการผิดพลาด'];

    fillSelect(el('game-select'), state.games, '— เลือกเกม —');
    fillSelect(el('platform'), state.validPlatforms, '— เลือกแพลตฟอร์ม —');
    fillSelect(el('status'), statuses, '— เลือกสถานะ —');
    fillSelect(el('filter-platform'), state.validPlatforms, 'ทุกแพลตฟอร์ม');
    fillSelect(el('filter-status'), statuses, 'ทุกสถานะ');

    refillPackageOptions();
    renderOrders(ordersData.orders || [], ordersData.total || 0);
  }
  
  function getCurrentFilters() {
    const params = new URLSearchParams();
    const q = el('search-q').value.trim();
    const status = el('filter-status').value;
    const platform = el('filter-platform').value;
    const startDate = el('filter-start-date').value;
    const endDate = el('filter-end-date').value;
    
    params.set('page', state.currentPage);
    params.set('limit', state.rowsPerPage);

    if (q) params.set('q', q);
    if (status) params.set('status', status);
    if (platform) params.set('platform', platform);
    if (startDate) params.set('startDate', startDate);
    if (endDate) params.set('endDate', endDate);
    
    return params;
  }

  async function refreshOrders() {
    const params = getCurrentFilters();
    const url = `/api/orders?${params.toString()}`;
    
    const res = await fetch(url);
    const data = await res.json();
    renderOrders(data.orders || [], data.total || 0);
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
      order_date: el('order-date').value ? new Date(el('order-date').value).toISOString() : new Date().toISOString(),
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
    
    state.currentPage = 1; // กลับไปหน้าแรกทุกครั้งที่ save สำเร็จ
    await refreshOrders();
    setTimeout(() => resetForm(), 1000);
  }

  async function deleteOrder(orderId) {
    const confirmed = await showCustomConfirm(`คุณแน่ใจหรือไม่ว่าต้องการลบออเดอร์ <strong>${orderId}</strong>?<br>การกระทำนี้ไม่สามารถย้อนกลับได้`, 'ยืนยันการลบ');
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
    
    fillSelect(el('platform'), state.validPlatforms, '— เลือกแพลตฟอร์ม —');
    
    // Format the full ISO string from DB to the format needed by datetime-local input
    if (orderData.order_date) {
    // 1. สร้าง Date object จากเวลา UTC ที่ได้จากฐานข้อมูล
    const localDate = new Date(orderData.order_date);
    
    // 2. ชดเชยเวลาด้วย Timezone offset ของเครื่องผู้ใช้
    localDate.setMinutes(localDate.getMinutes() - localDate.getTimezoneOffset());
    
    // 3. แปลงเป็น ISO string และตัดให้เหลือรูปแบบที่ input ต้องการ
    el('order-date').value = localDate.toISOString().slice(0, 19);
    }
    
    setIfExists(el('game-select'), orderData.game_name);
    refillPackageOptions();
    
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

  document.addEventListener('DOMContentLoaded', () => {
    resetForm();
    
    // ++ REVISED: Auto-parses pasted date-time string using 'paste' event ++
    el('order-date').addEventListener('paste', e => {
      // 1. ป้องกันไม่ให้บราวเซอร์วางข้อความตามปกติ
      e.preventDefault();

      // 2. ดึงข้อความจากคลิปบอร์ดโดยตรง
      const pastedText = (e.clipboardData || window.clipboardData).getData('text');

      // 3. ใช้ Regex ตรวจสอบข้อความที่ได้มา
      const regex = /วันที่:\s*(\d{2})\/(\d{2})\/(\d{4})\s*เวลา:\s*(\d{2}):(\d{2}):(\d{2})/;
      const match = pastedText.match(regex);

      // 4. ถ้าตรงตามรูปแบบ ให้แปลงและใส่ค่าลงในช่อง input
      if (match) {
        const [, day, month, year, hour, minute, second] = match;
        const formattedDateTime = `${year}-${month}-${day}T${hour}:${minute}:${second}`;
        e.target.value = formattedDateTime;
      }
    });

    // 1. สร้าง object ของวันที่สำหรับวันนี้และ 7 วันก่อน
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(endDate.getDate() - 6); // ตั้งค่าวันที่ของ startDate เป็น 6 วันก่อนหน้า (รวมเป็น 7 วัน)

    // 2. Format วันที่ให้เป็นรูปแบบ YYYY-MM-DD
    const formatDate = (d) => d.toLocaleDateString('en-CA', { timeZone: 'Asia/Bangkok' }); // YYYY-MM-DD
    const formattedStartDate = formatDate(startDate);
    const formattedEndDate = formatDate(endDate);

    // 3. กำหนดค่าเริ่มต้นให้กับ input ที่ใช้กรองข้อมูล
    const startDateInput = el('filter-start-date');
    const endDateInput = el('filter-end-date');
    startDateInput.value = formattedStartDate;
    endDateInput.value = formattedEndDate;

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
    
    const exportBtn = el('btn-export-csv');
    if (exportBtn) {
        exportBtn.addEventListener('click', async () => {
            const originalBtnContent = exportBtn.innerHTML;
            exportBtn.innerHTML = `<span><svg class="btn-spinner" viewBox="0 0 50 50"><circle class="path" cx="25" cy="25" r="20" fill="none" stroke-width="5"></circle></svg> Processing...</span>`;
            exportBtn.disabled = true;

            try {
                const params = getCurrentFilters();
                const res = await fetch(`/api/orders/export/csv?${params.toString()}`);

                if (res.ok) {
                    const blob = await res.blob();
                    const url = window.URL.createObjectURL(blob);
                    const a = document.createElement('a');
                    a.style.display = 'none';
                    a.href = url;
                    
                    const disposition = res.headers.get('content-disposition');
                    let filename = `orders-export.csv`;
                    if (disposition && disposition.includes('attachment')) {
                        const matches = /filename="([^"]+)"/.exec(disposition);
                        if (matches && matches[1]) filename = matches[1];
                    }
                    
                    a.download = filename;
                    document.body.appendChild(a);
                    a.click();
                    window.URL.revokeObjectURL(url);
                    a.remove();
                } else {
                    const errorMsg = await res.text();
                    showCustomAlert(errorMsg || 'ไม่มีข้อมูลออเดอร์ให้ Export', 'แจ้งเตือน');
                }
            } catch (err) {
                console.error("CSV Export failed:", err);
                showCustomAlert('การ Export ล้มเหลว กรุณาลองใหม่อีกครั้ง', 'เกิดข้อผิดพลาด');
            } finally {
                exportBtn.innerHTML = originalBtnContent;
                exportBtn.disabled = false;
            }
        });
    }
    
    el('search-q').addEventListener('input', () => {
      state.currentPage = 1;
      refreshOrders();
    });
    ['filter-status', 'filter-platform'].forEach(id => {
        el(id).addEventListener('change', () => {
          state.currentPage = 1;
          refreshOrders();
        });
    });
    
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
    
    el('pagination-controls').addEventListener('click', handlePaginationClick);

    new Litepicker({
        element: el('date-range-picker'),
        singleMode: false,
        autoApply: true,
        startDate: startDate,
        endDate: endDate,
        format: 'YYYY-MM-DD',
        separator: ' ถึง ',
        setup: (picker) => {
            picker.on('selected', (date1, date2) => {
                startDateInput.value = picker.getStartDate().format('YYYY-MM-DD');
                endDateInput.value = picker.getEndDate().format('YYYY-MM-DD');
                state.currentPage = 1;
                refreshOrders();
            });
            picker.on('clear:selection', () => {
                startDateInput.value = '';
                endDateInput.value = '';
                state.currentPage = 1;
                refreshOrders();
            });
        }
    });

  });
})();
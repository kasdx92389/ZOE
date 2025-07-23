document.addEventListener('DOMContentLoaded', () => {
    // --- DATA ---
    const packageTypes = ["UID", "ID-PASS", "RIOT#", "OPEN/ID", "CODE", "QRCODE"];
    const games = ["VALORANT", "LOL_WILDRIFT", "DUNK_CITY_DYNASTY", "RACING_MASTER", "GENSHIN_IMPACT", "MINECRAFT", "DELTA_FORCE", "ROV", "CRYSTAL_OF_ATLAN", "RIOTCODE"];
    
    const autoFillMap = {
        'คูปอง':      { type: 'OPEN/ID', game: 'ROV' },
        'WC':          { type: 'ID-PASS', game: 'LOL_WILDRIFT' },
        'STELLACORN':  { type: 'ID-PASS', game: 'LOL_WILDRIFT' },
        'CELESTIAL':   { type: 'ID-PASS', game: 'LOL_WILDRIFT' },
        'เหรียญ':      { type: 'ID-PASS', game: 'MINECRAFT' },
        'VP':          { type: 'RIOT#',   game: 'VALORANT' },
        'แพ็คโชคดี':    { type: 'QRCODE',  game: 'RACING_MASTER' },
        'RIOT':    { type: 'CODE',  game: 'RIOTCODE' },
        'โอปอล':       { type: 'UID',     game: 'CRYSTAL_OF_ATLAN' },
        'DELTA':       { type: 'UID',     game: 'DELTA_FORCE' },
        'GEMS':        { type: 'UID',     game: 'RACING_MASTER' },
        'รายสัปดาห์':  { type: 'UID',     game: 'RACING_MASTER' },
        'รายเดือน':    { type: 'UID',     game: 'RACING_MASTER' },
        'สัญญาขั้นสูง (DELUXE)': { type: 'UID', game: 'RACING_MASTER' },
        'สัญญาพิเศษ (PREMIUM)': { type: 'UID', game: 'RACING_MASTER' },
        'อัพเกรดสัญญา': { type: 'UID',     game: 'RACING_MASTER' },
        'GROWTH FUND': { type: 'UID',     game: 'RACING_MASTER' },
        'แพ็คแฟชั่น (VALUE)': { type: 'UID', game: 'RACING_MASTER' },
        'TOKENS':      { type: 'UID',     game: 'DUNK_CITY_DYNASTY' },
        'พรแห่งดวงจันทร์':      { type: 'UID',     game: 'GENSHIN_IMPACT' }
    };
    let orderItems = [];

    // --- DOM ELEMENTS ---
    const addItemForm = document.getElementById('add-item-form');
    const itemQuantityInput = document.getElementById('item-quantity');
    const itemNameInput = document.getElementById('item-name');
    const itemTypeSelect = document.getElementById('item-type');
    const itemPriceInput = document.getElementById('item-price');
    const currentOrderListEl = document.getElementById('current-order-list');
    
    const customerInfoSection = document.getElementById('customer-info-section');
    const uidFields = document.getElementById('uid-fields');
    const idPassFields = document.getElementById('id-pass-fields');
    const riotFields = document.getElementById('riot-fields');
    const uidInput = document.getElementById('uid-input');
    const serverInput = document.getElementById('server-input');
    const idEmailInput = document.getElementById('id-email-input');
    const passwordInput = document.getElementById('password-input');
    const inGameNameInput = document.getElementById('in-game-name-input');
    const loginMethodInput = document.getElementById('login-method-input');
    const riotInput = document.getElementById('riot-input');
    
    const gameSelect = document.getElementById('game-select');
    const initialSummaryEl = document.getElementById('initial-summary');
    const finalSummaryEl = document.getElementById('final-summary');
    const copyInitialBtn = document.getElementById('copy-initial-btn');
    const copyFinalBtn = document.getElementById('copy-final-btn');

    // --- INITIALIZATION ---
    function init() {
        populateSelects();
        addEventListeners();
        setupDashboardPasswordToggles(); //  เพิ่มฟังก์ชันนี้
        updateCustomerInfoVisibility();
        updateSummaries();
    }

    function populateSelects() {
        itemTypeSelect.innerHTML = packageTypes.map(type => `<option value="${type}">${type}</option>`).join('');
        gameSelect.innerHTML = games.map(game => `<option value="${game}">${game}</option>`).join('');
    }
    
    function addEventListeners() {
        addItemForm.addEventListener('submit', handleAddItem);
        currentOrderListEl.addEventListener('click', handleRemoveItem);
        
        itemNameInput.addEventListener('input', handleItemNameInput);

        document.getElementById('customer-info-container').querySelectorAll('input').forEach(input => {
            input.addEventListener('input', updateSummaries);
        });
        gameSelect.addEventListener('change', updateSummaries);

        copyInitialBtn.addEventListener('click', () => copyToClipboard(initialSummaryEl, copyInitialBtn, 'คัดลอก (สำหรับแจ้งยอด)'));
        copyFinalBtn.addEventListener('click', () => copyToClipboard(finalSummaryEl, copyFinalBtn, 'คัดลอก (ส่งให้ทีมงาน)'));
    }

    //  ฟังก์ชันใหม่สำหรับเปิด-ปิดตาใน Dashboard
    function setupDashboardPasswordToggles() {
        const toggleIcon = document.querySelector('.toggle-password-icon');
        if (toggleIcon) {
            toggleIcon.addEventListener('click', function() {
                const type = passwordInput.getAttribute('type') === 'password' ? 'text' : 'password';
                passwordInput.setAttribute('type', type);
                this.classList.toggle('fa-eye-slash');
            });
        }
    }
    
    function handleItemNameInput() {
        const value = itemNameInput.value.trim().toUpperCase();
        let matchFound = false;
        itemTypeSelect.disabled = false;
        gameSelect.disabled = false;
        for (const prefix in autoFillMap) {
            if (value.includes(prefix.toUpperCase())) {
                const { type, game } = autoFillMap[prefix];
                itemTypeSelect.value = type;
                itemTypeSelect.disabled = true;
                gameSelect.value = game;
                gameSelect.disabled = true;
                matchFound = true;
                break;
            }
        }
    }
    
    function updateCustomerInfoVisibility() {
        if (orderItems.length > 0) {
            customerInfoSection.classList.remove('hidden');
        } else {
            customerInfoSection.classList.add('hidden');
        }
        const requiredTypes = new Set(orderItems.map(item => item.typeDetail.slice(1, -1)));
        uidFields.classList.toggle('hidden', !requiredTypes.has('UID') && !requiredTypes.has('OPEN/ID'));
        idPassFields.classList.toggle('hidden', !requiredTypes.has('ID-PASS'));
        riotFields.classList.toggle('hidden', !requiredTypes.has('RIOT#'));
    }

    function handleAddItem(event) {
        event.preventDefault();
        const newItem = {
            id: Date.now(),
            quantity: parseInt(itemQuantityInput.value),
            name: itemNameInput.value.trim(),
            typeDetail: `(${itemTypeSelect.value})`,
            price: parseFloat(itemPriceInput.value)
        };
        if (!newItem.name || isNaN(newItem.price) || newItem.price < 0 || newItem.quantity < 1) {
            alert("กรุณากรอกข้อมูลรายการให้ถูกต้อง (ราคาต้องไม่ติดลบ)");
            return;
        }
        orderItems.push(newItem);
        renderOrderList();
        updateCustomerInfoVisibility();
        updateSummaries();
        itemNameInput.value = '';
        itemPriceInput.value = '';
        itemQuantityInput.value = '1';
        itemNameInput.focus();
    }

    function handleRemoveItem(event) {
        const button = event.target.closest('.remove-item-btn');
        if (button) {
            const itemId = parseInt(button.dataset.id);
            orderItems = orderItems.filter(item => item.id !== itemId);
            renderOrderList();
            updateCustomerInfoVisibility();
            updateSummaries();
            if (orderItems.length === 0) {
                itemTypeSelect.disabled = false;
                gameSelect.disabled = false;
                handleItemNameInput(); 
            }
        }
    }

    function renderOrderList() {
        if (orderItems.length === 0) {
            currentOrderListEl.innerHTML = '<p class="placeholder">ยังไม่มีรายการในออเดอร์</p>';
            return;
        }
        const trashIcon = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" viewBox="0 0 16 16"><path d="M5.5 5.5A.5.5 0 0 1 6 6v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5zm2.5 0a.5.5 0 0 1 .5.5v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5zm3 .5a.5.5 0 0 0-1 0v6a.5.5 0 0 0 1 0V6z"/><path fill-rule="evenodd" d="M14.5 3a1 1 0 0 1-1 1H13v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V4h-.5a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1H6a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1h3.5a1 1 0 0 1 1 1v1zM4.118 4 4 4.059V13a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1V4.059L11.882 4H4.118zM2.5 3V2h11v1h-11z"/></svg>`;
        currentOrderListEl.innerHTML = orderItems.map(item => `
            <div class="order-item">
                <span class="order-item-details">
                    ${item.quantity}x <strong>${item.name}</strong> ${item.typeDetail} - ${item.price.toFixed(2)} บาท/หน่วย
                </span>
                <button class="remove-item-btn" data-id="${item.id}" title="ลบรายการนี้">${trashIcon}</button>
            </div>
        `).join('');
    }

    function updateSummaries() {
        let total = 0;
        let summaryText = '';
        let hasCustomerInfo = false;
        const isQrcodeOrder = orderItems.some(item => item.typeDetail === '(QRCODE)');

        const placeholderText = '@';

        if (orderItems.length > 0) {
            orderItems.forEach(item => {
                const lineTotal = item.quantity * item.price;
                summaryText += `${item.quantity}x ${item.name} ${item.typeDetail}: ${lineTotal.toFixed(2)} บาท\n`;
                total += lineTotal;
            });
            const footer = `\n-----------------------------\n💰ราคาสินค้า ${total.toFixed(2)} บาท\n-----------------------------`;
            const callToActionText = `\n\nหากต้องการสั่งซื้อ พิมพ์ "ยืนยันออเดอร์" \nเพื่อรับช่องทางการชำระเงินทันที`;
            
            initialSummaryEl.value = `=== สรุปการสั่งซื้อ ===\n\n${summaryText}${footer}${callToActionText}`;
            copyInitialBtn.disabled = false;

            let teamSummaryParts = [];
            
            if ((!uidFields.classList.contains('hidden') && uidInput.value) ||
                (!idPassFields.classList.contains('hidden') && idEmailInput.value) ||
                (!riotFields.classList.contains('hidden') && riotInput.value)) {
                hasCustomerInfo = true;
            }

            if (hasCustomerInfo || isQrcodeOrder) {
                teamSummaryParts.push(gameSelect.value);
                if (hasCustomerInfo) {
                    let customerInfoBlock = [];
                    if (!uidFields.classList.contains('hidden') && uidInput.value) {
                        const idLabel = gameSelect.value === 'ROV' ? 'Open ID' : 'UID';
                        customerInfoBlock.push(`${idLabel}: ${uidInput.value}`);
                        if (serverInput.value) customerInfoBlock.push(`Server: ${serverInput.value}`);
                    }
                    if (!idPassFields.classList.contains('hidden') && idEmailInput.value) {
                        customerInfoBlock.push(`ID/Email: ${idEmailInput.value}`);
                        if (passwordInput.value) customerInfoBlock.push(`Password: ${passwordInput.value}`);
                        if (inGameNameInput.value) customerInfoBlock.push(`In-game Name: ${inGameNameInput.value}`);
                        if (loginMethodInput.value) customerInfoBlock.push(`ช่องทางการล็อกอิน: ${loginMethodInput.value}`);
                    }
                    if (!riotFields.classList.contains('hidden') && riotInput.value) {
                        customerInfoBlock.push(`RIOT#: ${riotInput.value}`);
                    }
                    if (customerInfoBlock.length > 0) { teamSummaryParts.push(customerInfoBlock.join('\n')); }
                }
                let teamOrderList = orderItems.map(item => `${item.quantity}x ${item.name} ${item.typeDetail}`);
                if (teamOrderList.length > 0) { teamSummaryParts.push(teamOrderList.join('\n')); }
                finalSummaryEl.value = teamSummaryParts.join('\n\n');
                copyFinalBtn.disabled = false;

            } else {
                finalSummaryEl.value = placeholderText;
                copyFinalBtn.disabled = true;
            }
        } else {
            initialSummaryEl.value = placeholderText;
            finalSummaryEl.value = placeholderText;
            copyInitialBtn.disabled = true;
            copyFinalBtn.disabled = true;
        }
    }
    
    function copyToClipboard(textarea, button, originalText) {
        navigator.clipboard.writeText(textarea.value).then(() => {
            button.textContent = 'คัดลอกแล้ว!';
            setTimeout(() => { button.textContent = originalText; }, 2000);
        });
    }
    
    init();
});
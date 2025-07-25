document.addEventListener('DOMContentLoaded', () => {
    // --- GLOBAL DATA STORE ---
    let allPackages = [];
    let orderItems = [];

    // --- DOM ELEMENTS ---
    const addItemForm = document.getElementById('add-item-form');
    const gameSelector = document.getElementById('game-selector');
    const packageSelector = document.getElementById('package-selector');
    const itemQuantityInput = document.getElementById('item-quantity');
    
    const currentOrderListEl = document.getElementById('current-order-list');
    
    const customerInfoSection = document.getElementById('customer-info-section');
    const gameDisplayInput = document.getElementById('game-display');
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
    
    const initialSummaryEl = document.getElementById('initial-summary');
    const finalSummaryEl = document.getElementById('final-summary');
    const copyInitialBtn = document.getElementById('copy-initial-btn');
    const copyFinalBtn = document.getElementById('copy-final-btn');

    // --- INITIALIZATION ---
    async function init() {
        await fetchDashboardData();
        addEventListeners();
        renderOrderList(); 
        updateCustomerInfoVisibility();
        updateSummaries();
    }

    async function fetchDashboardData() {
        try {
            const response = await fetch('/api/dashboard-data');
            const data = await response.json();
            allPackages = data.packages || [];
            const games = data.games || [];
            populateGameSelector(games);
        } catch (error) {
            console.error('Failed to load dashboard data:', error);
            alert('ไม่สามารถโหลดข้อมูลเริ่มต้นของ Dashboard ได้');
        }
    }

    // --- DYNAMIC POPULATION ---
    function populateGameSelector(games) {
        games.forEach(game => {
            const option = document.createElement('option');
            option.value = game;
            option.textContent = game;
            gameSelector.appendChild(option);
        });
    }

    function populatePackageSelector(selectedGame) {
        const filteredPackages = allPackages.filter(p => p.game_association === selectedGame);
        packageSelector.innerHTML = '<option value="">-- กรุณาเลือกแพ็กเกจ --</option>';
        if (filteredPackages.length > 0) {
            filteredPackages.forEach(pkg => {
                const option = document.createElement('option');
                option.value = pkg.id;
                option.textContent = pkg.name;
                packageSelector.appendChild(option);
            });
            packageSelector.disabled = false;
        } else {
            packageSelector.innerHTML = '<option value="">-- ไม่มีแพ็กเกจ --</option>';
            packageSelector.disabled = true;
        }
    }
    
    function resetCustomerInfoFields() {
        uidInput.value = '';
        serverInput.value = '';
        idEmailInput.value = '';
        passwordInput.value = '';
        inGameNameInput.value = '';
        loginMethodInput.value = '';
        riotInput.value = '';
    }

    // --- EVENT LISTENERS & HANDLERS ---
    
    function addEventListeners() {
        gameSelector.addEventListener('change', handleGameSelection);
        addItemForm.addEventListener('submit', handleAddItem);
        currentOrderListEl.addEventListener('click', handleRemoveItem);

        document.getElementById('customer-info-container').querySelectorAll('input').forEach(input => {
            input.addEventListener('input', updateSummaries);
        });

        copyInitialBtn.addEventListener('click', () => copyToClipboard(initialSummaryEl, copyInitialBtn, 'คัดลอกแจ้งยอด'));
        copyFinalBtn.addEventListener('click', () => copyToClipboard(finalSummaryEl, copyFinalBtn, 'คัดลอกส่งทีมงาน'));
    }

    function handleGameSelection() {
        const selectedGame = gameSelector.value;
        gameDisplayInput.value = selectedGame;
        populatePackageSelector(selectedGame);
    }
    
    function handleAddItem(event) {
        event.preventDefault();
        const selectedPackageId = packageSelector.value;
        if (!selectedPackageId) {
            alert("กรุณาเลือกแพ็กเกจ");
            return;
        }
        
        const selectedPackage = allPackages.find(p => p.id == selectedPackageId);
        const quantity = parseInt(itemQuantityInput.value);

        if (!selectedPackage || quantity < 1) {
            alert("ข้อมูลรายการไม่ถูกต้อง");
            return;
        }

        const newItem = {
            id: Date.now(),
            quantity: quantity,
            name: selectedPackage.name,
            typeDetail: `(${selectedPackage.type})`,
            price: selectedPackage.price,
            game: selectedPackage.game_association
        };
        orderItems.push(newItem);
        renderOrderList();
        updateCustomerInfoVisibility();
        updateSummaries();
        
        packageSelector.value = '';
        itemQuantityInput.value = '1';
        packageSelector.focus();
    }
    
    function handleRemoveItem(event) {
        const button = event.target.closest('.remove-item-btn');
        if (button) {
            const itemId = parseInt(button.dataset.id);
            orderItems = orderItems.filter(item => item.id !== itemId);
            renderOrderList();
            
            if (orderItems.length === 0) {
                resetCustomerInfoFields();
                gameSelector.disabled = false;
                gameDisplayInput.value = '';
            }

            updateCustomerInfoVisibility();
            updateSummaries();
        }
    }

    function renderOrderList() {
        if (orderItems.length === 0) {
            currentOrderListEl.innerHTML = '<p class="placeholder">ยังไม่มีรายการในออเดอร์</p>';
            return;
        }
        const trashIcon = `<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" width="20" height="20"><path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" /></svg>`;
        
        currentOrderListEl.innerHTML = orderItems.map(item => `
            <div class="order-item">
                <span class="order-item-details">
                    ${item.quantity}x <strong>${item.name}</strong> ${item.typeDetail} - ${item.price.toFixed(2)} บาท/หน่วย
                </span>
                <button class="remove-item-btn" data-id="${item.id}" title="ลบรายการนี้">${trashIcon}</button>
            </div>
        `).join('');
    }

    function updateCustomerInfoVisibility() {
        const hasItems = orderItems.length > 0;
        customerInfoSection.classList.toggle('hidden', !hasItems);
        gameSelector.disabled = hasItems;

        if (hasItems) {
            const requiredTypes = new Set(orderItems.map(item => item.typeDetail.slice(1, -1)));
            document.getElementById('uid-fields').classList.toggle('hidden', !requiredTypes.has('UID') && !requiredTypes.has('OPEN/ID'));
            document.getElementById('id-pass-fields').classList.toggle('hidden', !requiredTypes.has('ID-PASS'));
            document.getElementById('riot-fields').classList.toggle('hidden', !requiredTypes.has('RIOT#'));
        }
    }

    function updateSummaries() {
        if (orderItems.length === 0) {
            initialSummaryEl.value = '@';
            finalSummaryEl.value = '@';
            copyInitialBtn.disabled = true;
            copyFinalBtn.disabled = true;
            return;
        }

        let total = 0;
        let summaryText = orderItems.map(item => {
            const lineTotal = item.quantity * item.price;
            total += lineTotal;
            return `${item.quantity}x ${item.name} ${item.typeDetail}: ${lineTotal.toFixed(2)} บาท`;
        }).join('\n');
        
        const footer = `\n-----------------------------\n💰ราคาสินค้า ${total.toFixed(2)} บาท\n-----------------------------`;
        initialSummaryEl.value = `=== สรุปการสั่งซื้อ ===\n\n${summaryText}${footer}\n\nหากต้องการสั่งซื้อ พิมพ์ "ยืนยันออเดอร์" \nเพื่อรับช่องทางการชำระเงินทันที`;
        copyInitialBtn.disabled = false;

        let teamSummaryParts = [];
        const gameForOrder = orderItems[0].game;
        let customerInfoBlock = [];
        if (uidInput.value) customerInfoBlock.push(`${gameForOrder === 'ROV' ? 'Open ID' : 'UID'}: ${uidInput.value}`);
        if (serverInput.value) customerInfoBlock.push(`Server: ${serverInput.value}`);
        if (idEmailInput.value) customerInfoBlock.push(`ID/Email: ${idEmailInput.value}`);
        if (passwordInput.value) customerInfoBlock.push(`Password: ${passwordInput.value}`);
        if (inGameNameInput.value) customerInfoBlock.push(`ชื่อในเกม: ${inGameNameInput.value}`);
        if (loginMethodInput.value) customerInfoBlock.push(`ช่องทางล็อกอิน: ${loginMethodInput.value}`);
        if (riotInput.value) customerInfoBlock.push(`RIOT ID: ${riotInput.value}`);
        
        if (customerInfoBlock.length > 0) {
            teamSummaryParts.push(gameForOrder);
            teamSummaryParts.push(customerInfoBlock.join('\n'));
            let teamOrderList = orderItems.map(item => `${item.quantity}x ${item.name} ${item.typeDetail}`);
            teamSummaryParts.push(teamOrderList.join('\n'));
            
            finalSummaryEl.value = teamSummaryParts.join('\n\n');
            copyFinalBtn.disabled = false;
        } else {
            finalSummaryEl.value = '@';
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
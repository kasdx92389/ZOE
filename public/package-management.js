document.addEventListener('DOMContentLoaded', () => {
    // --- GLOBAL STATE ---
    let allPackages = [];
    let filteredPackages = [];
    let selectedPackageIds = new Set();
    let currentPage = 1;
    const itemsPerPage = 10;

    // --- DOM ELEMENTS CACHE ---
    const tableBody = document.getElementById('package-table-body');
    const filterInput = document.getElementById('filter-input');
    const gameFilter = document.getElementById('game-filter');
    const paginationControls = document.getElementById('pagination-controls');
    const paginationSummary = document.getElementById('pagination-summary');
    const toast = document.getElementById('toast-notification');
    const packageModal = document.getElementById('package-modal');
    const bulkPriceModal = document.getElementById('bulk-price-modal');
    const bulkPriceList = document.getElementById('bulk-price-list');
    const packageForm = document.getElementById('package-form');
    const addNewBtn = document.getElementById('add-new-btn');
    const bulkPriceBtn = document.getElementById('bulk-price-btn');
    const bulkStatusBtn = document.getElementById('bulk-status-btn');
    const bulkDeleteBtn = document.getElementById('bulk-delete-btn');
    const saveBulkPriceChangesBtn = document.getElementById('save-bulk-price-changes-btn');
    const bulkActionsBar = document.getElementById('bulk-actions-bar');
    const selectionCount = document.getElementById('selection-count');
    const deselectBtn = document.getElementById('deselect-all-btn');
    const selectAllCheckbox = document.getElementById('select-all-checkbox');
    const packageIdInput = document.getElementById('package-id');
    const originalPackageIdInput = document.getElementById('original-package-id');
    const nameInput = document.getElementById('name');
    const priceInput = document.getElementById('price');
    const productCodeInput = document.getElementById('product_code');
    const typeInput = document.getElementById('type');
    const channelInput = document.getElementById('channel');
    const gameAssociationInput = document.getElementById('game_association');
    const bulkStatusModal = document.getElementById('bulk-status-modal');
    const setActiveBtn = document.getElementById('set-active-btn');
    const setInactiveBtn = document.getElementById('set-inactive-btn');
    const confirmModal = document.getElementById('confirmation-modal');

    // Order Modal
    const reorderAllBtn = document.getElementById('reorder-all-btn');
    const orderModal = document.getElementById('order-modal');
    const orderListContainer = document.getElementById('order-list-container');
    const saveOrderBtn = document.getElementById('save-order-btn');

    // --- API ENDPOINTS ---
    const DASHBOARD_DATA_API_URL = '/api/dashboard-data';
    const BULK_API_URL = '/api/packages/bulk-actions';
    const GAME_ORDER_API_URL = '/api/games/order';
    const PACKAGE_ORDER_API_URL = '/api/packages/order';
    const API_URL = '/api/packages';

    // --- UTILITY & RENDER FUNCTIONS ---
    const showToast = (message, type = 'success') => {
        toast.textContent = message;
        toast.className = `toast ${type} show`;
        setTimeout(() => toast.classList.remove('show'), 3000);
    };

    const showModal = (modalEl) => modalEl.classList.remove('hidden');
    const hideModal = (modalEl) => modalEl.classList.add('hidden');

    const showConfirmModal = (title, message, onConfirm) => {
        const confirmTitle = confirmModal.querySelector('#confirm-title');
        const confirmMessage = confirmModal.querySelector('#confirm-message');
        const confirmBtn = confirmModal.querySelector('#confirm-action-btn');
        const cancelBtn = confirmModal.querySelector('#cancel-action-btn');

        confirmTitle.textContent = title;
        confirmMessage.textContent = message;

        const newConfirmBtn = confirmBtn.cloneNode(true);
        confirmBtn.parentNode.replaceChild(newConfirmBtn, confirmBtn);

        const confirmHandler = () => {
            hideModal(confirmModal);
            onConfirm();
        };

        const cancelHandler = () => hideModal(confirmModal);

        newConfirmBtn.addEventListener('click', confirmHandler, { once: true });
        cancelBtn.addEventListener('click', cancelHandler, { once: true });

        const closeBtn = confirmModal.querySelector('.close-btn');
        if (closeBtn) {
           const newCloseBtn = closeBtn.cloneNode(true);
           closeBtn.parentNode.replaceChild(newCloseBtn, closeBtn);
           newCloseBtn.addEventListener('click', cancelHandler, { once: true });
        }
        showModal(confirmModal);
    };

    const renderPagination = (totalItems) => {
        paginationControls.innerHTML = '';
        const totalPages = Math.ceil(totalItems / itemsPerPage);

        if (totalItems === 0) {
            paginationSummary.textContent = 'No items found';
            return;
        }

        const startItem = (currentPage - 1) * itemsPerPage + 1;
        const endItem = Math.min(startItem + itemsPerPage - 1, totalItems);
        paginationSummary.textContent = `Showing ${startItem}-${endItem} of ${totalItems} items`;

        if (totalPages <= 1) return;

        const prevButton = document.createElement('button');
        prevButton.innerHTML = '&lsaquo;';
        prevButton.classList.add('pagination-btn');
        prevButton.disabled = currentPage === 1;
        prevButton.addEventListener('click', () => { if (currentPage > 1) { currentPage--; renderTable(filteredPackages); } });
        paginationControls.appendChild(prevButton);

        for (let i = 1; i <= totalPages; i++) {
            const pageButton = document.createElement('button');
            pageButton.textContent = i;
            pageButton.classList.add('pagination-btn');
            if (i === currentPage) pageButton.classList.add('active');
            pageButton.addEventListener('click', () => { currentPage = i; renderTable(filteredPackages); });
            paginationControls.appendChild(pageButton);
        }

        const nextButton = document.createElement('button');
        nextButton.innerHTML = '&rsaquo;';
        nextButton.classList.add('pagination-btn');
        nextButton.disabled = currentPage === totalPages;
        nextButton.addEventListener('click', () => { if (currentPage < totalPages) { currentPage++; renderTable(filteredPackages); } });
        paginationControls.appendChild(nextButton);
    };

    const renderTable = (packages) => {
        tableBody.innerHTML = '';
        const paginatedPackages = packages.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage);

        if (paginatedPackages.length === 0 && currentPage > 1) {
             currentPage--;
             renderTable(packages);
             return;
        }

        if (paginatedPackages.length === 0 && currentPage === 1) {
            tableBody.innerHTML = `<tr><td colspan="7" style="text-align: center; padding: 60px; color: var(--text-light);">No packages found.</td></tr>`;
            renderPagination(0);
            return;
        }

        const typeColorMap = {
            'UID': 'tag-blue', 'ID-PASS': 'tag-purple', 'RIOT#': 'tag-red',
            'OPEN/ID': 'tag-yellow', 'CODE': 'tag-gray', 'QRCODE': 'tag-green'
        };

        paginatedPackages.forEach(pkg => {
            const row = document.createElement('tr');
            row.dataset.id = pkg.id;
            const isSelected = selectedPackageIds.has(pkg.id);
            row.classList.toggle('selected-row', isSelected);

            const statusClass = pkg.is_active ? 'active' : 'inactive';
            const statusText = pkg.is_active ? 'Active' : 'Inactive';
            const typeTagClass = typeColorMap[pkg.type] || 'tag-gray';
            
            const hamburgerIcon = `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 16 16"><path fill-rule="evenodd" d="M2.5 12a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5m0-4a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5m0-4a.5.5 0 0 1 .5-.5h10a.5.5 0 0 1 0 1H3a.5.5 0 0 1-.5-.5"/></svg>`;

            row.innerHTML = `
                <td class="checkbox-cell">
                    <input type="checkbox" data-id="${pkg.id}" ${isSelected ? 'checked' : ''}>
                </td>
                <td>
                    <div class="package-details">
                        <span class="name">${pkg.name || ''}</span>
                        <span class="code">${pkg.product_code || 'No Code'}</span>
                    </div>
                </td>
                <td class="price-cell">${(pkg.price || 0).toFixed(2)}</td>
                <td><span class="tag ${typeTagClass}">${pkg.type || ''}</span></td>
                <td><span class="tag tag-gray">${pkg.game_association || ''}</span></td>
                <td>
                    <span class="status-toggle ${statusClass}" data-id="${pkg.id}" data-status="${pkg.is_active}">
                        <span class="dot"></span>
                        ${statusText}
                    </span>
                </td>
                <td class="actions-cell">
                    <div class="kebab-menu">
                        <button class="kebab-toggle" data-id="${pkg.id}">
                            ${hamburgerIcon}
                        </button>
                    </div>
                </td>
            `;
            tableBody.appendChild(row);
        });

        const onScreenIds = paginatedPackages.map(p => p.id);
        selectAllCheckbox.checked = onScreenIds.length > 0 && onScreenIds.every(id => selectedPackageIds.has(id));
        renderPagination(packages.length);
    };

    const getFilteredPackages = () => {
        const searchTerm = filterInput.value.toLowerCase();
        const selectedGame = gameFilter.value;

        let packagesToFilter = [...allPackages];

        return packagesToFilter.filter(pkg =>
            (selectedGame ? pkg.game_association === selectedGame : true) &&
            (searchTerm ? ((pkg.name || '').toLowerCase().includes(searchTerm) || (pkg.product_code || '').toLowerCase().includes(searchTerm)) : true)
        );
    };

    const applyFiltersAndRender = () => {
        filteredPackages = getFilteredPackages();
        currentPage = 1;
        renderTable(filteredPackages);
        updateBulkActionsBar();
    };

    const populateGameFilter = (games) => {
        const currentSelection = gameFilter.value;
        gameFilter.innerHTML = '<option value="">All Games</option>';
        games.forEach(game => {
            const option = document.createElement('option');
            option.value = game;
            option.textContent = game;
            gameFilter.appendChild(option);
        });
        if (games.includes(currentSelection)) {
            gameFilter.value = currentSelection;
        }
    };

    const fetchAndRenderPackages = async (resetSelection = true) => {
        try {
            const response = await fetch(DASHBOARD_DATA_API_URL);
            if (!response.ok) throw new Error('Failed to fetch data');
            const data = await response.json();
            allPackages = data.packages || [];
            const sortedGames = data.games || [];

            if(resetSelection) {
                selectedPackageIds.clear();
            }
            populateGameFilter(sortedGames);
            applyFiltersAndRender();
        } catch (error) {
            console.error(error);
            showToast('Could not load package data.', 'error');
        }
    };

    const updateBulkActionsBar = () => {
        const count = selectedPackageIds.size;
        if (count > 0) {
            selectionCount.textContent = `${count} item(s) selected`;
            bulkActionsBar.classList.remove('hidden');
        } else {
            bulkActionsBar.classList.add('hidden');
        }
    };

    const handleSelectionChange = (event) => {
        const checkbox = event.target;
        if (!checkbox) return;

        const packageId = parseInt(checkbox.dataset.id, 10);
        const row = checkbox.closest('tr');
        if (checkbox.checked) {
            selectedPackageIds.add(packageId);
            row.classList.add('selected-row');
        } else {
            selectedPackageIds.delete(packageId);
            row.classList.remove('selected-row');
        }

        const onScreenIds = filteredPackages.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage).map(p => p.id);
        selectAllCheckbox.checked = onScreenIds.length > 0 && onScreenIds.every(id => selectedPackageIds.has(id));
        updateBulkActionsBar();
    };

    const handleSelectAll = () => {
        const onScreenIds = filteredPackages.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage).map(p => p.id);
        const isChecked = selectAllCheckbox.checked;

        onScreenIds.forEach(id => {
            if (isChecked) {
                selectedPackageIds.add(id);
            } else {
                selectedPackageIds.delete(id);
            }
        });
        renderTable(filteredPackages);
        updateBulkActionsBar();
    };

    async function handleBulkAction(action, payload = {}) {
        const ids = Array.from(selectedPackageIds);
        if (ids.length === 0) return;
        try {
            const response = await fetch(BULK_API_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ action, ...payload, ids })
            });
            if (!response.ok) throw new Error(`Bulk action '${action}' failed`);

            const resetSelection = action === 'delete';
            if(resetSelection) selectedPackageIds.clear();

            await fetchAndRenderPackages(false);
            showToast('Bulk action completed!', 'success');
        } catch (error) {
            showToast(`Error performing bulk action: ${error.message}`, 'error');
        }
    }

    const openBulkPriceModal = () => {
        const selectedPackages = allPackages.filter(p => selectedPackageIds.has(p.id));
        bulkPriceList.innerHTML = selectedPackages.map(pkg => `
            <div class="bulk-price-item">
                <span>${pkg.name}</span>
                <span class="current-price">${(pkg.price || 0).toFixed(2)}</span>
                <input type="number" step="0.01" data-id="${pkg.id}" value="${(pkg.price || 0).toFixed(2)}">
            </div>
        `).join('');
        showModal(bulkPriceModal);
    };

    const handleSaveBulkPriceChanges = () => {
        const priceUpdates = [];
        const inputs = bulkPriceList.querySelectorAll('input[type="number"]');
        inputs.forEach(input => {
            priceUpdates.push({
                id: parseInt(input.dataset.id, 10),
                newPrice: parseFloat(input.value)
            });
        });
        handleBulkAction('setIndividualPrices', { priceUpdates });
        hideModal(bulkPriceModal);
    };

    const openNewPackageModal = () => {
        packageForm.reset();
        packageIdInput.value = '';
        originalPackageIdInput.value = '';
        document.getElementById('modal-title').textContent = 'Add New Package';
        showModal(packageModal);
    };

    const openEditPackageModal = (id) => {
        const pkgToEdit = allPackages.find(p => p.id == id);
        if (pkgToEdit) {
            packageIdInput.value = pkgToEdit.id;
            originalPackageIdInput.value = '';
            nameInput.value = pkgToEdit.name;
            priceInput.value = pkgToEdit.price;
            productCodeInput.value = pkgToEdit.product_code || '';
            typeInput.value = pkgToEdit.type;
            channelInput.value = pkgToEdit.channel;
            gameAssociationInput.value = pkgToEdit.game_association;
            document.getElementById('modal-title').textContent = 'Edit Package';
            showModal(packageModal);
        }
    };

    const openClonePackageModal = (id) => {
        const pkgToClone = allPackages.find(p => p.id == id);
        if (pkgToClone) {
            packageIdInput.value = '';
            originalPackageIdInput.value = pkgToClone.id;
            nameInput.value = `${pkgToClone.name} - Clone`;
            priceInput.value = pkgToClone.price;
            productCodeInput.value = pkgToClone.product_code || '';
            typeInput.value = pkgToClone.type;
            channelInput.value = pkgToClone.channel;
            gameAssociationInput.value = pkgToClone.game_association;
            document.getElementById('modal-title').textContent = 'Clone Package';
            showModal(packageModal);
        }
    };

    const handleFormSubmit = async (event) => {
        event.preventDefault();
        const packageData = {
            name: nameInput.value,
            price: parseFloat(priceInput.value),
            product_code: productCodeInput.value,
            type: typeInput.value,
            channel: channelInput.value,
            game_association: gameAssociationInput.value
        };
        const id = packageIdInput.value;
        const originalId = originalPackageIdInput.value;
        const method = id ? 'PUT' : 'POST';
        const url = id ? `${API_URL}/${id}` : API_URL;
        if (method === 'POST' && originalId) packageData.originalId = originalId;

        let bodyPayload = packageData;
        if (method === 'PUT') {
            const existingPackage = allPackages.find(p => p.id == id);
            bodyPayload = { ...existingPackage, ...packageData };
        }

        try {
            const response = await fetch(url, { method: method, headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(bodyPayload) });
            if (!response.ok) throw new Error(`Failed to ${id ? 'update' : 'create'} package`);
            hideModal(packageModal);
            await fetchAndRenderPackages(false);
            showToast(`Package ${id ? 'updated' : 'created'} successfully!`, 'success');
        } catch (error) { showToast('Error saving data.', 'error'); }
    };

    const handleStatusToggle = async (target) => {
        const id = target.dataset.id;
        const newStatus = parseInt(target.dataset.status, 10) === 1 ? 0 : 1;
        try {
            const pkgToUpdate = allPackages.find(p => p.id == id);
            const response = await fetch(`${API_URL}/${id}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ ...pkgToUpdate, is_active: newStatus })
            });
            if (!response.ok) throw new Error('Failed to update status');
            await fetchAndRenderPackages(false);
            showToast('Status updated!');
        } catch (error) {
            showToast('Error updating status.', 'error');
        }
    };

    const handleDelete = async (id) => {
        showConfirmModal(
            'Confirm Deletion',
            'Are you sure you want to permanently delete this package? This action cannot be undone.',
            async () => {
                try {
                    const response = await fetch(`${API_URL}/${id}`, { method: 'DELETE' });
                    if (!response.ok) throw new Error('Failed to delete package');
                    selectedPackageIds.delete(parseInt(id, 10));
                    await fetchAndRenderPackages(false);
                    showToast('Package deleted!', 'success');
                } catch (error) {
                    showToast(`Error deleting data: ${error.message}`, 'error');
                }
            }
        );
    };

    const removeExistingDropdown = () => {
        const existingDropdown = document.querySelector('.kebab-dropdown-portal');
        if (existingDropdown) existingDropdown.remove();
    };

    const showDropdown = (targetButton) => {
        removeExistingDropdown();
        const packageId = targetButton.dataset.id;
        const rect = targetButton.getBoundingClientRect();
        const dropdown = document.createElement('div');
        dropdown.className = 'kebab-dropdown-portal';

        const editIcon = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M16.862 4.487l1.687-1.688a1.875 1.875 0 112.652 2.652L6.832 19.82a4.5 4.5 0 01-1.897 1.13l-2.685.8.8-2.685a4.5 4.5 0 011.13-1.897L16.863 4.487z" /></svg>`;
        const cloneIcon = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M15.666 3.888A2.25 2.25 0 0013.5 2.25h-3c-1.03 0-1.9.693-2.166 1.638m7.332 0c.055.194.084.4.084.612v0a2.25 2.25 0 01-2.25 2.25h-1.5a2.25 2.25 0 01-2.25-2.25v0c0-.212.03-.418.084-.612m7.332 0c.646.049 1.288.11 1.927.184 1.1.128 1.907 1.077 1.907 2.185V19.5a2.25 2.25 0 01-2.25 2.25H6.75A2.25 2.25 0 014.5 19.5V6.257c0-1.108.806-2.057 1.907-2.185a48.208 48.208 0 011.927-.184" /></svg>`;
        const deleteIcon = `<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" /></svg>`;

        dropdown.innerHTML = `
            <div class="kebab-dropdown-item edit-btn" data-id="${packageId}">${editIcon} <span>Edit</span></div>
            <div class="kebab-dropdown-item clone-btn" data-id="${packageId}">${cloneIcon} <span>Clone</span></div>
            <div class="kebab-dropdown-item delete delete-btn" data-id="${packageId}">${deleteIcon} <span>Delete</span></div>`;
        document.body.appendChild(dropdown);
        const top = rect.bottom + 6;
        const right = window.innerWidth - rect.right;
        dropdown.style.top = `${top}px`;
        dropdown.style.right = `${right}px`;
        setTimeout(() => dropdown.classList.add('show'), 10);
    };

    const handleOpenOrderModal = async () => {
        orderListContainer.innerHTML = '<h3>Loading...</h3>';
        showModal(orderModal);

        try {
            const response = await fetch(DASHBOARD_DATA_API_URL);
            if (!response.ok) throw new Error('Could not fetch latest data');
            const data = await response.json();
            const sortedGames = data.games;
            const sortedPackages = data.packages;

            orderListContainer.innerHTML = '';

            sortedGames.forEach(game => {
                const gamePackages = sortedPackages.filter(p => p.game_association === game);

                if (gamePackages.length > 0) {
                    const groupEl = document.createElement('div');
                    groupEl.className = 'package-group';
                    groupEl.dataset.gameName = game;

                    const headerEl = document.createElement('div');
                    headerEl.className = 'package-group-header collapsed';
                    headerEl.innerHTML = `
                        <span class="group-drag-handle">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 16 16"><path d="M7 4.5a.5.5 0 0 0-1 0v7a.5.5 0 0 0 1 0v-7zm4 0a.5.5 0 0 0-1 0v7a.5.5 0 0 0 1 0v-7z"/></svg>
                        </span>
                        <span>${game}</span>
                        <span class="group-toggle-icon">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 16 16"><path fill-rule="evenodd" d="M4.646 1.646a.5.5 0 0 1 .708 0l6 6a.5.5 0 0 1 0 .708l-6 6a.5.5 0 0 1-.708-.708L10.293 8 4.646 2.354a.5.5 0 0 1 0-.708z"/></svg>
                        </span>
                    `;

                    const itemsContainer = document.createElement('div');
                    itemsContainer.className = 'package-group-items collapsed';

                    gamePackages.forEach(pkg => {
                        const itemEl = document.createElement('div');
                        itemEl.className = 'package-order-item';
                        itemEl.dataset.id = pkg.id;
                        itemEl.textContent = pkg.name;
                        itemsContainer.appendChild(itemEl);
                    });

                    groupEl.appendChild(headerEl);
                    groupEl.appendChild(itemsContainer);
                    orderListContainer.appendChild(groupEl);

                    new Sortable(itemsContainer, {
                        group: 'packages',
                        animation: 150,
                        ghostClass: 'sortable-ghost',
                    });
                }
            });

            new Sortable(orderListContainer, {
                handle: '.group-drag-handle',
                animation: 150,
                ghostClass: 'sortable-ghost',
            });

        } catch (error) {
            orderListContainer.innerHTML = '<h3>Error loading order data.</h3>';
            showToast('Error loading data.', 'error');
            console.error(error);
        }
    };

    const handleSaveOrder = async () => {
        const gameGroupElements = orderListContainer.querySelectorAll('.package-group');
        const newGameOrder = Array.from(gameGroupElements).map(g => g.dataset.gameName);

        const packageElements = orderListContainer.querySelectorAll('.package-order-item');
        const newPackageOrder = Array.from(packageElements).map(p => parseInt(p.dataset.id, 10));

        try {
            const [gameResponse, packageResponse] = await Promise.all([
                fetch(GAME_ORDER_API_URL, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ gameOrder: newGameOrder })
                }),
                fetch(PACKAGE_ORDER_API_URL, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ order: newPackageOrder })
                })
            ]);

            if (!gameResponse.ok || !packageResponse.ok) {
                throw new Error('Failed to save one or more order lists.');
            }

            hideModal(orderModal);
            showToast('Order saved successfully!', 'success');
            await fetchAndRenderPackages(false);

        } catch (error) {
            showToast('Error saving order.', 'error');
            console.error(error);
        }
    };

    function init() {
        [packageModal, bulkPriceModal, bulkStatusModal, orderModal, confirmModal].forEach(modal => {
            if (!modal) return;
            modal.querySelectorAll('.close-btn, .btn-subtle.close-btn').forEach(btn => {
                 if(btn.id !== 'cancel-action-btn') {
                    btn.addEventListener('click', () => hideModal(modal));
                 }
            });
        });

        addNewBtn.addEventListener('click', openNewPackageModal);
        packageForm.addEventListener('submit', handleFormSubmit);
        selectAllCheckbox.addEventListener('change', handleSelectAll);

        deselectBtn.addEventListener('click', () => {
            selectedPackageIds.clear();
            applyFiltersAndRender();
        });

        filterInput.addEventListener('input', applyFiltersAndRender);
        gameFilter.addEventListener('change', applyFiltersAndRender);

        bulkDeleteBtn.addEventListener('click', () => {
            const count = selectedPackageIds.size;
            if (count > 0) {
                showConfirmModal(
                    `Delete ${count} items?`,
                    `Are you sure you want to permanently delete these ${count} selected packages?`,
                    () => handleBulkAction('delete')
                );
            }
        });
        bulkStatusBtn.addEventListener('click', () => showModal(bulkStatusModal));
        setActiveBtn.addEventListener('click', () => {
            handleBulkAction('updateStatus', { status: 1 });
            hideModal(bulkStatusModal);
        });
        setInactiveBtn.addEventListener('click', () => {
            handleBulkAction('updateStatus', { status: 0 });
            hideModal(bulkStatusModal);
        });
        bulkPriceBtn.addEventListener('click', openBulkPriceModal);
        saveBulkPriceChangesBtn.addEventListener('click', handleSaveBulkPriceChanges);

        reorderAllBtn.addEventListener('click', handleOpenOrderModal);
        saveOrderBtn.addEventListener('click', handleSaveOrder);

        document.body.addEventListener('click', (e) => {
            const target = e.target;
            if (target.matches('#package-table-body input[type="checkbox"]')) {
                handleSelectionChange(e);
            } else if (target.closest('.status-toggle')) {
                handleStatusToggle(target.closest('.status-toggle'));
            } else if (target.closest('.kebab-toggle')) {
                showDropdown(target.closest('.kebab-toggle'));
            } else if (target.closest('.kebab-dropdown-portal')) {
                const id = target.closest('[data-id]').dataset.id;
                if (target.closest('.edit-btn')) openEditPackageModal(id);
                if (target.closest('.clone-btn')) openClonePackageModal(id);
                if (target.closest('.delete-btn')) handleDelete(id);
                removeExistingDropdown();
            } else if (!target.closest('.kebab-menu')) {
                removeExistingDropdown();
            }
        });

        orderListContainer.addEventListener('click', (e) => {
            const header = e.target.closest('.package-group-header');
            if (header) {
                const items = header.nextElementSibling;
                if (items && items.classList.contains('package-group-items')) {
                    header.classList.toggle('collapsed');
                    items.classList.toggle('collapsed');
                    const icon = header.querySelector('.group-toggle-icon');
                    icon.style.transform = header.classList.contains('collapsed') ? 'rotate(-90deg)' : 'rotate(0deg)';
                }
            }
        });

        fetchAndRenderPackages();
    }

    init();
});
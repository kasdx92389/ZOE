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
    const reorderGamesBtn = document.getElementById('reorder-games-btn');
    const gameOrderModal = document.getElementById('game-order-modal');
    const gameOrderList = document.getElementById('game-order-list');
    const saveGameOrderBtn = document.getElementById('save-game-order-btn');

    // --- API ENDPOINTS ---
    const API_URL = '/api/packages';
    const BULK_API_URL = '/api/packages/bulk-actions';
    const GAME_ORDER_API_URL = '/api/games/order';

    // --- UTILITY & RENDER FUNCTIONS ---
    const showToast = (message, type = 'success') => {
        toast.textContent = message;
        toast.className = `toast ${type} show`;
        setTimeout(() => toast.classList.remove('show'), 3000);
    };

    const showModal = (modalEl) => modalEl.classList.remove('hidden');
    const hideModal = (modalEl) => modalEl.classList.add('hidden');

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
        prevButton.textContent = '‹ Prev';
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
        nextButton.textContent = 'Next ›';
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
            tableBody.innerHTML = `<tr><td colspan="8" style="text-align: center; padding: 40px;">No packages found.</td></tr>`;
            renderPagination(0);
            return;
        }
        
        paginatedPackages.forEach(pkg => {
            const row = document.createElement('tr');
            row.dataset.id = pkg.id;
            const isSelected = selectedPackageIds.has(pkg.id);
            row.classList.toggle('selected-row', isSelected);

            const statusClass = pkg.is_active ? 'active' : 'inactive';
            const statusText = pkg.is_active ? 'Active' : 'Inactive';
            
            row.innerHTML = `
                <td class="checkbox-cell"><input type="checkbox" data-id="${pkg.id}" ${isSelected ? 'checked' : ''}></td>
                <td class="drag-handle"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" width="20" height="20"><path d="M10 5.5a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0Zm5 0a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0Zm-5 6a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0Zm5 0a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0Zm-5 6a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0Zm5 0a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0Z"></path></svg></td>
                <td><div class="package-details"><div class="name">${pkg.name || ''}</div><div class="code">${pkg.product_code || ''}</div></div></td>
                <td>${(pkg.price || 0).toFixed(2)}</td>
                <td>${pkg.type || ''}</td>
                <td>${pkg.game_association || ''}</td>
                <td class="status-column"><span class="status-toggle ${statusClass}" data-id="${pkg.id}" data-status="${pkg.is_active}">${statusText}</span></td>
                <td class="actions-cell"><div class="kebab-menu"><button class="kebab-toggle" data-id="${pkg.id}"><svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 16 16"><path d="M9.5 13a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0zm0-5a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0zm0-5a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0z"/></svg></button></div></td>
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
        return allPackages.filter(pkg => 
            (selectedGame ? pkg.game_association === selectedGame : true) &&
            (searchTerm ? ((pkg.name || '').toLowerCase().includes(searchTerm) || (pkg.product_code || '').toLowerCase().includes(searchTerm)) : true)
        );
    };

    const applyFiltersAndRender = () => {
        filteredPackages = getFilteredPackages();
        renderTable(filteredPackages);
    };

    const populateGameFilter = (packages) => {
        const currentSelection = gameFilter.value;
        const games = [...new Set(packages.map(p => p.game_association))].sort();
        gameFilter.innerHTML = '<option value="">All Games</option>';
        games.forEach(game => {
            const option = document.createElement('option');
            option.value = game;
            option.textContent = game;
            gameFilter.appendChild(option);
        });
        gameFilter.value = currentSelection;
    };

    const fetchAndRenderPackages = async (resetSelection = true) => {
        try {
            const response = await fetch(API_URL);
            if (!response.ok) throw new Error('Failed to fetch packages');
            allPackages = await response.json(); 
            if(resetSelection) {
                selectedPackageIds.clear();
            }
            populateGameFilter(allPackages);
            applyFiltersAndRender();
            updateBulkActionsBar();
        } catch (error) {
            console.error(error);
            showToast('Could not load package data.', 'error');
        }
    };

    const updateBulkActionsBar = () => {
        const count = selectedPackageIds.size;
        selectionCount.textContent = count > 0 ? `${count} item(s) selected` : '';
        bulkActionsBar.classList.toggle('hidden', count === 0);
    };

    const handleSelectionChange = (event) => {
        const checkbox = event.target;
        const packageId = parseInt(checkbox.dataset.id, 10);
        const row = checkbox.closest('tr');
        if (checkbox.checked) {
            selectedPackageIds.add(packageId);
        } else {
            selectedPackageIds.delete(packageId);
        }
        row.classList.toggle('selected-row', checkbox.checked);
        const onScreenIds = filteredPackages.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage).map(p => p.id);
        selectAllCheckbox.checked = onScreenIds.length > 0 && onScreenIds.every(id => selectedPackageIds.has(id));
        updateBulkActionsBar();
    };

    const handleSelectAll = () => {
        const onScreenIds = filteredPackages.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage).map(p => p.id);
        onScreenIds.forEach(id => {
            if (selectAllCheckbox.checked) {
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
            if (!response.ok) throw new Error('Bulk action failed');
            await fetchAndRenderPackages();
            showToast('Bulk action completed!', 'success');
        } catch (error) {
            showToast('Error performing bulk action.', 'error');
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
        if (confirm('Are you sure you want to delete this package?')) {
            try {
                const response = await fetch(`${API_URL}/${id}`, { method: 'DELETE' });
                if (!response.ok) throw new Error('Failed to delete package');
                await fetchAndRenderPackages(false); 
                showToast('Package deleted!', 'success');
            } catch (error) {
                showToast('Error deleting data.', 'error');
            }
        }
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
        dropdown.innerHTML = `
            <div class="kebab-dropdown-item edit-btn" data-id="${packageId}">Edit</div>
            <div class="kebab-dropdown-item clone-btn" data-id="${packageId}">Clone</div>
            <div class="kebab-dropdown-item delete delete-btn" data-id="${packageId}">Delete</div>`;
        document.body.appendChild(dropdown);
        const top = rect.bottom + 4;
        const right = window.innerWidth - rect.right;
        dropdown.style.top = `${top}px`;
        dropdown.style.right = `${right}px`;
        setTimeout(() => dropdown.classList.add('show'), 10);
    };

    const initSortable = () => {
        if (typeof Sortable === 'undefined') {
            console.error("SortableJS library is not loaded.");
            return;
        }

        new Sortable(tableBody, {
            handle: '.drag-handle',
            animation: 150,
            ghostClass: 'sortable-ghost',
            onEnd: async (evt) => {
                const rows = tableBody.querySelectorAll('tr[data-id]');
                const newOrder = Array.from(rows).map(row => parseInt(row.dataset.id, 10));

                try {
                    const response = await fetch('/api/packages/order', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ order: newOrder })
                    });

                    if (!response.ok) {
                        throw new Error('Failed to update order on the server.');
                    }
                    
                    showToast('Order updated successfully!', 'success');
                    await fetchAndRenderPackages(false);

                } catch (error) {
                    showToast('Error: Could not save the new order.', 'error');
                    await fetchAndRenderPackages(false);
                }
            }
        });
    };
    
    const handleOpenGameOrderModal = async () => {
        try {
            const response = await fetch(GAME_ORDER_API_URL);
            if (!response.ok) throw new Error('Could not fetch game order');
            const games = await response.json();
            
            gameOrderList.innerHTML = ''; 
            games.forEach(game => {
                const item = document.createElement('div');
                item.className = 'game-order-item';
                item.textContent = game;
                item.dataset.gameName = game;
                gameOrderList.appendChild(item);
            });

            new Sortable(gameOrderList, {
                animation: 150,
                ghostClass: 'sortable-ghost',
            });

            showModal(gameOrderModal);
        } catch (error) {
            showToast('Error loading game order.', 'error');
        }
    };
    
    const handleSaveGameOrder = async () => {
        const items = gameOrderList.querySelectorAll('.game-order-item');
        const newGameOrder = Array.from(items).map(item => item.dataset.gameName);

        try {
            const response = await fetch(GAME_ORDER_API_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ gameOrder: newGameOrder })
            });

            if (!response.ok) throw new Error('Could not save game order');

            hideModal(gameOrderModal);
            showToast('Game order saved!', 'success');
        } catch (error) {
            showToast('Error saving game order.', 'error');
        }
    };

    function init() {
        addNewBtn.addEventListener('click', openNewPackageModal);
        packageModal.querySelector('.close-btn').addEventListener('click', () => hideModal(packageModal));
        bulkPriceModal.querySelector('.close-btn').addEventListener('click', () => hideModal(bulkPriceModal));
        packageForm.addEventListener('submit', handleFormSubmit);
        selectAllCheckbox.addEventListener('change', handleSelectAll);

        filterInput.addEventListener('input', () => {
            currentPage = 1;
            applyFiltersAndRender();
        });
        gameFilter.addEventListener('change', () => {
            currentPage = 1;
            applyFiltersAndRender();
        });
        
        bulkDeleteBtn.addEventListener('click', () => {
            if (confirm(`Are you sure you want to delete ${selectedPackageIds.size} packages?`)) handleBulkAction('delete');
        });
        
        bulkStatusBtn.addEventListener('click', () => {
            showModal(bulkStatusModal);
        });
        bulkStatusModal.querySelector('.close-btn').addEventListener('click', () => hideModal(bulkStatusModal));
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
        
        reorderGamesBtn.addEventListener('click', handleOpenGameOrderModal);
        gameOrderModal.querySelector('.close-btn').addEventListener('click', () => hideModal(gameOrderModal));
        saveGameOrderBtn.addEventListener('click', handleSaveGameOrder);
        
        document.body.addEventListener('click', (e) => {
            const target = e.target;
            if (target.matches('#package-table-body input[type="checkbox"]')) {
                handleSelectionChange(e);
            } else if (target.closest('.status-toggle')) {
                handleStatusToggle(target.closest('.status-toggle'));
            } else if (target.closest('.kebab-toggle')) {
                showDropdown(target.closest('.kebab-toggle'));
            } else if (target.closest('.kebab-dropdown-portal')) {
                const id = target.dataset.id;
                if (target.classList.contains('edit-btn')) openEditPackageModal(id);
                if (target.classList.contains('clone-btn')) openClonePackageModal(id);
                if (target.classList.contains('delete-btn')) handleDelete(id);
                removeExistingDropdown();
            } else if (!target.closest('.kebab-menu')) {
                removeExistingDropdown();
            }
        });

        fetchAndRenderPackages();
        initSortable();
    }

    init();
});
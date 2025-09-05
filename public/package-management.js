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

    // ++ NEW: Bulk Edit Modal Elements
    const bulkEditBtn = document.getElementById('bulk-edit-btn');
    const bulkEditModal = document.getElementById('bulk-edit-modal');
    const bulkEditForm = document.getElementById('bulk-edit-form');


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

        const createButton = (text, page, isDisabled = false, isActive = false) => {
            const button = document.createElement('button');
            button.textContent = text;
            button.classList.add('pagination-btn');
            if (isDisabled) button.disabled = true;
            if (isActive) button.classList.add('active');
            button.addEventListener('click', () => {
                currentPage = page;
                renderTable(filteredPackages);
            });
            return button;
        };
        
        const createEllipsis = () => {
            const span = document.createElement('span');
            span.textContent = '...';
            span.className = 'pagination-ellipsis';
            return span;
        };

        paginationControls.appendChild(createButton('‹ Prev', currentPage - 1, currentPage === 1));

        const pageNumbersToShow = new Set();
        pageNumbersToShow.add(1);
        pageNumbersToShow.add(totalPages);
        pageNumbersToShow.add(currentPage);
        if (currentPage > 1) pageNumbersToShow.add(currentPage - 1);
        if (currentPage < totalPages) pageNumbersToShow.add(currentPage + 1);

        let lastPage = 0;
        Array.from(pageNumbersToShow).sort((a, b) => a - b).forEach(page => {
            if (page > lastPage + 1) {
                paginationControls.appendChild(createEllipsis());
            }
            paginationControls.appendChild(createButton(page, page, false, page === currentPage));
            lastPage = page;
        });

        paginationControls.appendChild(createButton('Next ›', currentPage + 1, currentPage === totalPages));
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
            tableBody.innerHTML = `<tr><td colspan="7" style="text-align: center; padding: 40px;">No packages found.</td></tr>`;
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
                <td><div class="package-details"><div class="name">${pkg.name || ''}</div><div class="code">${pkg.product_code || ''}</div></div></td>
                <td>${(pkg.price || 0).toFixed(2)}</td>
                <td>${pkg.type || ''}</td>
                <td><span class="game-tag">${pkg.game_association || ''}</span></td>
                <td class="status-column"><span class="status-toggle ${statusClass}" data-id="${pkg.id}" data-status="${pkg.is_active}">${statusText}</span></td>
                <td class="actions-cell">
                    <div class="kebab-menu">
                        <button class="kebab-toggle" data-id="${pkg.id}">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 16 16"><path d="M9.5 13a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0zm0-5a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0zm0-5a1.5 1.5 0 1 1-3 0 1.5 1.5 0 0 1 3 0z"/></svg>
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

        const totalPages = Math.ceil(filteredPackages.length / itemsPerPage);
        if (currentPage > totalPages && totalPages > 0) {
            currentPage = totalPages;
        }

        renderTable(filteredPackages);
    };
    
    const populateGameFilter = (games) => {
        const currentSelection = gameFilter.value;
        gameFilter.innerHTML = '<option value="">  -- เลือกเกม --  </option>';
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
            if (!response.ok) {
                 const errData = await response.json();
                 throw new Error(errData.details || 'Bulk action failed');
            }
            await fetchAndRenderPackages();
            showToast('Bulk action completed!', 'success');
        } catch (error) {
            showToast(`Error: ${error.message}`, 'error');
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
    
    // ++ NEW: Handler for Bulk Edit Form Submission
    const handleBulkEditSubmit = async (event) => {
        event.preventDefault();
        
        const updates = {};
        
        const price = document.getElementById('bulk-price').value;
        const type = document.getElementById('bulk-type').value;
        const channel = document.getElementById('bulk-channel').value;
        const game = document.getElementById('bulk-game_association').value;

        if (price.trim() !== '') updates.price = parseFloat(price);
        if (type.trim() !== '') updates.type = type;
        if (channel.trim() !== '') updates.channel = channel;
        if (game.trim() !== '') updates.game_association = game.trim();

        if (Object.keys(updates).length === 0) {
            showToast('No changes were specified.', 'error');
            return;
        }

        hideModal(bulkEditModal);
        await handleBulkAction('bulkEdit', { updates });
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
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" viewBox="0 0 16 16"><path fill-rule="evenodd" d="M7.646 4.646a.5.5 0 0 1 .708 0l6 6a.5.5 0 0 1-.708.708L8 5.707l-5.646 5.647a.5.5 0 0 1-.708-.708l6-6z" transform="rotate(90 8 8)"/></svg>
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

        // ++ NEW: Event listeners for Bulk Edit
        bulkEditBtn.addEventListener('click', () => {
            bulkEditForm.reset();
            showModal(bulkEditModal);
        });
        bulkEditModal.querySelector('.close-btn').addEventListener('click', () => hideModal(bulkEditModal));
        bulkEditForm.addEventListener('submit', handleBulkEditSubmit);
        
        reorderAllBtn.addEventListener('click', handleOpenOrderModal);
        orderModal.querySelector('.close-btn').addEventListener('click', () => hideModal(orderModal));
        saveOrderBtn.addEventListener('click', handleSaveOrder);
        
        orderListContainer.addEventListener('click', (e) => {
            const header = e.target.closest('.package-group-header');
            if (header) {
                const items = header.nextElementSibling;
                if (items && items.classList.contains('package-group-items')) {
                    header.classList.toggle('collapsed');
                    items.classList.toggle('collapsed');
                }
            }
        });
        
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
    }

    init();
});
// Default configuration to prevent undefined errors
let Config = {
    SirenOptions: {
        enableSiren: true,
        repeatAlarm: true,
        alarmDuration: 15,
        alarmRepeatInterval: 7
    },
    JobSirenOptions: {
        enableSiren: true,
        repeatAlarm: true,
        alarmDuration: 15,
        alarmRepeatInterval: 7
    }
};

// Siren control for rental vehicles using vehicleNetId
// Global job vehicles array for siren controls
let currentJobVehicles = [];
function startSiren(index) {
    const rental = currentRentals[index];
    if (!rental || !rental.netId) {
        return;
    }
    // Reset siren for reliability
    resetSiren(rental.netId, 'rental');
    fetch('https://jd-carspawner/startRentalSiren', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ vehicleNetId: rental.netId })
    });
}

function stopSiren(index) {
    const rental = currentRentals[index];
    if (!rental || !rental.netId) {
        return;
    }
    // Immediately stop siren by sending stop twice for reliability
    fetch('https://jd-carspawner/stopRentalSiren', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ vehicleNetId: rental.netId })
    });
    setTimeout(() => {
        fetch('https://jd-carspawner/stopRentalSiren', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ vehicleNetId: rental.netId })
        });
    }, 100);
}

// Siren control for job vehicles using jobVehicleNetId
// Reset siren utility for reliability
function resetSiren(netId, type) {
    // Try to forcibly stop and restart siren to ensure reliability
    if (type === 'rental') {
        fetch('https://jd-carspawner/stopRentalSiren', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ vehicleNetId: netId })
        });
        setTimeout(() => {
            fetch('https://jd-carspawner/startRentalSiren', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ vehicleNetId: netId })
            });
        }, 100);
    } else if (type === 'job') {
        fetch('https://jd-carspawner/stopJobSiren', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ vehicleNetId: netId })
        });
        setTimeout(() => {
            fetch('https://jd-carspawner/startJobSiren', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ vehicleNetId: netId })
            });
        }, 100);
    }
}
function startJobSiren(index) {
    const jobVehicle = currentJobVehicles[index];
    if (!jobVehicle || !jobVehicle.netId) {
        return;
    }
    fetch('https://jd-carspawner/startJobSiren', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ vehicleNetId: jobVehicle.netId })
    });
}
window.startJobSiren = startJobSiren;

function stopJobSiren(index) {
    const jobVehicle = currentJobVehicles[index];
    if (!jobVehicle || !jobVehicle.netId) {
        return;
    }
    // Immediately stop job siren by sending stop twice for reliability
    fetch('https://jd-carspawner/stopJobSiren', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ vehicleNetId: jobVehicle.netId })
    });
    setTimeout(() => {
        fetch('https://jd-carspawner/stopJobSiren', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ vehicleNetId: jobVehicle.netId })
        });
    }, 100);
}
window.stopJobSiren = stopJobSiren;

// JD-Carspawner
{
let currentMenuData = null;
let selectedVehicle = null;
let selectedVehicleData = null;
let selectedColor = null;
let selectedTime = null;
let selectedPayment = null;
let rentalFees = {};
let rentalDurations = {};
let playerMoney = { cash: 0, bank: 0 };
let showPlayerMoney = false;
let currentRentals = [];
}
document.addEventListener('DOMContentLoaded', function() {
    document.getElementById('app').classList.add('hidden');
});

function showVehicleConfirm(vehicleData) {
    if (!vehicleData.name) {
        console.error('Vehicle data missing name property:', vehicleData);
        return;
    }
    selectedVehicleData = vehicleData;
    const imageSrc = vehicleData.image || `img/${vehicleData.model.toLowerCase()}.webp`;
    showVehicleConfirmModal(vehicleData.model, imageSrc, vehicleData.base_price, vehicleData.name);
}

function showVehicleConfirmModal(vehicleName, imageSrc, price, displayName) {
    document.getElementById('confirm-vehicle-name').textContent = displayName;
    document.getElementById('confirm-vehicle-image').src = imageSrc;
    
    const modal = document.getElementById('vehicle-confirm-modal');
    modal.classList.remove('hidden');
    
    const overlay = modal.querySelector('.modal-overlay');
    overlay.onclick = closeConfirmModal;
}

function closeConfirmModal() {
    document.getElementById('vehicle-confirm-modal').classList.add('hidden');
    selectedVehicleData = null;
}

function confirmSpawn() {
    if (selectedVehicleData) {
        spawnJobVehicle(selectedVehicleData.model);
        closeConfirmModal();
    }
}

window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'openMenu') {
        openMenu(data.data);
    } else if (data.action === 'closeMenu') {
        document.getElementById('app').classList.add('hidden');
    } else if (data.action === 'openRentalMenu') {
        showRentalManagementMenu(data);
    }
    
    switch (data.action) {
        case 'createCountdownFrame':
            createCountdownIframe();
            break;
        case 'showCountdown':
            showCountdownIframe(data.seconds);
            break;
        case 'updateCountdown':
            updateCountdownIframe(data.seconds);
            break;
        case 'hideCountdown':
            hideCountdownIframe();
            break;
    }
});

function openMenu(menuData) {
    currentMenuData = menuData;
    
    if (menuData.rentalFees) {
        rentalFees = menuData.rentalFees;
    }
    
    if (menuData.rentalDurations) {
        rentalDurations = menuData.rentalDurations;
    }
    
    if (menuData.playerMoney) {
        playerMoney = menuData.playerMoney;
    }
    
    if (menuData.showPlayerMoney !== undefined) {
        showPlayerMoney = menuData.showPlayerMoney;
    }

    if (menuData.config) {
        Config = menuData.config;
    }
    
    document.getElementById('app').classList.remove('hidden');

    if (menuData.type === 'job') {
        showJobMenu(menuData);
    } else if (menuData.type === 'rental') {
        showRentalMenu(menuData);
    }
}

function showJobMenu(menuData) {
    document.getElementById('menu-title').textContent = 'Job Vehicle Spawner';
    document.getElementById('job-menu').classList.remove('hidden');
    document.getElementById('rental-menu').classList.add('hidden');

    document.getElementById('current-player-name').textContent = menuData.playerName || 'Unknown Player';
    document.getElementById('current-player-id').textContent = `ID: ${menuData.playerId || 'N/A'}`;

    const vehicleGrid = document.getElementById('job-vehicles');
    vehicleGrid.innerHTML = '';

    let allVehicles = [];
    
    const hasGradeStructure = menuData.vehicles && typeof menuData.vehicles === 'object' && 
                             !Array.isArray(menuData.vehicles) && 
                             Object.keys(menuData.vehicles).some(key => !isNaN(key));
    
    if (hasGradeStructure) {
        const playerGrade = menuData.playerGrade || 0;
        
        const gradeNames = menuData.gradeNames || {
            '0': 'Recruit',
            '1': 'Officer', 
            '2': 'Sergeant',
            '3': 'Detective',
            '4': 'Commander'
        };

        const vehicleGradeMap = new Map();
        
        for (let gradeLevel = 0; gradeLevel <= playerGrade; gradeLevel++) {
            const rankVehicles = menuData.vehicles[gradeLevel];
            if (Array.isArray(rankVehicles)) {
                const gradeName = gradeNames[gradeLevel] || `Grade ${gradeLevel}`;
                
                rankVehicles.forEach(vehicle => {
                    if (!vehicleGradeMap.has(vehicle.model) || gradeLevel < vehicleGradeMap.get(vehicle.model).gradeLevel) {
                        vehicleGradeMap.set(vehicle.model, {
                            ...vehicle,
                            grade: gradeName,
                            gradeLevel: gradeLevel,
                            requiredGrade: gradeName
                        });
                    }
                });
            }
        }
        
        allVehicles = Array.from(vehicleGradeMap.values());
    } else if (Array.isArray(menuData.vehicles)) {
        const gradeNames = menuData.gradeNames || {
            '0': 'Recruit',
            '1': 'Officer', 
            '2': 'Sergeant',
            '3': 'Detective',
            '4': 'Commander'
        };
        allVehicles = menuData.vehicles.map(vehicle => ({...vehicle, grade: gradeNames['0'] || 'Recruit', gradeLevel: 0}));
    } else {
        allVehicles = [];
    }

    allVehicles.sort((a, b) => (a.gradeLevel || 0) - (b.gradeLevel || 0));

    allVehicles.forEach(vehicleData => {
        const vehicleCard = document.createElement('div');
        vehicleCard.className = 'vehicle-card';
        vehicleCard.onclick = () => showVehicleConfirm(vehicleData);

        if (!vehicleData.name) {
            console.error('Vehicle data missing name property:', vehicleData);
            return;
        }
        const imageSrc = vehicleData.image || `img/${vehicleData.model.toLowerCase()}.webp`;

        vehicleCard.innerHTML = `
            <div class="vehicle-image">
                <img src="${imageSrc}" alt="${vehicleData.model}" onerror="this.parentElement.innerHTML='<i class=\\'fas fa-car\\'></i><br>No Image'">
            </div>
            <div class="vehicle-info">
                <div class="vehicle-name">${vehicleData.name}</div>
                <div class="vehicle-grade">Grade: ${vehicleData.grade}</div>
            </div>
        `;

        vehicleGrid.appendChild(vehicleCard);
    });
}

function showRentalMenu(menuData) {
    const menuTitle = document.getElementById('menu-title');
    const rentalMenu = document.getElementById('rental-menu');
    const jobMenu = document.getElementById('job-menu');
    const rentalPlayerName = document.getElementById('rental-player-name');
    const rentalPlayerId = document.getElementById('rental-player-id');
    
    if (menuTitle) menuTitle.textContent = 'Vehicle Rental';
    if (rentalMenu) rentalMenu.classList.remove('hidden');
    if (jobMenu) jobMenu.classList.add('hidden');
    if (rentalPlayerName) rentalPlayerName.textContent = menuData.playerName || 'Unknown Player';
    if (rentalPlayerId) rentalPlayerId.textContent = `ID: ${menuData.playerId || 'N/A'}`;

    resetRental();

    const vehicleGrid = document.getElementById('rental-vehicles');
    vehicleGrid.innerHTML = '';

    menuData.vehicles.forEach(vehicle => {
        const vehicleCard = document.createElement('div');
        vehicleCard.className = 'vehicle-card';
        vehicleCard.onclick = () => selectRentalVehicle(vehicle);

        if (!vehicle.name) {
            console.error('Vehicle data missing name property:', vehicle);
            return;
        }
        const imageSrc = vehicle.image || `img/${vehicle.model.toLowerCase()}.webp`;

        vehicleCard.innerHTML = `
            <div class="vehicle-image">
                <img src="${imageSrc}" alt="${vehicle.model}" onerror="this.parentElement.innerHTML='<i class=\\'fas fa-car\\'></i><br>No Image'">
            </div>
            <div class="vehicle-info">
                <div class="vehicle-name">${vehicle.name}</div>
                <div class="vehicle-price">Base: $${vehicle.base_price}</div>
            </div>
        `;

        vehicleGrid.appendChild(vehicleCard);
    });

    const timeGrid = document.getElementById('time-options');
    timeGrid.innerHTML = '';

    Object.entries(menuData.timeOptions).forEach(([hours, label]) => {
        if (label && label.trim() !== '') {
            const timeOption = document.createElement('div');
            timeOption.className = 'time-option';
            timeOption.onclick = () => selectTime(hours, label);
            timeOption.textContent = label;
            timeGrid.appendChild(timeOption);
        }
    });

    // Use default colors if none provided
    const colors = menuData.colors;
    setupColorOptions(colors);
    setupPaymentOptions();
}

function selectRentalVehicle(vehicle) {
    selectedVehicle = vehicle;

    document.querySelectorAll('#rental-vehicles .vehicle-card').forEach(card => {
        card.classList.remove('selected');
    });
    event.target.closest('.vehicle-card').classList.add('selected');

    document.getElementById('color-section').style.display = 'block';
    updateSummary();
}

function setupColorOptions(colors) {
    const colorGrid = document.getElementById('color-options');
    colorGrid.innerHTML = '';
    
    if (!colors || !Array.isArray(colors)) {
        console.warn('No colors provided for vehicle selection');
        return;
    }

    colors.forEach(color => {
        if (color && color.hex && color.name) {
            const colorOption = document.createElement('div');
            colorOption.className = 'color-option';
            colorOption.style.background = color.hex;
            colorOption.title = color.name;
            colorOption.dataset.color = JSON.stringify(color);
            colorOption.onclick = () => selectColor(color);
            colorGrid.appendChild(colorOption);
        } else {
            console.warn('Invalid color data:', color);
        }
    });
}

function selectColor(color) {
    selectedColor = color;

    document.querySelectorAll('.color-option').forEach(option => {
        option.classList.remove('selected');
    });
    event.target.classList.add('selected');

    document.getElementById('time-section').style.display = 'block';
    updateSummary();
}

function selectTime(hours, label) {
    selectedTime = { hours: parseInt(hours), label: label };

    document.querySelectorAll('.time-option').forEach(option => {
        option.classList.remove('selected');
    });
    event.target.classList.add('selected');

    document.getElementById('payment-section').style.display = 'block';
    updateSummary();
}

function setupPaymentOptions() {
    document.querySelectorAll('.payment-option').forEach(option => {
        option.onclick = () => selectPayment(option.dataset.payment);
        
        if (showPlayerMoney && playerMoney) {
            const paymentType = option.dataset.payment;
            const moneyAmount = paymentType === 'cash' ? playerMoney.cash : playerMoney.bank;
            
            const existingMoneyDisplay = option.querySelector('.money-display');
            if (existingMoneyDisplay) {
                existingMoneyDisplay.remove();
            }
            
            const moneyDisplay = document.createElement('div');
            moneyDisplay.className = 'money-display';
            moneyDisplay.textContent = `$${moneyAmount.toLocaleString()}`;
            
            option.appendChild(moneyDisplay);
        } else {
            const existingMoneyDisplay = option.querySelector('.money-display');
            if (existingMoneyDisplay) {
                existingMoneyDisplay.remove();
            }
        }
    });
}

function selectPayment(paymentType) {
    selectedPayment = paymentType;

    document.querySelectorAll('.payment-option').forEach(option => {
        option.classList.remove('selected');
    });
    document.querySelector(`[data-payment="${paymentType}"]`).classList.add('selected');

    document.getElementById('summary-section').style.display = 'block';
    document.getElementById('rent-btn').style.display = 'inline-flex';
    updateSummary();
}

function updateSummary() {
    const summaryPriceElement = document.getElementById('summary-price');
    const rentBtn = document.getElementById('rent-btn');
    
    if (selectedVehicle && selectedTime) {
        const displayName = selectedVehicle.name || selectedVehicle.model;
        document.getElementById('summary-vehicle').textContent = displayName;
        
        const rentalFee = rentalFees[selectedTime.hours] || 0;
        const basePrice = selectedVehicle.base_price;
        const finalPrice = basePrice + rentalFee;
        
        let hasEnoughMoney = false;
        let availableMoney = 0;
        
        if (selectedPayment) {
            if (selectedPayment === 'cash') {
                availableMoney = playerMoney.cash || 0;
                hasEnoughMoney = availableMoney >= finalPrice;
            } else if (selectedPayment === 'bank') {
                availableMoney = playerMoney.bank || 0;
                hasEnoughMoney = availableMoney >= finalPrice;
            }
            
            summaryPriceElement.textContent = `$${finalPrice}`;
            if (hasEnoughMoney) {
                summaryPriceElement.style.color = '#22c55e';
                summaryPriceElement.style.fontWeight = 'bold';
                rentBtn.disabled = false;
                rentBtn.style.opacity = '1';
                rentBtn.style.cursor = 'pointer';
            } else {
                summaryPriceElement.style.color = '#ef4444';
                summaryPriceElement.style.fontWeight = 'bold';
                rentBtn.disabled = true;
                rentBtn.style.opacity = '0.5';
                rentBtn.style.cursor = 'not-allowed';
            }
            
            const paymentMethodText = selectedPayment.charAt(0).toUpperCase() + selectedPayment.slice(1);
            summaryPriceElement.title = `${paymentMethodText}: $${availableMoney} ${hasEnoughMoney ? '✓' : '✗'}`;
        } else {
            summaryPriceElement.textContent = `$${finalPrice}`;
            summaryPriceElement.style.color = '#ffffff';
            summaryPriceElement.style.fontWeight = 'normal';
            rentBtn.disabled = true;
            rentBtn.style.opacity = '0.5';
            rentBtn.style.cursor = 'not-allowed';
        }
    } else if (selectedVehicle) {
        const displayName = selectedVehicle.name || selectedVehicle.model;
        document.getElementById('summary-vehicle').textContent = displayName;
        summaryPriceElement.textContent = `Base: $${selectedVehicle.base_price}`;
        summaryPriceElement.style.color = '#ffffff';
        summaryPriceElement.style.fontWeight = 'normal';
        rentBtn.disabled = true;
        rentBtn.style.opacity = '0.5';
        rentBtn.style.cursor = 'not-allowed';
    }

    if (selectedTime) {
        document.getElementById('summary-time').textContent = selectedTime.label;
    }

    if (selectedPayment) {
        const paymentElement = document.getElementById('summary-payment');
        paymentElement.textContent = selectedPayment.charAt(0).toUpperCase() + selectedPayment.slice(1);
        
        const availableMoney = selectedPayment === 'cash' ? playerMoney.cash : playerMoney.bank;
        paymentElement.title = `Available: $${availableMoney}`;
    }
}

function resetRental() {
    selectedVehicle = null;
    selectedColor = null;
    selectedTime = null;
    selectedPayment = null;

    const colorSection = document.getElementById('color-section');
    const timeSection = document.getElementById('time-section');
    const paymentSection = document.getElementById('payment-section');
    const summarySection = document.getElementById('summary-section');
    const rentBtn = document.getElementById('rent-btn');
    
    if (colorSection) colorSection.style.display = 'none';
    if (timeSection) timeSection.style.display = 'none';
    if (paymentSection) paymentSection.style.display = 'none';
    if (summarySection) summarySection.style.display = 'none';
    
    if (rentBtn) {
        rentBtn.style.display = 'none';
        rentBtn.disabled = true;
        rentBtn.style.opacity = '0.5';
        rentBtn.style.cursor = 'not-allowed';
    }

    document.querySelectorAll('.selected').forEach(element => {
        element.classList.remove('selected');
    });

    const summaryVehicle = document.getElementById('summary-vehicle');
    const summaryTime = document.getElementById('summary-time');
    const summaryPayment = document.getElementById('summary-payment');
    const summaryPriceElement = document.getElementById('summary-price');
    
    if (summaryVehicle) summaryVehicle.textContent = '-';
    if (summaryTime) summaryTime.textContent = '-';
    if (summaryPayment) summaryPayment.textContent = '-';
    
    if (summaryPriceElement) {
        summaryPriceElement.textContent = 'Select options above';
        summaryPriceElement.style.color = '#ffffff';
        summaryPriceElement.style.fontWeight = 'normal';
    }
    summaryPriceElement.title = '';
}

function spawnJobVehicle(vehicle) {
    const data = {
        type: 'job',
        vehicle: vehicle,
        jobName: currentMenuData.jobName, // Add job name to the data
        spawnCoords: currentMenuData.spawnCoords,
        spawnHeading: currentMenuData.spawnHeading
    };

    fetch(`https://jd-carspawner/spawnVehicle`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    }).catch(err => {
        console.log('Failed to spawn job vehicle:', err);
    });
}

function confirmRental() {
    if (!selectedVehicle || !selectedTime || !selectedPayment) {
        return;
    }

    const rentalFee = rentalFees[selectedTime.hours] || 0;
    const finalPrice = selectedVehicle.base_price + rentalFee;
    
    const availableMoney = selectedPayment === 'cash' ? playerMoney.cash : playerMoney.bank;
    if (availableMoney < finalPrice) {
        console.log('Insufficient funds for rental');
        return;
    }

    const data = {
        type: 'rental',
        vehicle: selectedVehicle.model,
        rentalTime: selectedTime.hours,
        rentalDurationSeconds: rentalDurations[selectedTime.hours] || 3600,
        rentalPrice: finalPrice,
        paymentType: selectedPayment,
        vehicleColor: selectedColor, // Pass the entire color object
        spawnCoords: currentMenuData.spawnCoords,
        spawnHeading: currentMenuData.spawnHeading
    };

    fetch(`https://jd-carspawner/spawnVehicle`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    }).catch(err => {
        console.log('Failed to spawn rental vehicle:', err);
    });
}

function closeMenu() {
    document.getElementById('app').classList.add('hidden');
    
    fetch(`https://jd-carspawner/closeMenu`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    }).catch(err => {
        console.log('Failed to send close menu callback:', err);
    });
}

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        event.preventDefault();
        // Check for rental management overlay first
        if (rentalManagementOverlay) {
            closeRentalMenu(true); // Force cleanup when closing with ESC
        } else if (!document.getElementById('vehicle-confirm-modal').classList.contains('hidden')) {
            closeConfirmModal();
        } else {
            closeMenu();
        }
    }
});


let countdownIframe = null;
let isCountdownVisible = false;

function createCountdownIframe() {
    if (countdownIframe) {
        return;
    }

    countdownIframe = document.createElement('iframe');
    countdownIframe.id = 'countdown-iframe';
    countdownIframe.src = 'countdown.html';
    countdownIframe.style.cssText = `
        position: fixed !important;
        top: 0 !important;
        left: 0 !important;
        width: 100vw !important;
        height: 100vh !important;
        border: none !important;
        background: transparent !important;
        z-index: 999999 !important;
        pointer-events: none !important;
        display: none !important;
    `;

    document.body.appendChild(countdownIframe);
}

function showCountdownIframe(seconds) {
    if (!countdownIframe) {
        createCountdownIframe();
    }

    if (!isCountdownVisible) {
        countdownIframe.style.display = 'block';
        isCountdownVisible = true;
        
        setTimeout(() => {
            if (countdownIframe.contentWindow) {
                countdownIframe.contentWindow.postMessage({
                    type: 'showCountdown',
                    seconds: seconds
                }, '*');
            }
        }, 100);
    }
}

function updateCountdownIframe(seconds) {
    if (countdownIframe && isCountdownVisible && countdownIframe.contentWindow) {
        countdownIframe.contentWindow.postMessage({
            type: 'updateCountdown',
            seconds: seconds
        }, '*');
    }
}

function hideCountdownIframe() {
    if (countdownIframe && isCountdownVisible) {
        if (countdownIframe.contentWindow) {
            countdownIframe.contentWindow.postMessage({
                type: 'hideCountdown'
            }, '*');
        }
        
        setTimeout(() => {
            countdownIframe.style.display = 'none';
            isCountdownVisible = false;
        }, 500);
    }
}

// Clean up all GPS and siren states when menu closes
function cleanupAllVehicleStates() {
    // Clean up rental vehicle states
    Object.keys(rentalGpsIntervals).forEach(index => {
        clearInterval(rentalGpsIntervals[index]);
        delete rentalGpsIntervals[index];
    });
    
    Object.keys(rentalSirenStates).forEach(index => {
        if (rentalSirenStates[index]) {
            stopSiren(index);
        }
        delete rentalSirenStates[index];
    });
    
    // Clean up job vehicle states
    Object.keys(jobGpsIntervals).forEach(index => {
        clearInterval(jobGpsIntervals[index]);
        delete jobGpsIntervals[index];
    });
    
    Object.keys(jobSirenStates).forEach(index => {
        if (jobSirenStates[index]) {
            stopJobSiren(index);
        }
        delete jobSirenStates[index];
    });
}

let rentalManagementOverlay = null;
let rentalUpdateInterval = null;

function showRentalManagementMenu(data) {
    let rentals = [];
    let jobVehicles = [];
    if (Array.isArray(data)) {
        rentals = data;
    } else if (data && typeof data === 'object') {
        rentals = data.rentals || [];
        jobVehicles = data.jobVehicles || [];
    }
    // Update currentRentals and currentJobVehicles with the fresh data
    currentRentals = [...rentals];
    currentJobVehicles = [...jobVehicles];
    
    // Initialize siren states if not already set
    currentRentals.forEach((rental, idx) => {
        rentalSirenStates[idx] = rentalSirenStates[idx] || false;
    });
    currentJobVehicles.forEach((jobVehicle, idx) => {
        jobSirenStates[idx] = jobSirenStates[idx] || false;
    });

    // Update GPS and Siren active states for rentals
    currentRentals.forEach((rental, idx) => {
        rental.gpsActive = !!rentalGpsIntervals[idx];
        rental.sirenActive = !!rental.sirenActive;
    });
    // Update GPS and Siren active states for job vehicles
    currentJobVehicles.forEach((jobVehicle, idx) => {
        jobVehicle.gpsActive = !!jobGpsIntervals[idx];
        jobVehicle.sirenActive = !!jobVehicle.sirenActive;
    });
    
    if (rentalManagementOverlay) {
        document.body.removeChild(rentalManagementOverlay);
    }
    
    if (rentalUpdateInterval) {
        clearInterval(rentalUpdateInterval);
        rentalUpdateInterval = null;
    }
    
    rentalManagementOverlay = document.createElement('div');
    rentalManagementOverlay.id = 'rental-management-overlay';
    rentalManagementOverlay.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 100vw;
        height: 100vh;
        background: rgba(0, 0, 0, 0.4);
        z-index: 10000;
        display: flex;
        justify-content: center;
        align-items: center;
    `;
    
    const activeRentals = currentRentals.filter(rental => rental.timeLeft > 0);
    
    const rentalSection = activeRentals.length === 0 ? 
        '<div class="no-rentals">No active rental vehicles</div>' :
        activeRentals.map((rental, index) => {
            // Find the original index in currentRentals for proper data binding
            const originalIndex = currentRentals.findIndex(r => r === rental);
            return `
                <div class="rental-item" data-rental-index="${originalIndex}">
                    <div class="rental-info">
                        <h3>🚗 ${rental.vehicleModel || 'Unknown Vehicle'} (Rental)</h3>
                        <p class="time-remaining">Time remaining: <span class="timer-display">${formatTime(Math.max(0, Math.floor((rental.timeLeft || 0) / 1000)))}</span></p>
                        <p>Location: ${getLocationName(rental.coords)}</p>
                    </div>
                    <div class="rental-actions">
                    <button onclick="window.handleGpsStart(${originalIndex})" class="locate-btn" id="gps-start-${originalIndex}">🗺️ GPS Route</button>
                    <button onclick="window.handleGpsStop(${originalIndex})" class="hide-btn" id="gps-stop-${originalIndex}" style="display:none;">🚫 Hide GPS</button>
                    ${Config.SirenOptions.enableSiren ? `
                    <button onclick="window.handleSirenStart(${originalIndex})" class="siren-btn start-siren-btn" id="siren-start-${originalIndex}"><i class='fas fa-bullhorn'></i> Start Siren</button>
                    <button onclick="window.handleSirenStop(${originalIndex})" class="siren-btn stop-siren-btn" id="siren-stop-${originalIndex}" style="display:none;"><i class='fas fa-bullhorn'></i> Stop Siren</button>
                    ` : ''}
                        <button onclick="returnVehicle(${originalIndex})" class="return-btn">🔄 Return</button>
                    </div>
                </div>
            `;
        }).join('');
    
    const jobVehicleSection = jobVehicles.length === 0 ? 
        '<div class="no-rentals">No active job vehicles</div>' :
        jobVehicles.map((jobVehicle, index) => `
            <div class="rental-item job-vehicle-item" data-job-vehicle-index="${index}">
                <div class="rental-info">
                    <h3>🚔 ${jobVehicle.vehicleModel || 'Unknown Vehicle'} (${jobVehicle.jobName.toUpperCase()})</h3>
                    <p class="job-info">Plate: ${jobVehicle.plate}</p>
                    <p>Location: ${getLocationName(jobVehicle.coords)}</p>
                </div>
                <div class="rental-actions">
                    <button onclick="window.handleJobGpsStart(${index})" class="locate-btn" id="job-gps-start-${index}">🗺️ GPS Route</button>
                    <button onclick="window.handleJobGpsStop(${index})" class="hide-btn" id="job-gps-stop-${index}" style="display:none;">🚫 Hide GPS</button>
                    ${Config.JobSirenOptions.enableSiren ? `
                    <button onclick="window.handleJobSirenStart(${index})" class="siren-btn start-job-siren-btn" id="job-siren-start-${index}"><i class='fas fa-bullhorn'></i> Start Siren</button>
                    <button onclick="window.handleJobSirenStop(${index})" class="siren-btn stop-job-siren-btn" id="job-siren-stop-${index}" style="display:none;"><i class='fas fa-bullhorn'></i> Stop Siren</button>
                    ` : ''}
                    <button onclick="storeJobVehicle(${index})" class="store-btn">🏪 Store Vehicle</button>
                </div>
            </div>
        `).join('');
    
    let contentHtml = '';
    if (rentals.length > 0) {
        contentHtml += `<div class="vehicle-section">
            <h3 class="section-title">� Rental Vehicles</h3>
            ${rentalSection}
        </div>`;
    }
    
    if (jobVehicles.length > 0) {
        contentHtml += `<div class="vehicle-section">
            <h3 class="section-title">🚔 Job Vehicles</h3>
            ${jobVehicleSection}
        </div>`;
    }
    
    if (rentals.length === 0 && jobVehicles.length === 0) {
        contentHtml = '<div class="no-rentals">No active vehicles</div>';
    }
    
    rentalManagementOverlay.innerHTML = `
        <div class="rental-management-container">
            <div class="rental-header">
                <h2>🚗 Vehicle Management</h2>
                <button onclick="closeRentalMenu(false)" class="close-btn">✕</button>
            </div>
            <div class="rental-content">
                ${contentHtml}
            </div>
        </div>
    `;
    
    document.body.appendChild(rentalManagementOverlay);

    startRentalTimerUpdates();

    // Attach initial button visibility logic for all rentals and job vehicles
    setTimeout(() => {
        if (currentRentals) {
            currentRentals.forEach((rental, idx) => {
                // GPS: If rental.gpsActive is true, show stop, else show start
                window.toggleGpsButtons(idx, rental.gpsActive === true);
                // Siren: Use our persistent siren state
                window.toggleSirenButtons(idx, rentalSirenStates[idx] === true);
            });
        }
        if (currentJobVehicles) {
            currentJobVehicles.forEach((jobVehicle, idx) => {
                // GPS: If jobVehicle.gpsActive is true, show stop, else show start
                window.toggleJobGpsButtons(idx, jobVehicle.gpsActive === true);
                // Siren: Use our persistent siren state
                window.toggleJobSirenButtons(idx, jobSirenStates[idx] === true);
            });
        }
    }, 50);
// Toggle GPS buttons for rental vehicles
window.toggleGpsButtons = function(index, isActive) {
    const startBtn = document.getElementById(`gps-start-${index}`);
    const stopBtn = document.getElementById(`gps-stop-${index}`);
    if (startBtn && stopBtn) {
        startBtn.style.display = isActive ? 'none' : '';
        stopBtn.style.display = isActive ? '' : 'none';
    }
}

// Toggle Siren buttons for rental vehicles
window.toggleSirenButtons = function(index, isActive) {
    const startBtn = document.getElementById(`siren-start-${index}`);
    const stopBtn = document.getElementById(`siren-stop-${index}`);
    if (startBtn && stopBtn) {
        startBtn.style.display = isActive ? 'none' : '';
        stopBtn.style.display = isActive ? '' : 'none';
    }
}

// Toggle GPS buttons for job vehicles
window.toggleJobGpsButtons = function(index, isActive) {
    const startBtn = document.getElementById(`job-gps-start-${index}`);
    const stopBtn = document.getElementById(`job-gps-stop-${index}`);
    if (startBtn && stopBtn) {
        startBtn.style.display = isActive ? 'none' : '';
        stopBtn.style.display = isActive ? '' : 'none';
    }
}

// Toggle Siren buttons for job vehicles
window.toggleJobSirenButtons = function(index, isActive) {
    const startBtn = document.getElementById(`job-siren-start-${index}`);
    const stopBtn = document.getElementById(`job-siren-stop-${index}`);
    if (startBtn && stopBtn) {
        startBtn.style.display = isActive ? 'none' : '';
        stopBtn.style.display = isActive ? '' : 'none';
    }
}
}

function startRentalTimerUpdates() {
    if (rentalUpdateInterval) {
        clearInterval(rentalUpdateInterval);
    }
    // Always start the timer, regardless of whether there are active rentals
    rentalUpdateInterval = setInterval(() => {
        updateRentalTimers();
    }, 1000);
}

function updateRentalTimers() {
    if (!rentalManagementOverlay || !currentRentals || currentRentals.length === 0) {
        return;
    }
    
    const itemsToRemove = [];
    
    currentRentals.forEach((rental, index) => {
        const timerElement = rentalManagementOverlay.querySelector(`[data-rental-index="${index}"] .timer-display`);
        
        if (timerElement && rental.timeLeft !== undefined) {
            const timeLeft = Math.max(0, rental.timeLeft - 1000);
            const secondsLeft = Math.floor(timeLeft / 1000);
            
            currentRentals[index].timeLeft = timeLeft;
            
            if (timeLeft > 0) {
                const formattedTime = formatTime(secondsLeft);
                timerElement.textContent = formattedTime;
                
                if (secondsLeft <= 30) {
                    timerElement.style.color = '#ef4444';
                    timerElement.style.fontWeight = 'bold';
                } else if (secondsLeft <= 60) {
                    timerElement.style.color = '#f59e0b';
                    timerElement.style.fontWeight = 'bold';
                } else if (secondsLeft <= 300) {
                    timerElement.style.color = '#eab308';
                } else {
                    timerElement.style.color = '#22c55e';
                }
            } else {
                // Vehicle expired - remove from display and array
                const vehicleItem = timerElement.closest('.rental-item');
                if (vehicleItem) {
                    vehicleItem.remove();
                    itemsToRemove.push(index);
                }
            }
        }
    });
    
    // Remove expired items from the array (in reverse order to maintain indices)
    for (let i = itemsToRemove.length - 1; i >= 0; i--) {
        currentRentals.splice(itemsToRemove[i], 1);
    }
    
    // Check if we need to update the display when no rentals remain
    if (currentRentals.length === 0) {
        const rentalSection = rentalManagementOverlay.querySelector('.vehicle-section');
        const jobSection = rentalManagementOverlay.querySelector('.vehicle-section:last-child');
        
        // If there are job vehicles, only update the rental section
        if (jobSection && rentalSection !== jobSection) {
            if (rentalSection) {
                rentalSection.innerHTML = `
                    <h3 class="section-title">🚗 Rental Vehicles</h3>
                    <div class="no-rentals">No active rental vehicles</div>
                `;
            }
        } else {
            // No vehicles at all
            const rentalContent = rentalManagementOverlay.querySelector('.rental-content');
            if (rentalContent) {
                rentalContent.innerHTML = '<div class="no-rentals">No active vehicles</div>';
            }
        }
    }
}

function formatTime(seconds) {
    if (seconds <= 0) return "Expired";
    
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    
    if (hours > 0) {
        return `${hours}h ${minutes}m ${secs}s`;
    } else if (minutes > 0) {
        return `${minutes}m ${secs}s`;
    } else {
        return `${secs}s`;
    }
}

function getLocationName(coords) {
    if (!coords) return 'Unknown';
    
    // Basic zone detection for common Los Santos areas
    const x = coords.x;
    const y = coords.y;
    
    // Popular areas in Los Santos
    if (x >= -1200 && x <= -800 && y >= -1500 && y <= -1000) {
        return 'Vespucci';
    } else if (x >= 200 && x <= 400 && y >= -1200 && y <= -800) {
        return 'Pillbox Hill';
    } else if (x >= -800 && x <= -200 && y >= -800 && y <= -200) {
        return 'Downtown';
    } else if (x >= 400 && x <= 600 && y >= -1100 && y <= -900) {
        return 'Mission Row Police Station';
    } else if (x >= 400 && x <= 800 && y >= -1000 && y <= -600) {
        return 'Strawberry';
    } else if (x >= -400 && x <= 200 && y >= -1600 && y <= -1200) {
        return 'Little Seoul';
    } else if (x >= -1600 && x <= -1200 && y >= -200 && y <= 200) {
        return 'Rockford Hills';
    } else if (x >= -2000 && x <= -1600 && y >= -200 && y <= 400) {
        return 'Vinewood Hills';
    } else if (x >= 1200 && x <= 2000 && y >= 2400 && y <= 3000) {
        return 'Sandy Shores';
    } else if (x >= -500 && x <= 0 && y >= 5500 && y <= 6500) {
        return 'Paleto Bay';
    } else if (x >= 1800 && x <= 2200 && y >= 2500 && y <= 3000) {
        return 'Prison Area';
    } else if (x >= -800 && x <= -400 && y >= -1200 && y <= -800) {
        return 'Mission Row';
    } else if (x >= 280 && x <= 320 && y >= -620 && y <= -580) {
        return 'Central Medical Center';
    } else if (x >= 200 && x <= 600 && y >= -700 && y <= -300) {
        return 'Textile City';
    } else if (x >= -500 && x <= -400 && y >= 6000 && y <= 6100) {
        return 'Paleto Bay Police Station';
    } else if (x >= 1800 && x <= 1900 && y >= 2500 && y <= 2650) {
        return 'Bolingbroke Penitentiary';
    } else {
        // Fallback to coordinates if no zone matches
        return `${Math.round(x)}, ${Math.round(y)}`;
    }
}

// GPS update intervals and siren states for rental and job vehicles
let rentalGpsIntervals = {};
let jobGpsIntervals = {};
let rentalSirenStates = {};
let jobSirenStates = {};

function locateVehicle(index) {
    // Clear any previous interval for this rental vehicle
    if (rentalGpsIntervals[index]) {
        clearInterval(rentalGpsIntervals[index]);
    }
    // Immediately set GPS route
    fetch(`https://jd-carspawner/locateRentalVehicle`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ rentalIndex: index })
    });
    // Set interval to update GPS every 30 seconds
    rentalGpsIntervals[index] = setInterval(() => {
        fetch(`https://jd-carspawner/locateRentalVehicle`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ rentalIndex: index })
        });
    }, 30000);
}

function hideWaypoint(index) {
    // Stop GPS updates for this rental vehicle
    if (rentalGpsIntervals[index]) {
        clearInterval(rentalGpsIntervals[index]);
        delete rentalGpsIntervals[index];
    }
    fetch(`https://jd-carspawner/hideRentalWaypoint`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ rentalIndex: index })
    });
}

function returnVehicle(index) {
    // Stop GPS updates for this rental vehicle
    if (rentalGpsIntervals[index]) {
        clearInterval(rentalGpsIntervals[index]);
        delete rentalGpsIntervals[index];
    }
    // Stop siren if active
    if (rentalSirenStates[index]) {
        stopSiren(index);
        delete rentalSirenStates[index];
    }
    fetch(`https://jd-carspawner/returnRentalVehicle`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ rentalIndex: index })
    });
}

function closeRentalMenu(forceCleanup = false) {
    if (rentalManagementOverlay) {
        document.body.removeChild(rentalManagementOverlay);
        rentalManagementOverlay = null;
    }
    
    if (rentalUpdateInterval) {
        clearInterval(rentalUpdateInterval);
        rentalUpdateInterval = null;
    }
    
    // Only cleanup states if force closing (like with ESC key)
    if (forceCleanup) {
        cleanupAllVehicleStates();
    }
    
    fetch(`https://jd-carspawner/closeRentalMenu`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ forceCleanup: forceCleanup })
    });
}

// Rental GPS button handlers
window.handleGpsStart = function(index) {
    toggleGpsButtons(index, true);
    locateVehicle(index);
}
window.handleGpsStop = function(index) {
    toggleGpsButtons(index, false);
    hideWaypoint(index);
}
// Rental Siren button handlers
window.handleSirenStart = function(index) {
    rentalSirenStates[index] = true;
    toggleSirenButtons(index, true);
    startSiren(index);
}
window.handleSirenStop = function(index) {
    rentalSirenStates[index] = false;
    toggleSirenButtons(index, false);
    stopSiren(index);
}
// Job GPS button handlers
window.handleJobGpsStart = function(index) {
    toggleJobGpsButtons(index, true);
    locateJobVehicle(index);
}
window.handleJobGpsStop = function(index) {
    toggleJobGpsButtons(index, false);
    hideJobVehicleWaypoint(index);
}
// Job Siren button handlers
window.handleJobSirenStart = function(index) {
    jobSirenStates[index] = true;
    toggleJobSirenButtons(index, true);
    startJobSiren(index);
}
window.handleJobSirenStop = function(index) {
    jobSirenStates[index] = false;
    toggleJobSirenButtons(index, false);
    stopJobSiren(index);
}


function locateJobVehicle(index) {
    // Clear any previous interval for this job vehicle
    if (jobGpsIntervals[index]) {
        clearInterval(jobGpsIntervals[index]);
    }
    // Immediately set GPS route
    fetch(`https://jd-carspawner/locateJobVehicle`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ jobVehicleIndex: index })
    });
    // Set interval to update GPS every 30 seconds
    jobGpsIntervals[index] = setInterval(() => {
        fetch(`https://jd-carspawner/locateJobVehicle`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ jobVehicleIndex: index })
        });
    }, 30000);
}

function hideJobVehicleWaypoint(index) {
    // Stop GPS updates for this job vehicle
    if (jobGpsIntervals[index]) {
        clearInterval(jobGpsIntervals[index]);
        delete jobGpsIntervals[index];
    }
    fetch(`https://jd-carspawner/hideJobVehicleWaypoint`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ jobVehicleIndex: index })
    });
}

function storeJobVehicle(index) {
    // Stop GPS updates for this job vehicle
    if (jobGpsIntervals[index]) {
        clearInterval(jobGpsIntervals[index]);
        delete jobGpsIntervals[index];
    }
    // Stop siren if active
    if (jobSirenStates[index]) {
        stopJobSiren(index);
        delete jobSirenStates[index];
    }
    fetch(`https://jd-carspawner/storeJobVehicle`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ jobVehicleIndex: index })
    });
}

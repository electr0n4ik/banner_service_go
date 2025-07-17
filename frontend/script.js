const API_BASE = window.location.origin;

async function checkStatus() {
    try {
        const response = await fetch(`${API_BASE}/api/v1/status`);
        const data = await response.json();
        
        document.getElementById('status').innerHTML = `
            <strong>Status:</strong> ✅ Online<br>
            <strong>Version:</strong> ${data.version}<br>
            <strong>Uptime:</strong> ${data.uptime}
        `;
    } catch (error) {
        document.getElementById('status').innerHTML = `
            <strong>Status:</strong> ❌ Offline<br>
            <strong>Error:</strong> ${error.message}
        `;
    }
}

async function sendEcho() {
    const message = document.getElementById('messageInput').value;
    
    if (!message.trim()) {
        alert('Please enter a message');
        return;
    }

    try {
        const response = await fetch(`${API_BASE}/api/v1/echo`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ message: message })
        });

        const data = await response.json();
        
        document.getElementById('echoResult').innerHTML = `
            <strong>Echo:</strong> ${data.echo}<br>
            <strong>Timestamp:</strong> ${new Date(data.timestamp * 1000).toLocaleString()}
        `;
    } catch (error) {
        document.getElementById('echoResult').innerHTML = `
            <strong>Error:</strong> ${error.message}
        `;
    }
}

// Проверяем статус при загрузке страницы
document.addEventListener('DOMContentLoaded', checkStatus);
let currentPage = 1;
const pageSize = 10;
let totalPages = 1;
let currentUserName = '';

async function sendMessage() {
    const msg = document.getElementById('msgInput').value;
    let name = document.getElementById('nameInput').value;
    const responseArea = document.getElementById('responseArea');
    const prompt = document.getElementById('prmpInput').value;

    responseArea.textContent = '已送出，等待伺服器回應...'

    if (!name) {
    name = 'unnamed'
    }

    try {
    const res = await fetch('/send_image', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
        user_name: name,
        image_base64: msg,
        prompt: prompt
        })
    });
    const data = await res.json();
    if (data.status === 'ok') {
        responseArea.textContent = '回應 emoji: ' + data.emoji + ' 圖片 id: ' + data.history_id;
    } else {
        responseArea.textContent = '錯誤: ' + data.error;
    }
    } catch (err) {
    responseArea.textContent = '連線失敗: ' + err;
    }
}

async function loadHistory(page = 1) {
    currentPage = page;
    const offset = (currentPage - 1) * pageSize;
    const list = document.getElementById('historyList');
    const nameInput = document.getElementById('nameSearch');
    const userName = nameInput?.value?.trim();
    currentUserName = userName;

    list.innerHTML = '';

    const url = userName ? '/history' : '/history_all';
    const fetchOptions = userName
        ? {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ user_name: userName, offset: offset, limit: pageSize })
        }
        : {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ offset: offset, limit: pageSize })
        };
    const finalUrl = url;
    try {
        const res = await fetch(finalUrl, fetchOptions);
        const data = await res.json();
        if (data.status === 'ok') {
            totalPages = Math.ceil(data.total / pageSize);
            document.getElementById('pageInfo').textContent = `第 ${currentPage} 頁 / 共 ${totalPages} 頁`;

            for (const item of data.history) {
                const tr = document.createElement('tr');

                const tdName = `<td>${item.user_name || userName || 'unnamed'}</td>`;
                const tdTime = `<td>${item.timestamp}</td>`;
                const tdEmoji = `<td>${item.emoji}</td>`;
                const tdImgBtn = `
                    <td>
                    <button onclick="toggleImage(this, '${item.image_base64}')">顯示圖片</button>
                    <div style="display:none;"></div>
                    </td>`;
                const tdId = `<td>${item.history_id}</td>`;
                const tdFeedback = `
                    <td>
                    <button onclick="showFeedbackForm(this, ${item.history_id}, '${item.image_base64}')">回饋</button>
                    <div class="feedback-form" style="display:none;">
                        <input type="number" min="1" max="5" placeholder="評分 (1-5)">
                        <input type="text" placeholder="留言...">
                        <button onclick="submitFeedback(this, ${item.history_id}, '${item.user_name || userName || 'unnamed'}')">送出</button>
                        <p class="status"></p>
                    </div>
                    </td>`;

                tr.innerHTML = tdName + tdTime + tdEmoji + tdImgBtn + tdId + tdFeedback;
                list.appendChild(tr);
            }
        } else {
            list.innerHTML = `<tr><td colspan="6">錯誤: ${data.error}</td></tr>`;
        }
    } catch (err) {
        list.innerHTML = `<tr><td colspan="6">連線失敗: ${err}</td></tr>`;
    }
}

function prevPage() {
    if (currentPage > 1) {
        loadHistory(currentPage - 1);
    }
}

function nextPage() {
    if (currentPage < totalPages) {
        loadHistory(currentPage + 1);
    }
}


function toggleImage(button, imageData) {
    const container = button.nextElementSibling;
    if (container.style.display === 'none') {
    const img = document.createElement('img');

    // 判斷是否是 base64（簡單判斷開頭）
    if (imageData.startsWith('data:image/') || /^[A-Za-z0-9+/=]{100,}$/.test(imageData)) {
        img.src = imageData.startsWith('data:image/')
        ? imageData
        : 'data:image/png;base64,' + imageData;
    } else {
        // 當作 URL 處理（可支援相對路徑或絕對網址）
        img.src = imageData;
    }

    img.style.maxWidth = '200px';
    container.innerHTML = '';
    container.appendChild(img);
    container.style.display = 'block';
    button.textContent = '隱藏圖片';
    } else {
    container.style.display = 'none';
    button.textContent = '顯示圖片';
    }
}

function showFeedbackForm(button) {
    const form = button.nextElementSibling;
    form.style.display = (form.style.display === 'none') ? 'block' : 'none';
}

async function submitFeedback(button, imageResultId) {
    const form = button.parentElement;
    const rating = parseInt(form.querySelector('input[type=number]').value);
    const comment = form.querySelector('input[type=text]').value;
    const status = form.querySelector('.status');

    try {
    const res = await fetch('/feedback', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
        image_result_id: imageResultId,
        rating: rating,
        comment: comment
        })
    });
    const data = await res.json();
    if (data.status === 'ok') {
        status.textContent = '回饋送出成功';
    } else {
        status.textContent = '錯誤: ' + data.error;
    }
    } catch (err) {
    status.textContent = '送出失敗: ' + err;
    }
}
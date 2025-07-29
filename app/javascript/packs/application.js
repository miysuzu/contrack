import Rails from "@rails/ujs"
import Turbolinks from "turbolinks"
import * as ActiveStorage from "@rails/activestorage"
import "channels"

Rails.start()
Turbolinks.start()
ActiveStorage.start()

// Bootstrap と SCSS 読み込み
import "bootstrap"
import "../stylesheets/application"

// 通知ドロップダウンの機能
function toggleNotifications() {
  const dropdown = document.getElementById('notificationDropdown');

  if (dropdown.style.display === 'none' || dropdown.style.display === '') {
    dropdown.style.display = 'block';
  } else {
    dropdown.style.display = 'none';
  }
}

// 画面クリックで閉じる
document.addEventListener('click', function (event) {
  const dropdown = document.getElementById('notificationDropdown');
  const bell = document.querySelector('.notification-container button');
  if (!dropdown || !bell) return;

  if (!dropdown.contains(event.target) && !bell.contains(event.target)) {
    dropdown.style.display = 'none';
  }
});

// グローバル関数として公開
window.toggleNotifications = toggleNotifications;

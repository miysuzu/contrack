// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Bootstrap 5 JavaScript はCDNで読み込み済み

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
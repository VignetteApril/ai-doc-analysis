// 登录提示框关闭功能
(function() {
  // 初始化函数
  function initCloseButtons() {
    // 为所有关闭按钮添加点击事件
    var closeButtons = document.querySelectorAll('.flash-close');
    closeButtons.forEach(function(button) {
      // 先移除可能存在的事件监听器，避免重复绑定
      button.removeEventListener('click', handleCloseClick);
      button.addEventListener('click', handleCloseClick);
    });
  }

  // 点击处理函数
  function handleCloseClick(e) {
    e.preventDefault();
    e.stopPropagation();
    // 找到包含此按钮的flash-message元素
    var flashMessage = this.closest('.flash-message');
    if (flashMessage) {
      flashMessage.remove();
      // 检查是否还有其他提示框
      var remainingMessages = document.querySelectorAll('.flash-message');
      if (remainingMessages.length === 0) {
        var flashContainer = document.querySelector('.flash-container');
        if (flashContainer) {
          flashContainer.remove();
        }
      }
    }
  }

  // 等待DOM加载完成
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initCloseButtons);
  } else {
    initCloseButtons();
  }

  // 监听Turbo事件，当页面内容更新时重新初始化
  if (window.Turbo) {
    document.addEventListener('turbo:load', initCloseButtons);
    document.addEventListener('turbo:frame-load', initCloseButtons);
    document.addEventListener('turbo:render', initCloseButtons);
  }
})();

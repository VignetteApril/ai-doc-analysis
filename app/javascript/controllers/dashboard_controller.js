import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.setupTabNavigation();
    this.setupUserMenu();
  }

  setupTabNavigation() {
    const tabButtons = document.querySelectorAll(".tab-button");
    
    tabButtons.forEach(button => {
      button.addEventListener("click", (e) => {
        e.preventDefault();
        
        const tabId = button.dataset.tab;
        
        // 移除所有 tab 按钮的选中状态
        tabButtons.forEach(btn => {
          btn.classList.remove("active");
          btn.classList.add("inactive");
        });
        
        // 隐藏所有 tab 内容
        document.querySelectorAll(".tab-content").forEach(content => {
          content.classList.add("hidden");
        });
        
        // 添加当前 tab 按钮的选中状态
        button.classList.remove("inactive");
        button.classList.add("active");
        
        // 显示当前 tab 内容
        document.getElementById(`${tabId}-content`).classList.remove("hidden");
      });
    });
  }

  setupUserMenu() {
    const userMenuButton = document.getElementById("user-menu-button");
    const userMenu = document.getElementById("user-menu");
    
    if (userMenuButton && userMenu) {
      userMenuButton.addEventListener("click", (e) => {
        e.preventDefault();
        userMenu.classList.toggle("hidden");
      });
      
      // 点击页面其他地方关闭菜单
      document.addEventListener("click", (e) => {
        if (!userMenuButton.contains(e.target) && !userMenu.contains(e.target)) {
          userMenu.classList.add("hidden");
        }
      });
    }
  }
}